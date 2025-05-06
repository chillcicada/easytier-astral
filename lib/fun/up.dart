import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  /// GitHub 仓库所有者
  final String owner;

  /// GitHub 仓库名称
  final String repo;

  /// 可选：指定检查的分支名称，默认为 'main'
  final String branch;

  UpdateChecker({
    required this.owner,
    required this.repo,
    this.branch = 'main',
  });

  /// 检查更新
  Future<void> scheckForUpdates(BuildContext context) async {
    try {
      final releaseInfo = await _fetchLatestRelease();
      if (releaseInfo == null) {
        _showUpdateDialog(
          // 添加空值处理
          context,
          '检查更新失败',
          '无法获取最新版本信息',
          'https://github.com/$owner/$repo/releases',
        );
        return;
      }

      // 获取当前应用版本
      final currentVersion = await _getCurrentVersion();

      // 比较版本号，如果有新版本则显示更新弹窗
      if (_shouldUpdate(currentVersion, releaseInfo['tag_name'])) {
        _showUpdateDialog(
          context,
          releaseInfo['tag_name'],
          releaseInfo['body'] ?? '新版本已发布',
          releaseInfo['html_url'],
        );
      }
    } catch (e) {
      _showUpdateDialog(
        context,
        '更新检查失败',
        '检查更新时发生错误: $e',
        'https://github.com/$owner/$repo/releases',
      );
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final releaseInfo = await _fetchLatestRelease();
      if (releaseInfo == null) {
        _showUpdateDialog(
          // 添加空值处理
          context,
          '检查更新失败',
          '无法获取最新版本信息',
          'https://github.com/$owner/$repo/releases',
        );
        return;
      }

      // 获取当前应用版本
      final currentVersion = await _getCurrentVersion();

      // 比较版本号，如果有新版本则显示更新弹窗
      if (_shouldUpdate(currentVersion, releaseInfo['tag_name'])) {
        _showUpdateDialog(
          context,
          releaseInfo['tag_name'],
          releaseInfo['body'] ?? '新版本已发布',
          releaseInfo['html_url'],
        );
      } else {
        _showUpdateDialog(
          context,
          '当前已是最新版本',
          '当前版本为: $currentVersion',
          'https://github.com/$owner/$repo/releases',
        );
      }
    } catch (e) {
      _showUpdateDialog(
        context,
        '更新检查失败',
        '检查更新时发生错误: $e',
        'https://github.com/$owner/$repo/releases',
      );
    }
  }

  /// 获取最新发布版本信息
  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      // 添加异常捕获
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'astral',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        if (releases.isEmpty) return null;

        // 获取第一个发布版本（最新版本）
        return releases[0];
      } else {
        return {
          // 返回错误信息
          'tag_name': '错误 ${response.statusCode}',
          'body': '请求GitHub API失败',
          'html_url': 'https://github.com/$owner/$repo/releases',
        };
      }
    } catch (e) {
      return null;
    }
  }

  /// 获取当前应用版本
  Future<String> _getCurrentVersion() async {
    try {
      return AppInfoUtil.getVersion();
    } catch (e) {
      return "0.0.0"; // 返回默认版本号避免后续比较崩溃
    }
  }

  /// 比较版本号，判断是否需要更新
  bool _shouldUpdate(String currentVersion, String latestVersion) {
    // 确保版本号格式正确（添加v前缀如果没有）
    final current =
        currentVersion.startsWith('v')
            ? currentVersion.substring(1)
            : currentVersion;
    final latest =
        latestVersion.startsWith('v')
            ? latestVersion.substring(1)
            : latestVersion;

    // 处理预发布版本标签（如 -alpha, -beta 等）
    String currentClean = current;
    String latestClean = latest;

    if (current.contains('-')) {
      currentClean = current.split('-')[0];
    }

    if (latest.contains('-')) {
      latestClean = latest.split('-')[0];
    }

    // 分割版本号为数组
    final currentParts = currentClean.split('.');
    final latestParts = latestClean.split('.');

    // 比较主版本号、次版本号和修订号
    for (int i = 0; i < 3; i++) {
      final currentPart =
          i < currentParts.length ? int.parse(currentParts[i]) : 0;
      final latestPart = i < latestParts.length ? int.parse(latestParts[i]) : 0;

      if (latestPart > currentPart) {
        return true;
      } else if (latestPart < currentPart) {
        return false;
      }
    }

    // 版本号相同，检查预发布标签
    if (current.contains('-') && !latest.contains('-')) {
      // 当前是预发布版本，而最新是正式版本
      return true;
    } else if (!current.contains('-') && latest.contains('-')) {
      // 当前是正式版本，而最新是预发布版本
      return false;
    } else if (current.contains('-') && latest.contains('-')) {
      // 两者都是预发布版本，比较预发布标签
      final currentPreRelease = current.split('-')[1];
      final latestPreRelease = latest.split('-')[1];

      // 简单比较预发布标签（alpha < beta < rc）
      if (currentPreRelease.startsWith('alpha') &&
          (latestPreRelease.startsWith('beta') ||
              latestPreRelease.startsWith('rc'))) {
        return true;
      } else if (currentPreRelease.startsWith('beta') &&
          latestPreRelease.startsWith('rc')) {
        return true;
      } else if (currentPreRelease == latestPreRelease) {
        return false;
      }

      // 如果预发布标签包含数字（如 beta.1, beta.2），则比较数字部分
      if (currentPreRelease.contains('.') &&
          latestPreRelease.contains('.') &&
          currentPreRelease.split('.')[0] == latestPreRelease.split('.')[0]) {
        try {
          final currentNum = int.parse(currentPreRelease.split('.')[1]);
          final latestNum = int.parse(latestPreRelease.split('.')[1]);
          return latestNum > currentNum;
        } catch (e) {
          // 解析失败，返回简单比较结果
          return latestPreRelease.compareTo(currentPreRelease) > 0;
        }
      }

      // 默认比较预发布标签的字符串
      return latestPreRelease.compareTo(currentPreRelease) > 0;
    }

    return false; // 版本相同，不需要更新
  }

  /// 显示更新弹窗
  void _showUpdateDialog(
    BuildContext context,
    String version,
    String releaseNotes,
    String downloadUrl,
  ) {
    final isLatestVersion = version.contains("当前已是最新版本");

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isLatestVersion ? version : '发现新版本: $version'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLatestVersion) Text('更新内容:'),
                  if (!isLatestVersion) const SizedBox(height: 8),
                  Text(releaseNotes, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后再说'),
              ),
              if (!isLatestVersion) // 仅在新版本弹窗显示更新按钮
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _launchUrl(downloadUrl);
                  },
                  child: const Text('立即更新'),
                ),
              if (isLatestVersion) // 最新版本显示确认按钮
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
            ],
          ),
    );
  }

  /// 打开浏览器跳转到下载链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {}
  }
}

class AppInfoUtil {
  static PackageInfo? _packageInfo;

  /// 初始化应用信息
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 获取应用版本号 (例如: 1.0.0)
  static String getVersion() {
    return _packageInfo?.version ?? '';
  }

  /// 获取应用构建号 (例如: 1)
  static String getBuildNumber() {
    return _packageInfo?.buildNumber ?? '';
  }

  /// 获取完整版本号 (例如: 1.0.0+1)
  static String getFullVersion() {
    final version = getVersion();
    final buildNumber = getBuildNumber();
    return '$version+$buildNumber';
  }

  /// 获取应用名称
  static String getAppName() {
    return _packageInfo?.appName ?? '';
  }

  /// 获取包名
  static String getPackageName() {
    return _packageInfo?.packageName ?? '';
  }
}
