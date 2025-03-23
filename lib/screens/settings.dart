import 'dart:async';
import 'dart:io';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/utils/app_info.dart';
import 'package:astral/utils/logger.dart';
import 'package:astral/utils/up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 添加 Riverpod 导入
import '../config/app_config.dart';
import '../utils/ping_util.dart';
import 'package:astral/utils/kv_state.dart';
import 'package:http/http.dart' as http; // 添加 http 包导入
import 'dart:convert'; // 添加 json 解析支持
import 'package:astral/utils/serverjs.dart';
import 'package:astral/utils/network_util.dart'; // 添加网络工具类导入
import 'package:flutter/foundation.dart'; // 添加compute支持

class Pserver {
  final int id;
  final String name;
  final String address;
  final String provider;
  final String version;
  final bool isOfficialServer;
  final bool isTransferable;
  final String ip;

  Pserver({
    required this.id,
    required this.name,
    required this.address,
    required this.provider,
    required this.version,
    required this.isOfficialServer,
    required this.isTransferable,
    required this.ip,
  });
}

// 将 StatefulWidget 改为 ConsumerStatefulWidget
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

final updateChecker = UpdateChecker(
  owner: 'ldoubil',
  repo: 'astral',
);

// 存储服务器组列表的状态变量
// 使用 StateProvider 来管理服务器组列表状态
final pServerProvider = StateProvider<List<Pserver>>((ref) => []);

// 将 State 改为 ConsumerState
class _SettingsPageState extends ConsumerState<SettingsPage> {
  late List<Map<String, dynamic>> _serverList;
  late TextEditingController _overlapValueController;
  final _appConfig = AppConfig();
  bool _closeToTray = false; // 添加关闭进入托盘变量
  bool _pingEnabled = true; // 添加全局ping开关

  // 添加高级选项变量
  String _defaultProtocol = "tcp";
  String _devName = "";
  bool _enableEncryption = true;
  bool _enableIpv6 = true;
  int _mtu = 1380;
  bool _latencyFirst = false;
  bool _enableExitNode = false;
  bool _proxyForwardBySystem = false;
  bool _noTun = false;
  bool _useSmoltcp = false;
  String _relayNetworkWhitelist = "*";
  bool _disableP2p = false;
  bool _relayAllPeerRpc = false;
  bool _disableUdpHolePunching = false;
  bool _multiThread = true;
  String _dataCompressAlgo = "None";
  bool _bindDevice = true;
  bool _enableKcpProxy = false;
  bool _disableKcpInput = false;
  bool _disableRelayKcp = true;

  String serverIP = "";
  // 添加 ping 相关状态
  Map<String, int?> pingResults = {};

  @override
  void initState() {
    super.initState();
    // 从 Riverpod 获取服务器列表
    _serverList = ref.read(serverListProvider);
    serverIP = _getSelectedServersString();
    _closeToTray = _appConfig.closeToTray; // 初始化托盘设置
    // 初始化全局ping开关
    _pingEnabled = _appConfig.enablePing;
    _overlapValueController = TextEditingController();
// 添加监听器以在provider值变化时更新控制器文本
    ref.listenManual(networkOverlapValueProvider, (previous, next) {
      // 只有当文本框不是焦点时才更新文本，避免干扰用户输入
      if (!_overlapValueController.text.isEmpty &&
          !FocusScope.of(context).hasFocus) {
        _overlapValueController.text = next.toString();
      }
    });
    // 设置初始值
    _overlapValueController.text =
        ref.read(networkOverlapValueProvider).toString();
    // 初始化高级设置
    final advancedConfig = ref.read(advancedConfigProvider);
    _defaultProtocol = advancedConfig['defaultProtocol'] ?? "tcp";
    _devName = advancedConfig['devName'] ?? "";
    _enableEncryption = advancedConfig['enableEncryption'] ?? true;
    _enableIpv6 = advancedConfig['enableIpv6'] ?? true;
    _mtu = advancedConfig['mtu'] ?? 1380;
    _latencyFirst = advancedConfig['latencyFirst'] ?? false;
    _enableExitNode = advancedConfig['enableExitNode'] ?? false;
    _proxyForwardBySystem = advancedConfig['proxyForwardBySystem'] ?? false;
    _noTun = advancedConfig['noTun'] ?? false;
    _useSmoltcp = advancedConfig['useSmoltcp'] ?? false;
    _relayNetworkWhitelist = advancedConfig['relayNetworkWhitelist'] ?? "*";
    _disableP2p = advancedConfig['disableP2p'] ?? false;
    _relayAllPeerRpc = advancedConfig['relayAllPeerRpc'] ?? false;
    _disableUdpHolePunching = advancedConfig['disableUdpHolePunching'] ?? false;
    _multiThread = advancedConfig['multiThread'] ?? true;
    _dataCompressAlgo = advancedConfig['dataCompressAlgo'] ?? "None";
    _bindDevice = advancedConfig['bindDevice'] ?? true;
    _enableKcpProxy = advancedConfig['enableKcpProxy'] ?? false;
    _disableKcpInput = advancedConfig['disableKcpInput'] ?? false;
    _disableRelayKcp = advancedConfig['disableRelayKcp'] ?? true;

    // 初始化 ping 状态
    for (var server in _serverList) {
      pingResults[server['url']] = null;
    }

    // 开始 ping 所有服务器
    _startPingAllServers();
  }

