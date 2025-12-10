import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 套餐管理页面
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<dynamic> _plans = [];
  List<dynamic> _groups = [];
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
      final results = await Future.wait([
        ApiService.instance.get('/plan/fetch', isAdmin: true),
        ApiService.instance.getServerGroups(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].success) {
            _plans = results[0].getData<List>() ?? [];
          } else {
            _error = results[0].getMessage();
          }
          if (results[1].success) {
            _groups = results[1].getData<List>() ?? [];
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
                        '订阅管理',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '管理套餐和订阅计划',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (!_plans.isEmpty) ...[
                            const SizedBox(width: 12),
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
                                '有效订阅总人数: ${_plans.fold<int>(0, (sum, plan) => sum + (plan['count'] as int? ?? 0))}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  text: '添加套餐',
                  icon: LucideIcons.plus,
                  onPressed: () => _showPlanFormDialog(null),
                  width: 120,
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
                    child: _plans.isEmpty
                        ? const EmptyState(
                            title: '暂无套餐',
                            subtitle: '点击右上角添加套餐按钮创建新套餐',
                            icon: LucideIcons.package,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 350,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) =>
                                _buildPlanCard(_plans[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = plan['id'];
    final name = plan['name'] ?? 'Unknown';
    final monthPrice = (plan['month_price'] ?? 0) / 100;
    final transferEnable = (plan['transfer_enable'] ?? 0) / 1073741824; // GB
    final show = plan['show'] == 1;
    final sell = plan['sell'] == 1;
    final count = plan['count'] ?? 0; // 订阅人数

    return GlassCard(
      padding: const EdgeInsets.all(16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Switch(
                value: sell,
                onChanged: (value) => _togglePlanSell(plan, value),
                activeColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¥${monthPrice.toStringAsFixed(2)}/月',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                LucideIcons.database,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '${transferEnable.toStringAsFixed(0)} GB',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                LucideIcons.users,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Text(
                '$count 人在用',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              StatusBadge(
                text: show ? '显示' : '隐藏',
                color: show ? AppColors.info : AppColors.textMutedDark,
              ),
              StatusBadge(
                text: sell ? '在售' : '停售',
                color: sell ? AppColors.success : AppColors.error,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showPlanFormDialog(plan),
                icon: Icon(
                  LucideIcons.edit2,
                  size: 18,
                  color: AppColors.primary,
                ),
                tooltip: '编辑',
              ),
              IconButton(
                onPressed: () => _showDeleteConfirm(plan),
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
    );
  }

  void _showPlanFormDialog(dynamic plan) {
    final isEdit = plan != null;

    final nameController = TextEditingController(text: plan?['name'] ?? '');
    final contentController = TextEditingController(
      text: plan?['content'] ?? '',
    );
    final transferController = TextEditingController(
      text: ((plan?['transfer_enable'] ?? 0) / 1073741824).toString(),
    );
    final deviceLimitController = TextEditingController(
      text: (plan?['device_limit'] ?? '').toString(),
    );

    // 价格 Controllers
    final monthPriceController = TextEditingController(
      text: ((plan?['month_price'] ?? 0) / 100).toString(),
    );
    final quarterPriceController = TextEditingController(
      text: ((plan?['quarter_price'] ?? 0) / 100).toString(),
    );
    final halfYearPriceController = TextEditingController(
      text: ((plan?['half_year_price'] ?? 0) / 100).toString(),
    );
    final yearPriceController = TextEditingController(
      text: ((plan?['year_price'] ?? 0) / 100).toString(),
    );
    final twoYearPriceController = TextEditingController(
      text: ((plan?['two_year_price'] ?? 0) / 100).toString(),
    );
    final threeYearPriceController = TextEditingController(
      text: ((plan?['three_year_price'] ?? 0) / 100).toString(),
    );
    final onetimePriceController = TextEditingController(
      text: ((plan?['onetime_price'] ?? 0) / 100).toString(),
    );
    final resetPriceController = TextEditingController(
      text: ((plan?['reset_price'] ?? 0) / 100).toString(),
    );

    int? groupId = plan?['group_id'];
    int? resetTrafficMethod = plan?['reset_traffic_method'];
    bool show = plan?['show'] == 1;
    bool sell = plan?['sell'] == 1;
    bool renew = plan?['renew'] == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑套餐' : '添加套餐'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息
                  const Text(
                    '基本信息',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: '套餐名称',
                            prefixIcon: Icon(LucideIcons.package),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: groupId,
                          decoration: const InputDecoration(
                            labelText: '权限组',
                            prefixIcon: Icon(LucideIcons.users),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('无'),
                            ),
                            ..._groups.map(
                              (g) => DropdownMenuItem<int>(
                                value: g['id'],
                                child: Text(g['name'] ?? ''),
                              ),
                            ),
                          ],
                          onChanged: (v) => setDialogState(() => groupId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '套餐描述 (支持 HTML)',
                      prefixIcon: Icon(LucideIcons.fileText),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '流量与限制',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: transferController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '流量 (GB)',
                            prefixIcon: Icon(LucideIcons.database),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: deviceLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '设备数限制 (留空不限)',
                            prefixIcon: Icon(LucideIcons.monitor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: resetTrafficMethod,
                    decoration: const InputDecoration(
                      labelText: '流量重置方式',
                      prefixIcon: Icon(LucideIcons.refreshCw),
                    ),
                    items: const [
                      DropdownMenuItem<int>(value: null, child: Text('跟随系统')),
                      DropdownMenuItem<int>(value: 1, child: Text('每月1号重置')),
                      DropdownMenuItem<int>(value: 2, child: Text('按下单日重置')),
                      DropdownMenuItem<int>(value: 3, child: Text('不重置')),
                      DropdownMenuItem<int>(value: 4, child: Text('每年1月1日重置')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => resetTrafficMethod = v),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '定价设置 (元)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // 第一行价格
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceField(monthPriceController, '月付'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(quarterPriceController, '季付'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(halfYearPriceController, '半年付'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(yearPriceController, '年付'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 第二行价格
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceField(twoYearPriceController, '两年付'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(
                          threeYearPriceController,
                          '三年付',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(onetimePriceController, '一次性'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceField(resetPriceController, '重置包'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '开关设置',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('是否显示'),
                    value: show,
                    onChanged: (v) => setDialogState(() => show = v),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('是否销售'),
                    value: sell,
                    onChanged: (v) => setDialogState(() => sell = v),
                    activeColor: AppColors.success,
                  ),
                  SwitchListTile(
                    title: const Text('允许续费'),
                    value: renew,
                    onChanged: (v) => setDialogState(() => renew = v),
                    activeColor: AppColors.accent,
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请填写套餐名称')));
                  return;
                }

                Navigator.pop(context);

                // 辅助函数：将价格字符串转为分
                int? parsePrice(String text) {
                  final val = double.tryParse(text);
                  if (val == null) return null; // 保持 null 以便后端处理（如果支持）
                  return (val * 100).toInt();
                }

                // 为了兼容旧逻辑，如果是0也可能是未设置，这里统一转int，默认为null如果输入为空？
                // 现有逻辑是 String -> double -> int. 如果空串，double是null->0.
                int parsePriceSafe(String text) {
                  return ((double.tryParse(text) ?? 0) * 100).toInt();
                }

                final data = {
                  if (isEdit) 'id': plan['id'],
                  'name': nameController.text,
                  'content': contentController.text,
                  'group_id': groupId,
                  'transfer_enable':
                      ((double.tryParse(transferController.text) ?? 0) *
                              1073741824)
                          .toInt(),
                  'device_limit': int.tryParse(
                    deviceLimitController.text,
                  ), // null if empty
                  'reset_traffic_method': resetTrafficMethod,

                  // 价格
                  'month_price': parsePriceSafe(monthPriceController.text),
                  'quarter_price': parsePriceSafe(quarterPriceController.text),
                  'half_year_price': parsePriceSafe(
                    halfYearPriceController.text,
                  ),
                  'year_price': parsePriceSafe(yearPriceController.text),
                  'two_year_price': parsePriceSafe(twoYearPriceController.text),
                  'three_year_price': parsePriceSafe(
                    threeYearPriceController.text,
                  ),
                  'onetime_price': parsePriceSafe(onetimePriceController.text),
                  'reset_price': parsePriceSafe(resetPriceController.text),

                  'show': show ? 1 : 0,
                  'sell': sell ? 1 : 0,
                  'renew': renew ? 1 : 0,
                };

                try {
                  final response = await ApiService.instance.post(
                    isEdit ? '/plan/update' : '/plan/save',
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

  Widget _buildPriceField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  Future<void> _togglePlanSell(dynamic plan, bool sell) async {
    try {
      final response = await ApiService.instance.post(
        '/plan/update',
        data: {'id': plan['id'], 'sell': sell ? 1 : 0},
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
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
          SnackBar(content: Text('操作失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showDeleteConfirm(dynamic plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除套餐 "${plan['name']}" 吗？'),
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
                  '/plan/drop',
                  data: {'id': plan['id']},
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
