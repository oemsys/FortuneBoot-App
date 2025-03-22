import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_login_example/dashboard_screen.dart';
import 'package:flutter_login_example/login_screen.dart';
import 'package:flutter_login_example/Login/base_url_config_page.dart';
import 'package:flutter_login_example/theme/app_theme.dart';
import 'package:flutter_login_example/transition_route_observer.dart';
import 'generated/l10n.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor:
          SystemUiOverlayStyle.dark.systemNavigationBarColor,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ], // 支持的语言
      title: 'Login',
      darkTheme: AppTheme.lightTheme(), // 使用统一的亮色主题作为暗色主题的基础
      themeMode: ThemeMode.light, // 暗黑模式报错，待解决
      theme: AppTheme.lightTheme(),
      navigatorObservers: [TransitionRouteObserver()],
      initialRoute: BaseUrlConfigPage.routeName,
      routes: {
        BaseUrlConfigPage.routeName: (context) => const BaseUrlConfigPage(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
      },
    );
  }
}
