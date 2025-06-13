import 'package:isar/isar.dart';

part 'user_node.g.dart';

@collection
class UserNode {
  Id id = Isar.autoIncrement;
  
  /// 用户ID（peer_id）
  late String userId;
  
  /// 用户名称
  late String userName;
  
  /// 用户头像（base64编码或URL）
  String? avatar;
  
  /// 用户标签
  List<String> tags = [];
  
  /// 最后在线时间
  DateTime? lastSeen;
  
  /// 是否在线
  bool isOnline = false;
  
  /// IP地址
  String? ipAddress;
  
  /// 消息接收端口
  int? messagePort;
  
  /// 网络延迟（毫秒）
  int? latency;
  
  /// 用户状态消息
  String? statusMessage;
  
  /// 创建时间
  DateTime? createdAt;

  UserNode({
    required this.userId,
    required this.userName,
    this.avatar,
    this.tags = const [],
    DateTime? lastSeen,
    this.isOnline = false,
    this.ipAddress,
    this.messagePort,
    this.latency,
    this.statusMessage,
    DateTime? createdAt,
  }) {
    this.lastSeen = lastSeen ?? DateTime.now();
    this.createdAt = createdAt ?? DateTime.now();
  }
  
  UserNode.empty();
  
  /// 转换为广播消息格式
  Map<String, dynamic> toBroadcastMessage() {
    return {
      'userId': userId,
      'userName': userName,
      'avatar': avatar,
      'tags': tags,
      'statusMessage': statusMessage,
      'messagePort': messagePort,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// 从广播消息创建用户节点
  factory UserNode.fromBroadcastMessage(Map<String, dynamic> data) {
    return UserNode(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      avatar: data['avatar'],
      tags: List<String>.from(data['tags'] ?? []),
      statusMessage: data['statusMessage'],
      messagePort: data['messagePort'],
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isOnline: true,
    );
  }
  
  /// 更新在线状态
  void updateOnlineStatus() {
    isOnline = true;
    lastSeen = DateTime.now();
  }
  
  bool get isOffline {
    final lastSeenTime = lastSeen;
    if (lastSeenTime == null) return true;
    return DateTime.now().difference(lastSeenTime).inSeconds > 10;
  }
}