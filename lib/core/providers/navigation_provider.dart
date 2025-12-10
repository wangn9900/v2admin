import 'package:flutter/material.dart';

/// 导航状态管理
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  /// 跳转到指定索引
  void jumpTo(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// 定义各个页面的索引常量，方便调用
  static const int dashboard = 0;
  static const int users = 1;
  static const int notices = 2;
  static const int servers = 3;
  static const int plans = 4;
  static const int orders = 5;
  static const int coupons = 6;
  static const int giftCards = 7;
  static const int knowledge = 8;
  static const int tickets = 9;
  static const int queue = 10;
  static const int systemConfig = 11;
  // ... 其他设置页
}
