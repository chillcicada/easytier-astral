import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/models_mod/all_settings_cz.dart';
import 'package:astral/k/models_mod/user_node_cz.dart';
import 'package:astral/services/encryption_service.dart';

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
  final EncryptionService _encryptionService = EncryptionService();
  
  /// 当前用户节点信息
  UserNode? _currentUser;
  
  /// 是否正在运行
  bool _isRunning = false;
  
  /// UDP广播相关
  RawDatagramSocket? _udpSocket;
  static const String _broadcastAddress = '255.255.255.255';
  static const int _broadcastPort = 37627;
  
  /// WebSocket服务器
  HttpServer? _webSocketServer;
  
  /// WebSocket连接列表
  final Set<WebSocket> _webSocketConnections = {};
  
  /// 当前用户的WebSocket服务端口
  int? _webSocketPort;
  
  /// 广播间隔（秒）
  static const int _broadcastInterval = 2;
  
  /// 清理间隔（秒）
  static const int _cleanupInterval = 5;
  
  /// WebSocket服务端口（原UDP广播端口）
  static const int _defaultWebSocketPort = 37628;
  
  /// 消息回调函数
  Function(String fromUserId, String fromUserName, String message)? _onMessageReceived;
  
  /// 已知的其他节点WebSocket地址
  final Set<String> _knownNodes = {};

  /// 启动节点发现服务
  Future<void> start() async {
    if (_isRunning) return;
    
    try {
      await _initCurrentUser();
      await _initUdpSocket();
      await _initWebSocketServer();
      
      _startBroadcastTimer();
      _startCleanupTimer();
      
      _isRunning = true;
      print('节点发现服务启动成功，UDP广播端口: $_broadcastPort, WebSocket端口: $_webSocketPort');
    } catch (e) {
      print('启动节点发现服务失败: $e');
      await stop();
      rethrow;
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
    try {
      _udpSocket?.close();
      _udpSocket = null;
    } catch (e) {
      print('关闭UDP Socket失败: $e');
    }
    
    // 关闭所有WebSocket连接
    for (final ws in _webSocketConnections) {
      try {
        await ws.close();
      } catch (e) {
        print('关闭WebSocket连接失败: $e');
      }
    }
    _webSocketConnections.clear();
    
    // 关闭WebSocket服务器
    try {
      await _webSocketServer?.close();
      _webSocketServer = null;
    } catch (e) {
      print('关闭WebSocket服务器失败: $e');
    }
    
    _knownNodes.clear();
    
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
      messagePort: _webSocketPort,
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
      // 确保WebSocket端口信息是最新的
      _currentUser!.messagePort = _webSocketPort;
      
      // 更新当前用户的最后活跃时间
      _currentUser!.updateOnlineStatus();
      await _userNodeCz.addOrUpdateUserNode(_currentUser!);
      
      // 创建广播消息
      final broadcastMessage = _currentUser!.toBroadcastMessage();
      final messageJson = jsonEncode(broadcastMessage);
      
      await _sendBroadcastMessage(messageJson);
      
      print('广播用户信息: ${_currentUser!.userName}');
    } catch (e) {
      print('广播失败: $e');
    }
  }

  /// 初始化UDP Socket
  Future<void> _initUdpSocket() async {
    try {
      // 检查网络接口
      final interfaces = await NetworkInterface.list();
      if (interfaces.isEmpty) {
        throw Exception('没有可用的网络接口');
      }
      
      // 绑定到广播端口
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _udpSocket!.broadcastEnabled = true;
      
      // 监听接收到的数据
      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final remoteAddress = datagram.address.address;
              handleReceivedBroadcast(message, remoteAddress);
            } catch (e) {
              print('处理UDP消息失败: $e');
            }
          }
        }
      }, onError: (error) {
        print('UDP Socket错误: $error');
        if (error.toString().contains('1232')) {
          print('网络访问权限错误，尝试重新初始化UDP Socket...');
          Future.delayed(const Duration(seconds: 2), () async {
            try {
              await _initUdpSocket();
            } catch (e) {
              print('重新初始化UDP Socket失败: $e');
            }
          });
        }
      });
      
      print('UDP Socket初始化成功，端口: $_broadcastPort');
    } catch (e) {
      print('初始化UDP Socket失败: $e');
      rethrow;
    }
  }
  
  /// 初始化WebSocket服务器
  Future<void> _initWebSocketServer() async {
    print('=== 开始初始化WebSocket服务器 ===');
    
    try {
      // 尝试绑定到默认端口，如果失败则使用随机端口
      int port = _defaultWebSocketPort;
      try {
        _webSocketServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
        _webSocketPort = port;
        print('✓ WebSocket服务器已绑定到默认端口: $port');
      } catch (e) {
        print('⚠️ 无法绑定到默认端口 $port，尝试随机端口: $e');
        _webSocketServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
        _webSocketPort = _webSocketServer!.port;
        print('✓ WebSocket服务器已绑定到随机端口: $_webSocketPort');
      }
      
      // 监听WebSocket连接
      _webSocketServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          try {
            final webSocket = await WebSocketTransformer.upgrade(request);
            _handleNewWebSocketConnection(webSocket, request.connectionInfo?.remoteAddress.address ?? 'unknown');
          } catch (e) {
            print('WebSocket升级失败: $e');
          }
        } else {
          // 非WebSocket请求，返回404
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      }, onError: (error) {
        print('✗ WebSocket服务器监听错误: $error');
        if (error is SocketException) {
          final socketError = error as SocketException;
          print('WebSocket服务器错误详情:');
          print('  - 错误消息: ${socketError.message}');
          if (socketError.osError != null) {
            print('  - OS错误: ${socketError.osError!.errorCode} - ${socketError.osError!.message}');
          }
        }
        
        // 尝试重新初始化
        print('⚠️ WebSocket服务器遇到问题，将尝试重新初始化...');
        Timer(const Duration(seconds: 3), () {
          if (_isRunning) {
            print('🔄 尝试重新初始化WebSocket服务器...');
            _initWebSocketServer();
          }
        });
      });
      
      print('✓ WebSocket服务器初始化成功，监听端口: $_webSocketPort');
      
    } catch (e) {
      print('✗ 初始化WebSocket服务器失败: $e');
      _webSocketServer = null;
      _webSocketPort = null;
      
      if (e is SocketException && e.osError?.errorCode == 1232) {
        print('⚠️ 网络权限错误，WebSocket功能将被禁用');
        print('⚠️ 建议以管理员身份运行应用或检查防火墙设置');
        return;
      }
      
      // 对于其他错误，记录但不崩溃
      print('⚠️ WebSocket服务器初始化失败，将在稍后重试');
      Timer(const Duration(seconds: 5), () {
        if (_isRunning) {
          print('🔄 重试初始化WebSocket服务器...');
          _initWebSocketServer();
        }
      });
    }
    
    print('=== WebSocket服务器初始化完成 ===\n');
  }
  
  /// 处理新的WebSocket连接
  void _handleNewWebSocketConnection(WebSocket webSocket, String remoteAddress) {
    print('新的WebSocket连接来自: $remoteAddress');
    
    _webSocketConnections.add(webSocket);
    
    // 监听WebSocket消息
    webSocket.listen(
      (dynamic message) {
        try {
          final messageStr = message.toString();
          print('收到WebSocket消息: $messageStr');
          _handleWebSocketMessage(messageStr, remoteAddress, webSocket);
        } catch (e) {
          print('处理WebSocket消息失败: $e');
        }
      },
      onDone: () {
        print('WebSocket连接已关闭: $remoteAddress');
        _webSocketConnections.remove(webSocket);
      },
      onError: (error) {
        print('WebSocket连接错误: $error');
        _webSocketConnections.remove(webSocket);
      },
    );
    
    // 向新连接发送当前用户信息
    if (_currentUser != null) {
      final broadcastMessage = _currentUser!.toBroadcastMessage();
      final messageJson = jsonEncode(broadcastMessage);
      _sendToWebSocket(webSocket, messageJson);
    }
  }
  
  /// 处理WebSocket消息
  void _handleWebSocketMessage(String message, String remoteAddress, WebSocket webSocket) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      
      // 检查消息类型
      final messageType = data['type'] as String?;
      
      if (messageType == 'broadcast') {
        // 处理节点广播消息
        handleReceivedBroadcast(message, remoteAddress);
      } else if (messageType == 'direct_message') {
        // 处理直接消息
        _handleReceivedMessage(message, remoteAddress);
      } else {
        // 默认作为广播消息处理
        handleReceivedBroadcast(message, remoteAddress);
      }
    } catch (e) {
      print('解析WebSocket消息失败: $e');
    }
  }
  
  /// 向WebSocket发送消息
  void _sendToWebSocket(WebSocket webSocket, String message) {
    try {
      webSocket.add(message);
    } catch (e) {
      print('发送WebSocket消息失败: $e');
      _webSocketConnections.remove(webSocket);
    }
  }
  
  /// 发送UDP广播消息
  Future<void> _sendBroadcastMessage(String message) async {
    RawDatagramSocket? tempSocket;
    try {
      // 每次发送时创建临时Socket
      tempSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      tempSocket.broadcastEnabled = true;
      
      final data = utf8.encode(message);
      final address = InternetAddress(_broadcastAddress);
      
      final bytesSent = tempSocket.send(data, address, _broadcastPort);
      if (bytesSent != data.length) {
        print('UDP广播发送不完整: 发送 $bytesSent/${data.length} 字节');
      }
      
    } catch (e) {
      print('发送UDP广播失败: $e');
      if (e.toString().contains('1232')) {
        print('网络访问权限错误，请检查防火墙设置');
      } else if (e.toString().contains('10013')) {
        print('权限被拒绝，请以管理员身份运行');
      } else if (e.toString().contains('10049')) {
        print('无法分配请求的地址，请检查网络配置');
      }
    } finally {
      try {
        tempSocket?.close();
      } catch (e) {
        print('关闭临时UDP Socket失败: $e');
      }
    }
  }
  
  /// 广播消息给所有WebSocket客户端
  Future<void> _broadcastToWebSocketClients(String message) async {
    final deadConnections = <WebSocket>[];
    
    for (final webSocket in _webSocketConnections) {
      try {
        webSocket.add(message);
      } catch (e) {
        print('向WebSocket客户端发送消息失败: $e');
        deadConnections.add(webSocket);
      }
    }
    
    // 清理失效的连接
    for (final deadConnection in deadConnections) {
      _webSocketConnections.remove(deadConnection);
    }
  }
  
  /// 连接到已知节点并发送消息
  Future<void> _connectToKnownNodes(String message) async {
    // 获取所有在线用户节点
    final onlineUsers = await _userNodeCz.getOnlineUserNodes();
    
    for (final user in onlineUsers) {
      if (user.userId == _currentUser?.userId) continue; // 跳过自己
      if (user.ipAddress == null || user.messagePort == null) continue;
      
      final nodeAddress = '${user.ipAddress}:${user.messagePort}';
      if (_knownNodes.contains(nodeAddress)) continue; // 已经连接过
      
      try {
        final webSocket = await WebSocket.connect('ws://$nodeAddress');
        _knownNodes.add(nodeAddress);
        
        // 发送消息
        webSocket.add(message);
        
        // 监听响应（可选）
        webSocket.listen(
          (dynamic response) {
            try {
              final responseStr = response.toString();
              _handleWebSocketMessage(responseStr, user.ipAddress!, webSocket);
            } catch (e) {
              print('处理节点响应失败: $e');
            }
          },
          onDone: () {
            _knownNodes.remove(nodeAddress);
          },
          onError: (error) {
            print('连接到节点 $nodeAddress 时出错: $error');
            _knownNodes.remove(nodeAddress);
          },
        );
        
        // 短暂延迟后关闭连接（避免长期占用资源）
        Timer(const Duration(seconds: 5), () {
          webSocket.close();
          _knownNodes.remove(nodeAddress);
        });
        
      } catch (e) {
        print('无法连接到节点 $nodeAddress: $e');
      }
    }
  }
  

  


  /// 处理接收到的广播消息
  Future<void> handleReceivedBroadcast(String message, String ipAddress) async {
    try {
      print('=== 收到UDP广播 ===');
      print('原始消息内容: $message');
      print('发送方IP: $ipAddress');
      
      final data = jsonDecode(message) as Map<String, dynamic>;
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
      print('=== UDP广播处理完成 ===\n');
    } catch (e) {
      print('✗ 处理UDP广播消息失败: $e');
      print('原始消息: $message');
      print('=== UDP广播处理失败 ===\n');
    }
  }

  /// 处理接收到的消息
  void _handleReceivedMessage(String message, String fromIpAddress) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final fromUserId = data['fromUserId'] as String;
      final fromUserName = data['fromUserName'] as String;
      String messageContent = data['message'] as String;
      
      // 获取当前房间密码用于解密
      final currentRoom = Aps().selectroom.value;
      
      // 如果当前房间是保护房间且消息看起来是加密的，则尝试解密
      if (currentRoom != null && currentRoom.encrypted && currentRoom.password.isNotEmpty) {
        if (_encryptionService.isEncryptedMessage(messageContent)) {
          final decryptedMessage = _encryptionService.decryptMessage(messageContent, currentRoom.password);
          print('收到加密消息，解密前: $messageContent');
          print('解密后: $decryptedMessage');
          messageContent = decryptedMessage;
        }
      }
      
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
      
      // 获取当前房间密码用于加密
      final currentRoom = Aps().selectroom.value;
      String encryptedMessage = message;
      
      // 如果当前房间是保护房间，则加密消息
      if (currentRoom != null && currentRoom.encrypted && currentRoom.password.isNotEmpty) {
        encryptedMessage = _encryptionService.encryptMessage(message, currentRoom.password);
        print('消息已加密，原文: $message');
        print('加密后: $encryptedMessage');
      }
      
      // 构建消息
      final messageData = {
        'type': 'direct_message',
        'fromUserId': _currentUser?.userId ?? '',
        'fromUserName': _currentUser?.userName ?? '',
        'message': encryptedMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final messageJson = jsonEncode(messageData);
      
      // 通过WebSocket发送消息
      try {
        final webSocket = await WebSocket.connect('ws://${targetUser.ipAddress}:${targetUser.messagePort}');
        
        try {
          webSocket.add(messageJson);
          print('消息发送成功到 ${targetUser.userName} (${targetUser.ipAddress}:${targetUser.messagePort})');
          
          // 等待确认或短暂延迟后关闭连接
          Timer(const Duration(seconds: 2), () {
            webSocket.close();
          });
          
          return true;
        } catch (e) {
          print('发送WebSocket消息失败: $e');
          webSocket.close();
          return false;
        }
      } catch (e) {
        print('连接到目标用户WebSocket失败: $e');
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
  
  /// 获取当前用户的WebSocket端口
  int? get messagePort => _webSocketPort;

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
    
    // 确保WebSocket端口信息是最新的
    _currentUser!.messagePort = _webSocketPort;
    
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