  // 获取选中的服务器字符串
  String _getSelectedServersString() {
    final selected =
        _serverList.where((server) => server['selected'] == true).toList();
    if (selected.isEmpty && _serverList.isNotEmpty) {
      return _serverList.first['url'];
    }
    return selected.map((server) => server['url']).join(', ');
  }

  // 添加一个计时器变量来控制 ping 操作
  Timer? _pingTimer;

  // 新增方法：开始 ping 所有服务器
  void _startPingAllServers() {
    // 取消之前的计时器（如果存在）
    _pingTimer?.cancel();

    // 创建新的计时器，使用设置的间隔时间
    _pingTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_pingEnabled) {
        for (var server in _serverList) {
          _pingServerOnce(server['url']);
        }
      }
    });
  }

  @override
  void dispose() {
    // 取消计时器
    _pingTimer?.cancel();
    _pingTimer = null;
    super.dispose();
  }

  // 执行单次 ping 操作
  Future<void> _pingServerOnce(String server) async {
    final pingResult = await PingUtil.ping(server);

    if (mounted) {
      setState(() {
        pingResults[server] = pingResult;
      });
    }
  }

  // 显示公共服务器列表
  void _showPublicServerList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.public),
              const SizedBox(width: 8),
              const Text('公共服务器列表'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _fetchEasyTierStatus();
                },
                tooltip: '刷新服务器列表',
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            // 调整高度，使其不会过高
            height: MediaQuery.of(context).size.height * 0.5,
            child: Consumer(
              builder: (context, ref, child) {
                final publicServers = ref.watch(pServerProvider);

                return publicServers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('暂无公共服务器数据'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _fetchEasyTierStatus();
                              },
                              child: const Text('获取公共服务器数据'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // 修改为ListView.builder，移除separated
                        itemCount: publicServers.length,
                        itemBuilder: (context, index) {
                          final server = publicServers[index];
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  server.isOfficialServer
                                      ? Icons.verified_user
                                      : Icons.person,
                                  color: server.isOfficialServer
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                title: Text(server.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '地址: ${server.address}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'IP: ${server.ip}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Chip(
                                            label: Text(
                                              server.isOfficialServer
                                                  ? '官方'
                                                  : '第三方',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor: server
                                                    .isOfficialServer
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.blue.withOpacity(0.2),
                                            visualDensity:
                                                VisualDensity.compact,
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Chip(
                                            label: Text(
                                              server.isTransferable
                                                  ? '可转发'
                                                  : '不可转发',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor: server
                                                    .isTransferable
                                                ? Colors.orange.withOpacity(0.2)
                                                : Colors.red.withOpacity(0.2),
                                            visualDensity:
                                                VisualDensity.compact,
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  color: Colors.green,
                                  onPressed: () =>
                                      _addPublicServerToList(server),
                                  tooltip: '添加到我的服务器',
                                ),
                              ),
                              if (index < publicServers.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        },
                      );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 添加公共服务器到我的服务器列表
  void _addPublicServerToList(Pserver publicServer) {
    // 检查是否已存在相同地址的服务器
    final existingServer = _serverList.firstWhere(
      (server) => server['url'] == publicServer.ip,
      orElse: () => <String, dynamic>{},
    );

    if (existingServer.isNotEmpty) {
      // 已存在相同地址的服务器
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('服务器 ${publicServer.ip} 已存在于您的列表中'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      // 添加新服务器，默认不选中，使用IP地址而不是address
      _serverList.add({
        'url': publicServer.ip,
        'name': publicServer.name,
        'selected': false,
        'tcp': true,
        'udp': true,
        'ws': false,
        'wss': false,
        'quic': false,
      });
      _appConfig.setServerList(_serverList);

      // 初始化新服务器的 ping 状态
      pingResults[publicServer.ip] = null;
    });

    // 显示添加成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加服务器: ${publicServer.name}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '确定',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // 切换全局ping状态
  void _togglePingStatus(bool value) {
    setState(() {
      _pingEnabled = value;
      _appConfig.setEnablePing(_pingEnabled);
      if (!_pingEnabled) {
        // 如果关闭ping，清空所有结果
        for (var server in _serverList) {
          pingResults[server['url']] = null;
        }
      }
    });
  }

  // 添加服务器对话框
  Future<void> _showAddServerDialog() async {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    // 添加协议开关状态
    bool tcpEnabled = true; // 默认启用TCP
    bool udpEnabled = true; // 默认启用UDP
    bool wsEnabled = false;
    bool wssEnabled = false;
    bool quicEnabled = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加服务器'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '服务器名称',
                    hintText: '自定义名称',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'example.com:port',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('支持的协议',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('TCP'),
                  value: tcpEnabled,
                  onChanged: (value) => setState(() => tcpEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('UDP'),
                  value: udpEnabled,
                  onChanged: (value) => setState(() => udpEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('WebSocket (WS)'),
                  value: wsEnabled,
                  onChanged: (value) => setState(() => wsEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('WebSocket Secure (WSS)'),
                  value: wssEnabled,
                  onChanged: (value) => setState(() => wssEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('QUIC'),
                  value: quicEnabled,
                  onChanged: (value) => setState(() => quicEnabled = value),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'url': urlController.text,
                    'name': nameController.text.isNotEmpty
                        ? nameController.text
                        : urlController.text,
                    'tcp': tcpEnabled,
                    'udp': udpEnabled,
                    'ws': wsEnabled,
                    'wss': wssEnabled,
                    'quic': quicEnabled,
                  });
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // 添加新服务器，默认不选中，包含协议设置
        _serverList.add({
          'url': result['url'],
          'name': result['name'],
          'selected': false,
          'tcp': result['tcp'] ?? true,
          'udp': result['udp'] ?? true,
          'ws': result['ws'] ?? false,
          'wss': result['wss'] ?? false,
          'quic': result['quic'] ?? false,
        });
        _appConfig.setServerList(_serverList);

        // 初始化新服务器的 ping 状态
        pingResults[result['url']] = null;
      });
    }
  }

  // 编辑服务器对话框
  Future<void> _showEditServerDialog(int index) async {
    final server = _serverList[index];
    final urlController = TextEditingController(text: server['url']);
    final nameController = TextEditingController(text: server['name']);
    // 初始化协议开关状态
    bool tcpEnabled = server['tcp'] ?? true;
    bool udpEnabled = server['udp'] ?? true;
    bool wsEnabled = server['ws'] ?? false;
    bool wssEnabled = server['wss'] ?? false;
    bool quicEnabled = server['quic'] ?? false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑服务器'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '服务器名称',
                    hintText: '自定义名称',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'example.com:port',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('支持的协议',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('TCP'),
                  value: tcpEnabled,
                  onChanged: (value) => setState(() => tcpEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('UDP'),
                  value: udpEnabled,
                  onChanged: (value) => setState(() => udpEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('WebSocket (WS)'),
                  value: wsEnabled,
                  onChanged: (value) => setState(() => wsEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('WebSocket Secure (WSS)'),
                  value: wssEnabled,
                  onChanged: (value) => setState(() => wssEnabled = value),
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('QUIC'),
                  value: quicEnabled,
                  onChanged: (value) => setState(() => quicEnabled = value),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'url': urlController.text,
                    'name': nameController.text.isNotEmpty
                        ? nameController.text
                        : urlController.text,
                    'tcp': tcpEnabled,
                    'udp': udpEnabled,
                    'ws': wsEnabled,
                    'wss': wssEnabled,
                    'quic': quicEnabled,
                  });
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final oldUrl = server['url'];
      setState(() {
        _serverList[index] = {
          'url': result['url'],
          'name': result['name'],
          'selected': server['selected'],
          'tcp': result['tcp'] ?? true,
          'udp': result['udp'] ?? true,
          'ws': result['ws'] ?? false,
          'wss': result['wss'] ?? false,
          'quic': result['quic'] ?? false,
        };
        _appConfig.setServerList(_serverList);

        // 更新 ping 状态
        if (oldUrl != result['url']) {
          pingResults[result['url']] = pingResults[oldUrl];
          pingResults.remove(oldUrl);
        }

        // 更新当前选中的服务器显示
        serverIP = _getSelectedServersString();
        // 使用 Riverpod 更新服务器列表
        ref.read(serverListProvider.notifier).setServerList(_serverList);
      });
    }
  }

  // 删除服务器
  Future<void> _deleteServer(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个服务器吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final server = _serverList[index];

      setState(() {
        _serverList.removeAt(index);
        _appConfig.setServerList(_serverList);

        // 移除 ping 状态
        pingResults.remove(server['url']);

        // 确保至少有一个服务器被选中
        if (_serverList.isNotEmpty &&
            !_serverList.any((server) => server['selected'] == true)) {
          _serverList.first['selected'] = true;
        }

        // 更新当前选中的服务器显示
        serverIP = _getSelectedServersString();
        // 使用 Riverpod 更新服务器列表
        ref.read(serverListProvider.notifier).setServerList(_serverList);
      });
    }
  }

  // 切换服务器选中状态
  void _toggleServerSelection(int index) {
    setState(() {
      _serverList[index]['selected'] =
          !(_serverList[index]['selected'] ?? false);
      _appConfig.setServerList(_serverList);

      // 更新当前选中的服务器显示
      serverIP = _getSelectedServersString();

      // 使用 Riverpod 更新服务器列表
      ref.read(serverListProvider.notifier).setServerList(_serverList);
    });
  }

  // 添加构建 ping 显示组件的方法
  Widget _buildPingWidget(String url) {
    final pingResult = pingResults[url];
    if (!_pingEnabled) {
      return const Text('Ping已关闭', style: TextStyle(color: Colors.grey));
    } else if (pingResult == null) {
      return const Text('测试中...', style: TextStyle(color: Colors.grey));
    } else {
      return Text(
        '${pingResult}ms',
        style: TextStyle(
          color: pingResult < 100
              ? Colors.green
              : (pingResult < 300 ? Colors.orange : Colors.red),
        ),
      );
    }
  }

  // 添加一个方法来显示服务器支持的协议
  Widget _buildProtocolChips(Map<String, dynamic> server) {
    List<Widget> chips = [];

    if (server['tcp'] == true) {
      chips.add(Chip(
        label: const Text('TCP', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.blue.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ));
    }

    if (server['udp'] == true) {
      chips.add(Chip(
        label: const Text('UDP', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.green.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ));
    }

    if (server['ws'] == true) {
      chips.add(Chip(
        label: const Text('WS', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.orange.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ));
    }

    if (server['wss'] == true) {
      chips.add(Chip(
        label: const Text('WSS', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.purple.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ));
    }

    if (server['quic'] == true) {
      chips.add(Chip(
        label: const Text('QUIC', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.teal.withOpacity(0.2),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: chips,
    );
  }

  @override
  Widget build(BuildContext context) {
    // updateChecker.checkForUpdates(context);
    return ListView(padding: const EdgeInsets.all(16.0), children: [
      Card(
        child: Column(
          children: [
            ExpansionTile(
              initiallyExpanded: false,
              leading: const Icon(Icons.list),
              title: const Text('服务器列表'),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _serverList.length,
                  itemBuilder: (context, index) {
                    final server = _serverList[index];
                    final isSelected = server['selected'] == true;

                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.green : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              server['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPingWidget(server['url']),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(server['url']),
                          const SizedBox(height: 4),
                          _buildProtocolChips(server),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditServerDialog(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteServer(index),
                          ),
                        ],
                      ),
                      onTap: () => _toggleServerSelection(index),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('添加新服务器'),
                  onTap: _showAddServerDialog,
                ),
                // 添加公共服务器列表入口
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('查看公共服务器列表'),
                  onTap: () => _showPublicServerList(context),
                ),
              ],
            ),
            if (Platform.isWindows) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('启用网卡跃点'),
                      subtitle: const Text('允许网卡跃点重叠'),
                      value: ref.watch(networkOverlapEnabledProvider),
                      onChanged: (value) {
                        ref
                            .read(networkOverlapProvider.notifier)
                            .setEnabled(value);
                      },
                    ),
                  ),
                  if (ref.watch(networkOverlapEnabledProvider))
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: '跃点值',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              controller:
                                  _overlapValueController, // 使用类成员变量的控制器
                              onChanged: (value) {
                                final overlapValue = int.tryParse(value) ?? 0;
                                ref
                                    .read(networkOverlapProvider.notifier)
                                    .setValue(overlapValue);
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // 获取当前跃点值并应用
                              final overlapValue =
                                  ref.read(networkOverlapValueProvider);
                              // 调用Rust函数设置跃点值
                              setNetworkInterfaceHops(hop: overlapValue);
                              // 显示应用成功提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已应用网卡跃点设置')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            child: const Text('应用'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('网卡跃点列表'),
                subtitle: const Text('查看网卡名称和对应的跃点值'),
                onTap: () => _showNetworkInterfaceMetricsDialog(context),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('应用设置'),
            ),
            SwitchListTile(
              title: const Text('关闭时最小化到托盘'),
              subtitle: const Text('关闭窗口时应用将继续在后台运行'),
              value: _closeToTray,
              onChanged: (value) {
                setState(() {
                  _closeToTray = value;
                  _appConfig.setCloseToTray(value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('启用服务器Ping测试'),
              subtitle: const Text('定期测试所有服务器的网络延迟'),
              value: _pingEnabled,
              onChanged: _togglePingStatus,
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),
      // 添加高级选项卡
      Card(
        child: Column(
          children: [
            ExpansionTile(
              leading: const Icon(Icons.tune),
              title: const Text('高级选项'),
              subtitle: const Text('调整网络和性能参数'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 协议设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '协议设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '默认协议',
                          border: OutlineInputBorder(),
                        ),
                        value: _defaultProtocol,
                        items: const [
                          DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                          DropdownMenuItem(value: 'udp', child: Text('UDP')),
                          DropdownMenuItem(value: 'quic', child: Text('QUIC')),
                          DropdownMenuItem(
                              value: 'ws', child: Text('WebSocket')),
                          DropdownMenuItem(
                              value: 'wss', child: Text('WebSocket Secure')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _defaultProtocol = value!;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .setDefaultProtocol(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 设备设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '设备设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '设备名称',
                          hintText: '留空使用默认值',
                          border: OutlineInputBorder(),
                        ),
                        controller: TextEditingController(text: _devName),
                        onChanged: (value) {
                          setState(() {
                            _devName = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .setDevName(value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // 网络设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '网络设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('启用IPv6'),
                        subtitle: const Text('允许IPv6网络连接'),
                        value: _enableIpv6,
                        onChanged: (value) {
                          setState(() {
                            _enableIpv6 = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('enableIpv6', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('优先低延迟'),
                        subtitle: const Text('优先考虑连接延迟而非带宽'),
                        value: _latencyFirst,
                        onChanged: (value) {
                          setState(() {
                            _latencyFirst = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('latencyFirst', value);
                          });
                        },
                      ),
                      // SwitchListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   title: const Text('启用出口节点'),
                      //   subtitle: const Text('允许作为网络出口节点'),
                      //   value: _enableExitNode,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       _enableExitNode = value;
                      //       ref
                      //           .read(advancedConfigProvider.notifier)
                      //           .updateConfig('enableExitNode', value);
                      //     });
                      //   },
                      // ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('系统代理转发'),
                        subtitle: const Text('通过系统代理转发流量'),
                        value: _proxyForwardBySystem,
                        onChanged: (value) {
                          setState(() {
                            _proxyForwardBySystem = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('proxyForwardBySystem', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('禁用TUN'),
                        subtitle: const Text('不使用TUN虚拟网络接口'),
                        value: _noTun,
                        onChanged: (value) {
                          setState(() {
                            _noTun = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('noTun', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('使用Smoltcp'),
                        subtitle: const Text('使用Smoltcp网络栈'),
                        value: _useSmoltcp,
                        onChanged: (value) {
                          setState(() {
                            _useSmoltcp = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('useSmoltcp', value);
                          });
                        },
                      ),

                      // 中继设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '中继设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '中继网络白名单',
                          hintText: '使用*表示允许所有',
                          border: OutlineInputBorder(),
                        ),
                        controller:
                            TextEditingController(text: _relayNetworkWhitelist),
                        onChanged: (value) {
                          setState(() {
                            _relayNetworkWhitelist = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('relayNetworkWhitelist', value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('禁用P2P'),
                        subtitle: const Text('禁用点对点直接连接'),
                        value: _disableP2p,
                        onChanged: (value) {
                          setState(() {
                            _disableP2p = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('disableP2p', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('中继所有对等RPC'),
                        subtitle: const Text('通过中继服务器转发所有RPC请求'),
                        value: _relayAllPeerRpc,
                        onChanged: (value) {
                          setState(() {
                            _relayAllPeerRpc = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('relayAllPeerRpc', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('禁用UDP打洞'),
                        subtitle: const Text('禁用UDP NAT穿透技术'),
                        value: _disableUdpHolePunching,
                        onChanged: (value) {
                          setState(() {
                            _disableUdpHolePunching = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('disableUdpHolePunching', value);
                          });
                        },
                      ),

                      // 性能设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '性能设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('多线程'),
                        subtitle: const Text('启用多线程处理以提高性能'),
                        value: _multiThread,
                        onChanged: (value) {
                          setState(() {
                            _multiThread = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('multiThread', value);
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '数据压缩算法',
                          border: OutlineInputBorder(),
                        ),
                        value: _dataCompressAlgo,
                        items: const [
                          DropdownMenuItem(value: 'None', child: Text('无压缩')),
                          DropdownMenuItem(value: 'Lz4', child: Text('LZ4')),
                          DropdownMenuItem(value: 'Zstd', child: Text('Zstd')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _dataCompressAlgo = value!;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('dataCompressAlgo', value);
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // KCP设置
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'KCP设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('绑定设备'),
                        subtitle: const Text('将连接绑定到特定网络设备'),
                        value: _bindDevice,
                        onChanged: (value) {
                          setState(() {
                            _bindDevice = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('bindDevice', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('启用KCP代理'),
                        subtitle: const Text('使用KCP协议进行代理'),
                        value: _enableKcpProxy,
                        onChanged: (value) {
                          setState(() {
                            _enableKcpProxy = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('enableKcpProxy', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('禁用KCP输入'),
                        subtitle: const Text('禁止KCP协议输入'),
                        value: _disableKcpInput,
                        onChanged: (value) {
                          setState(() {
                            _disableKcpInput = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('disableKcpInput', value);
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('禁用中继KCP'),
                        subtitle: const Text('禁用中继服务器的KCP协议'),
                        value: _disableRelayKcp,
                        onChanged: (value) {
                          setState(() {
                            _disableRelayKcp = value;
                            ref
                                .read(advancedConfigProvider.notifier)
                                .updateConfig('disableRelayKcp', value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('应用版本'),
              subtitle: Text(AppInfoUtil.getVersion()),
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('检查更新'),
              onTap: () {
                updateChecker.checkForUpdates(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('获取 EasyTier 状态'),
              onTap: _fetchEasyTierStatus,
            ),
          ],
        ),
      ),
    ]);
  }

  // 添加网络请求方法
  Future<void> _fetchEasyTierStatus() async {
    try {
      // 显示加载指示器
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在获取服务器数据...')),
        );
      }

      final response = await http
          .get(Uri.parse('https://easytier.gd.nkbpal.cn/status/easytier'));

      if (response.statusCode == 200) {
        // 请求成功，打印响应内容
        Logger.info('EasyTier 状态: ${response.body}');

        // 提取 window.preloadData = 和 </script> 之间的内容
        try {
          final String responseBody = response.body;
          final startMarker = 'window.preloadData = ';
          final endMarker = '</script>';

          final startIndex = responseBody.indexOf(startMarker);
          final endIndex = responseBody.indexOf(endMarker, startIndex);

          if (startIndex != -1 && endIndex != -1) {
            final startDataIndex = startIndex + startMarker.length;
            final extractedData =
                responseBody.substring(startDataIndex, endIndex).trim();

            Logger.info('提取的数据: $extractedData');

            // 尝试解析提取的JSON数据
            try {
              // 先将字符串解析为Map
              // 去除最后的分号并将单引号替换为双引号
              String cleanData = extractedData
                  .replaceAll(RegExp(r';$'), '')
                  .replaceAll("'", '"');
              Map<String, dynamic> jsonMap = json.decode(cleanData);
              StatusPageData? pageData = StatusPageData.fromJson(jsonMap);
              // 打印解析后的数据
              Logger.info('解析后的数据: $pageData');

              // 初始化空列表
              final List<Pserver> pGroupList = [];

              if (pageData.publicGroupList.length > 1) {
                pageData.publicGroupList[1].monitorList.forEach((monitor) {
                  try {
                    List<String> parts = monitor.name.split('/');
                    if (parts.length >= 4) {
                      // 尝试从各个部分中提取IP:端口格式
                      String finalIp = "";

                      // 遍历所有部分，查找符合IP:端口或域名:端口格式的字符串
                      for (String part in parts) {
                        // 检查是否符合IP:端口或域名:端口格式
                        bool isIpPort =
                            RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                .hasMatch(part);
                        bool isDomainPort = RegExp(
                                r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                            .hasMatch(part);

                        if (isIpPort || isDomainPort) {
                          finalIp = part;
                          break;
                        }
                      }

                      // 如果没有找到，尝试查找IPv4或IPv6标记后的部分
                      if (finalIp.isEmpty) {
                        for (int i = 0; i < parts.length - 1; i++) {
                          if (parts[i] == "IPv4" ||
                              parts[i] == "IPv6" ||
                              parts[i] == "TCP" ||
                              parts[i] == "UDP") {
                            String nextPart = parts[i + 1];
                            if (RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                                    .hasMatch(nextPart) ||
                                RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                    .hasMatch(nextPart)) {
                              finalIp = nextPart;
                              break;
                            }
                          }
                        }
                      }

                      // 如果仍然没有找到，使用默认值
                      if (finalIp.isEmpty && parts.length > 3) {
                        finalIp = parts[3]; // 使用默认位置
                      }

                      pGroupList.add(Pserver(
                        id: monitor.id,
                        name: monitor.name,
                        address: parts[0],
                        provider: parts[1],
                        version: parts[2],
                        isOfficialServer: true,
                        isTransferable: true,
                        ip: finalIp,
                      ));
                    }
                  } catch (e) {
                    Logger.info('Error parsing server data: $e');
                  }
                });
              }

              if (pageData.publicGroupList.length > 2) {
                pageData.publicGroupList[2].monitorList.forEach((monitor) {
                  try {
                    List<String> parts = monitor.name.split('/');
                    if (parts.length >= 4) {
                      // 尝试从各个部分中提取IP:端口格式
                      String finalIp = "";

                      // 遍历所有部分，查找符合IP:端口或域名:端口格式的字符串
                      for (String part in parts) {
                        // 检查是否符合IP:端口或域名:端口格式
                        bool isIpPort =
                            RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                .hasMatch(part);
                        bool isDomainPort = RegExp(
                                r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                            .hasMatch(part);

                        if (isIpPort || isDomainPort) {
                          finalIp = part;
                          break;
                        }
                      }

                      // 如果没有找到，尝试查找IPv4或IPv6标记后的部分
                      if (finalIp.isEmpty) {
                        for (int i = 0; i < parts.length - 1; i++) {
                          if (parts[i] == "IPv4" ||
                              parts[i] == "IPv6" ||
                              parts[i] == "TCP" ||
                              parts[i] == "UDP") {
                            String nextPart = parts[i + 1];
                            if (RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                                    .hasMatch(nextPart) ||
                                RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                    .hasMatch(nextPart)) {
                              finalIp = nextPart;
                              break;
                            }
                          }
                        }
                      }

                      // 如果仍然没有找到，使用默认值
                      if (finalIp.isEmpty && parts.length > 3) {
                        finalIp = parts[3]; // 使用默认位置
                      }

                      pGroupList.add(Pserver(
                        id: monitor.id,
                        name: monitor.name,
                        address: parts[0],
                        provider: parts[1],
                        version: parts[2],
                        isOfficialServer: false,
                        isTransferable: true,
                        ip: finalIp,
                      ));
                    }
                  } catch (e) {
                    Logger.info('Error parsing server data: $e');
                  }
                });
              }

              if (pageData.publicGroupList.length > 3) {
                pageData.publicGroupList[3].monitorList.forEach((monitor) {
                  try {
                    List<String> parts = monitor.name.split('/');
                    if (parts.length >= 4) {
                      // 尝试从各个部分中提取IP:端口格式
                      String finalIp = "";

                      // 遍历所有部分，查找符合IP:端口或域名:端口格式的字符串
                      for (String part in parts) {
                        // 检查是否符合IP:端口或域名:端口格式
                        bool isIpPort =
                            RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                .hasMatch(part);
                        bool isDomainPort = RegExp(
                                r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                            .hasMatch(part);

                        if (isIpPort || isDomainPort) {
                          finalIp = part;
                          break;
                        }
                      }

                      // 如果没有找到，尝试查找IPv4或IPv6标记后的部分
                      if (finalIp.isEmpty) {
                        for (int i = 0; i < parts.length - 1; i++) {
                          if (parts[i] == "IPv4" ||
                              parts[i] == "IPv6" ||
                              parts[i] == "TCP" ||
                              parts[i] == "UDP") {
                            String nextPart = parts[i + 1];
                            if (RegExp(r'^[a-zA-Z0-9][-a-zA-Z0-9\.]+\.[a-zA-Z]+:\d+$')
                                    .hasMatch(nextPart) ||
                                RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$')
                                    .hasMatch(nextPart)) {
                              finalIp = nextPart;
                              break;
                            }
                          }
                        }
                      }

                      // 如果仍然没有找到，使用默认值
                      if (finalIp.isEmpty && parts.length > 3) {
                        finalIp = parts[3]; // 使用默认位置
                      }

                      pGroupList.add(Pserver(
                        id: monitor.id,
                        name: monitor.name,
                        address: parts[0],
                        provider: parts[1],
                        version: parts[2],
                        isOfficialServer: false,
                        isTransferable: false,
                        ip: finalIp,
                      ));
                    }
                  } catch (e) {
                    Logger.info('Error parsing server data: $e');
                  }
                });
              }

              // 更新状态
              ref.read(pServerProvider.notifier).state = pGroupList;

              // 显示成功提示
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pGroupList.isEmpty
                        ? '未找到可用的服务器数据'
                        : '成功获取并解析 ${pGroupList.length} 个服务器数据'),
                  ),
                );
              }
            } catch (e) {
              Logger.info('JSON 解析错误: $e');
              // 确保状态被设置为空列表，而不是null
              ref.read(pServerProvider.notifier).state = [];
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('数据解析失败: $e')),
                );
              }
            }
          } else {
            Logger.info('未找到目标数据标记');
            // 确保状态被设置为空列表
            ref.read(pServerProvider.notifier).state = [];
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('未找到目标数据标记')),
              );
            }
          }
        } catch (e) {
          Logger.info('数据提取错误: $e');
          // 确保状态被设置为空列表
          ref.read(pServerProvider.notifier).state = [];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('数据提取错误: $e')),
            );
          }
        }
      } else {
        // 请求失败
        Logger.info('请求失败，状态码: ${response.statusCode}');
        // 确保状态被设置为空列表
        ref.read(pServerProvider.notifier).state = [];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('获取失败，状态码: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // 捕获网络错误
      Logger.info('网络请求错误: $e');
      // 确保状态被设置为空列表
      ref.read(pServerProvider.notifier).state = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络请求错误: $e')),
        );
      }
    }
  }
}

Future<void> _showNetworkInterfaceMetricsDialog(BuildContext context) async {
  // 显示加载指示器
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 从系统API获取网卡跃点列表
    final NetworkInterfaceHops interfaceMetrics =
        await NetworkUtil.getInterfaceMetrics();

    // 关闭加载指示器
    Navigator.of(context).pop();

    if (interfaceMetrics.hops.isEmpty) {
      // 如果获取失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取网卡跃点列表失败')),
      );
      return;
    }

    // 显示网卡跃点列表对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('网卡跃点列表'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300, // 设置一个固定高度
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: interfaceMetrics.hops.length,
            itemBuilder: (context, index) {
              final hop = interfaceMetrics.hops[index];
              return ListTile(
                title: Text(hop.interfaceName),
                trailing: Text(
                  '${hop.hopCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hop.hopCount < 50
                        ? Colors.green
                        : (hop.hopCount < 100 ? Colors.orange : Colors.red),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showNetworkInterfaceMetricsDialog(context); // 重新打开对话框以刷新数据
            },
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  } catch (e) {
    // 关闭加载指示器
    Navigator.of(context).pop();

    // 显示错误信息
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('获取网卡跃点列表失败: $e')),
    );
  }
}
