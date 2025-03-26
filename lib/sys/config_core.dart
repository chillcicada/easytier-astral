
import 'package:astral/model/config_model.dart';
import 'package:astral/utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:hive_flutter/hive_flutter.dart';

// 配置模型基类
abstract class BaseConfigModel {
  Map<String, dynamic> toJson();
  String get configKey; // 配置在存储中的键名
}

// 配置管理器核心
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  static late Box _configBox;
  static late String _configDirectory;
  static bool _initialized = false;

  // 配置模型映射表
  final Map<Type, ConfigModel> _configModels = {};

  // 配置类型与工厂函数映射
  final Map<Type, Function> _configFactories = {};

  factory AppConfig() {
    return _instance;
  }

  // 设置配置目录
  static void setConfigDir(String dirPath) {
    _configDirectory = dirPath;
    Logger.info('配置目录已设置为: $_configDirectory');
  }

  AppConfig._internal() {
    // 注册所有配置类型
    registerConfig<ConfigModel>(
        (json) => ConfigModel.fromJson(json), ConfigModel());
  }

  // 注册配置类型
  void registerConfig<T extends ConfigModel>(
    T Function(Map<String, dynamic>) fromJson,
    T defaultValue,
  ) {
    _configFactories[T] = fromJson;
    _configModels[T] = defaultValue;
    Logger.info('注册配置类型: ${T.toString()}');
  }

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 如果没有预先设置配置目录，则尝试获取可执行文件所在目录
      if (!_configDirectory.isNotEmpty) {
        _configDirectory = File(Platform.resolvedExecutable).parent.path;
      }
      Logger.info('配置目录: $_configDirectory');

      // 初始化Hive
      await Hive.initFlutter(_configDirectory);
      Logger.info('Hive初始化完成');

      // 打开配置Box
      _configBox = await Hive.openBox('app_config');
      Logger.info('配置Box打开成功，包含 ${_configBox.length} 个条目');

      // 打印所有键值，用于调试
      Logger.info('配置Box中的所有键: ${_configBox.keys.toList()}');

      // 加载并验证配置
      await _instance._loadAndValidateConfig();
      Logger.info('配置加载和验证完成');

      _initialized = true;
    } catch (e) {
      Logger.info('AppConfig初始化失败: $e');
      // 尝试使用备用目录
      try {
        // 使用应用文档目录作为备用目录
        final appDocDir = Directory(
          path.join(Directory.current.path, 'config'),
        );

        // 确保目录存在
        if (!appDocDir.existsSync()) {
          appDocDir.createSync(recursive: true);
        }

        _configDirectory = appDocDir.path;
        Logger.info('尝试使用备用目录: $_configDirectory');

        await Hive.initFlutter(_configDirectory);
        _configBox = await Hive.openBox('app_config');

        await _instance._loadAndValidateConfig();
        _initialized = true;
        Logger.info('使用备用目录初始化成功');
      } catch (e2) {
        Logger.info('备用初始化也失败: $e2');
        rethrow;
      }
    }
  }

  // 加载并验证所有配置
  Future<void> _loadAndValidateConfig() async {
    Logger.info('开始加载配置...');
    // 加载所有注册的配置
    for (var entry in _configFactories.entries) {
      final type = entry.key;
      final fromJson = entry.value;
      final defaultValue = _configModels[type]!;
      final configKey = defaultValue.configKey;

      Logger.info('加载配置: $configKey (${type.toString()})');
      _configModels[type] = _loadConfig(
        configKey,
        fromJson as ConfigModel Function(Map<String, dynamic>),
        defaultValue,
      );
    }
  }

  // 通用配置加载方法
  T _loadConfig<T extends ConfigModel>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    T defaultValue,
  ) {
    final dynamic config = _configBox.get(key);
    Logger.info('读取配置 $key: ${config != null ? '存在' : '不存在'}');

    if (config != null) {
      try {
        Logger.info('配置内容: $config');
        final result = fromJson(Map<String, dynamic>.from(config));
        Logger.info('配置解析成功');
        return result;
      } catch (e) {
        Logger.info('配置解析失败: $e');
        // 如果解析失败，使用默认值
      }
    }

    // 保存默认值
    final defaultMap = defaultValue.toJson();
    Logger.info('使用默认配置: $defaultMap');
    _configBox.put(key, defaultMap);

    return defaultValue;
  }

  // 获取配置
  T getModel<T extends ConfigModel>() {
    if (!_configModels.containsKey(T)) {
      throw Exception('未注册的配置类型: $T');
    }
    return _configModels[T] as T;
  }

  // 更新配置
  Future<void> updateModel<T extends ConfigModel>(T newConfig) async {
    if (!_configModels.containsKey(T)) {
      throw Exception('未注册的配置类型: $T');
    }

    _configModels[T] = newConfig;
    await _configBox.put(newConfig.configKey, newConfig.toJson());
  }

  // 通用配置获取方法
  T? getConfig<T>(String key) {
    return _configBox.get(key) as T?;
  }

  // 通用配置设置方法
  Future<void> setConfig<T>(String key, T value) async {
    await _configBox.put(key, value);

    // 更新缓存的配置对象
    await _loadAndValidateConfig();
  }
}
