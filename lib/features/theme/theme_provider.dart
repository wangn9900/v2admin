import 'package:flutter/material.dart';
import '../../data/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  late int _themeMode;

  ThemeProvider() {
    _themeMode = _storage.getThemeMode();
  }

  int get themeModeIndex => _themeMode;

  ThemeMode get themeMode {
    switch (_themeMode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(int mode) {
    _themeMode = mode;
    _storage.saveThemeMode(mode);
    notifyListeners();
  }
}
