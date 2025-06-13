import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:astral/k/models/user_node.dart';
import 'package:astral/services/node_discovery_service.dart';
import 'package:astral/k/app_s/aps.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final NodeDiscoveryService _nodeService = NodeDiscoveryService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final Aps _aps = Aps();

  // 过滤后的用户列表
  List<UserNode> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _nodeService.start();
    effect(() {
      if (_searchQuery.isEmpty) {
        _filteredUsers = _aps.allUsersNode.value;
      } else {
        _filteredUsers =
            _aps.allUsersNode.value.where((user) {
              return user.userName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  user.tags.any(
                    (tag) =>
                        tag.toLowerCase().contains(_searchQuery.toLowerCase()),
                  );
            }).toList();
      }
    });
  }

  void _filterUsers() {}

  @override
  void dispose() {
    _searchController.dispose();
    _statusController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = _aps.isDesktop.watch(context);

    return Scaffold(
      body: Column(
        children: [
          // 头部区域
          _buildHeader(colorScheme),
          // 搜索栏
          _buildSearchBar(colorScheme),
          // 用户列表
          Expanded(
            child:
                _filteredUsers.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : _buildUserList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            tooltip: '返回',
          ),
          Icon(Icons.people_outline, color: colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '用户列表',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '在线用户: ${_aps.allUsersNode.watch(context).length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            tooltip: '节点设置',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索用户或标签...',
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _filterUsers();
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterUsers();
          });
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无在线用户',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待其他用户加入网络...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user, colorScheme);
      },
    );
  }

  Widget _buildUserCard(UserNode user, ColorScheme colorScheme) {
    final isCurrentUser = user.userId == _nodeService.currentUser?.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildUserAvatar(user, colorScheme),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.userName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '我',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.statusMessage?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user.statusMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            if (user.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children:
                      user.tags
                          .map((tag) => _buildTagChip(tag, colorScheme))
                          .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: user.isOnline ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.isOnline ? '在线' : '离线',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (user.latency != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.network_ping,
                      size: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${user.latency}ms',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        trailing:
            isCurrentUser
                ? IconButton(
                  onPressed: () => _showUserProfileDialog(context),
                  icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  tooltip: '编辑资料',
                )
                : IconButton(
                  onPressed: () => _showUserDetailsDialog(context, user),
                  icon: Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  tooltip: '用户详情',
                ),
      ),
    );
  }

  Widget _buildUserAvatar(UserNode user, ColorScheme colorScheme) {
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      try {
        // 尝试解析base64图片
        final bytes = base64Decode(user.avatar!);
        return CircleAvatar(radius: 20, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        // 如果不是base64，可能是URL或文件路径
        if (user.avatar!.startsWith('http')) {
          return CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(user.avatar!),
          );
        }
      }
    }

    // 默认头像
    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.primary.withOpacity(0.1),
      child: Text(
        user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  void _showUserProfileDialog(BuildContext context) {
    final currentUser = _nodeService.currentUser;
    if (currentUser == null) return;

    _statusController.text = currentUser.statusMessage ?? '';
    final tags = List<String>.from(currentUser.tags);

    showDialog(
      context: context,
      builder:
          (context) => _UserProfileDialog(
            currentUser: currentUser,
            statusController: _statusController,
            tagController: _tagController,
            tags: tags,
            onSave: (userName, avatar, newTags, statusMessage) async {
              await _nodeService.updateCurrentUser(
                userName: userName,
                avatar: avatar,
                tags: newTags,
                statusMessage: statusMessage,
              );

              // 同时更新Aps中的玩家名称
              if (userName != null && userName.isNotEmpty) {
                await _aps.updatePlayerName(userName);
              }
            },
          ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, UserNode user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('用户详情'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildUserAvatar(user, Theme.of(context).colorScheme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (user.statusMessage?.isNotEmpty == true)
                            Text(
                              user.statusMessage!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user.tags.isNotEmpty) ...[
                  Text('标签:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children:
                        user.tags
                            .map(
                              (tag) => _buildTagChip(
                                tag,
                                Theme.of(context).colorScheme,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '用户ID: ${user.userId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '最后活跃: ${user.lastSeen != null ? _formatTime(user.lastSeen!) : '未知'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('节点设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('刷新用户列表'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('清理离线用户'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    // 手动清理离线用户
                    await _nodeService.cleanupOfflineUsers();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已清理离线用户')));
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
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
}

class _UserProfileDialog extends StatefulWidget {
  final UserNode currentUser;
  final TextEditingController statusController;
  final TextEditingController tagController;
  final List<String> tags;
  final Function(String?, String?, List<String>, String?) onSave;

  const _UserProfileDialog({
    required this.currentUser,
    required this.statusController,
    required this.tagController,
    required this.tags,
    required this.onSave,
  });

  @override
  State<_UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<_UserProfileDialog> {
  late TextEditingController _nameController;
  String? _avatarBase64;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.userName);
    _avatarBase64 = widget.currentUser.avatar;
    _tags = List<String>.from(widget.tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('编辑个人资料'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头像选择
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceVariant,
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child:
                    _avatarBase64 != null
                        ? ClipOval(
                          child: Image.memory(
                            base64Decode(_avatarBase64!),
                            fit: BoxFit.cover,
                          ),
                        )
                        : Icon(
                          Icons.add_a_photo,
                          size: 32,
                          color: colorScheme.onSurfaceVariant,
                        ),
              ),
            ),
            const SizedBox(height: 16),
            // 用户名
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 状态消息
            TextField(
              controller: widget.statusController,
              decoration: const InputDecoration(
                labelText: '状态消息',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 标签管理
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.tagController,
                    decoration: const InputDecoration(
                      labelText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addTag(widget.tagController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 标签列表
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeTag(tag),
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _saveProfile, child: const Text('保存')),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _avatarBase64 = base64Encode(bytes);
      });
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
      });
      widget.tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveProfile() {
    widget.onSave(
      _nameController.text.trim(),
      _avatarBase64,
      _tags,
      widget.statusController.text.trim(),
    );
    Navigator.of(context).pop();
  }
}
