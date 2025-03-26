import 'dart:ui';

import 'package:astral/sys/config_core.dart';
import 'package:astral/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'config/windowconfiguration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:astral/utils/app_info.dart';

Future<void> main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化应用信息
    await AppInfoUtil.init();
    // 初始化日志系统
    await Logger.getInstance();
    Logger.info('应用启动');

    // 设置Flutter错误处理
    _setupErrorHandling();

    // 设置平台特定配置
    await _setupPlatformSpecificConfig();

    // 初始化核心服务
    await RustLib.init();
    await AppConfig.init();

    // 运行应用
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stack) {
    Logger.error('应用启动失败: $e');
    Logger.error('堆栈跟踪: $stack');
    rethrow; // 重新抛出异常以便系统可以处理
  }
}

/// 设置错误处理
void _setupErrorHandling() {
  // 设置Flutter错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger.error('Flutter错误: ${details.exception}');
    Logger.error('堆栈跟踪: ${details.stack}');
    // 继续将错误报告给Flutter
    FlutterError.dumpErrorToConsole(details);
  };

  // 捕获未处理的异步错误
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    Logger.error('平台分发器错误: $error');
    Logger.error('堆栈跟踪: $stack');
    return true; // 返回true表示错误已处理
  };
}

/// 设置平台特定配置
Future<void> _setupPlatformSpecificConfig() async {
  // 为Android平台设置配置目录
  if (Platform.isAndroid) {
    final appDir = await getApplicationDocumentsDirectory();
    AppConfig.setConfigDir(appDir.path);
  }

  // 桌面平台窗口设置
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    // 设置窗口属性
    await setupWindow();
  }
}
