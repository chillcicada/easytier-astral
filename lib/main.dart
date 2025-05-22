import 'dart:async';
import 'dart:io';
import 'package:astral/fun/up.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';

void main() async {
  // BindingBase.debugZoneErrorsAreFatal = true;

  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase().init();
  AppInfoUtil.init();
  
  // 添加正确的参数传递
  await RustLib.init();

  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await WindowManagerUtils.initializeWindow();
  }

  runApp(const KevinApp());
}
