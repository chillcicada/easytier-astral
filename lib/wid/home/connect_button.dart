import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/wid/left_nav.dart';
import 'package:flutter/material.dart';

enum ConnectionState { idle, connecting, connected }

class ConnectButton extends StatefulWidget {
  const ConnectButton({super.key});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  ConnectionState _state = ConnectionState.idle;
  late AnimationController _animationController;
  double _progress = 0.0;

  // 在类中添加这些变量
  Timer? _connectionTimer;
  int _connectionDuration = 0; // 连接持续时间（秒）

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 开始连接流程的方法
  /// 该方法负责将按钮状态从空闲(idle)切换到连接中(connecting)，
  /// 然后模拟一个10秒的网络连接过程，最后切换到已连接(connected)状态
  void _startConnection() {
    // 如果当前状态不是空闲状态，则直接返回，防止重复触发连接操作
    if (_state != ConnectionState.idle) return;
    final rom = Aps().selectroom.value;
    if (rom == null) return;
    // //利用 Serveripz 重组
    //     List<String> ssServerip = [];
    //     for (var item in Serveripz) {
    //       if (item.tcp) {
    //         ssServerip.add("tcp://" + item.url);
    //       }
    //       if (item.udp) {
    //         ssServerip.add("udp://" + item.url);
    //       }
    //       if (item.ws) {
    //         ssServerip.add("ws://" + item.url);
    //       }
    //       if (item.wss) {
    //         ssServerip.add("wss://" + item.url);
    //       }
    //       if (item.quic) {
    //         ssServerip.add("quic://" + item.url);
    //       }
    //     }
    createServer(
      username: Aps().PlayerName.value,
      enableDhcp: Aps().dhcp.value,
      specifiedIp: Aps().ipv4.value,
      roomName: rom.roomName,
      roomPassword: rom.password,
      severurl: ["tcp://124.71.134.95:11010", "udp://124.71.134.95:11010"],
      onurl: ["tcp://0.0.0.0:11010", "udp://0.0.0.0:11010", "tcp://[::]:11010"],
      flag: FlagsC(
        defaultProtocol: Aps().defaultProtocol.value, // 默认协议
        devName: Aps().devName.value, // 设备名称
        enableEncryption: Aps().enableEncryption.value, // 启用加密
        enableIpv6: Aps().enableIpv6.value, // 启用IPv6
        mtu: Aps().mtu.value, // 最大传输单元
        multiThread: Aps().multiThread.value, // 启用多线程
        latencyFirst: Aps().latencyFirst.value, // 优先考虑延迟
        enableExitNode: Aps().enableExitNode.value, // 启用出口节点
        noTun: Aps().noTun.value, // 不使用TUN设备
        useSmoltcp: Aps().useSmoltcp.value, // 使用Smoltcp
        relayNetworkWhitelist: Aps().relayNetworkWhitelist.value, // 中继网络白名单
        disableP2P: Aps().disableP2p.value, // 禁用P2P
        relayAllPeerRpc: Aps().relayAllPeerRpc.value, // 中继所有对等RPC
        disableUdpHolePunching: Aps().disableUdpHolePunching.value, // 禁用UDP打洞
        dataCompressAlgo: Aps().dataCompressAlgo.value, // 数据压缩算法
        bindDevice: Aps().bindDevice.value, // 绑定设备
        enableKcpProxy: Aps().enableKcpProxy.value, // 启用KCP代理
        disableKcpInput: Aps().disableKcpInput.value, // 禁用KCP输入
        disableRelayKcp: Aps().disableRelayKcp.value, // 禁用中继KCP
        proxyForwardBySystem: Aps().proxyForwardBySystem.value, // 通过系统代理转发
      ),
    );
    // 更新状态为连接中，并重置进度条进度为0
    setState(() {
      _state = ConnectionState.connecting;
      _progress = 0.0;
    });

    if (mounted) {
      // 更新状态为已连接
      setState(() {
        _state = ConnectionState.connected;
        _connectionDuration = 0; // 重置连接时间
      });

      // 创建一个每秒触发一次的计时器
      _connectionTimer = Timer.periodic(const Duration(seconds: 1), (
        timer,
      ) async {
        if (mounted) {
          setState(() {
            _connectionDuration++; // 每秒增加连接时间
          });

          var a = await getRunningInfo();
          var data = jsonDecode(a);
          print(data);
          Aps().updateIpv4(
            intToIp(
              data['my_node_info']?['virtual_ipv4']?.isEmpty ?? true
                  ? 0
                  : data['my_node_info']?['virtual_ipv4']['address']['addr'] ??
                      0,
            ),
          );
          Aps().netStatus.value = await getNetworkStatus();
        } else {
          timer.cancel(); // 如果组件已卸载，取消计时器
        }
      });
    }
  }

