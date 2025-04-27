import 'package:astral/k/app_s/aps.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 使用 Riverpod 监听节点数据
    return Scaffold(
      body: Builder(
        builder: (context) {
          if (Aps().netStatus.watch(context) == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '加载玩家信息...',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          } else if (Aps().netStatus.watch(context)!.nodes.isEmpty) {
            // 添加空数据状态显示
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无房间成员',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '当前没有其他玩家连接到房间',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final player =
                            Aps().netStatus.watch(context)!.nodes[index];
                        // 使用 player.ipv4 (或其他唯一标识符) 作为 Key
                        return Padding(
                          key: ValueKey(player.ipv4), // 添加 ValueKey
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildPlayerListItem(player, colorScheme),
                        );
                      },
                      childCount: Aps().netStatus.watch(context)!.nodes.length,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // 构建列表项视图
  Widget _buildPlayerListItem(KVNodeInfo player, ColorScheme colorScheme) {
    // 根据延迟值确定颜色
    Color latencyColor = _getLatencyColor(player.latencyMs);
    // 根据连接类型选择图标
    IconData connectionIcon = _getConnectionIcon(
      _mapConnectionType(player.cost, player.ipv4, Aps().ipv4.watch(context)),
    );

    // 使用独立的StatefulWidget来管理悬停状态
    return PlayerListItemCard(
      player: player,
      colorScheme: colorScheme,
      latencyColor: latencyColor,
      connectionIcon: connectionIcon,
      localIPv4: Aps().ipv4.watch(context),
      buildDesktopPlayerListItem: _buildDesktopPlayerListItem,
    );
  }

  // 为桌面设备优化的列表项布局
  Widget _buildDesktopPlayerListItem(
    KVNodeInfo player,
    ColorScheme colorScheme,
    Color latencyColor,
    IconData connectionIcon,
  ) {
    String displayName =
        player.hostname.startsWith('PublicServer_')
            ? player.hostname.substring('PublicServer_'.length)
            : player.hostname;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧玩家基本信息
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 玩家名称和连接类型
              Row(
                children: [
                  Icon(Icons.person, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getConnectionTypeColor(
                        _mapConnectionType(
                          player.cost,
                          player.ipv4,
                          Aps().ipv4.watch(context),
                        ),
                        colorScheme,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(connectionIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _mapConnectionType(
                            player.cost,
                            player.ipv4,
                            Aps().ipv4.watch(context),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // IP地址
              _buildInfoRow(
                Icons.lan,
                'IP地址',
                player.ipv4,
                colorScheme,
                showCopyButton: true,
              ),
              const SizedBox(height: 8),

              // ET版本
              _buildInfoRow(Icons.memory, 'ET版本', player.version, colorScheme),
              const SizedBox(height: 8),

              // NAT类型
              _buildInfoRow(
                _getNatTypeIcon(player.nat),
                'NAT类型',
                player.nat,
                colorScheme,
                valueColor: _getNatTypeColor(player.nat),
              ),

              // 添加跃点信息显示
              if (player.hops.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildHopsInfo(player.hops, colorScheme),
              ],
            ],
          ),
        ),

        // 中间网络状态信息
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 延迟信息
              _buildInfoRow(
                Icons.speed,
                '延迟',
                '${player.latencyMs} ms',
                colorScheme,
                valueColor: latencyColor,
              ),
              const SizedBox(height: 8),

              // 丢包率信息
              _buildInfoRow(
                Icons.error_outline,
                '丢包率',
                '${player.lossRate.toStringAsFixed(2)}%', // 修改这里，保留2位小数
                colorScheme,
                valueColor: _getPacketLossColor(player.lossRate),
              ),
              const SizedBox(height: 8),

              // 上传下载速度
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkDataItem(
                      '上传',
                      _formatSpeed(
                        player.connections.isEmpty
                            ? 0.0
                            : player.connections[0].rxPackets.toDouble(),
                      ), // 使用格式化方法
                      Icons.upload,
                      colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildNetworkDataItem(
                      '下载',
                      _formatSpeed(
                        player.connections.isEmpty
                            ? 0.0
                            : player.connections[0].txPackets.toDouble(),
                      ), // 使用格式化方法
                      Icons.download,
                      colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 右侧包数据信息
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNetworkDataItem(
                '发送包',
                '${player.connections.isEmpty ? 0.0 : player.connections[0].rxPackets.toDouble()}',
                Icons.send,
                colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _buildNetworkDataItem(
                '接收包',
                '${player.connections.isEmpty ? 0.0 : player.connections[0].txPackets.toDouble()}',
                Icons.call_received,
                colorScheme.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 添加一个速度单位转换的辅助方法
  String _formatSpeed(double speedInKB) {
    if (speedInKB >= 1048576) {
      // >= 1024 * 1024 KB (1 GB/s)
      return '${(speedInKB / 1048576).toStringAsFixed(2)} GB/s';
    } else if (speedInKB >= 1024) {
      // >= 1024 KB (1 MB/s)
      return '${(speedInKB / 1024).toStringAsFixed(2)} MB/s';
    } else {
      return '$speedInKB KB/s';
    }
  }

  // 更紧凑的网络数据项
  Widget _buildNetworkDataItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建信息行
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme, {
    Color? valueColor,
    bool showCopyButton = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        // 添加复制按钮到标签和值之间
        if (showCopyButton)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: '复制$label',
            onPressed: () {
              // 复制到剪贴板
              Clipboard.setData(ClipboardData(text: value));
              // 显示提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已复制: $value'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 根据延迟值获取颜色
  Color _getLatencyColor(double latency) {
    if (latency < 50) {
      return Colors.green;
    } else if (latency < 100) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // 根据丢包率获取颜色
  Color _getPacketLossColor(double lossRate) {
    if (lossRate < 1.0) {
      return Colors.green;
    } else if (lossRate < 5.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // 如果传入数值=1就是p2p 否则是relay 最后判断是不是等于本机IP如果等于就是direct 本机ip传入
  String _mapConnectionType(int connType, String ip, String thisip) {
    // 新增服务器IP判断
    if (ip == "0.0.0.0") {
      return '服务器';
    }
    // 如果是本机IP，返回direct
    if (thisip != null && ip == thisip) {
      // 检查 thisip 是否为 null
      return '本机';
    }
    // 根据连接成本判断连接类型
    if (connType == 1) {
      return '直链';
    } else if (connType >= 2) {
      return '中转';
    }
    return '未知';
  }

  // 根据连接类型获取图标
  IconData _getConnectionIcon(String connectionType) {
    // 将连接类型转为小写并进行匹配
    String lowerType = connectionType.toLowerCase();
    // 新增服务器图标
    if (lowerType.contains('server') || lowerType.contains('服务器')) {
      return Icons.dns;
    } else if (lowerType.contains('p2p') || lowerType.contains('直链')) {
      return Icons.link;
    } else if (lowerType.contains('relay') || lowerType.contains('中转')) {
      return Icons.swap_horiz;
    } else if (lowerType.contains('direct') || lowerType.contains('本机')) {
      return Icons.computer;
    } else {
      return Icons.device_unknown;
    }
  }

  // 根据连接类型获取颜色
  Color _getConnectionTypeColor(
    String connectionType,
    ColorScheme colorScheme,
  ) {
    // 将连接类型转为小写并进行匹配
    String lowerType = connectionType.toLowerCase();
    if (lowerType.contains('server') || lowerType.contains('服务器')) {
      return Colors.deepPurple;
    } else if (lowerType.contains('p2p') || lowerType.contains('直链')) {
      return Colors.green;
    } else if (lowerType.contains('relay') || lowerType.contains('中转')) {
      return Colors.orange;
    } else if (lowerType.contains('direct') || lowerType.contains('本机')) {
      return colorScheme.primary;
    } else {
      return Colors.grey;
    }
  }

  // 将NAT类型转换为中文
  String _mapNatType(String natType) {
    switch (natType) {
      case 'Unknown':
        return '未知';
      case 'OpenInternet':
        return '开放网络';
      case 'NoPat':
        return '无PAT';
      case 'FullCone':
        return '全锥形';
      case 'Restricted':
        return '受限锥形';
      case 'PortRestricted':
        return '端口受限锥形';
      case 'Symmetric':
        return '对称型';
      case 'SymUdpFirewall':
        return '对称UDP防火墙';
      case 'SymmetricEasyInc':
        return '对称递增型';
      case 'SymmetricEasyDec':
        return '对称递减型';
      default:
        return '未知';
    }
  }

  // 根据NAT类型获取图标
  IconData _getNatTypeIcon(String natType) {
    if (natType.contains('开放') || natType.contains('全锥形')) {
      return Icons.public;
    } else if (natType.contains('受限')) {
      return Icons.shield;
    } else if (natType.contains('端口受限')) {
      return Icons.security;
    } else if (natType.contains('对称')) {
      return Icons.sync_alt;
    } else if (natType.contains('防火墙')) {
      return Icons.fireplace;
    } else if (natType.contains('递增')) {
      return Icons.trending_up;
    } else if (natType.contains('递减')) {
      return Icons.trending_down;
    } else if (natType.contains('无PAT')) {
      return Icons.router;
    } else {
      return Icons.help_outline;
    }
  }

  // 根据NAT类型获取颜色
  Color _getNatTypeColor(String natType) {
    if (natType.contains('开放') ||
        natType.contains('全锥形') ||
        natType.contains('无PAT')) {
      return Colors.green;
    } else if (natType.contains('受限') || natType.contains('端口受限')) {
      return Colors.orange;
    } else if (natType.contains('对称') || natType.contains('防火墙')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}

// 构建跃点信息显示
Widget _buildHopsInfo(List<NodeHopStats> hops, ColorScheme colorScheme) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.route, size: 20, color: colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('连接路径:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < hops.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      hops[i].nodeName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (i < hops.length - 1)
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// 新建 StatefulWidget 来管理列表项的悬停状态
class PlayerListItem extends StatefulWidget {
  final KVNodeInfo player;
  final ColorScheme colorScheme;
  final String? localIPv4; // 需要传入本地 IP
  // 将辅助函数作为参数传递，或者定义为顶层/静态函数
  final Color Function(double) getLatencyColor;
  final IconData Function(String) getConnectionIcon;
  final String Function(int, String, String?) mapConnectionType;
  final Widget Function(KVNodeInfo, ColorScheme, Color, IconData, String?)
  buildDesktopPlayerListItem; // 传递构建函数

  const PlayerListItem({
    required Key key,
    required this.player,
    required this.colorScheme,
    required this.localIPv4,
    required this.getLatencyColor,
    required this.getConnectionIcon,
    required this.mapConnectionType,
    required this.buildDesktopPlayerListItem,
  }) : super(key: key);

  @override
  State<PlayerListItem> createState() => _PlayerListItemState();
}

class _PlayerListItemState extends State<PlayerListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 从 widget 属性获取数据和函数
    final player = widget.player;
    final colorScheme = widget.colorScheme;
    final localIPv4 = widget.localIPv4;

    // 调用传递进来的辅助函数
    final latencyColor = widget.getLatencyColor(player.latencyMs);
    final connectionType = widget.mapConnectionType(
      player.cost,
      player.ipv4,
      localIPv4,
    );
    final connectionIcon = widget.getConnectionIcon(connectionType);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _isHovered ? colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // 如果需要 onTap 功能，在这里实现
          },
          splashColor: colorScheme.primary.withValues(alpha: 0.3),
          highlightColor: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            // 调用传递进来的桌面布局构建函数
            child: widget.buildDesktopPlayerListItem(
              player,
              colorScheme,
              latencyColor,
              connectionIcon,
              localIPv4, // 可能需要传递 localIPv4 给 desktop builder
            ),
          ),
        ),
      ),
    );
  }
}

// 将列表项卡片抽取为独立的StatefulWidget
class PlayerListItemCard extends StatefulWidget {
  final KVNodeInfo player;
  final ColorScheme colorScheme;
  final Color latencyColor;
  final IconData connectionIcon;
  final String? localIPv4;
  final Widget Function(
    KVNodeInfo player,
    ColorScheme colorScheme,
    Color latencyColor,
    IconData connectionIcon,
  )
  buildDesktopPlayerListItem;

  const PlayerListItemCard({
    Key? key,
    required this.player,
    required this.colorScheme,
    required this.latencyColor,
    required this.connectionIcon,
    required this.localIPv4,
    required this.buildDesktopPlayerListItem,
  }) : super(key: key);

  @override
  State<PlayerListItemCard> createState() => _PlayerListItemCardState();
}

class _PlayerListItemCardState extends State<PlayerListItemCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Card(
        elevation: isHovered ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isHovered ? widget.colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {},
          splashColor: widget.colorScheme.primary.withValues(alpha: 0.3),
          highlightColor: widget.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(12),
            width: double.infinity,
            child: widget.buildDesktopPlayerListItem(
              widget.player,
              widget.colorScheme,
              widget.latencyColor,
              widget.connectionIcon,
            ),
          ),
        ),
      ),
    );
  }
}
