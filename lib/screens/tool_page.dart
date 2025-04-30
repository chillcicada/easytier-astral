import 'dart:convert';
import 'dart:io';

import 'package:astral/k/app_s/aps.dart';
import 'package:astral/k/models/kl.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  final _aps = Aps();
  final List<String> _udpLogs = [];
  final ScrollController _scrollController = ScrollController();
  RawDatagramSocket? _udpSocket;

  @override
  void initState() {
    super.initState();
    _startUdpListener();
  }

  void _startUdpListener() async {
    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      9999,
    );
    _udpSocket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _udpSocket?.receive();
        if (datagram != null) {
          // 添加编码处理
          try {
            final message = utf8.decode(datagram.data, allowMalformed: false);
            setState(() {
              _udpLogs.add('${DateTime.now().toLocal()} - $message');
              if (_udpLogs.length > 100) _udpLogs.removeAt(0);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              }
            });
          } catch (e) {
            // 处理二进制数据
            final hexString = datagram.data
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join(' ');
            setState(() {
              _udpLogs.add('${DateTime.now().toLocal()} - [HEX] $hexString');
              if (_udpLogs.length > 100) _udpLogs.removeAt(0);
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              }
            });
          }
          // ... existing scroll controller code ...
        }
      }
    });
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _scrollController.dispose();
    super.dispose();
  }

  // 根据宽度计算列数
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 3;
    } else if (width >= 900) {
      return 2;
    }
    return 1;
  }

  // 显示添加Kl配置的对话框
  void _showAddKlDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加新配置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '输入配置名称',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '配置正则',
                    hintText: '输入目标窗口匹配正则',
                  ),
                  maxLines: 3,
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
                if (nameController.text.isNotEmpty) {
                  final newKl = Kl(
                    name: nameController.text,
                    description: descriptionController.text,
                    enabled: true,
                  );
                  _aps.addKl(newKl);
                  Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  // 显示添加规则的对话框
  void _showAddRuleDialog(BuildContext context, Kl kl) {
    final matchIpController = TextEditingController();
    final matchPortController = TextEditingController();
    final replaceIpController = TextEditingController();
    final replacePortController = TextEditingController();
    OperationType selectedOp = OperationType.all;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加规则'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<OperationType>(
                      value: selectedOp,
                      decoration: const InputDecoration(labelText: '操作类型'),
                      items:
                          OperationType.values.map((op) {
                            return DropdownMenuItem<OperationType>(
                              value: op,
                              child: Text(_getOperationTypeName(op)),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedOp = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: matchIpController,
                      decoration: const InputDecoration(
                        labelText: '匹配IP',
                        hintText: '输入要匹配的IP',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: matchPortController,
                      decoration: const InputDecoration(
                        labelText: '匹配端口',
                        hintText: '输入要匹配的端口',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: replaceIpController,
                      decoration: const InputDecoration(
                        labelText: '替换IP',
                        hintText: '输入替换的IP',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: replacePortController,
                      decoration: const InputDecoration(
                        labelText: '替换端口',
                        hintText: '输入替换的端口',
                      ),
                      keyboardType: TextInputType.number,
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
                    final rule =
                        Rule()
                          ..op = selectedOp
                          ..matchIp =
                              matchIpController.text.isNotEmpty
                                  ? matchIpController.text
                                  : null
                          ..matchPort =
                              matchPortController.text.isNotEmpty
                                  ? int.tryParse(matchPortController.text)
                                  : null
                          ..replaceIp =
                              replaceIpController.text.isNotEmpty
                                  ? replaceIpController.text
                                  : null
                          ..replacePort =
                              replacePortController.text.isNotEmpty
                                  ? int.tryParse(replacePortController.text)
                                  : null;

                    _aps.addRule(rule, kl.id);
                    Navigator.pop(context);
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 显示编辑规则的对话框
  void _showEditRuleDialog(BuildContext context, Rule rule) {
    final matchIpController = TextEditingController(text: rule.matchIp ?? '');
    final matchPortController = TextEditingController(
      text: rule.matchPort?.toString() ?? '',
    );
    final replaceIpController = TextEditingController(
      text: rule.replaceIp ?? '',
    );
    final replacePortController = TextEditingController(
      text: rule.replacePort?.toString() ?? '',
    );
    OperationType selectedOp = rule.op;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑规则'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<OperationType>(
                      value: selectedOp,
                      decoration: const InputDecoration(labelText: '操作类型'),
                      items:
                          OperationType.values.map((op) {
                            return DropdownMenuItem<OperationType>(
                              value: op,
                              child: Text(_getOperationTypeName(op)),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedOp = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: matchIpController,
                      decoration: const InputDecoration(
                        labelText: '匹配IP',
                        hintText: '输入要匹配的IP',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: matchPortController,
                      decoration: const InputDecoration(
                        labelText: '匹配端口',
                        hintText: '输入要匹配的端口',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: replaceIpController,
                      decoration: const InputDecoration(
                        labelText: '替换IP',
                        hintText: '输入替换的IP',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: replacePortController,
                      decoration: const InputDecoration(
                        labelText: '替换端口',
                        hintText: '输入替换的端口',
                      ),
                      keyboardType: TextInputType.number,
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
                    rule.op = selectedOp;
                    rule.matchIp =
                        matchIpController.text.isNotEmpty
                            ? matchIpController.text
                            : null;
                    rule.matchPort =
                        matchPortController.text.isNotEmpty
                            ? int.tryParse(matchPortController.text)
                            : null;
                    rule.replaceIp =
                        replaceIpController.text.isNotEmpty
                            ? replaceIpController.text
                            : null;
                    rule.replacePort =
                        replacePortController.text.isNotEmpty
                            ? int.tryParse(replacePortController.text)
                            : null;

                    _aps.updateRule(rule);
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 获取操作类型的中文名称
  String _getOperationTypeName(OperationType op) {
    switch (op) {
      case OperationType.connect:
        return '连接';
      case OperationType.bind:
        return '绑定';
      case OperationType.sendto:
        return '发送到';
      case OperationType.recvfrom:
        return '接收自';
      case OperationType.all:
        return '全部';
      default:
        return '未知';
    }
  }

  // 构建规则列表项
  Widget _buildRuleItem(Rule rule) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          '${_getOperationTypeName(rule.op)} ${rule.matchIp ?? '*'}:${rule.matchPort ?? '*'} → ${rule.replaceIp ?? '*'}:${rule.replacePort ?? '*'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditRuleDialog(context, rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text('确定要删除这条规则吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              _aps.deleteRule(rule.id);
                              Navigator.pop(context);
                            },
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建Kl配置卡片
  Widget _buildKlCard(Kl kl) {
    return ExpansionTile(
      title: Text(
        kl.name ?? '未命名配置',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(kl.description ?? ''),
      leading: Icon(
        Icons.rule,
        color: kl.enabled == true ? Colors.green : Colors.grey,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: kl.enabled ?? false,
            onChanged: (value) {
              _aps.toggleKlEnabled(kl, value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定要删除这个配置吗？这将同时删除所有关联的规则。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            _aps.deleteKl(kl.id);
                            Navigator.pop(context);
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Rule>>(
                future: _aps.getRulesByKlId(kl.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('暂无规则，点击下方按钮添加'),
                      ),
                    );
                  }

                  return Column(
                    children:
                        snapshot.data!
                            .map((rule) => _buildRuleItem(rule))
                            .toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加规则'),
                  onPressed: () => _showAddRuleDialog(context, kl),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columnCount = _getColumnCount(width);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 新增UDP监听卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '注入日志监听',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _udpLogs.length,
                        itemBuilder: (context, index) => Text(_udpLogs[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ValueListenableBuilder<List<Kl>>(
                valueListenable: ValueNotifier(_aps.kls.watch(context)),
                builder: (context, klList, child) {
                  if (klList.isEmpty) {
                    return const Center(child: Text('暂无配置，点击右下角按钮添加'));
                  }

                  return StaggeredGrid.count(
                    crossAxisCount: columnCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children:
                        klList.map((kl) {
                          return Card(elevation: 4, child: _buildKlCard(kl));
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddKlDialog(context),
            child: const Icon(Icons.add),
            tooltip: '添加新配置',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () async {
              // 获取所有启用的规则
              final enabledKls =
                  Aps().kls.value.where((kl) => kl.enabled ?? false).toList();

              // 生成TOML内容
              final tomlContent = _generateTomlContent(enabledKls);

              // 获取exe所在目录路径
              final exeDir = File(Platform.resolvedExecutable).parent;
              final tomlFile = File('${exeDir.path}/kl.toml');

              // 写入文件
              try {
                await tomlFile.writeAsString(tomlContent);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('配置文件已生成：${tomlFile.path}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('文件生成失败：$e')));
              }
              // 获取窗口列表并匹配进程
              final matchedPids = await _findMatchingProcesses(enabledKls);

              // 打印匹配结果
              debugPrint('匹配到的进程PID: $matchedPids');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('找到 ${matchedPids.length} 个匹配进程')),
              );

              // 在日志区域显示结果
              setState(() {
                _udpLogs.add('=== 进程匹配结果 ===');
                _udpLogs.addAll(matchedPids.map((pid) => 'PID: $pid'));
              });
              for (var pid in matchedPids) {
                print("${exeDir.path}/Ak.dll");
                injectDllToPid(
                  pid: pid.toString(),
                  dllPath: "${exeDir.path}/Ak.dll",
                );
              }
            },
            child: const Icon(Icons.inbox),
            tooltip: '注入配置',
          ),
        ],
      ),
    );
  }
}

String _generateTomlContent(List<Kl> kls) {
  final buffer = StringBuffer("# Auto-generated kl.toml\n\n");

  for (final kl in kls) {
    buffer.writeln('[[rule_groups]]');
    buffer.writeln('name = "${_escapeTomlString(kl.name ?? "")}"');
    buffer.writeln('regex = "${_escapeTomlString(kl.description ?? "")}"');

    for (final rule in kl.rules) {
      buffer.writeln('\n[[rule_groups.rules]]');
      buffer.writeln('op = "${_escapeTomlString(rule.op.name)}"');
      if (rule.matchIp != null) {
        buffer.writeln('match_ip = "${_escapeTomlString(rule.matchIp!)}"');
      }
      if (rule.matchPort != null) {
        buffer.writeln('match_port = ${rule.matchPort}');
      }
      if (rule.replaceIp != null) {
        buffer.writeln('replace_ip = "${_escapeTomlString(rule.replaceIp!)}"');
      }
      if (rule.replacePort != null) {
        buffer.writeln('replace_port = ${rule.replacePort}');
      }
    }
    buffer.writeln();
  }
  return buffer.toString();
}

String _escapeTomlString(String input) {
  // 转义 TOML 字符串中的特殊字符
  return input.replaceAll('"', '\\"');
}

// 在_ToolPageState类中添加以下方法
Future<List<int>> _findMatchingProcesses(List<Kl> kls) async {
  try {
    final windowTitles = await _getWindowTitles(); // 需要实现窗口标题获取
    final pids = <int>{};

    for (final kl in kls) {
      if (kl.description?.isNotEmpty ?? false) {
        final regex = RegExp(kl.description!, caseSensitive: false);
        final matches = windowTitles.where((title) => regex.hasMatch(title.$1));
        pids.addAll(matches.map((m) => m.$2));
      }
    }
    return pids.toList();
  } catch (e) {
    debugPrint('进程匹配失败: $e');
    return [];
  }
}

Future<List<(String, int)>> _getWindowTitles() async {
  try {
    final result = await Process.run('powershell', [
      '-c',
      r"Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object Id, MainWindowTitle, ProcessName | ConvertTo-Csv -NoTypeInformation",
    ], runInShell: false);

    final output = result.stdout.toString().split('\n');
    final windowInfo = <(String, int)>[];

    for (var line in output) {
      if (line.startsWith('"Id"')) continue; // 跳过标题行

      final parts = line.split(',');
      if (parts.length >= 3) {
        final title = parts[1].replaceAll('"', '').trim();
        final pid = int.tryParse(parts[0].replaceAll('"', '').trim());
        if (pid != null && title.isNotEmpty) {
          windowInfo.add((title, pid));
        }
      }
    }
    return windowInfo;
  } catch (e) {
    debugPrint('窗口标题获取失败: $e');
    return [];
  }
}
