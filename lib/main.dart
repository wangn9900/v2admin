import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'data/services/storage_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/theme/theme_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'features/dashboard/dashboard_page.dart'; // 好像没用到，不过为了保险
import 'app.dart';

import 'core/services/background_service.dart';
import 'core/services/ticket_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面端窗口配置
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'V2Board Admin',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化存储服务
  await StorageService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const V2BoardAdminApp(),
    ),
  );

  // 初始化后台服务 (放在 runApp 之后，避免阻塞启动)
  // 使用 Future.microtask 或直接异步执行，不等待
  Future.delayed(const Duration(seconds: 1), () async {
    try {
      // 初始化后台服务 (Android)
      if (Platform.isAndroid) {
        await BackgroundService.init();
        await BackgroundService.requestPermissions();
      }

      // 初始化并启动全平台前台监听服务
      await TicketMonitorService.instance.init();
      TicketMonitorService.instance.start();
    } catch (e, stack) {
      debugPrint('Error initializing background services: $e\n$stack');
    }
  });
}
