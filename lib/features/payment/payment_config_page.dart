import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 支付配置页面
class PaymentConfigPage extends StatefulWidget {
  const PaymentConfigPage({super.key});

  @override
  State<PaymentConfigPage> createState() => _PaymentConfigPageState();
}

class _PaymentConfigPageState extends State<PaymentConfigPage> {
  List<dynamic> _payments = [];
  List<String> _paymentMethods = [];
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
        ApiService.instance.get('/payment/fetch', isAdmin: true),
        ApiService.instance.get('/payment/getPaymentMethods', isAdmin: true),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].success) {
            _payments = results[0].getData<List>() ?? [];
          } else {
            _error = results[0].getMessage();
          }
          if (results[1].success) {
            _paymentMethods = List<String>.from(
              results[1].getData<List>() ?? [],
            );
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
                        '支付配置',
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
                        '管理支付方式和网关',
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
                  text: '添加支付',
                  icon: LucideIcons.plus,
                  onPressed: () => _showPaymentFormDialog(null),
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
                    child: _payments.isEmpty
                        ? const EmptyState(
                            title: '暂无支付方式',
                            subtitle: '点击添加支付按钮创建新的支付方式',
                            icon: LucideIcons.creditCard,
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _payments.length,
                            onReorder: _onReorder,
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, index) =>
                                _buildPaymentCard(_payments[index], index),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _payments.removeAt(oldIndex);
      _payments.insert(newIndex, item);
    });
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      final ids = _payments.map((p) => p['id']).toList();
      final response = await ApiService.instance.post(
        '/payment/sort',
        data: {'ids': ids},
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('排序已保存'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.getMessage()),
              backgroundColor: AppColors.error,
            ),
          );
          _loadData(); // 恢复原顺序
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存排序失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadData();
      }
    }
  }

  Widget _buildPaymentCard(dynamic payment, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = payment['id'];
    final name = payment['name'] ?? 'Unknown';
    final paymentType = payment['payment'] ?? '';
    final enable = payment['enable'] == 1;
    final sort = payment['sort'] ?? index + 1;
    final notifyUrl = payment['notify_url'] ?? '';

    return Container(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 拖拽手柄
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.gripVertical,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.creditCard,
                color: AppColors.primary,
                size: 22,
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
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(text: paymentType, color: AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notifyUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '排序: $sort',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(width: 12),
            StatusBadge(
              text: enable ? '启用' : '禁用',
              color: enable ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 8),
            Switch(
              value: enable,
              onChanged: (value) => _togglePaymentEnable(payment),
              activeColor: AppColors.primary,
            ),
            IconButton(
              onPressed: () => _showPaymentFormDialog(payment),
              icon: const Icon(
                LucideIcons.edit2,
                size: 18,
                color: AppColors.primary,
              ),
              tooltip: '编辑',
            ),
            IconButton(
              onPressed: () => _showDeleteConfirm(payment),
              icon: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.error,
              ),
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePaymentEnable(dynamic payment) async {
    try {
      final response = await ApiService.instance.post(
        '/payment/show',
        data: {'id': payment['id']},
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

  void _showPaymentFormDialog(dynamic payment) {
    final isEdit = payment != null;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => _PaymentFormDialog(
        payment: payment,
        isEdit: isEdit,
        paymentMethods: _paymentMethods,
        onSave: (data) async {
          Navigator.of(dialogContext).pop();

          try {
            final response = await ApiService.instance.post(
              '/payment/save',
              data: data,
              isAdmin: true,
            );

            if (mounted) {
              if (response.success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? '保存成功' : '创建成功'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadData();
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(response.getMessage()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('操作失败: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除支付方式 "${payment['name']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await ApiService.instance.post(
                '/payment/drop',
                data: {'id': payment['id']},
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
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// 支付表单对话框
class _PaymentFormDialog extends StatefulWidget {
  final dynamic payment;
  final bool isEdit;
  final List<String> paymentMethods;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _PaymentFormDialog({
    this.payment,
    required this.isEdit,
    required this.paymentMethods,
    required this.onSave,
  });

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _iconController;
  late TextEditingController _notifyDomainController;
  late TextEditingController _handlingFeeFixedController;
  late TextEditingController _handlingFeePercentController;
  String? _selectedPayment;
  Map<String, TextEditingController> _configControllers = {};

  // 支付配置表单字段
  List<Map<String, dynamic>> _formFields = [];
  bool _isLoadingForm = false;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _iconController = TextEditingController(text: p?['icon'] ?? '');
    _notifyDomainController = TextEditingController(
      text: p?['notify_domain'] ?? '',
    );
    _handlingFeeFixedController = TextEditingController(
      text: p?['handling_fee_fixed']?.toString() ?? '',
    );
    _handlingFeePercentController = TextEditingController(
      text: p?['handling_fee_percent']?.toString() ?? '',
    );
    _selectedPayment = p?['payment'];

    if (_selectedPayment != null) {
      _loadPaymentForm();
    }
  }

  Future<void> _loadPaymentForm() async {
    if (_selectedPayment == null) return;

    setState(() => _isLoadingForm = true);

    try {
      final response = await ApiService.instance.get(
        '/payment/getPaymentForm',
        queryParameters: {
          'payment': _selectedPayment,
          if (widget.payment != null) 'id': widget.payment['id'],
        },
        isAdmin: true,
      );

      if (mounted && response.success) {
        final formData = response.getData<List>() ?? [];
        setState(() {
          _formFields = List<Map<String, dynamic>>.from(formData);
          // 初始化配置控制器
          _configControllers.clear();
          for (final field in _formFields) {
            final key = field['field'] ?? field['name'] ?? '';
            final value = field['value']?.toString() ?? '';
            _configControllers[key] = TextEditingController(text: value);
          }
        });
      }
    } catch (e) {
      debugPrint('加载支付表单失败: $e');
    } finally {
      if (mounted) setState(() => _isLoadingForm = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _notifyDomainController.dispose();
    _handlingFeeFixedController.dispose();
    _handlingFeePercentController.dispose();
    for (final c in _configControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 550,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    widget.isEdit ? '编辑支付方式' : '添加支付方式',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '显示名称',
                          hintText: '如：微信支付、支付宝',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                        validator: (v) => v?.isEmpty == true ? '请输入显示名称' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPayment,
                        decoration: const InputDecoration(
                          labelText: '支付网关',
                          prefixIcon: Icon(LucideIcons.creditCard),
                        ),
                        items: widget.paymentMethods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: widget.isEdit
                            ? null
                            : (v) {
                                setState(() => _selectedPayment = v);
                                _loadPaymentForm();
                              },
                        validator: (v) => v == null ? '请选择支付网关' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _iconController,
                        decoration: const InputDecoration(
                          labelText: '图标URL (可选)',
                          prefixIcon: Icon(LucideIcons.image),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notifyDomainController,
                        decoration: const InputDecoration(
                          labelText: '自定义通知域名 (可选)',
                          hintText: 'https://example.com',
                          prefixIcon: Icon(LucideIcons.globe),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _handlingFeeFixedController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '固定手续费 (分)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _handlingFeePercentController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '百分比手续费 (%)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isLoadingForm) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator()),
                      ] else if (_formFields.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          '支付配置参数',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._formFields.map((field) {
                          final key = field['field'] ?? field['name'] ?? '';
                          final label = field['label'] ?? key;
                          final desc = field['description'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _configControllers[key],
                              decoration: InputDecoration(
                                labelText: label,
                                helperText: desc.isNotEmpty ? desc : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(widget.isEdit ? '保存' : '创建'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择支付网关'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 构建配置数据
    final config = <String, dynamic>{};
    for (final entry in _configControllers.entries) {
      config[entry.key] = entry.value.text;
    }

    final data = <String, dynamic>{
      if (widget.isEdit) 'id': widget.payment['id'],
      'name': _nameController.text,
      'payment': _selectedPayment,
      'config': config,
    };

    if (_iconController.text.isNotEmpty) {
      data['icon'] = _iconController.text;
    }
    if (_notifyDomainController.text.isNotEmpty) {
      data['notify_domain'] = _notifyDomainController.text;
    }
    if (_handlingFeeFixedController.text.isNotEmpty) {
      data['handling_fee_fixed'] = int.tryParse(
        _handlingFeeFixedController.text,
      );
    }
    if (_handlingFeePercentController.text.isNotEmpty) {
      data['handling_fee_percent'] = double.tryParse(
        _handlingFeePercentController.text,
      );
    }

    widget.onSave(data);
  }
}
