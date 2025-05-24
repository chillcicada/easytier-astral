import 'dart:io';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/wid/home_box.dart';
import 'package:flutter/material.dart';

// 添加模拟数据模型
class NetworkNode {
  final String id;
  final String name;
  final bool isServer;
  final List<NetworkConnection> connections;

  NetworkNode({
    required this.id,
    required this.name,
    this.isServer = false,
    this.connections = const [],
  });
}

class NetworkConnection {
  final String targetId;
  final int latency; // 毫秒

  NetworkConnection({required this.targetId, required this.latency});
}

class VirtualIpBox extends StatelessWidget {
  const VirtualIpBox({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return HomeBox(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.network_check, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                '网络状态',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              // 添加状态指示器
              Container(
                margin: const EdgeInsets.only(right: 4), 
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    Aps().Connec_state.watch(context),
                    colorScheme,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(Aps().Connec_state.watch(context)),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          if (Platform.isWindows) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Icon(Icons.shield, size: 20, color: colorScheme.primary),
                    const Text(
                      '防火墙: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      Aps().firewallStatus.watch(context) ? '已开启' : '已关闭',
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  ],
                ),

                const Spacer(),
                Switch(
                  value: Aps().firewallStatus.watch(
                    context,
                  ), // 需要在Aps中添加firewall_enabled状态
                  onChanged: (bool value) {
                    Aps().setFirewall(value); // 切换防火墙状态
                  },
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ],
          if (Aps().ipv4.watch(context).isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                Icon(Icons.public, size: 20, color: colorScheme.primary),
                const Text(
                  '虚拟IP: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  Aps().ipv4.watch(context),
                  style: TextStyle(color: colorScheme.secondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// 获取状态颜色
Color _getStatusColor(CoState state, ColorScheme colorScheme) {
  switch (state) {
    case CoState.idle:
      return Colors.grey;
    case CoState.connecting:
      return Colors.orange;
    case CoState.connected:
      return Colors.green;
  }
}

// 获取状态文本
String _getStatusText(CoState state) {
  switch (state) {
    case CoState.idle:
      return '未连接';
    case CoState.connecting:
      return '连接中';
    case CoState.connected:
      return '已连接';
  }
}
