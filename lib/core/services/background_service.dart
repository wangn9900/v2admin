import 'dart:io';
// import 'package:workmanager/workmanager.dart'; // 暂时注释掉，避免 Windows 编译错误
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 由于 workmanager 插件在 Windows 编译时会导致错误，
// 我们暂时先禁用它，或者需要实现条件编译。
// 为了保证 Windows 正常运行，这里先提供一个空实现。

class BackgroundService {
  static Future<void> init() async {
    if (Platform.isAndroid) {
      debugPrint(
        '[Background] Service initialization skipped (Plugin compatibility issue)',
      );
      // 只有解决了 Windows 编译问题后才能启用
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      // 仍然可以请求通知权限，因为 flutter_local_notifications 支持 Windows
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }
}
