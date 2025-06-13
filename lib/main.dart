import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:astral/fun/up.dart';
import 'package:astral/fun/reg.dart'; // 添加这行导入
import 'package:astral/k/app_s/log_capture.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:astral/services/app_links/app_link_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';

// 修改后的main.dart文件内容
void main() async {
  // 添加Zone错误致命检测（必须放在最顶部）
  BindingBase.debugZoneErrorsAreFatal = false; // 改为false防止直接崩溃

  runZonedGuarded(
    () async {
      try {
        WidgetsFlutterBinding.ensureInitialized();
        
        // 设置Flutter框架异常处理
        FlutterError.onError = (FlutterErrorDetails details) {
          _handleFlutterError(details);
        };
        
        // 设置平台异常处理
        PlatformDispatcher.instance.onError = (error, stack) {
          _handlePlatformError(error, stack);
          return true;
        };
        
        // 设置全局异常捕获（在WidgetsFlutterBinding初始化后）
        await _setupGlobalErrorHandling();
        
        await AppDatabase().init();
        AppInfoUtil.init();
        await RustLib.init();
        await LogCapture().startCapture();
        // 注册 URL scheme（在 Windows 上）
        await UrlSchemeRegistrar.registerUrlScheme();

        // 初始化 app_links
        await _initAppLinks();

        if (!kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
          await WindowManagerUtils.initializeWindow();
        }
        
        runApp(const KevinApp());
      } catch (e, stackTrace) {
        // 捕获初始化过程中的任何异常
        _safeLogError('初始化异常', e.toString(), stackTrace.toString());
        // 重新抛出异常让runZonedGuarded处理
        rethrow;
      }
    },
    (exception, stackTrace) async {
      _handleZoneError(exception, stackTrace);
    },
  );
}

// 设置全局异常处理
Future<void> _setupGlobalErrorHandling() async {
  try {
    // 捕获Isolate中的未处理异常
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      try {
        final List<dynamic> errorAndStacktrace = pair;
        final error = errorAndStacktrace[0];
        final stackTrace = errorAndStacktrace[1];
        await _handleIsolateError(error, stackTrace);
      } catch (e) {
        _safeLogError('Isolate错误处理异常', e.toString(), StackTrace.current.toString());
      }
    }).sendPort);
  } catch (e) {
    _safeLogError('设置全局异常处理失败', e.toString(), StackTrace.current.toString());
  }
}

// 处理Flutter框架异常
  void _handleFlutterError(FlutterErrorDetails details) {
    try {
      final logCapture = LogCapture();
      
      logCapture.addErrorLog('Flutter异常捕获: ${details.exception}');
      logCapture.addErrorLog('堆栈跟踪: ${details.stack}');
      logCapture.addErrorLog('异常库: ${details.library}');
      logCapture.addErrorLog('异常上下文: ${details.context}');
      
      // 记录到日志文件
      _logErrorToFile('flutter_error', details.exception.toString(), details.stack.toString());
    } catch (e) {
      _safeLogError('Flutter异常处理失败', e.toString(), StackTrace.current.toString());
      _safeLogError('原始Flutter异常', details.exception.toString(), details.stack.toString());
    }
    
    // 在调试模式下显示红屏，发布模式下静默处理
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

// 处理平台异常
  bool _handlePlatformError(Object error, StackTrace stack) {
    try {
      final logCapture = LogCapture();
      
      logCapture.addErrorLog('平台异常捕获: $error');
      logCapture.addErrorLog('堆栈跟踪: $stack');
      
      // 记录到日志文件
      _logErrorToFile('platform_error', error.toString(), stack.toString());
    } catch (e) {
      _safeLogError('平台异常处理失败', e.toString(), StackTrace.current.toString());
      _safeLogError('原始平台异常', error.toString(), stack.toString());
    }
    
    return true;
  }

// 处理Zone异常
  void _handleZoneError(Object exception, StackTrace stackTrace) async {
    try {
      final logCapture = LogCapture();
      
      logCapture.addErrorLog('Zone异常捕获: $exception');
      logCapture.addErrorLog('堆栈跟踪: $stackTrace');
      
      // 记录到日志文件
      _logErrorToFile('zone_error', exception.toString(), stackTrace.toString());
    } catch (e) {
      _safeLogError('Zone异常处理失败', e.toString(), StackTrace.current.toString());
      _safeLogError('原始Zone异常', exception.toString(), stackTrace.toString());
    }
  }

// 处理Isolate异常
  Future<void> _handleIsolateError(dynamic error, dynamic stackTrace) async {
    try {
      final logCapture = LogCapture();
      
      logCapture.addErrorLog('Isolate异常捕获: $error');
      logCapture.addErrorLog('堆栈跟踪: $stackTrace');
      
      // 记录到日志文件
      _logErrorToFile('isolate_error', error.toString(), stackTrace.toString());
    } catch (e) {
      _safeLogError('Isolate异常处理失败', e.toString(), StackTrace.current.toString());
      _safeLogError('原始Isolate异常', error.toString(), stackTrace.toString());
    }
  }
 
 // 将异常记录到日志文件
  void _logErrorToFile(String errorType, String error, String stackTrace) {
    try {
      final logCapture = LogCapture();
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] [$errorType] $error\n$stackTrace\n\n';
      
      // 记录到LogCapture系统
      logCapture.addSystemLog('=== 异常日志记录 ===');
      logCapture.addSystemLog('异常类型: $errorType');
      logCapture.addSystemLog('异常信息: $error');
      logCapture.addSystemLog('堆栈跟踪: $stackTrace');
      logCapture.addSystemLog('=== 异常日志结束 ===');
      
      // 这里可以将日志写入文件或发送到日志服务
      // 暂时只记录到LogCapture
    } catch (e) {
      _safeLogError('记录异常日志时发生错误', e.toString(), StackTrace.current.toString());
    }
  }
  
  // 安全的日志记录方法（当LogCapture不可用时的备用方案）
  void _safeLogError(String type, String error, String stackTrace) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[$timestamp] [$type] $error\n$stackTrace';
      
      // 尝试使用LogCapture
      try {
        final logCapture = LogCapture();
        logCapture.addErrorLog('[$type] $error');
        logCapture.addErrorLog('堆栈: $stackTrace');
      } catch (_) {
        // LogCapture不可用时，直接打印到控制台
        print('=== 安全日志记录 ===');
        print(logMessage);
        print('=== 安全日志结束 ===');
      }
    } catch (e) {
      // 最后的备用方案
      print('严重错误：无法记录日志 - $e');
      print('原始错误：$type - $error');
    }
  }

// 替换原有的_initAppLinks方法
Future<void> _initAppLinks() async {
  final registry = AppLinkRegistry();
  await registry.initialize();
}
