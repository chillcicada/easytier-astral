import 'dart:io';

import 'package:astral/fun/up.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  // 1. 安全初始化 Sentry
  await SentryFlutter.init(
    (options) {
      // 方式1：从环境变量加载 DSN（推荐）
      final dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      
      // 方式2：备用方式（如果环境变量不可用）
      // final dsn = const String.fromEnvironment('SENTRY_DSN') ?? 
      //     'your-default-dsn-from-config-file'; // 不推荐硬编码
      
      if (dsn.isEmpty) {
        print('⚠️ WARNING: SENTRY_DSN not found in environment variables!');
        // 可以选择不初始化 Sentry 或使用空 DSN（不会发送数据）
        // options.dsn = ''; 
      } else {
        options.dsn = dsn;
      }

      // 关键配置
      options.debug = false; // 生产环境设为 false
      options.environment = 'production'; // 明确设置环境
      
      
      // 性能监控（可选）
      options.tracesSampleRate = 1.0; // 1.0 表示 100% 采样
      
      // 增强错误捕获
      options.attachStacktrace = true; // 附加堆栈跟踪
    },
    appRunner: () {
      // 2. 全局错误捕获
      FlutterError.onError = (FlutterErrorDetails details) {
        Sentry.captureException(
          details.exception, 
          stackTrace: details.stack
        );
        // 可选：仍然打印到控制台
        FlutterError.dumpErrorToConsole(details);
      };

      // 3. 运行应用
      runApp(const KevinApp());
    },
  );
}