  /// 断开连接的方法
  /// 该方法负责将按钮状态从已连接(connected)切换回空闲(idle)状态，
  /// 实现断开连接的功能
  void _disconnect() {
    // 取消计时器
    _connectionTimer?.cancel();
    _connectionTimer = null;

    closeServer();
    setState(() {
      _state = ConnectionState.idle;
    });
  }

  /// 切换连接状态的方法
  /// 根据当前的连接状态来决定是开始连接还是断开连接
  void _toggleConnection() {
    if (_state == ConnectionState.idle) {
      // 如果当前是空闲状态，则开始连接
      _startConnection();
    } else if (_state == ConnectionState.connected) {
      // 如果当前是已连接状态，则断开连接
      _disconnect();
    }
  }

  Widget _getButtonIcon(ConnectionState state) {
    switch (state) {
      case ConnectionState.idle:
        return Icon(
          Icons.power_settings_new_rounded,
          key: const ValueKey('idle_icon'),
        );
      case ConnectionState.connecting:
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animationController.value * 2 * pi,
              child: const Icon(
                Icons.sync_rounded,
                key: ValueKey('connecting_icon'),
              ),
            );
          },
        );
      case ConnectionState.connected:
        return Icon(Icons.link_rounded, key: const ValueKey('connected_icon'));
    }
  }

  Widget _getButtonLabel(ConnectionState state) {
    final String text;
    switch (state) {
      case ConnectionState.idle:
        text = '连接';
      case ConnectionState.connecting:
        text = '连接中...';
      case ConnectionState.connected:
        text = '已连接';
    }

    return Text(
      text,
      key: ValueKey('label_$state'),
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
    );
  }

  Color _getButtonColor(ConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case ConnectionState.idle:
        return colorScheme.primary;
      case ConnectionState.connecting:
        return colorScheme.surfaceVariant;
      case ConnectionState.connected:
        return colorScheme.tertiary;
    }
  }

  Color _getButtonForegroundColor(
    ConnectionState state,
    ColorScheme colorScheme,
  ) {
    switch (state) {
      case ConnectionState.idle:
        return colorScheme.onPrimary;
      case ConnectionState.connecting:
        return colorScheme.onSurfaceVariant;
      case ConnectionState.connected:
        return colorScheme.onTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 14, // 固定高度，包含进度条高度(6px)和底部边距(8px)
            width: 180, // 固定宽度与按钮一致
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset:
                  _state == ConnectionState.connecting
                      ? Offset.zero
                      : const Offset(0, 1.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _state == ConnectionState.connecting ? 1.0 : 0.0,
                child: Container(
                  width: 180,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'progress_${_state == ConnectionState.connecting}',
                    ),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 10), // 10秒完成动画
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      // 更新进度值
                      _progress = value * 100;
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
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: _state != ConnectionState.idle ? 180 : 100,
              height: 60,
              child: FloatingActionButton.extended(
                onPressed:
                    _state == ConnectionState.connecting
                        ? null
                        : _toggleConnection,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 2),
                splashColor:
                    _state != ConnectionState.idle
                        ? colorScheme.onTertiary.withAlpha(51)
                        : colorScheme.onPrimary.withAlpha(51),
                highlightElevation: 6,
                elevation: 2,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: _getButtonIcon(_state),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutQuad,
                  switchOutCurve: Curves.easeInQuad,
                  child: _getButtonLabel(_state),
                ),
                backgroundColor: _getButtonColor(_state, colorScheme),
                foregroundColor: _getButtonForegroundColor(_state, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 整数转为 IP 字符串
String intToIp(int ipInt) {
  return [
    (ipInt >> 24) & 0xFF,
    (ipInt >> 16) & 0xFF,
    (ipInt >> 8) & 0xFF,
    ipInt & 0xFF,
  ].join('.');
}
