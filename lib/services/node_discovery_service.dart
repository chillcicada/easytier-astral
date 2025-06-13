import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/models_mod/all_settings_cz.dart';
import 'package:astral/k/models_mod/user_node_cz.dart';

import '../k/models/user_node.dart';

import 'package:uuid/uuid.dart';

class NodeDiscoveryService {
  static final NodeDiscoveryService _instance = NodeDiscoveryService._internal();
  factory NodeDiscoveryService() => _instance;
  NodeDiscoveryService._internal();

  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  final UserNodeCz _userNodeCz = UserNodeCz();
  AllSettingsCz? _allSettingsCz;
  Aps? _aps;
  
  /// 当前用户节点信息
  UserNode? _currentUser;
  
  /// 是否正在运行
  bool _isRunning = false;
  
  /// UDP Socket用于广播
  RawDatagramSocket? _udpSocket;
  
  /// UDP Socket用于消息接收
  RawDatagramSocket? _messageSocket;
  
  /// 当前用户的消息接收端口
  int? _messagePort;
  
  /// 广播间隔（秒）
  static const int _broadcastInterval = 2;
  
  /// 清理间隔（秒）
  static const int _cleanupInterval = 5;
  
  /// 广播目标地址
  static const String _broadcastAddress = '255.255.255.255';
  
  /// 广播目标端口
  static const int _broadcastPort = 37628;
  
  /// 消息回调函数
  Function(String fromUserId, String fromUserName, String message)? _onMessageReceived;

  /// 启动节点发现服务
  Future<void> start() async {
    if (_isRunning) return;
    
    try {
      await _initCurrentUser();
      // 尝试初始化消息Socket，失败不影响整体启动
      try {
        await _initMessageSocket();
        // 同步更新当前用户的消息端口
        if (_currentUser != null && _messagePort != null) {
          _currentUser!.messagePort = _messagePort;
          await _userNodeCz.addOrUpdateUserNode(_currentUser!);
        }
        print('✓ 消息Socket初始化成功');
      } catch (e) {
        print('⚠️ 消息Socket初始化失败，消息功能将不可用: $e');
      }
      
      // 尝试初始化UDP Socket，失败不影响整体启动
      try {
        await _initUdpSocket();
        print('✓ UDP Socket初始化成功');
      } catch (e) {
        print('⚠️ UDP Socket初始化失败，广播功能将不可用: $e');
      }
      
      _startBroadcastTimer();
      _startCleanupTimer();
      _isRunning = true;
      
      if (_messagePort != null) {
        print('✓ 节点发现服务已启动');
      } else {
        print('⚠️ 节点发现服务已启动，但消息功能不可用');
      }
    } catch (e) {
      print('✗ 启动节点发现服务失败: $e');
      print('⚠️ 服务将以受限模式运行');
      _isRunning = true; // 即使部分功能失败，也标记为运行状态
    }
  }

  /// 停止节点发现服务
  Future<void> stop() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    
    // 停止定时器
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    // 关闭UDP Socket
    _udpSocket?.close();
    _udpSocket = null;
    
    // 关闭消息Socket
    _messageSocket?.close();
    _messageSocket = null;
    
