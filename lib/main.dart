import 'package:astral/k/mod/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WindowManagerUtils.initializeWindow();
  await RustLib.init();
  runApp(const KevinApp());
}
