import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/models/user_node.dart';
import 'package:isar/isar.dart';

class UserNodeCz {
  static final UserNodeCz _instance = UserNodeCz._internal();
  factory UserNodeCz() => _instance;
  UserNodeCz._internal();

  /// 获取Isar实例
  Isar get _isar => AppDatabase().isar;

  /// 添加或更新用户节点
  Future<void> addOrUpdateUserNode(UserNode userNode) async {
    await _isar.writeTxn(() async {
      // 先查找是否已存在相同userId的用户
      final existingUser = await _isar.userNodes
          .filter()
          .userIdEqualTo(userNode.userId)
          .findFirst();
      
      if (existingUser != null) {
        // 更新现有用户信息
        existingUser.userName = userNode.userName;
        existingUser.avatar = userNode.avatar;
        existingUser.tags = userNode.tags;
        existingUser.statusMessage = userNode.statusMessage;
        existingUser.lastSeen = userNode.lastSeen;
        existingUser.isOnline = userNode.isOnline;
        existingUser.ipAddress = userNode.ipAddress;
        existingUser.latency = userNode.latency;
        
        await _isar.userNodes.put(existingUser);
      } else {
        // 添加新用户
        await _isar.userNodes.put(userNode);
      }
    });
  }

  /// 获取所有用户节点
  Future<List<UserNode>> getAllUserNodes() async {
    return await _isar.userNodes.where().findAll();
  }

  /// 获取在线用户节点
  Future<List<UserNode>> getOnlineUserNodes() async {
    return await _isar.userNodes
        .filter()
        .isOnlineEqualTo(true)
        .findAll();
  }

  /// 根据用户ID获取用户节点
  Future<UserNode?> getUserNodeById(String userId) async {
    return await _isar.userNodes
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
  }

  /// 根据标签获取用户节点
  Future<List<UserNode>> getUserNodesByTag(String tag) async {
    return await _isar.userNodes
        .filter()
        .tagsElementContains(tag)
        .findAll();
  }

  /// 更新用户在线状态
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    await _isar.writeTxn(() async {
      final user = await _isar.userNodes
          .filter()
          .userIdEqualTo(userId)
          .findFirst();
      
      if (user != null) {
        user.isOnline = isOnline;
        user.lastSeen = DateTime.now();
        await _isar.userNodes.put(user);
      }
    });
  }

  /// 清理离线用户（超过指定时间未活跃的用户）
  Future<void> cleanupOfflineUsers({Duration? timeout}) async {
    timeout ??= const Duration(minutes: 5);
    final cutoffTime = DateTime.now().subtract(timeout);
    
    await _isar.writeTxn(() async {
      final offlineUsers = await _isar.userNodes
          .filter()
          .lastSeenLessThan(cutoffTime)
          .findAll();
      
      for (final user in offlineUsers) {
        user.isOnline = false;
        await _isar.userNodes.put(user);
      }
    });
  }

  /// 删除用户节点
  Future<void> deleteUserNode(String userId) async {
    await _isar.writeTxn(() async {
      await _isar.userNodes
          .filter()
          .userIdEqualTo(userId)
          .deleteAll();
    });
  }

  /// 清空所有用户节点
  Future<void> clearAllUserNodes() async {
    await _isar.writeTxn(() async {
      await _isar.userNodes.clear();
    });
  }

  /// 搜索用户节点（按用户名）
  Future<List<UserNode>> searchUserNodes(String query) async {
    if (query.isEmpty) {
      return await getAllUserNodes();
    }
    
    return await _isar.userNodes
        .filter()
        .userNameContains(query, caseSensitive: false)
        .findAll();
  }

  /// 获取用户节点数量统计
  Future<Map<String, int>> getUserNodeStats() async {
    final total = await _isar.userNodes.count();
    final online = await _isar.userNodes
        .filter()
        .isOnlineEqualTo(true)
        .count();
    
    return {
      'total': total,
      'online': online,
      'offline': total - online,
    };
  }

  /// 监听用户节点变化
  Stream<List<UserNode>> watchUserNodes() {
    return _isar.userNodes.where().watch(fireImmediately: true);
  }

  /// 监听在线用户节点变化
  Stream<List<UserNode>> watchOnlineUserNodes() {
    return _isar.userNodes
        .filter()
        .isOnlineEqualTo(true)
        .watch(fireImmediately: true);
  }
}