    print('节点发现服务已停止');
  }

  /// 初始化当前用户信息
  Future<void> _initCurrentUser() async {
    _aps ??= Aps();
    final playerName = _aps!.PlayerName.value;
    final userId = await _generateOrGetUserId();
    
    _currentUser = UserNode(
      userId: userId,
      userName: playerName.isNotEmpty ? playerName : '匿名用户',
      avatar: null, // 可以后续添加头像功能
      tags: ['default'], // 默认标签
      statusMessage: '在线',
      isOnline: true,
      messagePort: _messagePort,
      lastSeen: DateTime.now(), // 确保设置当前时间
    );
    
    // 将自己添加到用户列表中
    await _userNodeCz.addOrUpdateUserNode(_currentUser!);
  }

  /// 生成或获取用户ID
  Future<String> _generateOrGetUserId() async {
    // 确保 AllSettingsCz 已初始化
    _allSettingsCz ??= AllSettingsCz(AppDatabase().isar);
    
    // 从数据库获取已保存的用户ID
    String? existingUserId = await _allSettingsCz!.getUserId();
    
    if (existingUserId != null && existingUserId.isNotEmpty) {
      return existingUserId;
    }
    
    // 如果没有保存的用户ID，生成新的并保存
    String newUserId = const Uuid().v4();
    await _allSettingsCz!.setUserId(newUserId);
    return newUserId;
  }

  /// 开始定期广播
  void _startBroadcastTimer() {
    _broadcastTimer = Timer.periodic(
      const Duration(seconds: _broadcastInterval),
      (_) => _broadcastSelf(),
    );
    
    // 立即广播一次
    _broadcastSelf();
  }

  /// 开始定期清理
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: _cleanupInterval),
      (timer) => cleanupOfflineUsers(),
    );
  }

  /// 广播自己的信息
  Future<void> _broadcastSelf() async {
    if (_currentUser == null) return;
    
    try {
      // 确保消息端口信息是最新的
      _currentUser!.messagePort = _messagePort;
      
      // 更新当前用户的最后活跃时间
      _currentUser!.updateOnlineStatus();
      await _userNodeCz.addOrUpdateUserNode(_currentUser!);
      
      // 创建广播消息
      final broadcastMessage = _currentUser!.toBroadcastMessage();
      final messageJson = jsonEncode(broadcastMessage);
      
      // 可以通过UDP广播或者现有的网络模块发送
      await _sendBroadcastMessage(messageJson);
      
      print('广播用户信息: ${_currentUser!.userName}');
    } catch (e) {
      print('广播失败: $e');
    }
  }

  /// 初始化消息接收Socket
  Future<void> _initMessageSocket() async {
    print('=== 开始初始化消息接收Socket ===');
    
    try {
      // 尝试绑定到随机端口
      _messageSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _messagePort = _messageSocket!.port;
      
      print('✓ 消息接收Socket已初始化，端口: $_messagePort');
      
      // 同步更新当前用户的消息端口
      if (_currentUser != null && _messagePort != null) {
        _currentUser!.messagePort = _messagePort;
        await _userNodeCz.addOrUpdateUserNode(_currentUser!);
        print('✓ 已同步更新当前用户的消息端口: $_messagePort');
      }
      
      // 监听消息
      _messageSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _messageSocket!.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              _handleReceivedMessage(message, datagram.address.address);
            } catch (e) {
              print('解码消息失败: $e');
            }
          }
        }
      }, onError: (error) {
        print('✗ 消息Socket监听错误: $error');
        if (error is SocketException) {
          final socketError = error as SocketException;
          print('消息Socket错误详情:');
          print('  - 错误消息: ${socketError.message}');
          if (socketError.osError != null) {
            print('  - OS错误: ${socketError.osError!.errorCode} - ${socketError.osError!.message}');
            
            // 处理特定的网络错误
            if (socketError.osError!.errorCode == 1232) {
              print('⚠️ 消息Socket网络访问权限错误');
              print('⚠️ 消息功能将被禁用，但应用将继续运行');
              _messageSocket?.close();
              _messageSocket = null;
              _messagePort = null;
              return;
            }
          }
        }
        
        // 对于其他错误，尝试重新初始化
        print('⚠️ 消息Socket遇到问题，将尝试重新初始化...');
        try {
          _messageSocket?.close();
          _messageSocket = null;
          _messagePort = null;
          // 延迟重试
          Timer(const Duration(seconds: 3), () {
            if (_isRunning) {
              print('🔄 尝试重新初始化消息Socket...');
              _initMessageSocket();
            }
          });
        } catch (e) {
          print('清理消息Socket时出错: $e');
        }
      });
      
    } catch (e) {
      print('✗ 初始化消息接收Socket失败: $e');
      _messageSocket = null;
      _messagePort = null;
      
      if (e is SocketException && e.osError?.errorCode == 1232) {
        print('⚠️ 网络权限错误，消息功能将被禁用');
        print('⚠️ 建议以管理员身份运行应用或检查防火墙设置');
        // 不抛出异常，让应用继续运行
        return;
      }
      
      // 对于其他错误，记录但不崩溃
      print('⚠️ 消息Socket初始化失败，将在稍后重试');
      Timer(const Duration(seconds: 5), () {
        if (_isRunning) {
          print('🔄 重试初始化消息Socket...');
          _initMessageSocket();
        }
      });
    }
    
    print('=== 消息接收Socket初始化完成 ===\n');
  }
  
  /// 初始化UDP Socket
  Future<void> _initUdpSocket() async {
    print('=== 开始初始化UDP Socket ===');
    
    try {
      // 先检查网络接口是否可用
      print('检查网络接口...');
      final interfaces = await NetworkInterface.list();
      print('发现 ${interfaces.length} 个网络接口');
      
      if (interfaces.isEmpty) {
        print('⚠️ 没有可用的网络接口');
        return;
      }
      
      // 显示可用的网络接口
      for (int i = 0; i < interfaces.length; i++) {
        final interface = interfaces[i];
        print('接口 ${i + 1}: ${interface.name} (${interface.addresses.length} 个地址)');
      }
      
      print('尝试绑定到端口 $_broadcastPort...');
      // 绑定到广播端口用于接收
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      print('✓ 成功绑定到端口 $_broadcastPort');
      
      _udpSocket!.broadcastEnabled = true;
      print('✓ 广播模式已启用');
      
      // 监听接收到的数据
      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            print('收到广播数据: ${message.length} 字符，来源: ${datagram.address.address}:${datagram.port}');
            handleReceivedBroadcast(message, datagram.address.address);
          }
        }
      }, onError: (error) {
        print('✗ UDP Socket监听错误: $error');
        if (error is SocketException) {
          final socketError = error as SocketException;
          print('Socket监听错误详情:');
          print('  - 错误消息: ${socketError.message}');
          if (socketError.osError != null) {
            print('  - OS错误: ${socketError.osError!.errorCode} - ${socketError.osError!.message}');
          }
        }
      });
      
      print('✓ UDP Socket已成功初始化，监听端口: ${_udpSocket!.port}');
    } catch (e) {
      print('✗ 初始化UDP Socket失败: $e');
      
      if (e is SocketException) {
        final socketError = e as SocketException;
        print('Socket初始化错误详情:');
        print('  - 错误消息: ${socketError.message}');
        print('  - 地址: ${socketError.address}');
        print('  - 端口: ${socketError.port}');
        if (socketError.osError != null) {
          print('  - OS错误码: ${socketError.osError!.errorCode}');
          print('  - OS错误描述: ${socketError.osError!.message}');
        }
      }
      
      // 如果绑定指定端口失败，尝试绑定任意端口
      print('尝试使用随机端口作为备用方案...');
      try {
        _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        print('✓ 成功绑定到随机端口');
        
        _udpSocket!.broadcastEnabled = true;
        print('✓ 广播模式已启用');
        
        _udpSocket!.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = _udpSocket!.receive();
            if (datagram != null) {
              try {
                final message = utf8.decode(datagram.data);
                print('收到广播数据: ${message.length} 字符，来源: ${datagram.address.address}:${datagram.port}');
                handleReceivedBroadcast(message, datagram.address.address);
              } catch (e) {
                print('解码广播消息失败: $e');
              }
            }
          }
        }, onError: (error) {
          print('✗ UDP Socket监听错误: $error');
          if (error is SocketException) {
            final socketError = error as SocketException;
            print('Socket监听错误详情:');
            print('  - 错误消息: ${socketError.message}');
            if (socketError.osError != null) {
              print('  - OS错误: ${socketError.osError!.errorCode} - ${socketError.osError!.message}');
              
              // 处理特定的网络错误，避免应用崩溃
              if (socketError.osError!.errorCode == 1232) {
                print('⚠️ 网络访问权限错误（可能是网卡切换导致）');
                print('🔄 将尝试重新初始化UDP Socket...');
                try {
                  _udpSocket?.close();
                  _udpSocket = null;
                  // 延迟重试，等待网络状态稳定
                  Timer(const Duration(seconds: 3), () {
                    if (_isRunning) {
                      print('🔄 重新尝试初始化UDP Socket（错误码1232恢复）...');
                      _initUdpSocket();
                    }
                  });
                } catch (e) {
                  print('清理UDP Socket时出错: $e');
                }
                return;
              }
            }
          }
          
          // 对于其他网络错误，记录日志但不让应用崩溃
          print('⚠️ 网络监听遇到问题，将尝试重新初始化Socket');
          try {
            _udpSocket?.close();
            _udpSocket = null;
            // 延迟重试
            Timer(const Duration(seconds: 5), () {
              if (_isRunning) {
                print('🔄 尝试重新初始化UDP Socket...');
                _initUdpSocket();
              }
            });
          } catch (e) {
            print('清理Socket时出错: $e');
          }
        });
        
        print('✓ UDP Socket已初始化（备用端口），监听端口: ${_udpSocket!.port}');
      } catch (e2) {
        print('✗ 初始化UDP Socket完全失败: $e2');
        
        if (e2 is SocketException) {
          final socketError = e2 as SocketException;
          print('备用Socket初始化错误详情:');
          print('  - 错误消息: ${socketError.message}');
          if (socketError.osError != null) {
            print('  - OS错误码: ${socketError.osError!.errorCode}');
            print('  - OS错误描述: ${socketError.osError!.message}');
          }
        }
        
        _udpSocket = null;
        print('⚠️ 所有Socket初始化尝试均失败，网络广播功能不可用');
      }
    }
    
    print('=== UDP Socket初始化完成 ===\n');
  }
  
  /// 发送广播消息
  Future<void> _sendBroadcastMessage(String message) async {
    print('=== 开始发送广播消息 ===');
    print('消息长度: ${message.length} 字符');
    print('目标地址: $_broadcastAddress:$_broadcastPort');
    
    // 改为每次发送时临时创建Socket
    RawDatagramSocket? tempSocket;
    try {
      tempSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      tempSocket.broadcastEnabled = true;
      print('临时Socket已创建，端口: \${tempSocket.port}');
      final data = utf8.encode(message);
      final bytesSent = tempSocket.send(data, InternetAddress(_broadcastAddress), _broadcastPort);
      if (bytesSent > 0) {
        print('✓ 广播消息发送成功');
        print('发送字节数: \$bytesSent');
        print('消息内容预览: ${message.length > 100 ? "${message.substring(0, 100)}..." : message}');
      } else {
        print('✗ 广播消息发送失败：发送字节数为0');
      }
    } catch (e) {
      print('✗ 发送广播消息时出错: \$e');
      print('错误类型: \${e.runtimeType}');
      if (e is SocketException) {
        final socketError = e as SocketException;
        print('Socket错误详情:');
        print('  - 错误消息: \${socketError.message}');
        print('  - OS错误: \${socketError.osError}');
        print('  - 地址: \${socketError.address}');
        print('  - 端口: \${socketError.port}');
        if (socketError.osError != null) {
          print('  - 错误码: \${socketError.osError!.errorCode}');
          print('  - 错误描述: \${socketError.osError!.message}');
        }
      }
    } finally {
      tempSocket?.close();
      print('临时Socket已关闭');
    }
    print('=== 广播消息发送完成 ===\n');
  }
  


  /// 处理接收到的广播消息
  Future<void> handleReceivedBroadcast(String message, String ipAddress) async {
    try {
      print('=== 收到UDP广播 ===');
      print('原始消息内容: $message');
      print('发送方IP: $ipAddress');
      // 使用utf8解码确保正确处理中文等Unicode字符
      final data = jsonDecode(utf8.decode(message.codeUnits)) as Map<String, dynamic>;
      print('解析后的JSON数据: $data');
      
      // 特别检查messagePort字段
      final messagePortValue = data['messagePort'];
      print('messagePort字段值: $messagePortValue (类型: ${messagePortValue.runtimeType})');
      
      final userNode = UserNode.fromBroadcastMessage(data);
      print('创建的UserNode对象:');
      print('  - userId: ${userNode.userId}');
      print('  - userName: ${userNode.userName}');
      print('  - messagePort: ${userNode.messagePort}');
      print('  - statusMessage: ${userNode.statusMessage}');
      print('  - tags: ${userNode.tags}');
      
      // 不处理自己的广播
      if (userNode.userId == _currentUser?.userId) {
        print('跳过自己的广播消息');
        return;
      }
      
      // 设置IP地址
      userNode.ipAddress = ipAddress;
      userNode.messagePort = messagePortValue;
      print('设置IP地址后: ${userNode.ipAddress}');
      
      // 添加或更新用户节点
      await _userNodeCz.addOrUpdateUserNode(userNode);
      print('✓ 发现用户: ${userNode.userName} (${userNode.ipAddress}:${userNode.messagePort})');
      print('=== 广播处理完成 ===\n');
    } catch (e) {
      print('✗ 处理广播消息失败: $e');
      print('原始消息: $message');
      print('=== 广播处理失败 ===\n');
    }
  }

  /// 处理接收到的消息
  void _handleReceivedMessage(String message, String fromIpAddress) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final fromUserId = data['fromUserId'] as String;
      final fromUserName = data['fromUserName'] as String;
      final messageContent = data['message'] as String;
      
      print('收到来自 $fromUserName ($fromIpAddress) 的消息: $messageContent');
      
      // 调用消息回调
      _onMessageReceived?.call(fromUserId, fromUserName, messageContent);
    } catch (e) {
      print('处理接收消息失败: $e');
    }
  }
  
  /// 发送消息给指定用户
  Future<bool> sendMessageToUser(String userId, String message) async {
    try {
      // 查找目标用户
      final targetUser = await _userNodeCz.getUserNodeById(userId);
      if (targetUser == null) {
        print('未找到目标用户: $userId');
        return false;
      }
      
      if (targetUser.ipAddress == null || targetUser.messagePort == null) {
        print('目标用户缺少IP地址或端口信息');
        return false;
      }
      
      // 构建消息
      final messageData = {
        'fromUserId': _currentUser?.userId ?? '',
        'fromUserName': _currentUser?.userName ?? '',
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final messageJson = jsonEncode(messageData);
      final data = utf8.encode(messageJson);
      
      // 发送消息
      try {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        try {
          final bytesSent = socket.send(
            data,
            InternetAddress(targetUser.ipAddress!),
            targetUser.messagePort!,
          );
          
          if (bytesSent > 0) {
            print('消息发送成功到 ${targetUser.userName} (${targetUser.ipAddress}:${targetUser.messagePort})');
            return true;
          } else {
            print('消息发送失败：发送字节数为0');
            return false;
          }
        } finally {
          socket.close();
        }
      } catch (e) {
        if (e is SocketException && e.osError?.errorCode == 1232) {
          print('⚠️ 消息发送失败：网络访问权限错误');
          print('⚠️ 请以管理员身份运行应用或检查防火墙设置');
        } else {
          print('发送消息失败: $e');
        }
        return false;
      }
    } catch (e) {
      print('发送消息时出现意外错误: $e');
      return false;
    }
  }
  
  /// 设置消息接收回调
  void setMessageCallback(Function(String fromUserId, String fromUserName, String message) callback) {
    _onMessageReceived = callback;
  }
  
  /// 获取当前用户的消息端口
  int? get messagePort => _messagePort;

  /// 清理离线用户
  Future<void> cleanupOfflineUsers() async {
    try {
      await _userNodeCz.cleanupOfflineUsers(
        timeout: const Duration(seconds: _broadcastInterval * 5),
      );
      print('清理离线用户完成');
    } catch (e) {
      print('清理离线用户失败: $e');
    }
  }

  /// 更新当前用户信息
  Future<void> updateCurrentUser({
    String? userName,
    String? avatar,
    List<String>? tags,
    String? statusMessage,
  }) async {
    if (_currentUser == null) return;
    
    if (userName != null) _currentUser!.userName = userName;
    if (avatar != null) _currentUser!.avatar = avatar;
    if (tags != null) _currentUser!.tags = tags;
    if (statusMessage != null) _currentUser!.statusMessage = statusMessage;
    
    // 确保消息端口信息是最新的
    _currentUser!.messagePort = _messagePort;
    
    _currentUser!.updateOnlineStatus();
    await _userNodeCz.addOrUpdateUserNode(_currentUser!);
    
    // 立即广播更新
    await _broadcastSelf();
  }

  /// 获取当前用户信息
  UserNode? get currentUser => _currentUser;

  /// 获取在线用户数量
  Future<int> getOnlineUserCount() async {
    final stats = await _userNodeCz.getUserNodeStats();
    return stats['online'] ?? 0;
  }

  /// 获取所有在线用户
  Future<List<UserNode>> getOnlineUsers() async {
    return await _userNodeCz.getOnlineUserNodes();
  }

  /// 监听在线用户变化
  Stream<List<UserNode>> watchOnlineUsers() {
    return _userNodeCz.watchOnlineUserNodes();
  }

  /// 搜索用户
  Future<List<UserNode>> searchUsers(String query) async {
    return await _userNodeCz.searchUserNodes(query);
  }
}