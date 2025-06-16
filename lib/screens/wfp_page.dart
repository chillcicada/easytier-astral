import 'package:astral/src/rust/api/nt.dart';
import 'package:astral/src/rust/lib.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/api/astral_wfp.dart';
import 'package:file_picker/file_picker.dart';

class WfpRuleConfig {
  String name;
  String? appPath;
  String? localIp;
  String? localMask; // 新增本地掩码
  String? remoteIp;
  String? remoteMask; // 新增远程掩码
  String? localPort;
  String? remotePort;
  String protocol;
  String direction;
  String action;

  WfpRuleConfig({
    this.name = '',
    this.appPath,
    this.localIp,
    this.localMask,
    this.remoteIp,
    this.remoteMask,
    this.localPort,
    this.remotePort,
    this.protocol = 'tcp',
    this.direction = 'both',
    this.action = 'block',
  });
}

String? ipAndMaskToCidr(String? ip, String? mask) {
  if (ip == null || ip.isEmpty || mask == null || mask.isEmpty) return null;
  try {
    List<String> maskParts = mask.split('.');
    if (maskParts.length != 4) return null;
    int bits =
        maskParts
            .map((e) => int.parse(e).toRadixString(2).padLeft(8, '0'))
            .join()
            .split('1')
            .length -
        1;
    return '$ip/$bits';
  } catch (_) {
    return null;
  }
}

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  WfpController? _wfpController;
  bool _isBusy = false;
  List<WfpRuleConfig> _rules = [WfpRuleConfig(name: '默认规则')];

  Future<void> _startWfpController() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (_wfpController != null) {
        await _wfpController!.cleanup();
        _wfpController = null;
      }
      final controller = await WfpController.newInstance();
      await controller.initialize();
      // Convert rules asynchronously to handle getNtPath
      final filterRules = <FilterRule>[];
      for (final r in _rules) {
        String? ntPath;
        if (r.appPath != null && r.appPath!.isNotEmpty) {
          ntPath = await getNtPath(dosPath: r.appPath!);
        }
        filterRules.add(
          FilterRule(
            name: r.name,
            appPath: ntPath,
            localIp: r.localIp,
            remoteIp: r.remoteIp,
            localIpNetwork: ipAndMaskToCidr(r.localIp, r.localMask),
            remoteIpNetwork: ipAndMaskToCidr(r.remoteIp, r.remoteMask),
            localPort: r.localPort == null ? null : int.tryParse(r.localPort!),
            remotePort:
                r.remotePort == null ? null : int.tryParse(r.remotePort!),
            protocol:
                r.protocol == 'tcp'
                    ? Protocol.tcp
                    : r.protocol == 'udp'
                    ? Protocol.udp
                    : Protocol.icmp,
            direction:
                r.direction == 'inbound'
                    ? Direction.inbound
                    : r.direction == 'outbound'
                    ? Direction.outbound
                    : Direction.both,
            action:
                r.action == 'allow' ? FilterAction.allow : FilterAction.block,
          ),
        );
      }
      await controller.addAdvancedFilters(rules: filterRules);
      await controller.printStatus();
      setState(() => _wfpController = controller);
    } catch (error) {
      print('启动失败: $error');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _cleanupWfpController() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (_wfpController != null) {
        await _wfpController!.cleanup();
        setState(() => _wfpController = null);
      }
    } catch (error) {
      print('清理失败: $error');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Widget _buildRuleCard(int idx) {
    final rule = _rules[idx];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              initialValue: rule.name,
              decoration: const InputDecoration(labelText: '规则名称'),
              onChanged: (v) => setState(() => rule.name = v),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: rule.appPath),
                    readOnly: true,
                    decoration: const InputDecoration(labelText: '应用路径(可选)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe'],
                        );
                    if (result != null && result.files.single.path != null) {
                      setState(() => rule.appPath = result.files.single.path);
                    }
                  },
                  child: const Text('选择'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: rule.localIp,
                    decoration: const InputDecoration(labelText: '本地IP(可选)'),
                    onChanged: (v) => setState(() => rule.localIp = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: rule.localMask,
                    decoration: const InputDecoration(
                      labelText: '本地掩码(可选, 如255.255.255.0)',
                    ),
                    onChanged: (v) => setState(() => rule.localMask = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: rule.remoteIp,
                    decoration: const InputDecoration(labelText: '远程IP(可选)'),
                    onChanged: (v) => setState(() => rule.remoteIp = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: rule.remoteMask,
                    decoration: const InputDecoration(
                      labelText: '远程掩码(可选, 如255.255.255.0)',
                    ),
                    onChanged: (v) => setState(() => rule.remoteMask = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: rule.localPort,
                    decoration: const InputDecoration(labelText: '本地端口(可选)'),
                    onChanged: (v) => setState(() => rule.localPort = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: rule.remotePort,
                    decoration: const InputDecoration(labelText: '远程端口(可选)'),
                    onChanged: (v) => setState(() => rule.remotePort = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: rule.protocol,
                  items: const [
                    DropdownMenuItem(value: 'tcp', child: Text('TCP')),
                    DropdownMenuItem(value: 'udp', child: Text('UDP')),
                    DropdownMenuItem(value: 'icmp', child: Text('ICMP')),
                  ],
                  onChanged: (v) => setState(() => rule.protocol = v!),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: rule.direction,
                  items: const [
                    DropdownMenuItem(value: 'inbound', child: Text('入站')),
                    DropdownMenuItem(value: 'outbound', child: Text('出站')),
                    DropdownMenuItem(value: 'both', child: Text('双向')),
                  ],
                  onChanged: (v) => setState(() => rule.direction = v!),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: rule.action,
                  items: const [
                    DropdownMenuItem(value: 'allow', child: Text('允许')),
                    DropdownMenuItem(value: 'block', child: Text('阻止')),
                  ],
                  onChanged: (v) => setState(() => rule.action = v!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed:
                      _rules.length > 1
                          ? () => setState(() => _rules.removeAt(idx))
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WFP 规则配置')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isBusy ? null : _startWfpController,
                child: const Text('启动过滤器'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isBusy ? null : _cleanupWfpController,
                child: const Text('清理过滤器'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed:
                    _isBusy
                        ? null
                        : () => setState(
                          () => _rules.add(WfpRuleConfig(name: '新规则')),
                        ),
                child: const Text('添加规则'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _rules.length,
              itemBuilder: (ctx, idx) => _buildRuleCard(idx),
            ),
          ),
        ],
      ),
    );
  }
}
