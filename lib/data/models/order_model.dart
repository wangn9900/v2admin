import '../../core/constants/api_constants.dart';

/// 订单数据模型
class OrderModel {
  final int id;
  final int userId;
  final int? planId;
  final String? planName;
  final String period;
  final String tradeNo;
  final String? callbackNo;
  final int totalAmount;
  final int? discountAmount;
  final int? surplusAmount;
  final int? refundAmount;
  final int? balance_payment;
  final int status;
  final int type;
  final int? paidAt;
  final int? commissionStatus;
  final int? commissionBalance;
  final int? inviteUserId;
  final int createdAt;
  final int updatedAt;
  
  OrderModel({
    required this.id,
    required this.userId,
    this.planId,
    this.planName,
    required this.period,
    required this.tradeNo,
    this.callbackNo,
    required this.totalAmount,
    this.discountAmount,
    this.surplusAmount,
    this.refundAmount,
    this.balance_payment,
    required this.status,
    required this.type,
    this.paidAt,
    this.commissionStatus,
    this.commissionBalance,
    this.inviteUserId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      planId: json['plan_id'],
      planName: json['plan_name'],
      period: json['period'] ?? '',
      tradeNo: json['trade_no'] ?? '',
      callbackNo: json['callback_no'],
      totalAmount: json['total_amount'] ?? 0,
      discountAmount: json['discount_amount'],
      surplusAmount: json['surplus_amount'],
      refundAmount: json['refund_amount'],
      balance_payment: json['balance_payment'],
      status: json['status'] ?? 0,
      type: json['type'] ?? 1,
      paidAt: json['paid_at'],
      commissionStatus: json['commission_status'],
      commissionBalance: json['commission_balance'],
      inviteUserId: json['invite_user_id'],
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }
  
  /// 格式化金额 (分 -> 元)
  String get formattedAmount => (totalAmount / 100).toStringAsFixed(2);
  
  /// 状态名称
  String get statusName => OrderStatus.getName(status);
  
  /// 订单类型名称
  String get typeName => OrderType.getName(type);
  
  /// 周期名称
  String get periodName {
    switch (period) {
      case 'month_price': return '月付';
      case 'quarter_price': return '季付';
      case 'half_year_price': return '半年付';
      case 'year_price': return '年付';
      case 'two_year_price': return '两年付';
      case 'three_year_price': return '三年付';
      case 'onetime_price': return '一次性';
      case 'reset_price': return '流量重置';
      case 'deposit': return '充值';
      default: return period;
    }
  }
  
  /// 是否为待支付订单
  bool get isPending => status == OrderStatus.pending;
  
  /// 是否可取消
  bool get canCancel => status == OrderStatus.pending;
  
  /// 是否可标记为已支付
  bool get canMarkPaid => status == OrderStatus.pending;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan_name': planName,
      'period': period,
      'trade_no': tradeNo,
      'callback_no': callbackNo,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'surplus_amount': surplusAmount,
      'refund_amount': refundAmount,
      'balance_payment': balance_payment,
      'status': status,
      'type': type,
      'paid_at': paidAt,
      'commission_status': commissionStatus,
      'commission_balance': commissionBalance,
      'invite_user_id': inviteUserId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

/// 订单列表响应
class OrderListResponse {
  final List<OrderModel> orders;
  final int total;
  
  OrderListResponse({
    required this.orders,
    required this.total,
  });
  
  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] ?? [];
    return OrderListResponse(
      orders: dataList.map((e) => OrderModel.fromJson(e)).toList(),
      total: json['total'] ?? 0,
    );
  }
}
