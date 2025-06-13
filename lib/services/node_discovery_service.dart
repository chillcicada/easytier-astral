import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/user_node.dart';
import 'package:astral/k/models_mod/user_node_cz.dart';
import 'package:uuid/uuid.dart';

class NodeDiscoveryService {
  static final NodeDiscoveryService _instance = NodeDiscoveryService._internal();
  factory NodeDiscoveryService() => _instance;
  NodeDiscoveryService._internal();

  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  final UserNodeCz _userNodeCz = UserNodeCz();
  final Aps _aps = Aps();
  
  /// 当前用户节点信息
  UserNode? _currentUser;
  
  /// 是否正在运行
  bool _isRunning = false;
  
  /// 广播间隔（秒）
  static const int _broadcastInterval = 10;
  
  /// 清理间隔（秒）
  static const int _cleanupInterval = 30;

  /// 启动节点发现服务
  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // 初始化当前用户信息
    await _initCurrentUser();
    
    // 开始定期广播
    _startBroadcasting();
    
    // 开始定期清理离线用户
    _startCleanup();
    
    print('节点发现服务已启动');
  }

  /// 停止节点发现服务
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    
    print('节点发现服务已停止');
  }

  /// 初始化当前用户信息
  Future<void> _initCurrentUser() async {
    final playerName = _aps.PlayerName.value;
    final userId = await _generateOrGetUserId();
    
    _currentUser = UserNode(
      userId: userId,
      userName: playerName.isNotEmpty ? playerName : '匿名用户',
      avatar: null, // 可以后续添加头像功能
      tags: ['default'], // 默认标签
      statusMessage: '在线',
      isOnline: true,
    );
    
  // 将自己添加到用户列表中
    await _userNodeCz.addOrUpdateUserNode(_currentUser!);
  }

  /// 生成或获取用户ID
  Future<String> _generateOrGetUserId() async {
    // 这里可以从数据库获取已保存的用户ID，如果没有则生成新的
    // 暂时使用UUID生成
    return const Uuid().v4();
  }

  /// 开始定期广播
  void _startBroadcasting() {
    _broadcastTimer = Timer.periodic(
      const Duration(seconds: _broadcastInterval),
      (_) => _broadcastSelf(),
    );
    
    // 立即广播一次
    _broadcastSelf();
  }

  /// 开始定期清理
  void _startCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: _cleanupInterval),
      (timer) => cleanupOfflineUsers(),
    );
  }

  /// 广播自己的信息
  Future<void> _broadcastSelf() async {
    if (_currentUser == null) return;
    
    try {
      // 更新当前用户的最后活跃时间
      _currentUser!.updateOnlineStatus();
      await _userNodeCz.addOrUpdateUserNode(_currentUser!);
      
      // 创建广播消息
      final broadcastMessage = _currentUser!.toBroadcastMessage();
      final messageJson = jsonEncode(broadcastMessage);
      
      // TODO: 这里需要集成实际的P2P网络广播功能
      // 可以通过UDP广播或者现有的网络模块发送
      await _sendBroadcastMessage(messageJson);
      
      print('广播用户信息: ${_currentUser!.userName}');
    } catch (e) {
      print('广播失败: $e');
    }
  }

  /// 发送广播消息
  Future<void> _sendBroadcastMessage(String message) async {
    // TODO: 集成实际的网络发送逻辑
    // 这里可以使用UDP广播或者通过现有的P2P网络发送
    // 示例代码：
    // await UdpBroadcast.send(message, port: 8888);
    
    // 暂时模拟接收到其他用户的广播（用于测试）
    if (Random().nextBool()) {
      await _simulateReceiveBroadcast();
    }
  }

  /// 模拟接收广播（用于测试）
  Future<void> _simulateReceiveBroadcast() async {
    final testUsers = [
      {
        'userId': 'test-user-1',
        'userName': '测试用户1',
        'avatar': null,
        'tags': ['friend', 'online'],
        'statusMessage': '正在工作',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'userId': 'test-user-2',
        'userName': '测试用户2',
        'avatar': null,
        'tags': ['colleague'],
        'statusMessage': '空闲中',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ];
    
    final randomUser = testUsers[Random().nextInt(testUsers.length)];
    await handleReceivedBroadcast(jsonEncode(randomUser));
  }

  /// 处理接收到的广播消息
  Future<void> handleReceivedBroadcast(String message) async {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final userNode = UserNode.fromBroadcastMessage(data);
      
      // 不处理自己的广播
      if (userNode.userId == _currentUser?.userId) return;
      
      // 添加或更新用户节点
      await _userNodeCz.addOrUpdateUserNode(userNode);
      
      print('发现用户: ${userNode.userName}');
    } catch (e) {
      print('处理广播消息失败: $e');
    }
  }

  /// 清理离线用户
  Future<void> cleanupOfflineUsers() async {
    try {
      await _userNodeCz.cleanupOfflineUsers(
        timeout: const Duration(seconds: _broadcastInterval * 3),
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