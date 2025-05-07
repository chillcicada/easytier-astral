import 'dart:io';

import 'package:astral/fun/up.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定已初始化
  AppInfoUtil.init(); // 初始化应用信息
  await AppDatabase().init(); // 初始化数据库
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await WindowManagerUtils.initializeWindow(); // 初始化窗口管理器
  }
  await RustLib.init(); // 初始化 Rust 库
  // runApp(const KevinApp()); // 运行应用程序

  await SentryFlutter.init(
    (options) => options.dsn = const String.fromEnvironment('SENTRY_DSN'),
    appRunner: () => runApp(const KevinApp()),
  );
}
