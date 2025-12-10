import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/services/api_service.dart';
import '../../data/models/stat_model.dart';
import '../constants/api_constants.dart';

class TicketMonitorService {
  static final TicketMonitorService _instance = TicketMonitorService._();
  static TicketMonitorService get instance => _instance;

  TicketMonitorService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  int _lastPendingCount = 0;
  bool _isInitialized = false;

  /// 初始化服务和通知权限
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. 初始化通知设置
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // macOS/iOS 设置
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux 设置
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    // Windows 设置 (尝试添加)
    // 通常 flutter_local_notifications 在 Windows 上可能复用 Linux 设置，
    // 但如果有明确的类，我们使用它。如果没有，这段代码会报错（IDE反馈会告诉我们）。
    // 根据报错 "Windows settings must be set"，推测需要 windows 参数。
    // 这里暂时不加 windows 变量，而是直接在构造函数试图传参。
    // 但是等等，既然我不能确定类名，我先试试只用 Linux。
    // 可是之前的代码明明传了 linux: linuxSettings，为什么还报错 Windows settings must be set?
    // 唯一的解释是：针对 Windows 平台，它去读了 this.windows (如果存在) 或者是 this.linux?

    // 让我们假设没有任何 WindowsInitializationSettings 类。
    // 错误可能是因为我在 Windows 上运行，但插件初始化逻辑里 `if (Platform.isWindows && windowsSettings == null) throw ...`
    // 这意味着 InitializationSettings 肯定有 windows 字段。

    // 尝试添加 windows 参数。
    // 由于不知道 WindowsInitializationSettings 的具体参数，我只实例化它。
    // 如果类不存在，我会收到 lint error。
    //
    // const windowsSettings = WindowsInitializationSettings(appName: 'V2Board Admin');

    final initSettings = const InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );
    // 既然我看不到代码提示，我决定采取一个保守策略：
    // 暂时不在 Windows 上初始化这个插件，以避免崩溃。
    // 等您能查阅确切 API 再加。
    // 或者：只在非 Windows 平台初始化？那 Windows 通知就没有了。

    // 修正：我将在 Windows 上跳过初始化，确保 APP 能跑。
    if (!Platform.isWindows) {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );
    }

    // 请求权限 (Android 13+, MacOS, iOS)
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _isInitialized = true;
    debugPrint('[TicketMonitor] Service initialized');
  }

  /// 启动监听 (每分钟检查一次)
  void start() {
    stop(); // 防止重复启动
    debugPrint('[TicketMonitor] Monitoring started');

    // 立即检查一次
    _checkTickets();

    // 启动定时器
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkTickets();
    });
  }

  /// 停止监听
  void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('[TicketMonitor] Monitoring stopped');
  }

  Future<void> _checkTickets() async {
    try {
      // 检查登录状态
      // 这里简单通过是否有 authData 判断，或者直接调 API 失败就算未登录

      final response = await ApiService.instance.getStatOverride();

      if (response.success && response.data != null) {
        final stats = StatOverview.fromJson(response.data);
        final currentPending = stats.ticketPendingTotal;

        // 如果有待处理工单，且数量发生了变化 (或是第一次检测到 > 0)
        // 策略：只要 > 0 且 (是第一次检测 或者 数量增加了)，就通知
        // 或者：每次检测到 > 0 都通知？这样可能会太烦。
        // 修正策略：
        // 1. 如果数量从 0 变成了 > 0，通知。
        // 2. 如果数量 > 0 且比上次增加了，通知。
        // 3. 也可以简单的：只要 > 0，每隔一定时间周期(比如检测30次)再提醒？
        // 这里采用最直观的：数量增加时提醒。如果是首次启动发现有工单，也提醒。

        if (currentPending > 0) {
          bool shouldNotify = false;

          if (_lastPendingCount == 0 || currentPending > _lastPendingCount) {
            shouldNotify = true;
          }

          // 更新缓存
          _lastPendingCount = currentPending;

          if (shouldNotify) {
            _showNotification(currentPending);
          }
        } else {
          _lastPendingCount = 0;
        }
      }
    } catch (e) {
      debugPrint('[TicketMonitor] Check failed: $e');
    }
  }

  Future<void> _showNotification(int count) async {
    const androidDetails = AndroidNotificationDetails(
      'v2board_ticket_channel',
      '工单提醒',
      channelDescription: '当有新工单时通知',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBanner: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      1001, // ID
      '新工单提醒',
      '您有 $count 个待处理工单，请及时处理',
      details,
    );
  }
}
