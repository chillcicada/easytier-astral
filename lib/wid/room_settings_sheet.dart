import 'package:flutter/material.dart';
import 'package:astral/k/app_s/aps.dart';

// 房间设置弹窗组件
class RoomSettingsSheet extends StatefulWidget {
  const RoomSettingsSheet({Key? key}) : super(key: key);

  @override
  State<RoomSettingsSheet> createState() => _RoomSettingsSheetState();

  static Future<void> show(BuildContext context) async {
    if (MediaQuery.of(context).size.width > 600) {
      // PC端显示为对话框
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 400,
            height: 600,
            alignment: Alignment.topLeft, 
            child: const RoomSettingsSheet(),
          ),
        ),
      );
    } else {
      // 移动端显示为底部弹窗
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: const RoomSettingsSheet(),
          ),
        ),
      );
    }
  }
}

class _RoomSettingsSheetState extends State<RoomSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 8, 4), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '房间设置',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '点击下方设置项进行配置，所有更改将实时生效',
                textAlign: TextAlign.left,
                maxLines: null,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // 滚动内容区域
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // 显示模式
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      '显示模式',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton('简约', Aps().userListSimple.value, () {
                        Aps().setUserListSimple(true);
                      }),
                      _buildOptionButton('详细', !Aps().userListSimple.value, () {
                        Aps().setUserListSimple(false);
                      }),
                    ],
                  ),
                ],
              ),

              // 用户显示
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      '用户显示',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton('默认', Aps().displayMode.value == 0, () async {
                        await Aps().setDisplayMode(0);
                      }),
                      _buildOptionButton('用户', Aps().displayMode.value == 1, () async {
                        await Aps().setDisplayMode(1);
                      }),
                      _buildOptionButton('服务器', Aps().displayMode.value == 2, () async {
                        await Aps().setDisplayMode(2);
                      }),
                    ],
                  ),
                ],
              ),

              // 用户排序
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      '用户排序',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton('默认', Aps().sortOption.value == 0, () async {
                        await Aps().setSortOption(0);
                      }),
                      _buildOptionButton('延迟', Aps().sortOption.value == 1, () async {
                        await Aps().setSortOption(1);
                      }),
                      _buildOptionButton('用户名', Aps().sortOption.value == 2, () async {
                        await Aps().setSortOption(2);
                      }),
                    ],
                  ),
                ],
              ),

              // 排序方式
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Text(
                      '排序方式',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildOptionButton('升序', Aps().sortOrder.value == 0, () async {
                        await Aps().setSortOrder(0);
                      }),
                      _buildOptionButton('降序', Aps().sortOrder.value == 1, () async {
                        await Aps().setSortOrder(1);
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // 底部按钮
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: Navigator.of(context).pop,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('关闭'),
          ),
        ),
      ],
    );
  }

  // 构建选项按钮
  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onPressed) {
    bool _isHovered = false; // 新增悬停状态

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (_isHovered || isSelected) 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3) 
                  : Colors.transparent,
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              )
            ],
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(1.0),
            border: Border.all(
              color: (_isHovered || isSelected) 
                ? Theme.of(context).colorScheme.primary 
                : Colors.transparent,
              width: (_isHovered || isSelected) ? 1.5 : 1.0,
            ),
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black, // 统一设置为黑色
              ),
            ),
          ),
        ),
      ),
    );
  }
}