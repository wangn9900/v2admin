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
                      Text(
                        '管理套餐和订阅计划',
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
    final quarterPrice = (plan['quarter_price'] ?? 0) / 100;
    final halfYearPrice = (plan['half_year_price'] ?? 0) / 100;
    final yearPrice = (plan['year_price'] ?? 0) / 100;
    final transferEnable = (plan['transfer_enable'] ?? 0) / 1073741824; // GB
    final show = plan['show'] == 1;
    final sell = plan['sell'] == 1;

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
          Text(
            '流量: ${transferEnable.toStringAsFixed(0)} GB',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
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
    final transferController = TextEditingController(
      text: ((plan?['transfer_enable'] ?? 0) / 1073741824).toString(),
    );

    bool show = plan?['show'] == 1;
    bool sell = plan?['sell'] == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑套餐' : '添加套餐'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '套餐名称',
                      prefixIcon: Icon(LucideIcons.package),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: monthPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '月付价格 (元)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: quarterPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '季付价格 (元)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: halfYearPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '半年付价格 (元)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: yearPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '年付价格 (元)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: transferController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '流量 (GB)',
                      prefixIcon: Icon(LucideIcons.database),
                    ),
                  ),
                  const SizedBox(height: 16),
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

                final data = {
                  if (isEdit) 'id': plan['id'],
                  'name': nameController.text,
                  'month_price':
                      ((double.tryParse(monthPriceController.text) ?? 0) * 100)
                          .toInt(),
                  'quarter_price':
                      ((double.tryParse(quarterPriceController.text) ?? 0) *
                              100)
                          .toInt(),
                  'half_year_price':
                      ((double.tryParse(halfYearPriceController.text) ?? 0) *
                              100)
                          .toInt(),
                  'year_price':
                      ((double.tryParse(yearPriceController.text) ?? 0) * 100)
                          .toInt(),
                  'transfer_enable':
                      ((double.tryParse(transferController.text) ?? 0) *
                              1073741824)
                          .toInt(),
                  'show': show ? 1 : 0,
                  'sell': sell ? 1 : 0,
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
