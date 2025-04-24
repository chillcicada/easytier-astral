import 'package:astral/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class KevinApp extends StatefulWidget {
  const KevinApp({super.key});
  @override
  State<KevinApp> createState() => _KevinAppState();
}

class _KevinAppState extends State<KevinApp> {
  final _aps = Aps(); // 确保只初始化一次

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        // 添加国际化支持
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Insert this line
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      theme: ThemeData(
        fontFamily: 'MiSans',
        useMaterial3: true,
        
        colorSchemeSeed: _aps.themeColor.watch(context), // 设置当前主题颜色,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        fontFamily: 'MiSans',
        useMaterial3: true,
        colorSchemeSeed: _aps.themeColor.watch(context),
        brightness: Brightness.dark,
      ),
      themeMode: _aps.themeMode.watch(context), // 设置当前主题模式
      home: MainScreen(),
    );
  }
}
