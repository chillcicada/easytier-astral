import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:astral/k/app_s/aps.dart';

class WindowManagerUtils {
  static Future<void> initializeWindow() async {
    // 检查当前平台是否为 Windows、MacOS 或 Linux
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // 确保窗口管理器已初始化
      await windowManager.ensureInitialized();
      //添加信号监听
      // 创建响应式效果，用于监听和更新窗口标题
      effect(() {
        // 设置窗口标题为当前应用名称
        windowManager.setTitle(Aps().appName.value);
      });
      // 定义窗口选项配置
      final windowOptions = WindowOptions(
        // 设置窗口默认大小为 1280x720
        size: Size(1280, 720),
        // 设置窗口最小大小为 300x300
        minimumSize: Size(300, 300),
        // 设置窗口居中显示
        center: true,
        // 设置窗口标题
        title: Aps().appName.value,
        // 设置标题栏样式为隐藏
        titleBarStyle: TitleBarStyle.hidden,
        // 设置窗口背景为透明
        backgroundColor: Colors.transparent,
        // 设置是否在任务栏显示
        skipTaskbar: false,
      );

      // 等待窗口准备就绪并显示
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        // 显示窗口
        await windowManager.show();
        // 使窗口获得焦点
        await windowManager.focus();
      });
    }
  }
}
