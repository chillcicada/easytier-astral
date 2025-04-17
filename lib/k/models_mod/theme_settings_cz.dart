import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/theme_settings.dart';

class ThemeSettingsRepository {
  final Isar _isar;

  ThemeSettingsRepository(this._isar) {
    init();
  }

  Future<void> init() async {
    if (await _isar.themeSettings.count() == 0) {
      await _isar.writeTxn(() async {
        await _isar.themeSettings.put(ThemeSettings()..id = 1);
      });
    }
  }

  Future<void> updateThemeColor(int colorValue) async {
    ThemeSettings? settings = await _isar.themeSettings.get(1);
    if (settings != null) {
      settings.colorValue = colorValue;
      await _isar.writeTxn(() async {
        await _isar.themeSettings.put(settings);
      });
    }
  }

  Future<int> getThemeColor() async {
    ThemeSettings? settings = await _isar.themeSettings.get(1);
    return settings?.colorValue ?? 0;
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    ThemeSettings? settings = await _isar.themeSettings.get(1);
    if (settings != null) {
      settings.themeModeValue = themeMode;
      await _isar.writeTxn(() async {
        await _isar.themeSettings.put(settings);
      });
    }
  }

  Future<ThemeMode> getThemeMode() async {
    ThemeSettings? settings = await _isar.themeSettings.get(1);
    return settings?.themeModeValue ?? ThemeMode.system;
  }
}
