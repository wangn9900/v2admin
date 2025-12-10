import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 优惠券管理页面
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  List<dynamic> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.get(
        '/coupon/fetch',
        isAdmin: true,
      );
      if (mounted) {
        setState(() {
          if (response.success) {
            _coupons = response.getData<List>() ?? [];
          } else {
            _error = response.getMessage();
          }
          _isLoading = false;
        });
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '优惠券管理',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '管理优惠券和折扣码',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  text: '添加优惠券',
                  icon: LucideIcons.plus,
                  onPressed: () => _showCouponFormDialog(null),
                  width: 130,
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadData,
                  icon: Icon(
                    LucideIcons.refreshCw,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: '加载中...')
                : _error != null
                ? EmptyState(
                    title: '加载失败',
                    subtitle: _error,
                    icon: LucideIcons.alertCircle,
                    action: GradientButton(
                      text: '重试',
                      onPressed: _loadData,
                      width: 120,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _coupons.isEmpty
                        ? const EmptyState(
                            title: '暂无优惠券',
                            subtitle: '点击右上角添加优惠券按钮创建新优惠券',
                            icon: LucideIcons.ticket,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _coupons.length,
                            itemBuilder: (context, index) =>
                                _buildCouponCard(_coupons[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(dynamic coupon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = coupon['id'];
    final code = coupon['code'] ?? '';
    final name = coupon['name'] ?? '优惠券';
    final type = coupon['type'] ?? 1;
    final value = coupon['value'] ?? 0;
    final limitUse = coupon['limit_use'] ?? 0;
    final limitUseWithUser = coupon['limit_use_with_user'] ?? 0;
    final startTime = coupon['started_at'];
    final endTime = coupon['ended_at'];

    String valueText;
    if (type == 1) {
      valueText = '¥${(value / 100).toStringAsFixed(2)}';
    } else {
      valueText = '$value% 折扣';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.ticket,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$id',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      valueText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      type == 1 ? '固定金额' : '百分比折扣',
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
                StatusBadge(text: '限用 $limitUse 次', color: AppColors.info),
                const SizedBox(width: 8),
                StatusBadge(
                  text: '每用户 $limitUseWithUser 次',
                  color: AppColors.warning,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showCouponFormDialog(coupon),
                  icon: Icon(
                    LucideIcons.edit2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirm(coupon),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.error,
                  ),
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponFormDialog(dynamic coupon) {
    final isEdit = coupon != null;

    final nameController = TextEditingController(text: coupon?['name'] ?? '');
    final codeController = TextEditingController(text: coupon?['code'] ?? '');
    final valueController = TextEditingController(
      text: coupon != null
          ? (coupon['type'] == 1
                ? (coupon['value'] / 100).toString()
                : coupon['value'].toString())
          : '',
    );
    final limitUseController = TextEditingController(
      text: (coupon?['limit_use'] ?? 0).toString(),
    );
    final limitUseWithUserController = TextEditingController(
      text: (coupon?['limit_use_with_user'] ?? 1).toString(),
    );

    int type = coupon?['type'] ?? 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑优惠券' : '添加优惠券'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '优惠券名称',
                      hintText: '如：新用户优惠',
                      prefixIcon: Icon(LucideIcons.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: '优惠码',
                      hintText: '如：NEWYEAR2024',
                      prefixIcon: Icon(LucideIcons.ticket),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: '优惠类型',
                      prefixIcon: Icon(LucideIcons.percent),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('固定金额')),
                      DropdownMenuItem(value: 2, child: Text('百分比折扣')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => type = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 1 ? '优惠金额 (元)' : '折扣百分比',
                      hintText: type == 1 ? '如: 10' : '如: 20 表示 20% 折扣',
                      prefixIcon: Icon(
                        type == 1
                            ? LucideIcons.dollarSign
                            : LucideIcons.percent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: limitUseController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '使用次数限制',
                            hintText: '0 表示无限制',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: limitUseWithUserController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '每用户限制',
                            hintText: '0 表示无限制',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    codeController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请填写名称和优惠码')));
                  return;
                }

                Navigator.pop(context);

                int value;
                if (type == 1) {
                  value = ((double.tryParse(valueController.text) ?? 0) * 100)
                      .toInt();
                } else {
                  value = int.tryParse(valueController.text) ?? 0;
                }

                final data = {
                  if (isEdit) 'id': coupon['id'],
                  'name': nameController.text,
                  'code': codeController.text,
                  'type': type,
                  'value': value,
                  'limit_use': int.tryParse(limitUseController.text) ?? 0,
                  'limit_use_with_user':
                      int.tryParse(limitUseWithUserController.text) ?? 1,
                };

                try {
                  final response = await ApiService.instance.post(
                    isEdit ? '/coupon/update' : '/coupon/save',
                    data: data,
                    isAdmin: true,
                  );

                  if (mounted) {
                    if (response.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? '保存成功' : '创建成功'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _loadData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response.getMessage()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('操作失败: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(isEdit ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(dynamic coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除优惠券 "${coupon['name']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await ApiService.instance.post(
                  '/coupon/drop',
                  data: {'id': coupon['id']},
                  isAdmin: true,
                );

                if (mounted) {
                  if (response.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('删除成功'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.getMessage()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除失败: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
