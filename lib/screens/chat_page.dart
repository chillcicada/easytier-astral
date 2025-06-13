import 'package:flutter/material.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/screens/user_list_page.dart';
import 'package:astral/k/models/user_node.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final _aps = Aps();

  @override
  void initState() {
    super.initState();
    // 添加一些示例消息
    _messages.addAll([
      ChatMessage(
        id: '1',
        content: '欢迎使用去中心化聊天功能！',
        sender: 'System',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isOwn: false,
      ),
      ChatMessage(
        id: '2',
        content: '这是一个基于P2P网络的聊天系统',
        sender: 'System',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isOwn: false,
      ),
    ]);
    
    // 设置消息接收回调
    _aps.nodeDiscoveryService.setMessageCallback((String senderId, String messageId, String message) {
      _onMessageReceived(senderId, message);
    });
    
  }

  @override
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: '我',
      timestamp: DateTime.now(),
      isOwn: true,
    );

    setState(() {
      _messages.add(message);
    });

    _messageController.clear();
    _scrollToBottom();

    // 向所有在线用户发送消息
    _broadcastMessage(content);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = _aps.isDesktop.watch(context);

    return Scaffold(
      body: Column(
        children: [
          // 聊天头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '去中心化聊天',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '在线用户: ${_getOnlineUserCount()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserListPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.people_outlined,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  tooltip: '用户列表',
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index], colorScheme);
                    },
                  ),
          ),
          // 消息输入区域
          _buildMessageInput(colorScheme, isDesktop),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有消息',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始一段新的对话吧！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          if (!message.isOwn) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                message.sender[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isOwn
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isOwn
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isOwn
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isOwn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: message.isOwn
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: message.isOwn
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isOwn) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                message.sender[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ColorScheme colorScheme, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                prefixIcon: IconButton(
                  onPressed: _showEmojiPicker,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              maxLines: null,
              textInputAction: isDesktop ? TextInputAction.newline : TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            backgroundColor: colorScheme.primary,
            heroTag: "chat_send",
            child: Icon(
              Icons.send,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  int _getOnlineUserCount() {
    return _aps.allUsersNode.value.length;
  }



  void _broadcastMessage(String content) async {
    // 向所有在线用户发送消息
    for (final user in _aps.allUsersNode.value) {
      if (user.userId != _aps.nodeDiscoveryService.currentUser?.userId) {
        try {
          await _aps.nodeDiscoveryService.sendMessageToUser(user.userId, content);
        } catch (e) {
          print('发送消息给 ${user.userName} 失败: $e');
        }
      }
    }
  }

  void _onMessageReceived(String senderId, String message) {
    // 打印所有在线用户信息
    print('当前在线用户列表:');
    for (var user in _aps.allUsersNode.value) {
      print('用户ID: ${user.userId}, 用户名: ${user.userName}, IP: ${user.ipAddress}');
    }

    // 查找发送者信息并打印详细信息
    final sender = _aps.allUsersNode.value.firstWhere(
      (user) => user.userId == senderId,
      orElse: () {
        print('未找到ID为 $senderId 的用户，使用默认用户信息');
        return UserNode(
          userId: senderId,
          userName: '未知用户',
          ipAddress: '',
          messagePort: 0,
          statusMessage: '',
          tags: [],
        );
      },
    );

    // 打印找到的发送者详细信息
    print('发送者详细信息:');
    print('用户ID: ${sender.userId}');
    print('用户名: ${sender.userName}');
    print('IP地址: ${sender.ipAddress}');
    print('消息端口: ${sender.messagePort}');
    print('状态消息: ${sender.statusMessage}');
    print('标签: ${sender.tags.join(", ")}');

    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      sender: sender.userName,
      timestamp: DateTime.now(),
      isOwn: false,
    );

    setState(() {
      _messages.add(chatMessage);
    });

    _scrollToBottom();
  }

  void _showEmojiPicker() {
    // TODO: 实现表情选择器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('表情选择器功能待实现'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String sender;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.isOwn,
  });
}