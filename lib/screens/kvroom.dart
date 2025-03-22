// 导入必要的包
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/services.dart'; // 添加这一行导入剪贴板服务

import 'package:astral/utils/kv_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 替换 provider 导入
import '../widgets/card.dart';

/// 玩家信息模型类
class PlayerInfo {
  final String name;
  final String ip;
  final int latency; // 延迟(ms)
  final String connectionType; // 连接类型：直链、中转、本机
  final int uploadSpeed; // 上传速度(KB/s)
  final int downloadSpeed; // 下载速度(KB/s)
  final int sentPackets; // 发送包数量
  final int receivedPackets; // 接收包数量
  final double packetLossRate; // 丢包率(%)
  final String etVersion; // ET版本
  final String natType; // 添加NAT类型
  final List<NodeHopStats> hops; // 添加跃点路径信息

  PlayerInfo({
    required this.name,
    required this.ip,
    required this.latency,
    required this.connectionType,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.sentPackets,
    required this.receivedPackets,
    required this.packetLossRate,
    required this.etVersion,
    required this.natType,
    this.hops = const [], // 默认为空列表
  });
}

/// 房间页面组件
/// 用于显示所有玩家的信息
class RoomPage extends ConsumerStatefulWidget {
  // 修改为 ConsumerStatefulWidget
  const RoomPage({super.key});

  @override
  ConsumerState<RoomPage> createState() =>
      _RoomPageState(); // 修改为 ConsumerState
}

class _RoomPageState extends ConsumerState<RoomPage> {
  // 修改为 ConsumerState
  List<PlayerInfo> players = [];
  List<PlayerInfo> filteredPlayers = []; // 添加过滤后的玩家列表
  bool isLoading = true;
  String searchQuery = ''; // 添加搜索查询字符串
  TextEditingController searchController = TextEditingController(); // 添加搜索控制器

