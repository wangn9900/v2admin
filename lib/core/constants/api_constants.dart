/// V2Board API 常量定义
class ApiConstants {
  ApiConstants._();

  /// API 基础路径
  static const String apiPrefix = '/api/v1';

  /// 默认请求超时时间 (秒)
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // ============ Passport (认证) ============

  /// 登录
  static const String login = '$apiPrefix/passport/auth/login';

  /// 注册
  static const String register = '$apiPrefix/passport/auth/register';

  /// 忘记密码
  static const String forget = '$apiPrefix/passport/auth/forget';

  /// 发送邮箱验证码
  static const String sendEmailVerify =
      '$apiPrefix/passport/comm/sendEmailVerify';

  // ============ User (用户端) ============

  /// 获取用户信息
  static const String userInfo = '$apiPrefix/user/info';

  /// 获取订阅信息
  static const String userSubscribe = '$apiPrefix/user/getSubscribe';

  /// 检查登录状态
  static const String checkLogin = '$apiPrefix/user/checkLogin';

  // ============ Admin (管理端) - 需要拼接 securePath ============

  /// 系统配置
  static const String adminConfigFetch = '/config/fetch';
  static const String adminConfigSave = '/config/save';

  /// 统计数据
  static const String adminStatOverride = '/stat/getOverride';
  static const String adminStatOrder = '/stat/getOrder';
  static const String adminStatServerLastRank = '/stat/getServerLastRank';
  static const String adminStatServerTodayRank = '/stat/getServerTodayRank';
  static const String adminStatUserLastRank = '/stat/getUserLastRank';
  static const String adminStatUserTodayRank = '/stat/getUserTodayRank';
  static const String adminStatUser = '/stat/getStatUser';

  /// 用户管理
  static const String adminUserFetch = '/user/fetch';
  static const String adminUserUpdate = '/user/update';
  static const String adminUserInfo = '/user/getUserInfoById';
  static const String adminUserGenerate = '/user/generate';
  static const String adminUserBan = '/user/ban';
  static const String adminUserDelete = '/user/delUser';
  static const String adminUserSendMail = '/user/sendMail';
  static const String adminUserResetSecret = '/user/resetSecret';

  /// 订单管理
  static const String adminOrderFetch = '/order/fetch';
  static const String adminOrderDetail = '/order/detail';
  static const String adminOrderPaid = '/order/paid';
  static const String adminOrderCancel = '/order/cancel';
  static const String adminOrderUpdate = '/order/update';
  static const String adminOrderAssign = '/order/assign';

  /// 套餐管理
  static const String adminPlanFetch = '/plan/fetch';
  static const String adminPlanSave = '/plan/save';
  static const String adminPlanUpdate = '/plan/update';
  static const String adminPlanDrop = '/plan/drop';
  static const String adminPlanSort = '/plan/sort';

  /// 服务器管理
  static const String adminServerGroupFetch = '/server/group/fetch';
  static const String adminServerGroupSave = '/server/group/save';
  static const String adminServerGroupDrop = '/server/group/drop';
  static const String adminServerNodes = '/server/manage/getNodes';
  static const String adminServerSort = '/server/manage/sort';

  /// 公告管理
  static const String adminNoticeFetch = '/notice/fetch';
  static const String adminNoticeSave = '/notice/save';
  static const String adminNoticeUpdate = '/notice/update';
  static const String adminNoticeDrop = '/notice/drop';

  /// 工单管理
  static const String adminTicketFetch = '/ticket/fetch';
  static const String adminTicketReply = '/ticket/reply';
  static const String adminTicketClose = '/ticket/close';

  /// 优惠券管理
  static const String adminCouponFetch = '/coupon/fetch';
  static const String adminCouponGenerate = '/coupon/generate';
  static const String adminCouponDrop = '/coupon/drop';

  /// 礼品卡管理
  static const String adminGiftcardFetch = '/giftcard/fetch';
  static const String adminGiftcardGenerate = '/giftcard/generate';
  static const String adminGiftcardDrop = '/giftcard/drop';

  /// 知识库管理
  static const String adminKnowledgeFetch = '/knowledge/fetch';
  static const String adminKnowledgeCategory = '/knowledge/getCategory';
  static const String adminKnowledgeSave = '/knowledge/save';
  static const String adminKnowledgeShow = '/knowledge/show';
  static const String adminKnowledgeSort = '/knowledge/sort';
  static const String adminKnowledgeDrop = '/knowledge/drop';

  /// 支付管理
  static const String adminPaymentFetch = '/payment/fetch';
  static const String adminPaymentMethods = '/payment/getPaymentMethods';
  static const String adminPaymentSave = '/payment/save';
  static const String adminPaymentDrop = '/payment/drop';

  /// 系统状态
  static const String adminSystemStatus = '/system/getSystemStatus';
  static const String adminSystemLog = '/system/getSystemLog';
  static const String adminQueueStats = '/system/getQueueStats';
  static const String adminQueueWorkload = '/system/getQueueWorkload';
}

/// 订单状态
class OrderStatus {
  static const int pending = 0; // 待支付
  static const int paid = 1; // 开通中
  static const int cancelled = 2; // 已取消
  static const int completed = 3; // 已完成
  static const int refunded = 4; // 已折抵

  static String getName(int status) {
    switch (status) {
      case pending:
        return '待支付';
      case paid:
        return '开通中';
      case cancelled:
        return '已取消';
      case completed:
        return '已完成';
      case refunded:
        return '已折抵';
      default:
        return '未知';
    }
  }
}

/// 订单类型
class OrderType {
  static const int newOrder = 1; // 新购
  static const int renewal = 2; // 续费
  static const int upgrade = 3; // 升级
  static const int resetTraffic = 4; // 流量重置

  static String getName(int type) {
    switch (type) {
      case newOrder:
        return '新购';
      case renewal:
        return '续费';
      case upgrade:
        return '升级';
      case resetTraffic:
        return '流量重置';
      default:
        return '未知';
    }
  }
}
