import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'config/windowconfiguration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_config.dart';
import 'utils/kv_state.dart';
import 'package:astral/utils/app_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化应用信息
  await AppInfoUtil.init();
  await windowManager.ensureInitialized();
  // 获取pid
  // 设置窗口属性
  await setupWindow();
  await AppConfig.init();
  // 初始化应用信息
  await RustLib.init();
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
