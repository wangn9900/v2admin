import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';

/// 认证状态
enum AuthStatus {
  initial, // 初始状态
  loading, // 加载中
  authenticated, // 已认证
  unauthenticated, // 未认证
  error, // 错误
}

/// 认证状态管理 Provider
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserInfo? _user;
  String? _errorMessage;
  String? _authData;
  String? _currentLoginIp; // 本次登录使用的公网 IP（代理出口 IP）

  AuthStatus get status => _status;
  UserInfo? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get currentLoginIp => _currentLoginIp; // 当前登录的公网 IP

  final StorageService _storage = StorageService.instance;
  final ApiService _api = ApiService.instance;

  /// 初始化 - 检查本地存储的登录状态
  Future<void> init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final authData = await _storage.getAuthData();
      final baseUrl = _storage.getBaseUrl();
      final securePath = _storage.getSecurePath();

      if (authData != null && baseUrl != null && securePath != null) {
        // 初始化 API 服务
        await _api.init(
          baseUrl: baseUrl,
          securePath: securePath,
          authData: authData,
        );

        _authData = authData;

        // 验证 token 有效性
        final response = await _api.getUserInfo();
        if (response.success) {
          final data = response.getData<Map<String, dynamic>>();
          if (data != null) {
            _user = UserInfo.fromJson(data);

            // 尝试获取更详细的用户信息（包含 IP 和正确的管理员状态）
            await _tryFetchDetailedUserInfo();

            if (_user!.isAdmin) {
              _status = AuthStatus.authenticated;
              // 获取当前公网 IP（验证代理是否生效）
              _currentLoginIp = await _api.getCurrentPublicIp();
            } else {
              _status = AuthStatus.unauthenticated;
              _errorMessage = '非管理员账户';
              await _storage.clearLoginData();
            }
          } else {
            _status = AuthStatus.unauthenticated;
          }
        } else {
          _status = AuthStatus.unauthenticated;
          await _storage.clearLoginData();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// 登录
  Future<bool> login({
    required String baseUrl,
    required String securePath,
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    debugPrint('=== 开始登录 ===');
    debugPrint('baseUrl: $baseUrl');
    debugPrint('securePath: $securePath');
    debugPrint('email: $email');

    try {
      // 初始化 API 服务
      await _api.init(baseUrl: baseUrl, securePath: securePath);

      debugPrint('API 服务初始化完成');

      // 调用登录接口
      final response = await _api.login(email, password);

      debugPrint('登录响应: success=${response.success}, data=${response.data}');

      if (!response.success) {
        _status = AuthStatus.error;
        _errorMessage = response.getMessage();
        debugPrint('登录失败: $_errorMessage');
        notifyListeners();
        return false;
      }

      final data = response.getData<Map<String, dynamic>>();
      debugPrint('解析后的 data: $data');

      if (data == null) {
        _status = AuthStatus.error;
        _errorMessage = '登录响应数据异常';
        debugPrint('登录响应数据异常');
        notifyListeners();
        return false;
      }

      final authData = AuthData.fromJson(data);
      debugPrint(
        'authData: token=${authData.token}, isAdmin=${authData.isAdmin}, authData=${authData.authData}',
      );

      // 验证是否为管理员
      if (!authData.isAdminUser) {
        _status = AuthStatus.error;
        _errorMessage = '非管理员账户，无法登录';
        debugPrint('非管理员账户');
        notifyListeners();
        return false;
      }

      // 保存登录数据
      _authData = authData.authData;
      _api.updateAuthData(_authData);

      await _storage.saveBaseUrl(baseUrl);
      await _storage.saveSecurePath(securePath);
      await _storage.saveAuthData(authData.authData);
      await _storage.saveUserEmail(email);
      await _storage.saveIsAdmin(true);

      debugPrint('登录数据已保存');

      // 获取用户详细信息
      final userResponse = await _api.getUserInfo();
      debugPrint('获取用户信息: success=${userResponse.success}');

      if (userResponse.success) {
        final userData = userResponse.getData<Map<String, dynamic>>();
        if (userData != null) {
          _user = UserInfo.fromJson(userData);
          debugPrint('用户信息: ${_user?.email}');

          // 获取详细信息
          await _tryFetchDetailedUserInfo();
        }
      }

      _status = AuthStatus.authenticated;

      // 获取当前公网 IP（验证代理是否生效）
      _currentLoginIp = await _api.getCurrentPublicIp();
      debugPrint('[IPCheck] Login IP: $_currentLoginIp');

      debugPrint('=== 登录成功 ===');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      debugPrint('登录异常: $e');
      debugPrint('堆栈: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _storage.clearLoginData();
    _user = null;
    _authData = null;
    _api.updateAuthData(null);

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    try {
      final response = await _api.getUserInfo();
      if (response.success) {
        final data = response.getData<Map<String, dynamic>>();
        if (data != null) {
          _user = UserInfo.fromJson(data);
          await _tryFetchDetailedUserInfo();
          notifyListeners();
        }
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 尝试获取详细用户信息（使用 Admin API）
  /// 解决部分环境下 user/info 接口返回数据不全（如缺少 last_login_ip 或 is_admin）的问题
  Future<void> _tryFetchDetailedUserInfo() async {
    if (_user == null) {
      debugPrint('[UserInfoDebug] User is null, skipping detailed fetch');
      return;
    }

    try {
      int userId = _user!.id;

      // 如果 ID 为 0，说明 /user/info 没返回 ID，尝试通过 email 去获取
      if (userId == 0) {
        debugPrint(
          '[UserInfoDebug] User ID is 0, searching by email: ${_user!.email}',
        );
        final searchResponse = await _api.fetchUsers(
          current: 1,
          pageSize: 1,
          filter: [
            {'key': 'email', 'condition': '=', 'value': _user!.email},
          ],
        );

        if (searchResponse.success) {
          debugPrint(
            '[UserInfoDebug v2] Parsing search response explicitly...',
          );
          // V2 Fix: Do not use getData<Map> because data might be a List
          final rawData = searchResponse.data;

          // Check if rawData itself is the Map containing {data: [...], total: ...}
          if (rawData is Map<String, dynamic>) {
            final dataField = rawData['data'];
            if (dataField is List) {
              if (dataField.isNotEmpty) {
                final firstUser = dataField.first;
                if (firstUser is Map<String, dynamic>) {
                  userId = firstUser['id'] ?? 0;
                  debugPrint('[UserInfoDebug v2] Found ID via search: $userId');
                }
              } else {
                debugPrint('[UserInfoDebug v2] User list is empty');
              }
            } else {
              // In some cases, maybe data IS the list?
              debugPrint(
                '[UserInfoDebug v2] "data" field is not a List: ${dataField.runtimeType}',
              );
            }
          } else {
            debugPrint(
              '[UserInfoDebug v2] rawData is not a Map: ${rawData.runtimeType}',
            );
          }
        }
      }

      if (userId == 0) {
        debugPrint('[UserInfoDebug] Failed to determine User ID');
        return;
      }

      debugPrint(
        '[UserInfoDebug] Starting detailed info fetch for User ID: $userId',
      );

      // 只有当看起来像管理员时才尝试，或者尝试获取来验证是否为管理员
      // 先从 fetch 搜索的结果获取 ips（如果有的话）
      String? fetchedIps;

      // 如果之前通过 fetch 搜索过，从那个结果获取 ips
      if (userId != _user!.id) {
        // 重新获取一次，因为 fetch 有 ips 字段
        final fetchResponse = await _api.fetchUsers(
          current: 1,
          pageSize: 1,
          filter: [
            {'key': 'id', 'condition': '=', 'value': userId},
          ],
        );
        if (fetchResponse.success) {
          final rawData = fetchResponse.data;
          if (rawData is Map<String, dynamic> && rawData['data'] is List) {
            final list = rawData['data'] as List;
            if (list.isNotEmpty) {
              final userData = list.first as Map<String, dynamic>;
              fetchedIps = userData['ips']?.toString();
              debugPrint(
                '[UserInfoDebug] Fetched IPS from fetch API: $fetchedIps',
              );
            }
          }
        }
      }

      final response = await _api.getUserInfoById(userId);

      debugPrint('[UserInfoDebug] Response success: ${response.success}');
      debugPrint('[UserInfoDebug] Response code: ${response.statusCode}');

      if (response.success) {
        final adminData = response.getData<Map<String, dynamic>>();
        debugPrint('[UserInfoDebug] Admin Data received: $adminData');

        if (adminData != null) {
          // 尝试从 last_login_ip 获取，如果为空则尝试从 ips 字段解析
          String? ip = adminData['last_login_ip'];
          if (ip == null || ip.isEmpty) {
            // 优先使用 fetch API 返回的 ips
            final ips = fetchedIps ?? adminData['ips'];
            if (ips != null && ips is String && ips.isNotEmpty) {
              // ips 格式通常为 "IP_serverName, IP2_serverName2"，尝试提取第一个
              ip = ips.split(',').first.split('_').first.trim();
            }
          }

          final isAdmin = adminData['is_admin'];
          debugPrint('[UserInfoDebug] Extracted IP: $ip');
          debugPrint('[UserInfoDebug] Extracted IsAdmin: $isAdmin');

          // 合并数据
          final Map<String, dynamic> merged = _user!.toJson();
          merged.addAll(adminData);
          // 确保 ID 被修正
          merged['id'] = userId;
          // 手动修正 IP，确保本地模型显示正确
          if (ip != null && ip.isNotEmpty) {
            merged['last_login_ip'] = ip;
          }

          // 更新用户信息
          _user = UserInfo.fromJson(merged);
          debugPrint(
            '[UserInfoDebug] User info updated. New IP: ${_user!.lastLoginIp}',
          );
        } else {
          debugPrint('[UserInfoDebug] Admin Data is null');
        }
      } else {
        debugPrint('[UserInfoDebug] Fetch failed: ${response.getMessage()}');
      }
    } catch (e, s) {
      debugPrint('[UserInfoDebug] Exception during fetch: $e');
      debugPrint('[UserInfoDebug] Stack: $s');
      // 失败不影响主流程，使用已有数据
    }
  }
}
