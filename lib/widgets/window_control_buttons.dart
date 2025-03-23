import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../config/app_config.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

// Create an instance of Windows Notification with your application name
// application id must be null in packaged mode
final _winNotifyPlugin = WindowsNotification(applicationId: 'Astral');
// create new NotificationMessage instance with id, title, body, and images
NotificationMessage message = NotificationMessage.fromPluginTemplate(
  "astral_minimized",
  "Astral 已最小化到托盘",
  "应用程序正在后台运行，点击托盘图标可以恢复窗口",
  // largeImage: "assets/images/icon.ico",
  // image: file_path
);

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = isMaximized;
      });
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = true;
      });
      Logger.info("窗口已最大化: $_isMaximized"); // 添加调试信息
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = false;
      });
      Logger.info("窗口已还原: $_isMaximized"); // 添加调试信息
    }
  }

  @override
  Widget build(BuildContext context) {
    // 添加调试信息
    Logger.info("构建窗口控制按钮，当前最大化状态: $_isMaximized");

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => windowManager.minimize(),
          tooltip: '最小化',
        ),
        IconButton(
          icon: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square),
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            // 手动更新状态，以防事件监听不工作
            if (mounted) {
              final isMaximized = await windowManager.isMaximized();
              setState(() {
                _isMaximized = isMaximized;
              });
            }
          },
          tooltip: '最大化/还原',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (AppConfig().closeToTray) {
              await windowManager.hide(); // 隐藏主窗口
              // 替换托盘提示为系统通知
              _winNotifyPlugin.showNotificationPluginTemplate(message);
            } else {
              closeAllServer();
              windowManager.close();
            }
          },
          tooltip: '关闭',
        ),
      ],
    );
  }
}
