import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/wfp_model.dart';
import 'package:flutter/material.dart';

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('WFP 规则管理')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder<List<WfpModel>>(
          valueListenable: Aps().wfpModels as ValueNotifier<List<WfpModel>>,
          builder: (context, rules, _) {
            return Column(
              children: [
                Expanded(
                  child:
                      rules.isEmpty
                          ? Center(child: Text('暂无规则'))
                          : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 900
                                          ? 3
                                          : 1,
                                  childAspectRatio: 2.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: rules.length,
                            itemBuilder: (context, index) {
                              final rule = rules[index];
                              return _WfpRuleCard(
                                rule: rule,
                                onEdit: () => _showEditDialog(context, rule),
                                onDelete: () async {
                                  await Aps().deleteWfpModel(rule.id);
                                  setState(() {});
                                },
                              );
                            },
                          ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('添加规则'),
                    onPressed: () => _showEditDialog(context, null),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WfpModel? rule) {
    final isEdit = rule != null;
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: rule?.name ?? '');
    final appPathController = TextEditingController(text: rule?.appPath ?? '');
    final localController = TextEditingController(text: rule?.local ?? '');
    final remoteController = TextEditingController(text: rule?.remote ?? '');
    final localPortController = TextEditingController(
      text: rule?.localPort?.toString() ?? '',
    );
    final remotePortController = TextEditingController(
      text: rule?.remotePort?.toString() ?? '',
    );
    final localPortRangeController = TextEditingController(
      text: rule?.localPortRange?.join(',') ?? '',
    );
    final remotePortRangeController = TextEditingController(
      text: rule?.remotePortRange?.join(',') ?? '',
    );
    final protocolController = TextEditingController(
      text: rule?.protocol ?? '',
    );
    final directionController = TextEditingController(
      text: rule?.direction ?? 'both',
    );
    final actionController = TextEditingController(
      text: rule?.action ?? 'block',
    );
    final priorityController = TextEditingController(
      text: rule?.priority?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: rule?.description ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? '编辑规则' : '添加规则'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '规则名称'),
                    validator: (v) => v == null || v.isEmpty ? '请输入规则名称' : null,
                  ),
                  TextFormField(
                    controller: appPathController,
                    decoration: const InputDecoration(labelText: '应用程序路径'),
                  ),
                  TextFormField(
                    controller: localController,
                    decoration: const InputDecoration(labelText: '本地地址'),
                  ),
                  TextFormField(
                    controller: remoteController,
                    decoration: const InputDecoration(labelText: '远程地址'),
                  ),
                  TextFormField(
                    controller: localPortController,
                    decoration: const InputDecoration(labelText: '本地端口'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: remotePortController,
                    decoration: const InputDecoration(labelText: '远程端口'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: localPortRangeController,
                    decoration: const InputDecoration(
                      labelText: '本地端口范围(逗号分隔)',
                    ),
                  ),
                  TextFormField(
                    controller: remotePortRangeController,
                    decoration: const InputDecoration(
                      labelText: '远程端口范围(逗号分隔)',
                    ),
                  ),
                  TextFormField(
                    controller: protocolController,
                    decoration: const InputDecoration(labelText: '协议类型'),
                  ),
                  TextFormField(
                    controller: directionController,
                    decoration: const InputDecoration(
                      labelText: '方向 (inbound/outbound/both)',
                    ),
                    validator: (v) => v == null || v.isEmpty ? '请输入方向' : null,
                  ),
                  TextFormField(
                    controller: actionController,
                    decoration: const InputDecoration(
                      labelText: '动作 (allow/block)',
                    ),
                    validator: (v) => v == null || v.isEmpty ? '请输入动作' : null,
                  ),
                  TextFormField(
                    controller: priorityController,
                    decoration: const InputDecoration(labelText: '优先级'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: '描述'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final model =
                      WfpModel()
                        ..name = nameController.text
                        ..appPath =
                            appPathController.text.isEmpty
                                ? null
                                : appPathController.text
                        ..local =
                            localController.text.isEmpty
                                ? null
                                : localController.text
                        ..remote =
                            remoteController.text.isEmpty
                                ? null
                                : remoteController.text
                        ..localPort =
                            localPortController.text.isEmpty
                                ? null
                                : int.tryParse(localPortController.text)
                        ..remotePort =
                            remotePortController.text.isEmpty
                                ? null
                                : int.tryParse(remotePortController.text)
                        ..localPortRange =
                            localPortRangeController.text.isEmpty
                                ? null
                                : localPortRangeController.text
                                    .split(',')
                                    .map((e) => int.tryParse(e.trim()))
                                    .whereType<int>()
                                    .toList()
                        ..remotePortRange =
                            remotePortRangeController.text.isEmpty
                                ? null
                                : remotePortRangeController.text
                                    .split(',')
                                    .map((e) => int.tryParse(e.trim()))
                                    .whereType<int>()
                                    .toList()
                        ..protocol =
                            protocolController.text.isEmpty
                                ? null
                                : protocolController.text
                        ..direction = directionController.text
                        ..action = actionController.text
                        ..priority =
                            priorityController.text.isEmpty
                                ? null
                                : int.tryParse(priorityController.text)
                        ..description =
                            descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text;
                  if (isEdit) {
                    model.id = rule!.id;
                    await Aps().updateWfpModel(model);
                  } else {
                    await Aps().addWfpModel(model);
                  }
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

class _WfpRuleCard extends StatelessWidget {
  final WfpModel rule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _WfpRuleCard({required this.rule, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '方向: ${rule.direction}   动作: ${rule.action}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                if (rule.description != null && rule.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '描述: ${rule.description}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.primary),
                    onPressed: onEdit,
                    tooltip: '编辑规则',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: '删除规则',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
