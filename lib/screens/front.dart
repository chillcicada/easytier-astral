// 导入必要的包
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/sys/k_stare.dart';
import 'package:astral/utils/kv_state.dart';
import 'package:astral/utils/app_info.dart';
import 'package:astral/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 替换 provider 导入
import '../widgets/card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../utils/runin.dart';
import 'package:vpn_service_plugin/vpn_service_plugin.dart';
import 'package:process_run/process_run.dart'; // 添加这一行

enum ConnectionState { notStarted, connecting, connected }

Runin parseRunin(String jsonString) {
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  return Runin.fromJson(jsonMap);
}

// 辅助方法：将整数形式的IP转换为字符串
String _intToIpv4String(int addr) {
  return [
    (addr >> 24) & 0xFF,
    (addr >> 16) & 0xFF,
    (addr >> 8) & 0xFF,
    addr & 0xFF,
  ].join('.');
}

/// 首页组件
/// 用于显示应用的主页面，包含主题切换和问候功能
class HomePage extends ConsumerStatefulWidget {
  // 主题模式切换回调函数
  final Function toggleThemeMode;
  // 主题色更改回调函数
  final Function(Color) changeSeedColor;
  // 当前主题模式
  final ThemeMode currentThemeMode;

  /// 构造函数
  const HomePage({
    super.key,
    required this.toggleThemeMode,
    required this.changeSeedColor,
    required this.currentThemeMode,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final vpnPlugin = VpnServicePlugin();

  int connectionTimeoutCounter = 0;

  // 当前连接状态
  ConnectionState _connectionState = ConnectionState.notStarted;

  void _startVpn({
    required String ipv4Addr,
    int mtu = 1300,
    List<String> disallowedApplications = const ['com.example.astral'],
  }) {
    if (ipv4Addr.isNotEmpty & (ipv4Addr != "")) {
      // 确保IP地址格式为"IP/掩码"
      if (!ipv4Addr.contains('/')) {
        ipv4Addr = "$ipv4Addr/24";
      }

      vpnPlugin.startVpn(
        ipv4Addr: ipv4Addr,
        mtu: mtu,
        disallowedApplications: disallowedApplications,
      );
    } else {
      Logger.info("错误：无法启动VPN，IP地址为空");
    }
  }

  bool isRunning = false; // 只用于控制启动/暂停状态
  Duration runningTime = Duration.zero;
  Timer? timer;

  // 模拟数据
  double uploadSpeed = 0; // MB/s
  double downloadSpeed = 0; // MB/s
  String publicIP = "";
  // 房间名
  String roomName = "";
  // 房间密码
  String roomPassword = "";
  // 用户名
  String username = "";

  bool _isAutoIP = true; // 只用于控制IP自动/手动模式
  double _connectionProgress = 0.0; // 连接进度，用于显示进度条动画
  int _uploadBytes = 0;
  int _downloadBytes = 0;
  int _lastUploadBytes = 0;
  int _lastDownloadBytes = 0;
  // 定义卡片列表
  late final List<Widget Function(ColorScheme)> _cardBuilders;

  // 添加 TextEditingController
  late final TextEditingController _roomNameController;
  late final TextEditingController _roomPasswordController;
  late final TextEditingController _usernameController;
  late final TextEditingController _virtualIPController;
  // 添加FocusNode来监听焦点变化
  late final FocusNode _virtualIPFocusNode;
  late final FocusNode _usernameControllerFocusNode;
  late final FocusNode _roomNameControllerFocusNode;
  late final FocusNode _roomPasswordControllerFocusNode;

  // 防火墙状态
  bool _domainFirewallEnabled = true;
  bool _privateFirewallEnabled = true;
  bool _publicFirewallEnabled = true;

  // 记录初始防火墙状态
  bool? _initialDomainState;
  bool? _initialPrivateState;
  bool? _initialPublicState;

  Widget _buildFirewallCard(ColorScheme colorScheme) {
    return FloatingCard(
      colorScheme: colorScheme,
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              // 使用 Expanded 包裹文本，防止溢出
              Expanded(
                child: const Text(
                  '系统防火墙',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _toggleAllFirewall(!_domainFirewallEnabled),
                icon:
                    Icon(_domainFirewallEnabled ? Icons.lock : Icons.lock_open),
                label: Text(_domainFirewallEnabled ? '一键关闭' : '一键开启'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 防火墙状态列表
          _buildFirewallStatus('域网络', _domainFirewallEnabled, colorScheme),
          const SizedBox(height: 8),
          _buildFirewallStatus('专用网络', _privateFirewallEnabled, colorScheme),
          const SizedBox(height: 8),
          _buildFirewallStatus('公用网络', _publicFirewallEnabled, colorScheme),
        ],
      ),
    );
  }

  Future<void> _toggleAllFirewall(bool enable) async {
    var shell = Shell();
    try {
      await shell.run(
          'netsh advfirewall set allprofiles state ${enable ? "on" : "off"}');
      setState(() {
        _domainFirewallEnabled = enable;
        _privateFirewallEnabled = enable;
        _publicFirewallEnabled = enable;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('防火墙操作失败: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // 初始化所有TextEditingController
    _roomNameController = TextEditingController(text: roomName);
    _roomPasswordController = TextEditingController(text: roomPassword);
    _usernameController = TextEditingController(text: username);
    _virtualIPController = TextEditingController(text: publicIP); // 添加缺失的初始化

    // 初始化FocusNode并添加监听器
    _virtualIPFocusNode = FocusNode();
    _virtualIPFocusNode.addListener(_onVirtualIPFocusChange);

    // 初始化用户名、房间名和密码的FocusNode
    _usernameControllerFocusNode = FocusNode();
    _usernameControllerFocusNode.addListener(_onUsernameFocusChange);

    _roomNameControllerFocusNode = FocusNode();
    _roomNameControllerFocusNode.addListener(_onRoomNameFocusChange);

    _roomPasswordControllerFocusNode = FocusNode();
    _roomPasswordControllerFocusNode.addListener(_onRoomPasswordFocusChange);

    // 修改卡片构建器列表，添加服务器列表卡片
    _cardBuilders = [
      _buildNetworkStatusCard,
      _buildUserInfoCard,
      _buildRoomInfoCard,
      _buildServerListCard,
      if (Platform.isWindows) _buildFirewallCard,
      _buildVersionInfoCard,
    ];
    if (Platform.isAndroid) {
      // 监听VPN服务启动事件
      vpnPlugin.onVpnServiceStarted.listen((data) {
        Logger.info('VPN服务已启动，文件描述符: ${data['fd']}');
        setTunFd(fd: data['fd']);
        // 在这里处理VPN启动后的逻辑
      });

      // 监听VPN服务停止事件
      vpnPlugin.onVpnServiceStopped.listen((data) {
        Logger.info('VPN服务已停止');
        // 在这里处理VPN停止后的逻辑
      });
    }

    // 初始化防火墙状态
    if (Platform.isWindows) _initFirewallStatus();
  }

  // 初始化防火墙状态
  Future<void> _initFirewallStatus() async {
    var shell = Shell();

    // 获取域防火墙状态
    var domainResult = await shell.run('netsh advfirewall show domainprofile');
    _domainFirewallEnabled = domainResult[0]
        .stdout
        .toString()
        .contains('State                                 ON');
    _initialDomainState = _domainFirewallEnabled;

    // 获取专用防火墙状态
    var privateResult =
        await shell.run('netsh advfirewall show privateprofile');
    _privateFirewallEnabled = privateResult[0]
        .stdout
        .toString()
        .contains('State                                 ON');
    _initialPrivateState = _privateFirewallEnabled;

    // 获取公用防火墙状态
    var publicResult = await shell.run('netsh advfirewall show publicprofile');
    _publicFirewallEnabled = publicResult[0]
        .stdout
        .toString()
        .contains('State                                 ON');
    _initialPublicState = _publicFirewallEnabled;

    setState(() {});
  }

  // 添加焦点变化监听方法
  void _onVirtualIPFocusChange() {
    if (!_virtualIPFocusNode.hasFocus && !_isAutoIP) {
      // 当失去焦点且不是自动IP模式时更新值
      ref
          .read(virtualIPProvider.notifier)
          .setVirtualIP(_virtualIPController.text);
    }
  }

  // 添加一个处理VPN路由的方法
  List<String> _getValidRoutesForVpn(List<String> routes) {
    if (routes.isEmpty) {
      return [];
    }

    // 处理每个路由地址，确保格式正确
    List<String> validRoutes = [];
    for (String route in routes) {
      if (route.isEmpty) continue;

      String processedRoute = route;
      // 如果不包含CIDR格式（没有"/"），则添加"/32"
      if (!processedRoute.contains('/')) {
        processedRoute += '/32';
      }

      try {
        // 解析IP和CIDR部分
        final parts = processedRoute.split('/');
        final ipPart = parts[0];
        final cidrPart = parts[1];

        // 验证IP地址格式
        if (_isValidIPv4(ipPart)) {
          // 对于主机IP（如10.126.126.2），使用/32而不是/24
          // 对于网络IP（如10.126.126.0），使用/24
          final ipOctets = ipPart.split('.');
          final lastOctet = int.parse(ipOctets[3]);

          // 如果最后一个八位字节不是0，且CIDR是24，可能需要调整为/32
          if (lastOctet != 0 && cidrPart == "24") {
            // 这是一个主机IP，使用/32
            validRoutes.add("$ipPart/32");
          } else {
            // 保持原样
            validRoutes.add(processedRoute);
          }
        } else {
          Logger.info('跳过无效路由IP: $ipPart');
        }
      } catch (e) {
        Logger.info('处理路由时出错: $route, 错误: $e');
      }
    }

    // 去重并排序
    return validRoutes.toSet().toList()..sort();
  }

  // 添加用户名焦点变化监听方法
  void _onUsernameFocusChange() {
    if (!_usernameControllerFocusNode.hasFocus) {
      ref.read(usernameProvider.notifier).setUsername(_usernameController.text);
    }
  }

  // 添加房间名焦点变化监听方法
  void _onRoomNameFocusChange() {
    if (!_roomNameControllerFocusNode.hasFocus) {
      ref.read(roomNameProvider.notifier).setRoomName(_roomNameController.text);
    }
  }

  // 添加房间密码焦点变化监听方法
  void _onRoomPasswordFocusChange() {
    if (!_roomPasswordControllerFocusNode.hasFocus) {
      ref
          .read(roomPasswordProvider.notifier)
          .setRoomPassword(_roomPasswordController.text);
    }
  }

  @override
  void dispose() {
    // 取消所有计时器
    timer?.cancel();
    timer = null;

    // 释放所有控制器和焦点节点
    _roomNameController.dispose();
    _roomPasswordController.dispose();
    _usernameController.dispose();
    _virtualIPController.dispose();

    _virtualIPFocusNode.removeListener(_onVirtualIPFocusChange);
    _virtualIPFocusNode.dispose();

    _usernameControllerFocusNode.removeListener(_onUsernameFocusChange);
    _usernameControllerFocusNode.dispose();

    _roomNameControllerFocusNode.removeListener(_onRoomNameFocusChange);
    _roomNameControllerFocusNode.dispose();

    _roomPasswordControllerFocusNode.removeListener(_onRoomPasswordFocusChange);
    _roomPasswordControllerFocusNode.dispose();

    // 恢复初始防火墙状态
    if (Platform.isWindows) _restoreFirewallStatus();

    super.dispose();
  }

  Future<void> _restoreFirewallStatus() async {
    if (_initialDomainState != null &&
        _initialPrivateState != null &&
        _initialPublicState != null) {
      var shell = Shell();

      // 恢复域防火墙状态
      await shell.run(
          'netsh advfirewall set domainprofile state ${_initialDomainState! ? "on" : "off"}');

      // 恢复专用防火墙状态
      await shell.run(
          'netsh advfirewall set privateprofile state ${_initialPrivateState! ? "on" : "off"}');

      // 恢复公用防火墙状态
      await shell.run(
          'netsh advfirewall set publicprofile state ${_initialPublicState! ? "on" : "off"}');
    }
  }

  void toggleRunning() {
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        _connectionProgress = 0.0; // 重置进度
        // 切换到连接中状态
        _connectionState = ConnectionState.connecting;
        // 添加进度条自增定时器
        Timer.periodic(const Duration(milliseconds: 100), (progressTimer) {
          if (!mounted || _connectionState != ConnectionState.connecting) {
            progressTimer.cancel();
            return;
          }

          setState(() {
            // 每100毫秒增加1%，最大到95%（留5%给实际连接成功）
            _connectionProgress = min(_connectionProgress + 1, 95);
          });
        });
        //利用 Serveripz 重组
        List<String> ssServerip = [];
        for (var item in ref.read(KConfig.provider).servers) {
          if (item.tcp) {
            ssServerip.add("tcp://${item.url}");
          }
          if (item.udp) {
            ssServerip.add("udp://${item.url}");
          }
          if (item.ws) {
            ssServerip.add("ws://${item.url}");
          }
          if (item.wss) {
            ssServerip.add("wss://${item.url}");
          }
          if (item.quic) {
            ssServerip.add("quic://${item.url}");
          }
        }
        // 复制 创建服务器
        // 启动VPN服务
        if (Platform.isAndroid) {
          vpnPlugin.prepareVpn();
        }

        createServer(
            username: username,
            enableDhcp: _isAutoIP,
            specifiedIp: publicIP,
            roomName: roomName,
            roomPassword: roomPassword,
            severurl: ssServerip,
            flag: FlagsC(
                defaultProtocol:
                    ref.read(advancedConfigProvider)['defaultProtocol'] ??
                        "tcp",
                devName: ref.read(advancedConfigProvider)['devName'] ?? "",
                enableEncryption: true,
                enableIpv6:
                    ref.read(advancedConfigProvider)['enableIpv6'] ?? true,
                mtu: 1360,
                multiThread:
                    ref.read(advancedConfigProvider)['multiThread'] ?? true,
                latencyFirst:
                    ref.read(advancedConfigProvider)['latencyFirst'] ?? false,
                enableExitNode:
                    ref.read(advancedConfigProvider)['enableExitNode'] ?? false,
                noTun: false,
                useSmoltcp: false,
                relayNetworkWhitelist:
                    ref.read(advancedConfigProvider)['relayNetworkWhitelist'] ??
                        "*",
                disableP2P: false,
                relayAllPeerRpc: false,
                disableUdpHolePunching:
                    ref.read(advancedConfigProvider)['disableUdpHolePunching'] ??
                        false,
                dataCompressAlgo: ref.read(advancedConfigProvider)['dataCompressAlgo'] ==
                        "Invalid"
                    ? 0
                    : ref.read(advancedConfigProvider)['dataCompressAlgo'] ==
                            "None"
                        ? 1
                        : ref.read(advancedConfigProvider)['dataCompressAlgo'] ==
                                "Zstd"
                            ? 2
                            : 1,
                bindDevice: true,
                enableKcpProxy:
                    ref.read(advancedConfigProvider)['enableKcpProxy'] ?? false,
                disableKcpInput: false,
                disableRelayKcp:
                    ref.read(advancedConfigProvider)['disableRelayKcp'] ?? true,
                proxyForwardBySystem: false));

        // 不再使用固定延迟模拟连接成功，而是通过定时检查IP来确定连接状态
        timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          // 检查组件是否仍然挂载
          if (!mounted) {
            timer.cancel();
            return;
          }

          final info = await getRunningInfo();
          Runin runin = parseRunin(info);

          // 获取网络状态
          final networkStatus = await getNetworkStatus();
          ref.read(nodesProvider.notifier).setNodes(networkStatus.nodes);

          // 获取所有IP列表
          List<String> llk = await getAllIps();
          // 更新VPN状态
          if (Platform.isAndroid) {
            ref.read(vpnStatusProvider.notifier).updateStatus(
                  routes: llk,
                  ipv4Addr: publicIP, // 添加IP地址参数
                );
          }
          // 更新网络流量数据
          _updateNetworkStats(networkStatus.nodes);

          final int? version = runin.myNodeInfo?.virtualIpv4?.address?.addr;
          if (version != null) {
            String ipStr = _intToIpv4String(version);
            if (publicIP != ipStr) {
              ref.read(virtualIPProvider.notifier).setVirtualIP(ipStr);
            }

            // 如果当前状态还是连接中，则更新为已连接
            if (_connectionState == ConnectionState.connecting) {
              if (Platform.isAndroid) {
                // 确保IP地址不为空且格式正确
                if (ipStr.isNotEmpty) {
                  _startVpn(
                    ipv4Addr: ipStr,
                  );
                } else {
                  // 处理IP为空的情况
                  Logger.info("错误：无法获取有效的IP地址");
                  // 可能需要停止连接过程
                }
              }
              // 使用公共方法启动VPN
              if (Platform.isWindows) {
                if (ref.watch(networkOverlapEnabledProvider)) {
                  setNetworkInterfaceHops(
                      hop: ref.watch(networkOverlapValueProvider));
                }
              }
              setState(() {
                _connectionState = ConnectionState.connected;
              });
            }
            connectionTimeoutCounter = 0;
          } else if (_connectionState == ConnectionState.connecting) {
            connectionTimeoutCounter++;
            if (connectionTimeoutCounter >= 10) {
              connectionTimeoutCounter = 0;
              timer.cancel();
              setState(() {
                isRunning = false;
                _connectionState = ConnectionState.notStarted;
                runningTime = Duration.zero;
              });

              closeAllServer();
              // 清空玩家列表数据
              ref.read(nodesProvider.notifier).setNodes([]);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('连接失败，未能获取节点信息'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              return;
            }
          }

          // 再次检查组件是否仍然挂载
          if (!mounted) {
            timer.cancel();
            return;
          }

          // 更新运行时间
          // 检查是否已连接
          if (_connectionState == ConnectionState.connected) {
            setState(() {
              runningTime += const Duration(seconds: 1);
            });
          }
        });
      } else {
        if (Platform.isAndroid) {
          vpnPlugin.stopVpn();
        }
        // 停止时重置状态
        _connectionState = ConnectionState.notStarted;
        closeAllServer();
        // 清空玩家列表数据
        ref.read(nodesProvider.notifier).setNodes([]);
        timer?.cancel();
        runningTime = Duration.zero;
        // 重置网络统计数据
        _uploadBytes = 0;
        _downloadBytes = 0;
        _lastUploadBytes = 0;
        _lastDownloadBytes = 0;
        uploadSpeed = 0;
        downloadSpeed = 0;
      }
    });
  }

  // 添加网络统计数据更新方法
  void _updateNetworkStats(dynamic nodes) {
    if (nodes == null || nodes.isEmpty) return;

    int totalUploadBytes = 0;
    int totalDownloadBytes = 0;
    String myIP = ref.read(virtualIPProvider);

    // 查找本机节点
    for (var node in nodes) {
      if (node.ipv4 == myIP) {
        // 找到本机节点，计算上传下载总量
        if (node.connections != null && node.connections.isNotEmpty) {
          for (var conn in node.connections) {
            totalUploadBytes += (conn.txBytes as BigInt).toInt();
            totalDownloadBytes += (conn.rxBytes as BigInt).toInt();
          }
        }
        break;
      }
    }

    // 再次检查挂载状态，确保在setState前组件仍然挂载
    if (!mounted) return;

    // 计算速度 (字节/秒 转换为 MB/秒)
    setState(() {
      _uploadBytes = totalUploadBytes;
      _downloadBytes = totalDownloadBytes;

      // 计算速度差值
      if (_lastUploadBytes > 0) {
        uploadSpeed =
            (_uploadBytes - _lastUploadBytes) / (1024 * 1024); // 转换为MB/s
        uploadSpeed = double.parse(uploadSpeed.toStringAsFixed(2)); // 保留两位小数
      }

      if (_lastDownloadBytes > 0) {
        downloadSpeed =
            (_downloadBytes - _lastDownloadBytes) / (1024 * 1024); // 转换为MB/s
        downloadSpeed =
            double.parse(downloadSpeed.toStringAsFixed(2)); // 保留两位小数
      }

      // 更新上次的值
      _lastUploadBytes = _uploadBytes;
      _lastDownloadBytes = _downloadBytes;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 使用 Riverpod 读取数据
    _roomNameController.value = TextEditingValue(
      text: ref.read(roomNameProvider),
      selection: _roomNameController.selection,
    );
    _roomPasswordController.value = TextEditingValue(
      text: ref.read(roomPasswordProvider),
      selection: _roomPasswordController.selection,
    );
    _usernameController.value = TextEditingValue(
      text: ref.read(usernameProvider),
      selection: _usernameController.selection,
    );
    // 添加虚拟IP控制器的值同步
    _virtualIPController.value = TextEditingValue(
      text: ref.read(virtualIPProvider),
      selection: _virtualIPController.selection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 使用 Riverpod 读取数据
    publicIP = ref.watch(virtualIPProvider);
    _isAutoIP = ref.watch(dynamicIPProvider);
    roomName = ref.watch(roomNameProvider);
    roomPassword = ref.watch(roomPasswordProvider);
    username = ref.watch(usernameProvider);

    if (Platform.isAndroid) {
      // 监听 VPN 状态,当状态为运行中时返回 true
      ref.listen<VpnStatus>(vpnStatusProvider, (previous, current) {
        if (previous != null) {
          // 状态发生变化时的处理
          if (previous.state != current.state) {
            Logger.info('VPN状态变化: ${previous.state} -> ${current.state}');
          }

          if (previous.ipv4Addr != current.ipv4Addr) {
            Logger.info(
                'IPv4地址变化: ${previous.ipv4Addr} -> ${current.ipv4Addr}');
            //判断ip有没有变化
            if (publicIP != current.ipv4Addr &&
                current.ipv4Addr?.isNotEmpty == true) {
              // 使用公共方法启动VPN
              _startVpn(ipv4Addr: current.ipv4Addr!);
            }
          }

          if (previous.ipv4Cidr != current.ipv4Cidr) {
            Logger.info('CIDR变化: ${previous.ipv4Cidr} -> ${current.ipv4Cidr}');
          }

          if (!listEquals(previous.routes, current.routes)) {
            Logger.info('路由变化: ${previous.routes} -> ${current.routes}');
          }
        }
      });
    }

    // 使用 LayoutBuilder 来处理布局变化，同时保留状态
    return Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          // 根据约束计算列数
          final columnCount = _getColumnCount(constraints.maxWidth);

          return CustomScrollView(
            // 添加这个属性来控制滚动行为
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 替换原有的 SliverList 为 SliverPadding + SliverGrid
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: columnCount, // 使用计算出的列数
                  mainAxisSpacing: 16, // 主轴间距
                  crossAxisSpacing: 16, // 交叉轴间距
                  childCount: _cardBuilders.length,
                  itemBuilder: (context, index) {
                    // 直接从列表中获取构建函数并调用
                    return _cardBuilders[index](colorScheme);
                  },
                ),
              ),
            ],
          );
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end, // 确保右对齐
            children: [
              SizedBox(
                height: 14, // 固定高度，包含进度条高度(6px)和底部边距(8px)
                width: 180, // 固定宽度与按钮一致
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _connectionState == ConnectionState.connecting
                      ? Offset.zero
                      : const Offset(0, 1.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _connectionState == ConnectionState.connecting
                        ? 1.0
                        : 0.0,
                    child: Container(
                      width: 180,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      // 其余进度条代码保持不变
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                            'progress_${_connectionState == ConnectionState.connecting}'), // 添加key以重置动画
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 10), // 10秒完成动画
                        curve: Curves.easeInOut,
                        builder: (context, value, _) {
                          // 更新进度值，但不通过setState
                          _connectionProgress = value * 100;
                          return FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.tertiary,
                                    colorScheme.primary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // 按钮
              Align(
                alignment: Alignment.centerRight, // 将按钮右对齐
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: _connectionState != ConnectionState.notStarted
                      ? 180
                      : 100,
                  height: 60,
                  child: FloatingActionButton.extended(
                    onPressed: _connectionState == ConnectionState.connecting
                        ? null
                        : toggleRunning,
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 2),
                    splashColor: _connectionState != ConnectionState.notStarted
                        ? colorScheme.onTertiary.withAlpha(51)
                        : colorScheme.onPrimary.withAlpha(51),
                    highlightElevation: 6,
                    elevation: 2,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _getButtonIcon(_connectionState),
                    ),
                    label: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 0),
                      switchInCurve: Curves.easeOutQuad,
                      switchOutCurve: Curves.easeInQuad,
                      child: _getButtonLabel(_connectionState),
                    ),
                    backgroundColor:
                        _getButtonColor(_connectionState, colorScheme),
                    foregroundColor: _getButtonForegroundColor(
                        _connectionState, colorScheme),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // 修改为接受宽度参数，而不是使用 MediaQuery
  int _getColumnCount(double width) {
    if (width < 600) {
      return 1; // 手机屏幕显示1列
    } else if (width < 900) {
      return 2; // 平板或小屏幕显示2列
    } else {
      return 3; // 大屏幕显示3列
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

// 根据连接状态获取按钮图标
  Widget _getButtonIcon(ConnectionState state) {
    switch (state) {
      case ConnectionState.notStarted:
        return const Icon(
          Icons.play_arrow,
          key: ValueKey('play'),
          size: 34,
        );
      case ConnectionState.connecting:
        return SizedBox(
          key: const ValueKey('connecting'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onTertiary),
          ),
        );
      case ConnectionState.connected:
        return const Icon(
          Icons.pause,
          key: ValueKey('pause'),
          size: 34,
        );
    }
  }

  // 根据连接状态获取按钮文本
  Widget _getButtonLabel(ConnectionState state) {
    switch (state) {
      case ConnectionState.notStarted:
        return const Text(
          '启动',
          key: ValueKey('start_text'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        );
      case ConnectionState.connecting:
        return const Text(
          '连接中...',
          key: ValueKey('connecting_text'),
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      case ConnectionState.connected:
        return Text(
          _formatDuration(runningTime),
          key: const ValueKey('running_text'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
    }
  }

  // 根据连接状态获取按钮背景色
  Color _getButtonColor(ConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case ConnectionState.notStarted:
        return colorScheme.primary;
      case ConnectionState.connecting:
        return colorScheme.tertiary.withOpacity(0.7);
      case ConnectionState.connected:
        return colorScheme.tertiary;
    }
  }

  // 根据连接状态获取按钮前景色
  Color _getButtonForegroundColor(
      ConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case ConnectionState.notStarted:
        return colorScheme.onPrimary;
      case ConnectionState.connecting:
      case ConnectionState.connected:
        return colorScheme.onTertiary;
    }
  }

  Widget _buildTrafficInfo(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(label),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildIPInfo(
      String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: colorScheme.secondary)),
      ],
    );
  }

// 添加服务器列表卡片
  Widget _buildServerListCard(ColorScheme colorScheme) {
    return Consumer(
      builder: (context, ref, child) {
        // 直接使用 serverIP 列表
        final serverUrls = ref.watch(serverIPProvider);

        return FloatingCard(
          colorScheme: colorScheme,
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(Icons.dns, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('当前服务器',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // 当前选中的服务器
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serverUrls.isEmpty ||
                        (serverUrls.length == 1 && serverUrls[0].isEmpty)
                    ? [
                        Chip(
                          avatar: Icon(Icons.info_outline,
                              size: 16, color: colorScheme.error),
                          label: const Text('未选择服务器'),
                          backgroundColor:
                              colorScheme.errorContainer.withOpacity(0.3),
                        )
                      ]
                    : serverUrls
                        .map((url) => Chip(
                              avatar: Icon(Icons.dns,
                                  size: 16, color: colorScheme.primary),
                              label: Text(url),
                              backgroundColor: colorScheme.surfaceVariant,
                            ))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 新增合并后的网络状态卡片（合并了流量统计和IP信息）
  // 修改网络状态卡片，去除流量统计部分
  Widget _buildNetworkStatusCard(ColorScheme colorScheme) {
    return FloatingCard(
      colorScheme: colorScheme,
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏带有连接状态指示器
          Row(
            children: [
              Icon(Icons.network_check, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text('网络状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // 添加状态指示器
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_connectionState, colorScheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(_connectionState),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // IP信息部分
          _buildIPInfo('虚拟 IP', publicIP, Icons.public, colorScheme),

          // 添加运行时间显示
          if (_connectionState == ConnectionState.connected) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '运行时间: ${_formatDuration(runningTime)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 获取状态文本
  String _getStatusText(ConnectionState state) {
    switch (state) {
      case ConnectionState.notStarted:
        return '未连接';
      case ConnectionState.connecting:
        return '连接中';
      case ConnectionState.connected:
        return '已连接';
    }
  }

  // 获取状态颜色
  Color _getStatusColor(ConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case ConnectionState.notStarted:
        return Colors.grey;
      case ConnectionState.connecting:
        return Colors.orange;
      case ConnectionState.connected:
        return Colors.green;
    }
  }

  // 优化用户信息卡片
  Widget _buildUserInfoCard(ColorScheme colorScheme) {
    final isValidIP = _isAutoIP || _isValidIPv4(ref.watch(virtualIPProvider));

    return FloatingCard(
      colorScheme: colorScheme,
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Icon(Icons.person, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text('用户信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // 添加编辑状态指示器
              if (_connectionState == ConnectionState.connected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已锁定',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 用户名输入框
          TextField(
            controller: _usernameController,
            focusNode: _usernameControllerFocusNode, // 添加焦点节点
            enabled: _connectionState != ConnectionState.connected,
            onEditingComplete: () {
              // 改为完成编辑时更新
              ref
                  .read(usernameProvider.notifier)
                  .setUsername(_usernameController.text);
            },
            decoration: InputDecoration(
              labelText: '用户名',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.person, color: colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          const SizedBox(height: 12),

          // IP设置部分
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _virtualIPController,
                  focusNode: _virtualIPFocusNode, // 添加焦点节点
                  enabled: !_isAutoIP &&
                      _connectionState != ConnectionState.connected,
                  onChanged: (value) {
                    // 保留空回调以避免实时更新
                  },
                  onEditingComplete: () {
                    // 添加完成编辑回调
                    if (!_isAutoIP) {
                      ref
                          .read(virtualIPProvider.notifier)
                          .setVirtualIP(_virtualIPController.text);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '虚拟网IP',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lan, color: colorScheme.primary),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    errorText: !isValidIP && !_isAutoIP ? '请输入有效的IPv4地址' : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Switch(
                    value: _isAutoIP,
                    onChanged: _connectionState != ConnectionState.connected
                        ? (value) {
                            setState(() {
                              _isAutoIP = value;
                            });
                            ref
                                .read(dynamicIPProvider.notifier)
                                .setDynamicIP(value);
                            // 切换模式时同步最新值
                            if (!value) {
                              ref
                                  .read(virtualIPProvider.notifier)
                                  .setVirtualIP(_virtualIPController.text);
                            }
                          }
                        : null,
                  ),
                  Text(
                    _isAutoIP ? "自动" : "手动",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (_isAutoIP)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '系统将自动分配虚拟网IP',
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 优化房间信息卡片
  Widget _buildRoomInfoCard(ColorScheme colorScheme) {
    return FloatingCard(
      colorScheme: colorScheme,
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              Icon(Icons.meeting_room, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text('房间信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // 添加编辑状态指示器
              if (_connectionState == ConnectionState.connected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已锁定',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 房间名称输入框
          TextField(
            controller: _roomNameController,
            focusNode: _roomNameControllerFocusNode, // 添加焦点节点
            enabled: _connectionState != ConnectionState.connected,
            onEditingComplete: () {
              // 改为完成编辑时更新
              ref
                  .read(roomNameProvider.notifier)
                  .setRoomName(_roomNameController.text);
            },
            decoration: InputDecoration(
              labelText: '房间名称',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.meeting_room, color: colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
          const SizedBox(height: 12),

          // 房间密码输入框
          TextField(
            controller: _roomPasswordController,
            focusNode: _roomPasswordControllerFocusNode, // 添加焦点节点
            enabled: _connectionState != ConnectionState.connected,
            onEditingComplete: () {
              ref
                  .read(roomPasswordProvider.notifier)
                  .setRoomPassword(_roomPasswordController.text);
            },
            obscureText: true,
            decoration: InputDecoration(
              labelText: '房间密码',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              // helperText: '留空表示无密码',
            ),
          ),
        ],
      ),
    );
  }

// 验证IP地址格式是否有效
  bool _isValidIPv4(String ip) {
    if (ip == null || ip.isEmpty) return false;

    final RegExp ipRegex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

    return ipRegex.hasMatch(ip);
  }
}

// 添加版本信息卡片
Widget _buildVersionInfoCard(ColorScheme colorScheme) {
  // 这里可以从配置或API获取实际版本号
  final String appVersion = AppInfoUtil.getVersion();

  return FloatingCard(
    colorScheme: colorScheme,
    maxWidth: 600,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('版本信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        // 版本信息列表
        _buildVersionItem('软件版本', appVersion, Icons.apps, colorScheme),
        const SizedBox(height: 12),

        // 使用FutureBuilder处理异步获取的版本信息
        FutureBuilder<String>(
          future: easytierVersion(),
          builder: (context, snapshot) {
            String version = snapshot.hasData ? snapshot.data! : "加载中...";
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.memory, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text(
                  'ET内核版本:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    version,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildFirewallStatus(
    String label, bool enabled, ColorScheme colorScheme) {
  return Row(
    children: [
      Icon(
        enabled ? Icons.check_circle : Icons.cancel,
        color: enabled ? Colors.green : Colors.red,
        size: 20,
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          )),
      const Spacer(),
      Text(
        enabled ? '已启用' : '已禁用',
        style: TextStyle(
          color: enabled ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

// 版本信息项构建方法
Widget _buildVersionItem(
    String label, String version, IconData icon, ColorScheme colorScheme) {
  return Row(
    children: [
      Icon(icon, size: 20, color: colorScheme.primary),
      const SizedBox(width: 12),
      Text('$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          )),
      const SizedBox(width: 8),
      Text(
        version,
        style: TextStyle(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
