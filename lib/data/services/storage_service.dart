import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
/// 负责管理应用的本地数据存储
class StorageService {
  static StorageService? _instance;
  
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;
  
  // 存储键名常量
  static const String keyBaseUrl = 'base_url';
  static const String keySecurePath = 'secure_path';
  static const String keyAuthData = 'auth_data';
  static const String keyUserEmail = 'user_email';
  static const String keyIsAdmin = 'is_admin';
  static const String keyThemeMode = 'theme_mode';
  static const String keyRememberLogin = 'remember_login';
  
  StorageService._();
  
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }
  
  /// 初始化存储服务
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }
  
  // ============ 安全存储 (敏感数据) ============
  
  /// 保存认证数据
  Future<void> saveAuthData(String authData) async {
    await _secureStorage.write(key: keyAuthData, value: authData);
  }
  
  /// 获取认证数据
  Future<String?> getAuthData() async {
    return await _secureStorage.read(key: keyAuthData);
  }
  
  /// 删除认证数据
  Future<void> deleteAuthData() async {
    await _secureStorage.delete(key: keyAuthData);
  }
  
  // ============ 普通存储 (非敏感数据) ============
  
  /// 保存服务器地址
  Future<void> saveBaseUrl(String url) async {
    await _prefs.setString(keyBaseUrl, url);
  }
  
  /// 获取服务器地址
  String? getBaseUrl() {
    return _prefs.getString(keyBaseUrl);
  }
  
  /// 保存安全路径
  Future<void> saveSecurePath(String path) async {
    await _prefs.setString(keySecurePath, path);
  }
  
  /// 获取安全路径
  String? getSecurePath() {
    return _prefs.getString(keySecurePath);
  }
  
  /// 保存用户邮箱
  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(keyUserEmail, email);
  }
  
  /// 获取用户邮箱
  String? getUserEmail() {
    return _prefs.getString(keyUserEmail);
  }
  
  /// 保存管理员状态
  Future<void> saveIsAdmin(bool isAdmin) async {
    await _prefs.setBool(keyIsAdmin, isAdmin);
  }
  
  /// 获取管理员状态
  bool getIsAdmin() {
    return _prefs.getBool(keyIsAdmin) ?? false;
  }
  
  /// 保存主题模式 (0: 跟随系统, 1: 浅色, 2: 深色)
  Future<void> saveThemeMode(int mode) async {
    await _prefs.setInt(keyThemeMode, mode);
  }
  
  /// 获取主题模式
  int getThemeMode() {
    return _prefs.getInt(keyThemeMode) ?? 2; // 默认深色
  }
  
  /// 保存记住登录状态
  Future<void> saveRememberLogin(bool remember) async {
    await _prefs.setBool(keyRememberLogin, remember);
  }
  
  /// 获取记住登录状态
  bool getRememberLogin() {
    return _prefs.getBool(keyRememberLogin) ?? true;
  }
  
  /// 清除所有登录数据
  Future<void> clearLoginData() async {
    await deleteAuthData();
    await _prefs.remove(keyIsAdmin);
    // 保留 baseUrl, securePath, userEmail 以便下次登录
  }
  
  /// 清除所有数据
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }
}
