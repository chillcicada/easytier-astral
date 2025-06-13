import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:astral/k/app_s/aps.dart';
import 'package:flutter/material.dart';

// 公共服务器对话框组件
class PublicServersDialog extends StatefulWidget {
  final Function(String, String) onAddServer;

  const PublicServersDialog({
    Key? key,
    required this.onAddServer,
  }) : super(key: key);

  @override
  State<PublicServersDialog> createState() => _PublicServersDialogState();

  // 显示公共服务器对话框
  static Future<void> show(
    BuildContext context, 
    Function(String, String) onAddServer,
  ) async {
    // 根据屏幕宽度选择显示方式
    if (MediaQuery.of(context).size.width > 600) {
      // PC端显示为对话框
      await showDialog(
        context: context,
        builder: (context) => Hero(
          tag: 'public_servers_dialog',
          child: Dialog(
            child: SizedBox(
              width: 500,
              height: 600,
              child: PublicServersDialog(
                onAddServer: onAddServer,
              ),
            ),
          ),
        ),
      );
    } else {
      // 移动端显示为底部弹窗
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Hero(
          tag: 'public_servers_dialog',
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: PublicServersDialog(
                onAddServer: onAddServer,
              ),
            ),
          ),
        ),
      );
    }
  }

  static Future<List<Map<String, String>>?> _fetchPublicServers() async {
    try {
      final response = await http.get(
        Uri.parse('https://astral.fan/server.json'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => {
          'name': item['name'] as String,
          'url': item['url'] as String,
        }).toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      // 添加详细的错误日志
      debugPrint('获取公共服务器列表失败: $e');
      return []; // 返回空列表而不是null，避免后续空值异常
    }
  }
}

class _PublicServersDialogState extends State<PublicServersDialog> with TickerProviderStateMixin {
  List<Map<String, String>> _filteredServers = [];
  bool _isLoading = true;
  String? _error;
  final _aps = Aps();
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _scaleAnimations = {};

  @override
  void initState() {
    super.initState();
    _loadAndFilterServers();
  }

  @override
  void dispose() {
    // 清理所有动画控制器
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // 创建动画控制器
  void _createAnimationController(String serverUrl) {
    if (!_animationControllers.containsKey(serverUrl)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      final animation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      _animationControllers[serverUrl] = controller;
      _scaleAnimations[serverUrl] = animation;
    }
  }

  // 加载并过滤服务器列表
  Future<void> _loadAndFilterServers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 获取公共服务器列表
      final allServers = await PublicServersDialog._fetchPublicServers();
      if (allServers == null || allServers.isEmpty) {
        setState(() {
          _error = '获取服务器列表失败或列表为空';
          _isLoading = false;
        });
        return;
      }

      // 实时获取本地服务器列表进行过滤
      final existingUrls = _aps.servers.value.map((server) => server.url.trim().toLowerCase()).toSet();
      
      // 过滤掉已存在的服务器
      final filteredServers = allServers.where((server) {
        final serverUrl = server['url']?.trim().toLowerCase() ?? '';
        return serverUrl.isNotEmpty && !existingUrls.contains(serverUrl);
      }).toList();

      setState(() {
        _filteredServers = filteredServers;
        _isLoading = false;
      });
      
      // 为每个服务器创建动画控制器
      for (var server in filteredServers) {
        _createAnimationController(server['url']!);
      }
    } catch (e) {
      setState(() {
        _error = '获取服务器列表失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 8, 16), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.public,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '公共服务器',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '点击服务器卡片右方的添加按钮进行添加',
                textAlign: TextAlign.left,
                maxLines: null,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // 服务器列表 - 使用 Expanded 填充剩余空间
        Expanded(
          child: _buildContent(),
        ),

        // 底部按钮
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: Navigator.of(context).pop,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('关闭'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('获取中...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '获取服务器列表失败',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_filteredServers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '所有公共服务器已添加',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前没有新的公共服务器可以添加',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _filteredServers.length,
        itemBuilder: (context, index) {
          final server = _filteredServers[index];
          final serverUrl = server['url']!;
          
          // 确保动画控制器存在
          _createAnimationController(serverUrl);
          
          return AnimatedBuilder(
            animation: _scaleAnimations[serverUrl]!,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimations[serverUrl]!.value,
                child: Opacity(
                  opacity: _scaleAnimations[serverUrl]!.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _PublicServerItem(
                      server: server,
                      onAdd: () => _addServer(server['name']!, server['url']!),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 添加服务器并实时更新列表
  void _addServer(String name, String url) {
    // 调用外部回调添加服务器
    widget.onAddServer(name, url);
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加服务器: $name')),
    );
    
    // 从当前列表中移除已添加的服务器
    setState(() {
      _filteredServers.removeWhere((server) => 
        server['url']?.trim().toLowerCase() == url.trim().toLowerCase());
    });
  }
}

class _PublicServerItem extends StatefulWidget {
  final Map<String, String> server;
  final VoidCallback onAdd;

  const _PublicServerItem({
    Key? key,
    required this.server,
    required this.onAdd,
  }) : super(key: key);

  @override
  _PublicServerItemState createState() => _PublicServerItemState();
}

class _PublicServerItemState extends State<_PublicServerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (theme.brightness == Brightness.light)
              ? colorScheme.surfaceVariant.withOpacity(1.0)
              : colorScheme.surfaceVariant.withOpacity(1.0), 
          border: Border.all(
            color: _isHovered ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              widget.server['name']!, 
              style: TextStyle(
                fontSize: 16, 
                color: colorScheme.onSurface
              )
            ),
            subtitle: Text(
              widget.server['url']!,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              )
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: widget.onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('添加', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}