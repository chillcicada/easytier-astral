import 'dart:io';

import 'package:astral/utils/reg.dart';
import 'package:astral/utils/route_fun.dart';
import 'package:astral/utils/up.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/src/rust/api/hops.dart';
import 'package:astral/screens/logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _hasInstallPermission = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkInstallPermission();
    }
  }

  Future<void> _checkInstallPermission() async {
    try {
      final status = await Permission.requestInstallPackages.status;
      if (mounted) {
        setState(() {
          _hasInstallPermission = status.isGranted;
        });
      }
    } catch (e) {
      // 权限检查失败，默认为false
      if (mounted) {
        setState(() {
          _hasInstallPermission = false;
        });
      }
    }
  }

  Future<void> _requestInstallPermission() async {
    try {
      final status = await Permission.requestInstallPackages.request();
      if (!context.mounted) return;

      await _checkInstallPermission(); // 重新检查权限状态

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status.isGranted
                ? LocaleKeys.permission_install_success.tr()
                : LocaleKeys.permission_install_failed.tr(),
          ),
        ),
      );

      // 如果权限被永久拒绝，提示用户去设置页面
      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.permission_install_request_failed.tr()),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.permission_denied.tr()),
          content: Text(LocaleKeys.permission_denied_message.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocaleKeys.cancel.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(LocaleKeys.go_settings.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14.0),

      children: [
        if (Platform.isWindows)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠,
              leading: const Icon(Icons.broadcast_on_personal),
              title: Text(LocaleKeys.forwarding_management.tr()),
              children: [
                Builder(
                  builder: (context) {
                    final connections = Aps().connections.watch(context);
                    return Column(
                      children: [
                        ...List.generate(connections.length, (index) {
                          final manager = connections[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ExpansionTile(
                              leading: Switch(
                                value: manager.enabled,
                                onChanged: (value) async {
                                  await Aps().updateConnectionEnabled(
                                    index,
                                    value,
                                  );
                                },
                              ),
                              title: Text(
                                manager.name.isEmpty
                                    ? LocaleKeys.unnamed_group.tr()
                                    : manager.name,
                              ),
                              subtitle: Text(
                                '${manager.connections.length} ${LocaleKeys.connections_count.tr()}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: LocaleKeys.edit.tr(),
                                    onPressed:
                                        () => editConnectionManager(
                                          context,
                                          index,
                                          manager,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    tooltip: LocaleKeys.delete.tr(),
                                    onPressed:
                                        () => deleteConnectionManager(
                                          context,
                                          index,
                                          manager.name,
                                        ),
                                  ),
                                ],
                              ),
                              children: [
                                ...manager.connections.map(
                                  (conn) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.link, size: 16),
                                    title: Text(
                                      '${conn.bindAddr} → ${conn.dstAddr}',
                                    ),
                                    subtitle: Text(
                                      '${LocaleKeys.protocol.tr()}: ${conn.proto}',
                                    ),
                                  ),
                                ),
                                if (manager.connections.isEmpty)
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      LocaleKeys.no_connection_config.tr(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(LocaleKeys.add_forwarding_group.tr()),
                          onTap: () => addConnectionManager(context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        if (Platform.isWindows)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠
              leading: const Icon(Icons.network_check),
              title: Text(LocaleKeys.network_adapter_hop_settings.tr()),
              children: [
                SwitchListTile(
                  title: Text(LocaleKeys.auto_set_hop.tr()),
                  subtitle: Text(LocaleKeys.auto_set_hop_desc.tr()),
                  value: Aps().autoSetMTU.watch(context),
                  onChanged: (value) {
                    Aps().setAutoSetMTU(value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: Text(LocaleKeys.view_hop_list.tr()),
                  onTap: () async {
                    try {
                      final result = await getAllInterfacesMetrics();
                      if (!context.mounted) return;

                      await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                LocaleKeys.network_adapter_hop_list.tr(),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      result
                                          .map((e) => Text('${e.$1}: ${e.$2}'))
                                          .toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(LocaleKeys.close.tr()),
                                ),
                              ],
                            ),
                      );
                    } catch (e, s) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocaleKeys.get_hop_list_failed.tr()),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

        if (!Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false, // 默认折叠
              leading: const Icon(Icons.launch),
              title: Text(LocaleKeys.startup_related.tr()),
              children: [
                SwitchListTile(
                  title: Text(LocaleKeys.startup_on_boot.tr()),
                  subtitle: Text(LocaleKeys.startup_on_boot_desc.tr()),
                  value: Aps().startup.watch(context),
                  onChanged: (value) {
                    Aps().setStartup(value);
                    handleStartupSetting(value);
                  },
                ),
                SwitchListTile(
                  title: Text(LocaleKeys.startup_minimize.tr()),
                  subtitle: Text(LocaleKeys.startup_minimize_desc.tr()),
                  value: Aps().startupMinimize.watch(context),
                  onChanged: (value) {
                    Aps().setStartupMinimize(value);
                  },
                ),
                SwitchListTile(
                  title: Text(LocaleKeys.startup_auto_connect.tr()),
                  subtitle: Text(LocaleKeys.startup_auto_connect_desc.tr()),
                  value: Aps().startupAutoConnect.watch(context),
                  onChanged: (value) {
                    Aps().setStartupAutoConnect(value);
                  },
                ),
              ],
            ),
          ),

        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠
            leading: const Icon(Icons.list_alt),
            title: Text(LocaleKeys.listen_list.tr()),
            children: [
              Builder(
                builder: (context) {
                  final listenList = Aps().listenList.watch(context);
                  return Column(
                    children: [
                      ...List.generate(listenList.length, (index) {
                        final item = listenList[index];
                        return ListTile(
                          title: Text(item),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: LocaleKeys.edit.tr(),
                                onPressed: () async {
                                  final controller = TextEditingController(
                                    text: item,
                                  );
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            LocaleKeys.edit_listen_item.tr(),
                                          ),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              labelText:
                                                  LocaleKeys.listen_item.tr(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: Text(
                                                LocaleKeys.cancel.tr(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    controller.text,
                                                  ),
                                              child: Text(LocaleKeys.save.tr()),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (result != null &&
                                      result.trim().isNotEmpty &&
                                      result != item) {
                                    await Aps().updateListen(
                                      index,
                                      result.trim(),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                tooltip: LocaleKeys.delete.tr(),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            LocaleKeys.confirm_delete.tr(),
                                          ),
                                          content: Text(
                                            LocaleKeys
                                                .confirm_delete_listen_item
                                                .tr(namedArgs: {'item': item}),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text(
                                                LocaleKeys.cancel.tr(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Text(
                                                LocaleKeys.delete.tr(),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    await Aps().deleteListen(index);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: Text(LocaleKeys.add_listen_item.tr()),
                        onTap: () async {
                          final controller = TextEditingController();
                          final result = await showDialog<String>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('新增监听项'),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: LocaleKeys.listen_item.tr(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(LocaleKeys.cancel.tr()),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(
                                            context,
                                            controller.text,
                                          ),
                                      child: Text(LocaleKeys.add.tr()),
                                    ),
                                  ],
                                ),
                          );
                          if (result != null && result.trim().isNotEmpty) {
                            await Aps().addListen(result.trim());
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        if (!Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              leading: const Icon(Icons.route),
              title: Text(LocaleKeys.subnet_proxy_cidr.tr()),
              children: [
                Builder(
                  builder: (context) {
                    final cidrList = Aps().cidrproxy.watch(context);
                    return Column(
                      children: [
                        ...List.generate(cidrList.length, (index) {
                          final cidr = cidrList[index];
                          return ListTile(
                            title: Text(cidr),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final controller = TextEditingController(
                                      text: cidr,
                                    );
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              LocaleKeys.edit_cidr.tr(),
                                            ),
                                            content: TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                labelText:
                                                    LocaleKeys
                                                        .cidr_format_example
                                                        .tr(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  LocaleKeys.cancel.tr(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      controller.text,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.save.tr(),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      await Aps().updateCidrproxy(
                                        index,
                                        result,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              LocaleKeys.confirm_delete.tr(),
                                            ),
                                            content: Text(
                                              LocaleKeys.confirm_delete_cidr.tr(
                                                namedArgs: {'cidr': cidr},
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.cancel.tr(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.delete.tr(),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await Aps().deleteCidrproxy(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(LocaleKeys.add_cidr_proxy.tr()),
                          onTap: () async {
                            final controller = TextEditingController();
                            final result = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(LocaleKeys.add_cidr_proxy.tr()),
                                    content: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        labelText:
                                            LocaleKeys.cidr_format_example.tr(),
                                        hintText:
                                            LocaleKeys.cidr_input_hint.tr(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(LocaleKeys.cancel.tr()),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              context,
                                              controller.text,
                                            ),
                                        child: Text(LocaleKeys.add.tr()),
                                      ),
                                    ],
                                  ),
                            );
                            if (result != null && result.isNotEmpty) {
                              await Aps().addCidrproxy(result);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        if (Platform.isAndroid)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              initiallyExpanded: false,
              leading: const Icon(Icons.vpn_lock),
              title: Text(LocaleKeys.custom_vpn_segment.tr()),
              children: [
                Builder(
                  builder: (context) {
                    final vpnList = Aps().customVpn.watch(context);
                    return Column(
                      children: [
                        ...List.generate(vpnList.length, (index) {
                          final vpn = vpnList[index];
                          return ListTile(
                            title: Text(vpn),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () async {
                                    final controller = TextEditingController(
                                      text: vpn,
                                    );
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              LocaleKeys.edit_vpn_segment.tr(),
                                            ),
                                            content: TextField(
                                              controller: controller,
                                              decoration: InputDecoration(
                                                labelText:
                                                    LocaleKeys
                                                        .vpn_segment_format_example
                                                        .tr(),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  LocaleKeys.cancel.tr(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      controller.text,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.save.tr(),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      await Aps().updateCustomVpn(
                                        index,
                                        result,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              LocaleKeys.confirm_delete.tr(),
                                            ),
                                            content: Text(
                                              LocaleKeys
                                                  .confirm_delete_vpn_segment
                                                  .tr(namedArgs: {'vpn': vpn}),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.cancel.tr(),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  LocaleKeys.delete.tr(),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      await Aps().deleteCustomVpn(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(LocaleKeys.add_vpn_segment.tr()),
                          onTap: () async {
                            final controller = TextEditingController();
                            final result = await showDialog<String>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(
                                      LocaleKeys.add_vpn_segment.tr(),
                                    ),
                                    content: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        labelText:
                                            LocaleKeys
                                                .vpn_segment_format_example
                                                .tr(),
                                        hintText:
                                            LocaleKeys.vpn_segment_input_hint
                                                .tr(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(LocaleKeys.cancel.tr()),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(
                                              context,
                                              controller.text,
                                            ),
                                        child: Text(LocaleKeys.add.tr()),
                                      ),
                                    ],
                                  ),
                            );
                            if (result != null && result.isNotEmpty) {
                              await Aps().addCustomVpn(result);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠
            leading: const Icon(Icons.network_wifi),
            title: Text(LocaleKeys.network_settings.tr()),
            children: [
              // 压缩算法下拉单选
              ListTile(
                title: Text(LocaleKeys.p2p_hole_punching.tr()),
                subtitle: Text(LocaleKeys.preferred_protocol.tr()),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: DropdownButton<String>(
                        value:
                            Aps().defaultProtocol.watch(context).isEmpty
                                ? 'tcp'
                                : Aps().defaultProtocol.watch(context),
                        items: const [
                          DropdownMenuItem(
                            value: 'tcp',
                            child: Text('TCP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'udp',
                            child: Text('UDP', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'ws',
                            child: Text(
                              'WebSocket',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'wss',
                            child: Text('WSS', style: TextStyle(fontSize: 14)),
                          ),
                          DropdownMenuItem(
                            value: 'quic',
                            child: Text('QUIC', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDefaultProtocol(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SwitchListTile(
                title: Text(LocaleKeys.enable_encryption.tr()),
                subtitle: Text(LocaleKeys.auto_set_mtu.tr()),
                value: Aps().enableEncryption.watch(context),
                onChanged: (value) {
                  Aps().updateEnableEncryption(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.latency_first.tr()),
                subtitle: Text(LocaleKeys.latency_first_desc.tr()),
                value: Aps().latencyFirst.watch(context),
                onChanged: (value) {
                  Aps().updateLatencyFirst(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.magic_dns.tr()),
                subtitle: Text(LocaleKeys.magic_dns_desc.tr()),
                value: Aps().accept_dns.watch(context),
                onChanged: (value) {
                  Aps().updateAcceptDns(value);
                },
              ),
              SwitchListTile(
                title: Text(LocaleKeys.tun_device.tr()),
                subtitle: Text(LocaleKeys.tun_device_desc.tr()),
                value: Aps().noTun.watch(context),
                onChanged: (value) {
                  Aps().updateNoTun(value);
                },
              ),

              SwitchListTile(
                title: Row(
                  children: [
                    Text(LocaleKeys.smoltcp_stack.tr()),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        LocaleKeys.not_recommended.tr(),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(LocaleKeys.smoltcp_stack_desc.tr()),
                value: Aps().useSmoltcp.watch(context),
                onChanged: (value) {
                  Aps().updateUseSmoltcp(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.disable_p2p.tr()),
                subtitle: Text(LocaleKeys.disable_p2p_desc.tr()),
                value: Aps().disableP2p.watch(context),
                onChanged: (value) {
                  Aps().updateDisableP2p(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.relay_peer_rpc.tr()),
                subtitle: Text(LocaleKeys.relay_peer_rpc_desc.tr()),
                value: Aps().relayAllPeerRpc.watch(context),
                onChanged: (value) {
                  Aps().updateRelayAllPeerRpc(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.disable_udp_hole_punching.tr()),
                subtitle: Text(LocaleKeys.disable_udp_hole_punching_desc.tr()),
                value: Aps().disableUdpHolePunching.watch(context),
                onChanged: (value) {
                  Aps().updateDisableUdpHolePunching(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.enable_multi_thread.tr()),
                subtitle: Text(LocaleKeys.enable_multi_thread_desc.tr()),
                value: Aps().multiThread.watch(context),
                onChanged: (value) {
                  Aps().updateMultiThread(value);
                },
              ),

              // 压缩算法下拉单选
              ListTile(
                title: Text(LocaleKeys.compression_algorithm.tr()),
                subtitle: Text(LocaleKeys.compression_algorithm_desc.tr()),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        focusColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: DropdownButton<int>(
                        value: Aps().dataCompressAlgo.watch(context),
                        items: [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              LocaleKeys.no_compression.tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text(
                              LocaleKeys.high_performance_compression.tr(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        onChanged: (value) {
                          if (value != null) {
                            Aps().updateDataCompressAlgo(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              SwitchListTile(
                title: Text(LocaleKeys.bind_device.tr()),
                subtitle: Text(LocaleKeys.bind_device_desc.tr()),
                value: Aps().bindDevice.watch(context),
                onChanged: (value) {
                  Aps().updateBindDevice(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.enable_kcp_proxy.tr()),
                subtitle: Text(LocaleKeys.enable_kcp_proxy_desc.tr()),
                value: Aps().enableKcpProxy.watch(context),
                onChanged: (value) {
                  Aps().updateEnableKcpProxy(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.kcp_input.tr()),
                subtitle: Text(LocaleKeys.kcp_input_desc.tr()),
                value: Aps().disableKcpInput.watch(context),
                onChanged: (value) {
                  Aps().updateDisableKcpInput(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.disable_relay_kcp.tr()),
                subtitle: Text(LocaleKeys.disable_relay_kcp_desc.tr()),
                value: Aps().disableRelayKcp.watch(context),
                onChanged: (value) {
                  Aps().updateDisableRelayKcp(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.private_mode.tr()),
                subtitle: Text(LocaleKeys.private_mode_desc.tr()),
                value: Aps().privateMode.watch(context),
                onChanged: (value) {
                  Aps().updatePrivateMode(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.enable_quic_proxy.tr()),
                subtitle: Text(LocaleKeys.enable_quic_proxy_desc.tr()),
                value: Aps().enableQuicProxy.watch(context),
                onChanged: (value) {
                  Aps().updateEnableQuicProxy(value);
                },
              ),

              SwitchListTile(
                title: Text(LocaleKeys.disable_quic_input.tr()),
                subtitle: Text(LocaleKeys.disable_quic_input_desc.tr()),
                value: Aps().disableQuicInput.watch(context),
                onChanged: (value) {
                  Aps().updateDisableQuicInput(value);
                },
              ),
            ],
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠,
            leading: const Icon(Icons.info),
            title: Text(LocaleKeys.software_settings.tr()),
            children: [
              // if (Platform.isAndroid)
              //   ListTile(
              //     leading: const Icon(Icons.admin_panel_settings),
              //     title: const Text('申请Root权限'),
              //     subtitle: const Text('获取Root权限则无需创建VPN'),
              //     onTap: () async {
              //       try {
              //         final result = await const MethodChannel('astral_channel').invokeMethod('requestRoot');
              //         if (!context.mounted) return;

              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(content: Text(result ? 'Root权限获取成功' : 'Root权限获取失败')),
              //         );
              //       } catch (e) {
              //         if (!context.mounted) return;
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(content: Text('请求Root权限失败')),
              //         );
              //       }
              //     },
              //   ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.install_mobile),
                  title: Text(LocaleKeys.get_install_permission.tr()),
                  subtitle: Text(
                    _hasInstallPermission
                        ? LocaleKeys.install_permission_granted.tr()
                        : LocaleKeys.install_permission_not_granted.tr(),
                  ),
                  trailing:
                      _hasInstallPermission
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.warning, color: Colors.orange),
                  onTap:
                      _hasInstallPermission ? null : _requestInstallPermission,
                ),
              if (!Platform.isAndroid)
                SwitchListTile(
                  title: Text(LocaleKeys.minimize.tr()),
                  subtitle: Text(LocaleKeys.minimize_desc.tr()),
                  value: Aps().closeMinimize.watch(context),
                  onChanged: (value) {
                    Aps().updateCloseMinimize(value);
                  },
                ),
              SwitchListTile(
                title: Text(LocaleKeys.player_list_card.tr()),
                subtitle: Text(LocaleKeys.player_list_card_desc.tr()),
                value: Aps().userListSimple.watch(context),
                onChanged: (value) {
                  Aps().setUserListSimple(value);
                },
              ),
            ],
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            initiallyExpanded: false, // 默认折叠,
            leading: const Icon(Icons.system_update),
            title: Text(LocaleKeys.update_settings.tr()),
            children: [
              SwitchListTile(
                title: Text(LocaleKeys.join_beta.tr()),
                subtitle: Text(LocaleKeys.join_beta_desc.tr()),
                value: Aps().beta.watch(context),
                onChanged: (value) {
                  Aps().setBeta(value);
                },
              ),
              if (!Aps().beta.watch(context))
                SwitchListTile(
                  title: Text(LocaleKeys.auto_update.tr()),
                  subtitle: Text(LocaleKeys.auto_update_desc.tr()),
                  value: Aps().autoCheckUpdate.watch(context),
                  onChanged: (value) {
                    Aps().setAutoCheckUpdate(value);
                  },
                ),
              ListTile(
                title: Text(LocaleKeys.download_acceleration.tr()),
                subtitle: TextFormField(
                  decoration: InputDecoration(
                    hintText: LocaleKeys.download_acceleration_hint.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  initialValue: Aps().downloadAccelerate.watch(context),
                  onChanged: (value) {
                    Aps().setDownloadAccelerate(value);
                  },
                ),
              ),
            ],
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(LocaleKeys.about.tr()),
              ),
              ListTile(
                leading: Hero(
                  tag: "logs_hero",
                  child: const Icon(Icons.article),
                ),
                title: Text(LocaleKeys.view_logs.tr()),
                subtitle: Text(LocaleKeys.view_logs_desc.tr()),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              const LogsPage(),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text(LocaleKeys.official_qq_group.tr()),
                subtitle: Text(LocaleKeys.click_copy_group_number.tr()),
                onTap: () async {
                  const qqGroup = '808169040'; // 替换为实际QQ群号
                  await Clipboard.setData(const ClipboardData(text: qqGroup));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.group_number_copied.tr()),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: Text(LocaleKeys.user_feedback.tr()),
                onTap: _sendFeedback,
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: Text(LocaleKeys.check_update.tr()),
                onTap: () {
                  final updateChecker = UpdateChecker(
                    owner: 'ldoubil',
                    repo: 'astral',
                  );
                  if (mounted) {
                    updateChecker.checkForUpdates(context);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendFeedback() async {
    final feedbackController = TextEditingController();
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    final feedback = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LocaleKeys.user_feedback.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.name.tr(),
                    hintText: LocaleKeys.name_hint.tr(),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.email.tr(),
                    hintText: LocaleKeys.email_hint.tr(),
                  ),
                ),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.feedback_content.tr(),
                    hintText: LocaleKeys.feedback_content_hint.tr(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, {
                      'name': nameController.text,
                      'email': emailController.text,
                      'feedback': feedbackController.text,
                    }),
                child: Text(LocaleKeys.submit.tr()),
              ),
            ],
          ),
    );

    if (feedback != null &&
        feedback['feedback']?.trim().isNotEmpty == true &&
        feedback['email']?.trim().isNotEmpty == true &&
        feedback['name']?.trim().isNotEmpty == true) {}
  }
}
