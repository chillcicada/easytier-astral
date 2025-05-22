import 'dart:async';
import 'dart:io';

import 'package:astral/fun/up.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// 修改后的main.dart文件内容
void main() async {
  // 添加Zone错误致命检测（必须放在最顶部）
  BindingBase.debugZoneErrorsAreFatal = true;

  // 确保所有初始化在同一个Zone内完成
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppDatabase().init();
      AppInfoUtil.init();
      await RustLib.init();

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await WindowManagerUtils.initializeWindow();
      }

      await SentryFlutter.init((options) {
        // 公开DSN 如果滥用我会重置
        options.dsn =
            'https://8ddef9dc25ba468431473fc15187df30@o4509285217402880.ingest.de.sentry.io/4509285224087632';
      });

      runApp(const KevinApp());
    },
    (exception, stackTrace) async {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}
