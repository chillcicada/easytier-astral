import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/wfp_model.dart';
import 'package:astral/src/rust/api/nt.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:astral/src/rust/api/astral_wfp.dart';
import 'package:isar/isar.dart';
import 'dart:io';
import 'wfp_components.dart';

class WfpPage extends StatefulWidget {
  const WfpPage({super.key});

  @override
  State<WfpPage> createState() => _WfpPageState();
}

class _WfpPageState extends State<WfpPage> {
  WfpController? _wfpController;
  // 移除局部状态，使用 Aps().wfpStatus
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startWfp() async {
    try {
      setState(() {
        _isInitializing = true;
      });

      // 每次启动时初始化新的引擎
      _wfpController = await WfpController.newInstance();
      await _wfpController!.initialize();

      // 获取所有启用的规则并转换为FilterRule
      final allRules = Aps().wfpModels.value;
      final enabledRules = allRules.where((rule) => rule.enabled).toList();

      final filterRules = <FilterRule>[];

      for (int i = 0; i < enabledRules.length; i++) {
        final rule = enabledRules[i];

        // 跳过未启用的规则
        if (!rule.enabled) {
          continue;
        }

        // 处理应用程序路径转换
        String? ntPath;
        if (rule.appPath != null && rule.appPath!.isNotEmpty) {
          try {
            ntPath = await getNtPath(dosPath: rule.appPath!);
          } catch (e) {
            ntPath = rule.appPath; // 使用原始路径作为备选
          }
        }

        // 解析本地规则（支持多行）
        final localRules =
            rule.localRule != null && rule.localRule!.isNotEmpty
                ? _parseRules(rule.localRule!)
                : [<String, dynamic>{}];

        // 解析远程规则（支持多行）
        final remoteRules =
            rule.remoteRule != null && rule.remoteRule!.isNotEmpty
                ? _parseRules(rule.remoteRule!)
                : [<String, dynamic>{}];

        // 为每个本地规则和远程规则的组合创建FilterRule
        for (int localIndex = 0; localIndex < localRules.length; localIndex++) {
          for (
            int remoteIndex = 0;
            remoteIndex < remoteRules.length;
            remoteIndex++
          ) {
            final localParts = localRules[localIndex];
            final remoteParts = remoteRules[remoteIndex];

            // 如果本地和远程规则都为空，但有应用程序路径，仍然创建规则
            // 如果本地和远程规则都为空且没有应用程序路径，则跳过
            if (localParts.isEmpty && remoteParts.isEmpty && ntPath == null) {
              continue;
            }

            final localAddress = localParts['address'] as String?;
            final localPort = localParts['port'] as int?;
            final localPortRange = localParts['portRange'] as (int, int)?;

            final remoteAddress = remoteParts['address'] as String?;
            final remotePort = remoteParts['port'] as int?;
            final remotePortRange = remoteParts['portRange'] as (int, int)?;

            // 生成规则名称，如果有多个规则则添加序号
            String ruleName = rule.name;
            final totalCombinations = localRules.length * remoteRules.length;
            if (totalCombinations > 1) {
              final combinationIndex =
                  localIndex * remoteRules.length + remoteIndex + 1;
              ruleName = '${rule.name} #$combinationIndex';
            }

            final filterRule = await FilterRule.newWithParams(
              name: ruleName,
              appPath: ntPath,
              local: localAddress,
              remote: remoteAddress,
              localPort: localPort,
              remotePort: remotePort,
              localPortRange: localPortRange,
              remotePortRange: remotePortRange,
              protocol: _parseProtocol(rule.protocol),
              direction: _parseDirection(rule.direction),
              action: _parseAction(rule.action),
              priority: rule.priority,
              description: null,
            );

            await filterRule.validate();
            filterRules.add(filterRule);
          }
        }
      }

      // 添加所有过滤器
      await _wfpController!.addFilters(rules: filterRules);

      setState(() {
        _isInitializing = false;
      });
      // 更新防火墙状态
      Aps().wfpStatus.value = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WFP已启动，规则已应用'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动WFP失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopWfp() async {
    if (_wfpController == null) {
      return;
    }

    try {
      setState(() {
        _isInitializing = true;
      });

      // 清理所有过滤器
      await _wfpController!.cleanup();

      // 清理引擎引用
      _wfpController = null;

      setState(() {
        _isInitializing = false;
      });
      // 更新防火墙状态
      Aps().wfpStatus.value = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WFP已停止'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止WFP失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 解析规则字符串，支持以下格式：
  /// - "192.168.1.1:80" -> {address: "192.168.1.1", port: 80}
  /// - "192.168.1.1:8000-9000" -> {address: "192.168.1.1", portRange: (8000, 9000)}
  /// - "192.168.1.1" -> {address: "192.168.1.1"}
  /// - ":80" -> {port: 80}
  /// - ":8000-9000" -> {portRange: (8000, 9000)}
  /// 支持多行规则，每行一个规则
  List<Map<String, dynamic>> _parseRules(String rules) {
    final result = <Map<String, dynamic>>[];

    // 按行分割规则
    final lines = rules.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue; // 跳过空行

      final ruleData = _parseSingleRule(trimmedLine);
      if (ruleData.isNotEmpty) {
        result.add(ruleData);
      }
    }

    return result;
  }

  /// 解析单行规则
  Map<String, dynamic> _parseSingleRule(String rule) {
    final result = <String, dynamic>{};

    if (rule.contains(':')) {
      final parts = rule.split(':');
      final addressPart = parts[0];
      final portPart = parts[1];

      // 处理地址部分
      if (addressPart.isNotEmpty) {
        result['address'] = addressPart;
      }

      // 处理端口部分
      if (portPart.isNotEmpty) {
        if (portPart.contains('-')) {
          // 端口范围
          final rangeParts = portPart.split('-');
          if (rangeParts.length == 2) {
            final startPort = int.tryParse(rangeParts[0]);
            final endPort = int.tryParse(rangeParts[1]);
            if (startPort != null && endPort != null) {
              result['portRange'] = (startPort, endPort);
            }
          }
        } else {
          // 单个端口
          final port = int.tryParse(portPart);
          if (port != null) {
            result['port'] = port;
          }
        }
      }
    } else {
      // 只有地址，没有端口
      if (rule.isNotEmpty) {
        result['address'] = rule;
      }
    }

    return result;
  }

  /// 兼容性方法，保持向后兼容
  Map<String, dynamic> _parseRule(String rule) {
    final rules = _parseRules(rule);
    return rules.isNotEmpty ? rules.first : <String, dynamic>{};
  }

  Protocol _parseProtocol(String protocol) {
    return switch (protocol.toLowerCase()) {
      'tcp' => Protocol.tcp,
      'udp' => Protocol.udp,
      _ => Protocol.tcp,
    };
  }

  Direction _parseDirection(String direction) {
    return switch (direction.toLowerCase()) {
      'inbound' => Direction.inbound,
      'outbound' => Direction.outbound,
      'both' => Direction.both,
      _ => Direction.both,
    };
  }

  FilterAction _parseAction(String action) {
    return switch (action.toLowerCase()) {
      'allow' => FilterAction.allow,
      'block' => FilterAction.block,
      _ => FilterAction.block,
    };
  }

  // 批量切换规则状态
  Future<void> _toggleAllRules(bool enabled) async {
    final rules = Aps().wfpModels.value;
    for (final rule in rules) {
      if (rule.enabled != enabled) {
        final updatedRule =
            WfpModel()
              ..id = rule.id
              ..name = rule.name
              ..appPath = rule.appPath
              ..localRule = rule.localRule
              ..remoteRule = rule.remoteRule
              ..protocol = rule.protocol
              ..direction = rule.direction
              ..action = rule.action
              ..priority = rule.priority
              ..enabled = enabled;
        await Aps().updateWfpModel(updatedRule);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? '已启用所有规则' : '已禁用所有规则'),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // 切换单个规则状态
  Future<void> _toggleRule(WfpModel rule) async {
    final updatedRule =
        WfpModel()
          ..id = rule.id
          ..name = rule.name
          ..appPath = rule.appPath
          ..localRule = rule.localRule
          ..remoteRule = rule.remoteRule
          ..protocol = rule.protocol
          ..direction = rule.direction
          ..action = rule.action
          ..priority = rule.priority
          ..enabled = !rule.enabled;

    await Aps().updateWfpModel(updatedRule);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedRule.enabled ? '规则已启用' : '规则已禁用'),
          backgroundColor: updatedRule.enabled ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    // 页面销毁时清理WFP引擎
    if (_wfpController != null) {
      _wfpController!.cleanup();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WFP状态控制和规则统计区域 - 合并版
            ValueListenableBuilder<bool>(
              valueListenable: Aps().wfpStatus as ValueNotifier<bool>,
              builder: (context, isRunning, _) {
                return ValueListenableBuilder<List<WfpModel>>(
                  valueListenable:
                      Aps().wfpModels as ValueNotifier<List<WfpModel>>,
                  builder: (context, rules, _) {
                    final enabledRules = rules.where((r) => r.enabled).length;
                    final disabledRules = rules.where((r) => !r.enabled).length;

                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // 第一行：WFP状态和开关
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isRunning
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isRunning
                                        ? Icons.security
                                        : Icons.security_outlined,
                                    color:
                                        isRunning ? Colors.green : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '魔法墙',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
                                            ),
                                            child: Text(
                                              '共 ${rules.length} 条规则',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    colorScheme.onPrimaryContainer,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isRunning ? '正在运行，规则已生效' : '已停止，规则未生效',
                                        style: TextStyle(
                                          color:
                                              isRunning
                                                  ? Colors.green
                                                  : Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isInitializing)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isRunning ? '已启用' : '已禁用',
                                      style: TextStyle(
                                        color:
                                            isRunning
                                                ? Colors.green
                                                : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: isRunning,
                                      onChanged:
                                          _isInitializing
                                              ? null
                                              : (value) {
                                                if (value) {
                                                  _startWfp();
                                                } else {
                                                  _stopWfp();
                                                }
                                              },
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // 规则列表区域
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: Aps().wfpStatus as ValueNotifier<bool>,
                builder: (context, isWfpRunning, _) {
                  return ValueListenableBuilder<List<WfpModel>>(
                    valueListenable:
                        Aps().wfpModels as ValueNotifier<List<WfpModel>>,
                    builder: (context, rules, _) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          // 规则列表
                          Expanded(
                            child:
                                rules.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.security_outlined,
                                            size: 64,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '暂无防火墙规则',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '点击下方按钮添加第一条规则',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : _WfpRulesTable(
                                      rules: rules,
                                      isWfpRunning: isWfpRunning,
                                      onEditRule: showEditDialog,
                                      onDeleteRule: showDeleteConfirmDialog,
                                      onToggleRule: _toggleRule,
                                    ),
                          ),

                          // 添加规则按钮
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('添加新规则'),
                              onPressed:
                                  isWfpRunning
                                      ? null
                                      : () => showEditDialog(context, null),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 大表格布局组件
class _WfpRulesTable extends StatelessWidget {
  final List<WfpModel> rules;
  final bool isWfpRunning;
  final Function(BuildContext, WfpModel?) onEditRule;
  final Function(BuildContext, WfpModel) onDeleteRule;
  final Function(WfpModel) onToggleRule;

  const _WfpRulesTable({
    required this.rules,
    required this.isWfpRunning,
    required this.onEditRule,
    required this.onDeleteRule,
    required this.onToggleRule,
  });

  String _getRuleDisplay(String? rule) {
    if (rule == null || rule.isEmpty) {
      return '-';
    }
    return rule;
  }

  String _getAppPathDisplay(String? appPath) {
    if (appPath == null || appPath.isEmpty) {
      return '所有程序';
    }
    // 只显示文件名，不显示完整路径
    final fileName = appPath.split(Platform.pathSeparator).last;
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (rules.isEmpty) {
      return const Center(child: Text('暂无规则'));
    }
    return ListView.builder(
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // 主体内容
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 启用状态开关
                        Switch(
                          value: rule.enabled ?? false,
                          onChanged:
                              isWfpRunning
                                  ? null
                                  : (value) => onToggleRule(rule),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rule.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: rule.enabled ? null : Colors.grey,
                            ),
                          ),
                        ),
                        // 操作按钮
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          enabled: !isWfpRunning,
                          tooltip: isWfpRunning ? 'WFP运行时无法操作' : '更多操作',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                onEditRule(context, rule);
                                break;
                              case 'delete':
                                onDeleteRule(context, rule);
                                break;
                              case 'toggle':
                                onToggleRule(rule);
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        rule.enabled ?? false
                                            ? Icons.toggle_off
                                            : Icons.toggle_on,
                                        size: 16,
                                        color:
                                            rule.enabled ?? false
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        rule.enabled ?? false ? '禁用规则' : '启用规则',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('编辑规则'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '删除规则',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: '应用程序',
                          value: _getAppPathDisplay(rule.appPath),
                        ),
                        _InfoChip(
                          label: '协议',
                          value:
                              rule.protocol != null && rule.protocol!.isNotEmpty
                                  ? protocolOptions[rule.protocol!
                                          .toLowerCase()] ??
                                      rule.protocol!
                                  : '不限制',
                        ),
                        _InfoChip(
                          label: '方向',
                          value:
                              directionOptions[rule.direction] ??
                              rule.direction,
                        ),
                        _InfoChip(
                          label: '动作',
                          value: actionOptions[rule.action] ?? rule.action,
                          color:
                              rule.action == 'allow'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        _InfoChip(
                          label: '优先级',
                          value: rule.priority?.toString() ?? '-',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FieldRow(
                            label: '本地规则',
                            value: _getRuleDisplay(rule.localRule),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _FieldRow(
                            label: '远程规则',
                            value: _getRuleDisplay(rule.remoteRule),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 卡片内字段展示
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _InfoChip({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value', style: TextStyle(color: color)),
      backgroundColor: color?.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
