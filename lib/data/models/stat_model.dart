/// 统计概览数据模型
class StatOverview {
  final int onlineUser; // 在线人数
  final int monthIncome; // 本月收入 (分)
  final int monthRegisterTotal; // 本月注册总数
  final int dayRegisterTotal; // 今日注册
  final int ticketPendingTotal; // 待处理工单
  final int commissionPendingTotal; // 待结算佣金
  final int dayIncome; // 今日收入 (分)
  final int lastMonthIncome; // 上月收入 (分)
  final int commissionMonthPayout; // 本月佣金支出
  final int commissionLastMonthPayout; // 上月佣金支出

  StatOverview({
    this.onlineUser = 0,
    this.monthIncome = 0,
    this.monthRegisterTotal = 0,
    this.dayRegisterTotal = 0,
    this.ticketPendingTotal = 0,
    this.commissionPendingTotal = 0,
    this.dayIncome = 0,
    this.lastMonthIncome = 0,
    this.commissionMonthPayout = 0,
    this.commissionLastMonthPayout = 0,
  });

  factory StatOverview.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StatOverview();

    final data = json['data'] ?? json;
    return StatOverview(
      onlineUser: _parseInt(data['online_user']),
      monthIncome: _parseInt(data['month_income']),
      monthRegisterTotal: _parseInt(data['month_register_total']),
      dayRegisterTotal: _parseInt(data['day_register_total']),
      ticketPendingTotal: _parseInt(data['ticket_pending_total']),
      commissionPendingTotal: _parseInt(data['commission_pending_total']),
      dayIncome: _parseInt(data['day_income']),
      lastMonthIncome: _parseInt(data['last_month_income']),
      commissionMonthPayout: _parseInt(data['commission_month_payout']),
      commissionLastMonthPayout: _parseInt(
        data['commission_last_month_payout'],
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 格式化金额 (分 -> 元)
  String formatAmount(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  /// 今日收入格式化
  String get formattedDayIncome => formatAmount(dayIncome);

  /// 本月收入格式化
  String get formattedMonthIncome => formatAmount(monthIncome);

  /// 上月收入格式化
  String get formattedLastMonthIncome => formatAmount(lastMonthIncome);
}

/// 订单统计数据
class OrderStat {
  final String date;
  final int count;
  final int amount;

  OrderStat({required this.date, required this.count, required this.amount});

  factory OrderStat.fromJson(Map<String, dynamic> json) {
    return OrderStat(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      amount: json['amount'] ?? 0,
    );
  }

  String get formattedAmount => (amount / 100).toStringAsFixed(2);
}

/// 服务器排行数据
class ServerRank {
  final int? serverId;
  final String serverName;
  final String
  serverType; // 类型是字符串: trojan, shadowsocks, vless, hysteria, anytls
  final int u; // 上传流量 (字节)
  final int d; // 下载流量 (字节)
  final double total; // 总流量 (GB，API 返回的)

  ServerRank({
    this.serverId,
    required this.serverName,
    required this.serverType,
    this.u = 0,
    this.d = 0,
    this.total = 0,
  });

  factory ServerRank.fromJson(Map<String, dynamic> json) {
    return ServerRank(
      serverId: json['server_id'],
      serverName: json['server_name'] ?? 'Unknown',
      serverType: json['server_type']?.toString() ?? 'unknown',
      u: _parseInt(json['u']),
      d: _parseInt(json['d']),
      total: _parseDouble(json['total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// 格式化流量 (API 返回的 total 已经是 GB)
  String get formattedTotal => '${total.toStringAsFixed(2)} GB';
  String get formattedUpload => _formatBytes(u);
  String get formattedDownload => _formatBytes(d);

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  /// 服务器类型名称
  String get typeName {
    switch (serverType.toLowerCase()) {
      case 'shadowsocks':
        return 'Shadowsocks';
      case 'vmess':
        return 'VMess';
      case 'trojan':
        return 'Trojan';
      case 'vless':
        return 'VLESS';
      case 'hysteria':
        return 'Hysteria';
      case 'tuic':
        return 'TUIC';
      case 'anytls':
        return 'AnyTLS';
      default:
        return serverType;
    }
  }
}

/// 用户排行数据
class UserRank {
  final int userId;
  final String? email;
  final int u;
  final int d;
  final double total; // 总流量 (GB)

  UserRank({
    required this.userId,
    this.email,
    this.u = 0,
    this.d = 0,
    this.total = 0,
  });

  factory UserRank.fromJson(Map<String, dynamic> json) {
    return UserRank(
      userId: _parseInt(json['user_id']),
      email: json['email'],
      u: _parseInt(json['u']),
      d: _parseInt(json['d']),
      total: _parseDouble(json['total']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// 格式化流量
  String get formattedTotal => '${total.toStringAsFixed(2)} GB';

  /// 隐藏部分邮箱
  String get maskedEmail {
    if (email == null || email!.isEmpty) return 'Unknown';
    final parts = email!.split('@');
    if (parts.length != 2) return email!;

    final local = parts[0];
    final domain = parts[1];

    if (local.length <= 3) {
      return '${local[0]}***@$domain';
    }
    return '${local.substring(0, 3)}***@$domain';
  }
}
