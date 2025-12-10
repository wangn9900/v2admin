/// 登录响应数据模型
class AuthData {
  final String token;
  final int isAdmin;
  final String authData;

  AuthData({
    required this.token,
    required this.isAdmin,
    required this.authData,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] ?? '',
      isAdmin: json['is_admin'] ?? 0,
      authData: json['auth_data'] ?? '',
    );
  }

  bool get isAdminUser => isAdmin == 1;

  Map<String, dynamic> toJson() {
    return {'token': token, 'is_admin': isAdmin, 'auth_data': authData};
  }
}

/// 用户信息模型
class UserInfo {
  final int id;
  final String email;
  final int? inviteUserId;
  final String? telegram;
  final int? transferEnable;
  final int? deviceLimit;
  final int u; // 上传流量
  final int d; // 下载流量
  final int balance;
  final int commissionBalance;
  final int? planId;
  final int? speedLimit;
  final int? discount;
  final int? commissionType;
  final double? commissionRate;
  final int? expiredAt;
  final int? lastLoginAt;
  final String? lastLoginIp;
  final bool banned;
  final bool isAdmin;
  final bool isStaff;
  final String? remarks;
  final String? planName;
  final int aliveIp;
  final String? subscribeUrl;
  final int createdAt;
  final int updatedAt;

  UserInfo({
    required this.id,
    required this.email,
    this.inviteUserId,
    this.telegram,
    this.transferEnable,
    this.deviceLimit,
    this.u = 0,
    this.d = 0,
    this.balance = 0,
    this.commissionBalance = 0,
    this.planId,
    this.speedLimit,
    this.discount,
    this.commissionType,
    this.commissionRate,
    this.expiredAt,
    this.lastLoginAt,
    this.lastLoginIp,
    this.banned = false,
    this.isAdmin = false,
    this.isStaff = false,
    this.remarks,
    this.planName,
    this.aliveIp = 0,
    this.subscribeUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      inviteUserId: json['invite_user_id'],
      telegram: json['telegram_id']?.toString(),
      transferEnable: json['transfer_enable'],
      deviceLimit: json['device_limit'],
      u: json['u'] ?? 0,
      d: json['d'] ?? 0,
      balance: json['balance'] ?? 0,
      commissionBalance: json['commission_balance'] ?? 0,
      planId: json['plan_id'],
      speedLimit: json['speed_limit'],
      discount: json['discount'],
      commissionType: json['commission_type'],
      commissionRate: json['commission_rate']?.toDouble(),
      expiredAt: json['expired_at'],
      lastLoginAt: json['last_login_at'],
      lastLoginIp: json['last_login_ip'],
      banned: json['banned'] == 1 || json['banned'] == true,
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
      isStaff: json['is_staff'] == 1 || json['is_staff'] == true,
      remarks: json['remarks'],
      planName: json['plan_name'],
      aliveIp: json['alive_ip'] ?? 0,
      subscribeUrl: json['subscribe_url'],
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }

  /// 总流量使用 (bytes)
  int get totalUsed => u + d;

  /// 剩余流量 (bytes)
  int get remainingTraffic => (transferEnable ?? 0) - totalUsed;

  /// 流量使用百分比
  double get usagePercent {
    if (transferEnable == null || transferEnable == 0) return 0;
    return (totalUsed / transferEnable!) * 100;
  }

  /// 格式化流量为可读字符串
  String formatTraffic(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// 格式化余额 (分 -> 元)
  String get formattedBalance => (balance / 100).toStringAsFixed(2);

  /// 格式化佣金余额 (分 -> 元)
  String get formattedCommission =>
      (commissionBalance / 100).toStringAsFixed(2);

  /// 是否已过期
  bool get isExpired {
    if (expiredAt == null) return false;
    return expiredAt! < DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'invite_user_id': inviteUserId,
      'telegram_id': telegram,
      'transfer_enable': transferEnable,
      'device_limit': deviceLimit,
      'u': u,
      'd': d,
      'balance': balance,
      'commission_balance': commissionBalance,
      'plan_id': planId,
      'discount': discount,
      'commission_rate': commissionRate,
      'expired_at': expiredAt,
      'last_login_at': lastLoginAt,
      'banned': banned ? 1 : 0,
      'is_admin': isAdmin ? 1 : 0,
      'is_staff': isStaff ? 1 : 0,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
