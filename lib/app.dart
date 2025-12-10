import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/theme/theme_provider.dart';
import 'features/auth/login_page.dart';
import 'shared/layouts/main_layout.dart';

/// V2Board Admin 应用
class V2BoardAdminApp extends StatefulWidget {
  const V2BoardAdminApp({super.key});

  @override
  State<V2BoardAdminApp> createState() => _V2BoardAdminAppState();
}

class _V2BoardAdminAppState extends State<V2BoardAdminApp> {
  @override
  void initState() {
    super.initState();
    // 初始化认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'V2Board Admin',
      debugShowCheckedModeBanner: false,

      // 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // 根据认证状态显示不同页面
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.initial:
            case AuthStatus.loading:
              return const _SplashScreen();
            case AuthStatus.authenticated:
              return const MainLayout();
            case AuthStatus.unauthenticated:
            case AuthStatus.error:
              return const LoginPage();
          }
        },
      ),
    );
  }
}

/// 启动画面
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16162A)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'V2Board Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text('正在加载...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
