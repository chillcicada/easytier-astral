import 'package:isar/isar.dart';
import 'package:astral/k/models/theme_settings.dart';
import 'package:astral/k/models_mod/theme_settings_cz.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  late final Isar isar;
  late final ThemeSettingsRepository themeSettings;

  /// 初始化数据库
  Future<void> init(String directory) async {
    isar = await Isar.open([ThemeSettingsSchema], directory: directory);
    themeSettings = ThemeSettingsRepository(isar);
  }
}
