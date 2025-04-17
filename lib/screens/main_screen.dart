import 'package:astral/k/app_s/Aps.dart';
import 'package:astral/screens/home_page.dart';
import 'package:astral/screens/settings_page.dart';
import 'package:astral/wid/bottom_nav.dart';
import 'package:astral/wid/left_nav.dart';
import 'package:astral/wid/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:astral/k/navigtion.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// MainScreen的状态管理类
class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 监听屏幕等状态变化
    // 在第一帧渲染完成后获取屏幕宽度并更新分割宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      Aps().updateScreenSplitWidth(screenWidth);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 屏幕尺寸变化时更新
    final screenWidth = MediaQuery.of(context).size.width;
    Aps().updateScreenSplitWidth(screenWidth);
  }

  // 构建导航项
  final List<NavigationItem> navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '主页',
      page: const HomePage(),
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '设置',
      page: const SettingsPage(),
    ),
  ];
  List<Widget> get _pages => navigationItems.map((item) => item.page).toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 构建Scaffold组件
    return Scaffold(
      // 自定义应用栏
      appBar: StatusBar(),
      // 主体内容
      body: Row(
        children: [
          if (Aps().isDesktop.watch(context))
            LeftNav(items: navigationItems, colorScheme: colorScheme),
          Expanded(
            child: IndexedStack(
              index: Aps().selectedIndex.watch(context),
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          Aps().isDesktop.watch(context)
              ? null
              : BottomNav(
                navigationItems: navigationItems,
                colorScheme: colorScheme,
              ),
    );
  }
}
