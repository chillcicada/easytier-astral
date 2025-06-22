import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/server_mod.dart';
import 'package:flutter/material.dart';

class ServerCard extends StatefulWidget {
  final ServerMod server;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServerCard({
    super.key,
    required this.server,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends State<ServerCard> {
  late final Signal<bool> _hoveredSignal = signal(false);
  late final Computed<int?> _pingSignal = computed(() {
    final pingMap = Aps().pingResults.value;
    final url = widget.server.url;
    return pingMap.containsKey(url) ? pingMap[url] : null;
  });

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _hoveredSignal.value = true,
      onExit: (_) => _hoveredSignal.value = false,
      child: Card(
        elevation: _hoveredSignal.value ? 8.0 : 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _hoveredSignal.value 
                ? colorScheme.primary 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          // 去掉 onTap
          onTap: () => {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 服务器名称和操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        // 新增 Switch 控件
                        Switch(
                          value: server.enable,
                          onChanged: (value) {
                            Aps().setServerEnable(server, value);
                            setState(() {}); // 强制刷新
                          },
                          activeColor: colorScheme.primary,
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: colorScheme.primary),
                          onPressed: widget.onEdit,
                          tooltip: '编辑服务器',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: widget.onDelete,
                          tooltip: '删除服务器',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 服务器地址
                Row(
                  children: [
                    Icon(Icons.link, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    // 显示服务器地址文本
                    Text(
                      server.url,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                // Ping结果显示逻辑
                if (_pingSignal.value == null)
                  const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.grey,
                    size: 16,
                  )
                else if (_pingSignal.value == -1)
                  Text(
                    '无法连接',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _getPingColor(_pingSignal.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _pingSignal.value == null || _pingSignal.value == -1 
                          ? '无法连接' 
                          : '${_pingSignal.value}ms',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // 协议支持
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProtocolChip('TCP', server.tcp, colorScheme),
                    _buildProtocolChip('UDP', server.udp, colorScheme),
                    _buildProtocolChip('WS', server.ws, colorScheme),
                    _buildProtocolChip('WSS', server.wss, colorScheme),
                    _buildProtocolChip('QUIC', server.quic, colorScheme),
                    _buildProtocolChip('WG', server.wg, colorScheme),
                    _buildProtocolChip('TXT', server.txt, colorScheme),
                    _buildProtocolChip('SRV', server.srv, colorScheme),
                    _buildProtocolChip('HTTP', server.http, colorScheme),
                    _buildProtocolChip('HTTPS', server.https, colorScheme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolChip(
    String label,
    bool isEnabled,
    ColorScheme colorScheme,
  ) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color:
              isEnabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      backgroundColor:
          isEnabled ? colorScheme.primary : colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // 修改_getPingColor方法，处理可空int类型
  Color _getPingColor(int? ping) {
    if (ping == null || ping == -1) return Colors.red;
    return ping < 100 
        ? Colors.green 
        : (ping < 300 ? Colors.orange : Colors.red);
  }
}
