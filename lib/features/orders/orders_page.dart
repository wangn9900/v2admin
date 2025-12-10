import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/order_model.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 订单管理页面
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalOrders = 0;
  final int _pageSize = 15;
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService.instance;

      List<Map<String, dynamic>>? filter;
      if (_selectedStatus != null) {
        filter = [
          {'key': 'status', 'condition': '=', 'value': _selectedStatus},
        ];
      }

      final response = await api.fetchOrders(
        current: _currentPage,
        pageSize: _pageSize,
        filter: filter,
      );

      if (mounted) {
        if (response.success) {
          final List<dynamic> dataList = response.data['data'] ?? [];
          setState(() {
            _orders = dataList.map((e) => OrderModel.fromJson(e)).toList();
            _totalOrders = response.data['total'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.getMessage();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '订单管理',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 $_totalOrders 个订单',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // 状态筛选
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('全部', null),
                  _buildFilterChip('待支付', OrderStatus.pending),
                  _buildFilterChip('开通中', OrderStatus.paid),
                  _buildFilterChip('已完成', OrderStatus.completed),
                  _buildFilterChip('已取消', OrderStatus.cancelled),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 订单列表
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: '加载中...')
                : _error != null
                ? _buildErrorState()
                : _orders.isEmpty
                ? const EmptyState(
                    title: '暂无订单',
                    subtitle: '没有找到匹配的订单',
                    icon: LucideIcons.shoppingCart,
                  )
                : _buildOrderList(),
          ),

          // 分页控制
          if (!_isLoading && _orders.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? status) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
            _currentPage = 1;
          });
          _loadOrders();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return EmptyState(
      title: '加载失败',
      subtitle: _error,
      icon: LucideIcons.alertCircle,
      action: GradientButton(text: '重试', onPressed: _loadOrders, width: 120),
    );
  }

  Widget _buildOrderList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order, isDark);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showOrderDetail(order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.tradeNo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.planName ?? '套餐 #${order.planId ?? "未知"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildOrderInfoItem(
                icon: LucideIcons.user,
                label: '用户 ID',
                value: order.userId.toString(),
              ),
              const SizedBox(width: 24),
              _buildOrderInfoItem(
                icon: LucideIcons.tag,
                label: '类型',
                value: order.typeName,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${order.formattedAmount}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    order.periodName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 14,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(order.createdAt * 1000),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const Spacer(),
              if (order.canMarkPaid || order.canCancel)
                Row(
                  children: [
                    if (order.canMarkPaid)
                      TextButton.icon(
                        onPressed: () => _markPaid(order),
                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                        label: const Text('确认支付'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                        ),
                      ),
                    if (order.canCancel)
                      TextButton.icon(
                        onPressed: () => _cancelOrder(order),
                        icon: const Icon(LucideIcons.xCircle, size: 16),
                        label: const Text('取消'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int status) {
    switch (status) {
      case OrderStatus.pending:
        return StatusBadge.warning('待支付');
      case OrderStatus.paid:
        return StatusBadge.info('开通中');
      case OrderStatus.completed:
        return StatusBadge.success('已完成');
      case OrderStatus.cancelled:
        return StatusBadge.error('已取消');
      case OrderStatus.refunded:
        return const StatusBadge(text: '已折抵', color: AppColors.accent);
      default:
        return const StatusBadge(text: '未知', color: Colors.grey);
    }
  }

  Widget _buildPagination() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPages = (_totalOrders / _pageSize).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '第 $_currentPage / $totalPages 页',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadOrders();
                      }
                    : null,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              IconButton(
                onPressed: _currentPage < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadOrders();
                      }
                    : null,
                icon: const Icon(LucideIcons.chevronRight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(OrderModel order) {
    // TODO: 显示订单详情
  }

  Future<void> _markPaid(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认支付'),
        content: Text('确定要将订单 ${order.tradeNo} 标记为已支付吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.instance.markOrderPaid(order.tradeNo);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('订单已标记为已支付'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.getMessage()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消订单'),
        content: Text('确定要取消订单 ${order.tradeNo} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认取消', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.instance.cancelOrder(order.tradeNo);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('订单已取消'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.getMessage()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
