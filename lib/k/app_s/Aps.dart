import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:astral/k/database/app_data.dart';
export 'package:signals_flutter/signals_flutter.dart';

/// 全局状态管理类
class Aps {
  //单例模式
  Aps._internal() {
    _initThemeSettings();
  }
  static final Aps _instance = Aps._internal();
  factory Aps() => _instance;

  /// 主题颜色
  final Signal<int> themeColor = signal(0); // 初始化为0
  /// 主题模式
  final Signal<ThemeMode> themeMode = signal(ThemeMode.system); // 初始化为跟随系统
  /// 软件名
  final Signal<String> appName = signal('Astro Game'); // 初始化为Astro Game

  // 初始化主题设置
  Future<void> _initThemeSettings() async {
    final database = AppDatabase();
    themeColor.value = await database.themeSettings.getThemeColor();
    themeMode.value = await database.themeSettings.getThemeMode();
  }

  // 更新主题颜色
  Future<void> updateThemeColor(int color) async {
    themeColor.value = color;
    await AppDatabase().themeSettings.updateThemeColor(color);
  }

  // 更新主题模式
  Future<void> updateThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await AppDatabase().themeSettings.updateThemeMode(mode);
  }

  // 更新软件名
  Future<void> updateAppName(String name) async {
    appName.value = name;
  }
}