  @override
  void initState() {
    super.initState();
    isLoading = true;
    searchController.addListener(_onSearchChanged); // 添加搜索监听器
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged); // 移除搜索监听器
    searchController.dispose(); // 释放控制器资源
    super.dispose();
  }

  // 搜索变化处理函数
  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      _filterPlayers(); // 过滤玩家列表
    });
  }

  // 过滤玩家列表
  void _filterPlayers() {
    if (searchQuery.isEmpty) {
      filteredPlayers = List.from(players); // 如果搜索为空，显示所有玩家
    } else {
      filteredPlayers = players
          .where(
            (player) => player.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
          )
          .toList(); // 根据名称过滤玩家
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 使用 Riverpod 监听节点数据

    return Scaffold(
      appBar: AppBar(
        title: const Text('房间成员'),
        actions: [
          // 添加搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _PlayerSearchDelegate(
                  players: players,
                  colorScheme: colorScheme,
                  buildPlayerListItem: _buildPlayerListItem,
                ),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // 异步处理数据
          _processNodeData();

          if (isLoading) {
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
          } else if (players.isEmpty) {
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildPlayerListItem(
                          players[index],
                          colorScheme,
                        ),
                      );
                    }, childCount: players.length),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  int _getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 1; // 手机屏幕显示1列
    } else if (width < 900) {
      return 2; // 平板或小屏幕显示2列
    } else {
      return 3; // 大屏幕显示3列
    }
  }

  // 处理节点数据 - 合并了原来的两个相似方法
  Future<void> _processNodeData() async {
    try {
      final nodes = await ref.read(nodesProvider); // 获取最新的节点信息

      // 将节点数据转换为PlayerInfo对象
      List<PlayerInfo> nodePlayerInfos = [];

      for (var node in nodes) {
        // 计算上传下载速度和包数量总和
        int uploadSpeed = 0;
        int downloadSpeed = 0;
        int sentPackets = 0;
        int receivedPackets = 0;
        String connectionType = _mapConnectionType(
          node.cost,
          node.ipv4,
          ref.read(virtualIPProvider),
        );

        // 获取跃点信息 (示例，实际需要从节点数据中获取)
        List<NodeHopStats> hops = [];
        if (node.hops.isNotEmpty) {
          hops = node.hops;
        }

        // 如果有连接信息，计算网络统计数据
        if (node.connections.isNotEmpty) {
          for (var conn in node.connections) {
            uploadSpeed += conn.txBytes.toInt() ~/ 1024; // 转换为KB
            downloadSpeed += conn.rxBytes.toInt() ~/ 1024; // 转换为KB
            sentPackets += conn.txPackets.toInt();
            receivedPackets += conn.rxPackets.toInt();
          }
        }

        // 计算丢包率 (简单估算)
        double packetLossRate = node.lossRate;
        // 获取NAT类型
        String natType = _mapNatType(node.nat);

        // 创建PlayerInfo对象
        nodePlayerInfos.add(
          PlayerInfo(
            name: node.hostname,
            ip: node.ipv4, // 临时IP，实际应从节点信息中获取
            latency: (node.latencyMs).toInt(), // 转换为毫秒
            connectionType: connectionType,
            uploadSpeed: uploadSpeed,
            downloadSpeed: downloadSpeed,
            sentPackets: sentPackets,
            receivedPackets: receivedPackets,
            packetLossRate: packetLossRate,
            etVersion: node.version, // 获取版本信息
            natType: natType, // 添加NAT类型
            hops: hops, // 添加跃点信息
          ),
        );
      }

      if (!mounted) return; // 检查组件是否仍然挂载

      setState(() {
        players = nodePlayerInfos;
        _filterPlayers(); // 更新过滤后的玩家列表
        isLoading = false;
      });
    } catch (e) {
      print("加载节点数据失败: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 构建列表项视图
  Widget _buildPlayerListItem(PlayerInfo player, ColorScheme colorScheme) {
    // 根据延迟值确定颜色
    Color latencyColor = _getLatencyColor(player.latency);
    // 根据连接类型选择图标
    IconData connectionIcon = _getConnectionIcon(player.connectionType);

    // 检测是否为小屏幕设备
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return FloatingCard(
      colorScheme: colorScheme,
      maxWidth: double.infinity,
      child: isSmallScreen
          ? _buildMobilePlayerListItem(
              player,
              colorScheme,
              latencyColor,
              connectionIcon,
            )
          : _buildDesktopPlayerListItem(
              player,
              colorScheme,
              latencyColor,
              connectionIcon,
            ),
    );
  }

  // 为移动设备优化的列表项布局
  Widget _buildMobilePlayerListItem(
    PlayerInfo player,
    ColorScheme colorScheme,
    Color latencyColor,
    IconData connectionIcon,
  ) {
    // 处理显示名称
    String displayName = player.name.startsWith('PublicServer_')
        ? player.name.substring('PublicServer_'.length)
        : player.name;
    return Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConnectionTypeColor(
                  player.connectionType,
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
                    player.connectionType,
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
          player.ip,
          colorScheme,
          showCopyButton: true,
        ),
        const SizedBox(height: 8),

        // 延迟信息
        _buildInfoRow(
          Icons.speed,
          '延迟',
          '${player.latency} ms',
          colorScheme,
          valueColor: latencyColor,
        ),
        const SizedBox(height: 8),

        // ET版本
        _buildInfoRow(Icons.memory, 'ET版本', player.etVersion, colorScheme),
        const SizedBox(height: 8),
        // NAT类型
        _buildInfoRow(
          _getNatTypeIcon(player.natType),
          'NAT类型',
          player.natType,
          colorScheme,
          valueColor: _getNatTypeColor(player.natType),
        ),
        const SizedBox(height: 8),

        // 丢包率信息
        _buildInfoRow(
          Icons.error_outline,
          '丢包率',
          '${player.packetLossRate.toStringAsFixed(2)}%', // 修改这里，保留2位小数
          colorScheme,
          valueColor: _getPacketLossColor(player.packetLossRate),
        ),

        // 添加跃点信息显示
        if (player.hops.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildHopsInfo(player.hops, colorScheme),
        ],

        // 网络数据部分
        const Divider(height: 16),

        // 网络数据信息 - 移动设备上使用紧凑布局
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkDataItem(
                      '上传',
                      _formatSpeed(player.uploadSpeed), // 使用格式化方法
                      Icons.upload,
                      colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildNetworkDataItem(
                      '下载',
                      _formatSpeed(player.downloadSpeed), // 使用格式化方法
                      Icons.download,
                      colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkDataItem(
                      '发送包',
                      '${player.sentPackets}',
                      Icons.send,
                      colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildNetworkDataItem(
                      '接收包',
                      '${player.receivedPackets}',
                      Icons.call_received,
                      colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 为桌面设备优化的列表项布局
  Widget _buildDesktopPlayerListItem(
    PlayerInfo player,
    ColorScheme colorScheme,
    Color latencyColor,
    IconData connectionIcon,
  ) {
    String displayName = player.name.startsWith('PublicServer_')
        ? player.name.substring('PublicServer_'.length)
        : player.name;
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
                        player.connectionType,
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
                          player.connectionType,
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
                player.ip,
                colorScheme,
                showCopyButton: true,
              ),
              const SizedBox(height: 8),

              // ET版本
              _buildInfoRow(
                Icons.memory,
                'ET版本',
                player.etVersion,
                colorScheme,
              ),
              const SizedBox(height: 8),

              // NAT类型
              _buildInfoRow(
                _getNatTypeIcon(player.natType),
                'NAT类型',
                player.natType,
                colorScheme,
                valueColor: _getNatTypeColor(player.natType),
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
                '${player.latency} ms',
                colorScheme,
                valueColor: latencyColor,
              ),
              const SizedBox(height: 8),

              // 丢包率信息
              _buildInfoRow(
                Icons.error_outline,
                '丢包率',
                '${player.packetLossRate.toStringAsFixed(2)}%', // 修改这里，保留2位小数
                colorScheme,
                valueColor: _getPacketLossColor(player.packetLossRate),
              ),
              const SizedBox(height: 8),

              // 上传下载速度
              Row(
                children: [
                  Expanded(
                    child: _buildNetworkDataItem(
                      '上传',
                      _formatSpeed(player.uploadSpeed), // 使用格式化方法
                      Icons.upload,
                      colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildNetworkDataItem(
                      '下载',
                      _formatSpeed(player.downloadSpeed), // 使用格式化方法
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
                '${player.sentPackets}',
                Icons.send,
                colorScheme.primary,
              ),
              const SizedBox(height: 8),
              _buildNetworkDataItem(
                '接收包',
                '${player.receivedPackets}',
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
  String _formatSpeed(int speedInKB) {
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
  Color _getLatencyColor(int latency) {
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
    if (ip == thisip) {
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

// 玩家搜索委托类
class _PlayerSearchDelegate extends SearchDelegate<String> {
  final List<PlayerInfo> players;
  final ColorScheme colorScheme;
  final Function(PlayerInfo, ColorScheme) buildPlayerListItem;

  _PlayerSearchDelegate({
    required this.players,
    required this.colorScheme,
    required this.buildPlayerListItem,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          // 如果搜索框为空，直接返回
          if (query.isEmpty) {
            close(context, '');
          } else {
            // 否则清空搜索内容
            query = '';
            showSuggestions(context);
          }
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  // 修改方法签名，添加 BuildContext 参数
  Widget _buildSearchResults(BuildContext context) {
    final filteredPlayers = query.isEmpty
        ? players
        : players
            .where(
              (player) =>
                  player.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的玩家',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他搜索关键词',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    // 添加对屏幕宽度的检测
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用约束条件获取当前宽度
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredPlayers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: buildPlayerListItem(filteredPlayers[index], colorScheme),
            );
          },
        );
      },
    );
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
