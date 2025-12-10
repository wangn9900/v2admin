import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

/// V2Board API 服务
/// 负责所有与后端的 HTTP 通信
class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  bool _isDioInitialized = false;

  String? _baseUrl;
  String? _securePath;
  String? _authData;

  ApiService._();

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// 初始化 API 服务
  Future<void> init({
    required String baseUrl,
    String? securePath,
    String? authData,
  }) async {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _securePath = securePath;
    _authData = authData;

    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl!,
        connectTimeout: const Duration(seconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(seconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _isDioInitialized = true;

    // 添加拦截器
    _dio.interceptors.add(_buildInterceptor());

    // if (kDebugMode) {
    //   _dio.interceptors.add(
    //     LogInterceptor(requestBody: true, responseBody: true, error: true),
    //   );
    // }

    // 加载并应用代理设置
    await _loadProxy();
  }

  /// 获取当前公网 IP（通过外部服务）
  /// 用于验证代理是否生效
  Future<String?> getCurrentPublicIp() async {
    if (!_isDioInitialized) return null;

    try {
      // 使用 ipify 服务获取当前公网 IP
      // 这个请求会走代理（如果设置了的话），所以返回的是代理出口 IP
      final response = await _dio.get(
        'https://api.ipify.org',
        queryParameters: {'format': 'text'},
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final ip = response.data.toString().trim();
        debugPrint('[IPCheck] Current public IP: $ip');
        return ip;
      }
    } catch (e) {
      debugPrint('[IPCheck] Failed to get public IP: $e');
      // 备用服务
      try {
        final response = await _dio.get(
          'https://checkip.amazonaws.com',
          options: Options(
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );
        if (response.statusCode == 200 && response.data != null) {
          final ip = response.data.toString().trim();
          debugPrint('[IPCheck] Current public IP (backup): $ip');
          return ip;
        }
      } catch (e2) {
        debugPrint('[IPCheck] Backup IP check also failed: $e2');
      }
    }
    return null;
  }

  /// 更新认证数据
  void updateAuthData(String? authData) {
    _authData = authData;
  }

  /// 更新安全路径
  void updateSecurePath(String? securePath) {
    _securePath = securePath;
  }

  /// 更新基础 URL
  Future<void> updateBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _dio.options.baseUrl = _baseUrl!;
  }

  /// 设置代理
  Future<void> setProxy(String host, String port, bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proxy_host', host);
    await prefs.setString('proxy_port', port);
    await prefs.setBool('proxy_enable', enable);

    _applyProxy(host, port, enable);
  }

  /// 加载代理设置
  Future<void> _loadProxy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('proxy_host') ?? '';
      final port = prefs.getString('proxy_port') ?? '';
      final enable = prefs.getBool('proxy_enable') ?? false;

      _applyProxy(host, port, enable);
    } catch (e) {
      debugPrint('Failed to load proxy settings: $e');
    }
  }

  /// 应用代理到 Dio
  void _applyProxy(String host, String port, bool enable) {
    if (!_isDioInitialized) return;

    if (!enable || host.isEmpty || port.isEmpty) {
      _dio.httpClientAdapter = IOHttpClientAdapter();
      return;
    }

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY $host:$port';
        };
        // 允许自签名证书（如果代理也是 HTTPS 的话，通常不需要，但也为了以防万一）
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
  }

  /// 构建请求拦截器
  Interceptor _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // 添加认证头
        if (_authData != null && _authData!.isNotEmpty) {
          options.headers['Authorization'] = _authData;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    );
  }

  /// 获取管理员 API 的完整路径
  String _getAdminPath(String endpoint) {
    if (_securePath == null || _securePath!.isEmpty) {
      throw Exception('Security path not configured');
    }
    // 管理员 API 格式: /api/v1/{securePath}/{endpoint}
    return '/api/v1/$_securePath$endpoint';
  }

  // ============ 通用请求方法 ============

  /// GET 请求
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool isAdmin = false,
  }) async {
    try {
      final actualPath = isAdmin ? _getAdminPath(path) : path;
      final response = await _dio.get(
        actualPath,
        queryParameters: queryParameters,
      );
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// POST 请求
  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool isAdmin = false,
  }) async {
    try {
      final actualPath = isAdmin ? _getAdminPath(path) : path;
      final response = await _dio.post(
        actualPath,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// 处理 Dio 错误
  ApiResponse _handleDioError(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = '连接超时，请检查网络';
        break;
      case DioExceptionType.sendTimeout:
        message = '发送超时，请重试';
        break;
      case DioExceptionType.receiveTimeout:
        message = '接收超时，请重试';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 403) {
          message = '未登录或登录已过期';
        } else if (statusCode == 500) {
          // 尝试从响应中提取错误信息
          if (responseData is Map && responseData['message'] != null) {
            message = responseData['message'].toString();
          } else if (responseData is String) {
            message = responseData;
          } else {
            message = '服务器内部错误';
          }
        } else {
          message = '请求失败 ($statusCode)';
        }
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        message = '连接失败，请检查网络';
        break;
      default:
        message = e.message ?? '未知错误';
    }

    return ApiResponse.error(message, statusCode: e.response?.statusCode);
  }

  // ============ 认证相关 API ============

  /// 登录
  Future<ApiResponse> login(String email, String password) async {
    return post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
  }

  /// 获取用户信息
  Future<ApiResponse> getUserInfo() async {
    return get(ApiConstants.userInfo);
  }

  // ============ 管理员统计 API ============

  /// 获取统计概览
  Future<ApiResponse> getStatOverride() async {
    return get(ApiConstants.adminStatOverride, isAdmin: true);
  }

  /// 获取订单统计
  Future<ApiResponse> getStatOrder() async {
    return get(ApiConstants.adminStatOrder, isAdmin: true);
  }

  /// 获取服务器排行 (昨日)
  Future<ApiResponse> getServerLastRank() async {
    return get(ApiConstants.adminStatServerLastRank, isAdmin: true);
  }

  /// 获取用户排行 (今日)
  Future<ApiResponse> getUserTodayRank() async {
    return get(ApiConstants.adminStatUserTodayRank, isAdmin: true);
  }

  // ============ 用户管理 API ============

  /// 获取用户列表
  Future<ApiResponse> fetchUsers({
    int current = 1,
    int pageSize = 15,
    List<Map<String, dynamic>>? filter,
  }) async {
    return get(
      ApiConstants.adminUserFetch,
      queryParameters: {
        'current': current,
        'pageSize': pageSize,
        if (filter != null) 'filter': filter,
      },
      isAdmin: true,
    );
  }

  /// 获取用户详情
  Future<ApiResponse> getUserInfoById(int id) async {
    return get(
      ApiConstants.adminUserInfo,
      queryParameters: {'id': id},
      isAdmin: true,
    );
  }

  /// 更新用户信息
  Future<ApiResponse> updateUser(Map<String, dynamic> data) async {
    return post(ApiConstants.adminUserUpdate, data: data, isAdmin: true);
  }

  /// 封禁/解封用户
  Future<ApiResponse> banUser(int id) async {
    return post(ApiConstants.adminUserBan, data: {'id': id}, isAdmin: true);
  }

  /// 重置订阅信息
  Future<ApiResponse> resetUserSecret(int id) async {
    return post(
      ApiConstants.adminUserResetSecret,
      data: {'id': id},
      isAdmin: true,
    );
  }

  /// 删除用户
  Future<ApiResponse> deleteUser(int id) async {
    return post(ApiConstants.adminUserDelete, data: {'id': id}, isAdmin: true);
  }

  // ============ 订单管理 API ============

  /// 获取订单列表
  Future<ApiResponse> fetchOrders({
    int current = 1,
    int pageSize = 15,
    List<Map<String, dynamic>>? filter,
  }) async {
    return get(
      ApiConstants.adminOrderFetch,
      queryParameters: {
        'current': current,
        'pageSize': pageSize,
        if (filter != null) 'filter': filter,
      },
      isAdmin: true,
    );
  }

  /// 获取订单详情
  Future<ApiResponse> getOrderDetail(int id) async {
    return post(ApiConstants.adminOrderDetail, data: {'id': id}, isAdmin: true);
  }

  /// 手动标记订单为已支付
  Future<ApiResponse> markOrderPaid(String tradeNo) async {
    return post(
      ApiConstants.adminOrderPaid,
      data: {'trade_no': tradeNo},
      isAdmin: true,
    );
  }

  /// 取消订单
  Future<ApiResponse> cancelOrder(String tradeNo) async {
    return post(
      ApiConstants.adminOrderCancel,
      data: {'trade_no': tradeNo},
      isAdmin: true,
    );
  }

  // ============ 服务器管理 API ============

  /// 获取节点列表
  Future<ApiResponse> getServerNodes() async {
    return get(ApiConstants.adminServerNodes, isAdmin: true);
  }

  /// 获取服务器分组
  Future<ApiResponse> getServerGroups() async {
    return get(ApiConstants.adminServerGroupFetch, isAdmin: true);
  }

  // ============ 工单管理 API ============

  /// 获取工单列表
  Future<ApiResponse> fetchTickets() async {
    return get(ApiConstants.adminTicketFetch, isAdmin: true);
  }

  /// 回复工单
  Future<ApiResponse> replyTicket(int id, String message) async {
    return post(
      ApiConstants.adminTicketReply,
      data: {'id': id, 'message': message},
      isAdmin: true,
    );
  }

  /// 关闭工单
  Future<ApiResponse> closeTicket(int id) async {
    return post(ApiConstants.adminTicketClose, data: {'id': id}, isAdmin: true);
  }

  // ============ 系统管理 API ============

  /// 获取系统状态
  Future<ApiResponse> getSystemStatus() async {
    return get(ApiConstants.adminSystemStatus, isAdmin: true);
  }

  /// 获取系统配置
  Future<ApiResponse> getConfig() async {
    return get(ApiConstants.adminConfigFetch, isAdmin: true);
  }

  /// 保存系统配置
  Future<ApiResponse> saveConfig(Map<String, dynamic> config) async {
    return post(ApiConstants.adminConfigSave, data: config, isAdmin: true);
  }
}

/// API 响应包装类
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse(success: true, data: data);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  /// 获取 data 字段中的数据
  T? getData<T>() {
    if (data is Map && data['data'] != null) {
      return data['data'] as T;
    }
    return data as T?;
  }

  /// 获取消息
  String getMessage() {
    if (message != null) return message!;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return '';
  }
}
