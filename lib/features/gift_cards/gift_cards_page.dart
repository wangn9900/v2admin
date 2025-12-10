import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:v2board_admin/core/constants/api_constants.dart';
import 'package:v2board_admin/core/theme/app_colors.dart';
import 'package:v2board_admin/data/services/api_service.dart';

class GiftCardsPage extends StatefulWidget {
  const GiftCardsPage({super.key});

  @override
  State<GiftCardsPage> createState() => _GiftCardsPageState();
}

class _GiftCardsPageState extends State<GiftCardsPage> {
  bool _isLoading = false;
  List<dynamic> _list = [];
  int _total = 0;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.adminGiftcardFetch,
        queryParameters: {'current': _currentPage, 'pageSize': _pageSize},
        isAdmin: true,
      );
      if (mounted) {
        if (res.success) {
          setState(() {
            _list = res.data['data'] as List<dynamic>;
            _total = res.data['total'] as int;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTypeName(int type) {
    switch (type) {
      case 1:
        return '余额充值';
      case 2:
        return '会员时长';
      case 3:
        return '流量包';
      case 4:
        return '流量重置';
      case 5:
        return '套餐兑换';
      default:
        return '未知';
    }
  }

  String _getValueDisplay(dynamic item) {
    int type = int.tryParse(item['type']?.toString() ?? '0') ?? 0;
    int val = int.tryParse(item['value']?.toString() ?? '0') ?? 0;
    switch (type) {
      case 1:
        return '¥${(val / 100).toStringAsFixed(2)}';
      case 2:
        return '$val 天';
      case 3:
        return '$val GB';
      case 4:
        return '重置';
      case 5:
        return '$val 天';
      default:
        return '$val';
    }
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除?'),
        content: const Text('此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.instance.post(
        ApiConstants.adminGiftcardDrop,
        data: {'id': id},
        isAdmin: true,
      );
      _loadData();
    }
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => _GiftCardGenerateDialog(onSuccess: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('礼品卡管理'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(LucideIcons.refreshCw),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _showGenerateDialog,
            icon: const Icon(LucideIcons.plus),
            label: const Text('生成礼品卡'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                ? const Center(child: Text('暂无数据'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            isDark
                                ? const Color(0xFF2C2C3E)
                                : Colors.grey.shade100,
                          ),
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('名称')),
                            DataColumn(label: Text('兑换码')),
                            DataColumn(label: Text('类型')),
                            DataColumn(label: Text('数值/详情')),
                            DataColumn(label: Text('有效期')),
                            DataColumn(label: Text('状态')),
                            DataColumn(label: Text('操作')),
                          ],
                          rows: _list.map((item) {
                            final startTs =
                                int.tryParse(
                                  item['started_at']?.toString() ?? '0',
                                ) ??
                                0;
                            final endTs =
                                int.tryParse(
                                  item['ended_at']?.toString() ?? '0',
                                ) ??
                                0;

                            final start = startTs != 0
                                ? DateFormat('MM-dd').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      startTs * 1000,
                                    ),
                                  )
                                : '不限';
                            final end = endTs != 0
                                ? DateFormat('MM-dd').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      endTs * 1000,
                                    ),
                                  )
                                : '不限';
                            return DataRow(
                              cells: [
                                DataCell(Text('${item['id']}')),
                                DataCell(Text(item['name'] ?? '')),
                                DataCell(SelectableText(item['code'] ?? '')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getTypeName(item['type']),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(_getValueDisplay(item))),
                                DataCell(Text('$start 至 $end')),
                                DataCell(
                                  Text(item['status'] == 1 ? '正常' : '失效'),
                                ),
                                DataCell(
                                  IconButton(
                                    onPressed: () => _delete(item['id']),
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
          if (_total > _pageSize)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadData();
                          }
                        : null,
                    icon: const Icon(LucideIcons.chevronLeft),
                  ),
                  Text(' $_currentPage / ${(_total / _pageSize).ceil()} '),
                  IconButton(
                    onPressed: (_currentPage * _pageSize) < _total
                        ? () {
                            setState(() => _currentPage++);
                            _loadData();
                          }
                        : null,
                    icon: const Icon(LucideIcons.chevronRight),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GiftCardGenerateDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _GiftCardGenerateDialog({required this.onSuccess});

  @override
  State<_GiftCardGenerateDialog> createState() =>
      _GiftCardGenerateDialogState();
}

class _GiftCardGenerateDialogState extends State<_GiftCardGenerateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _limitUseController = TextEditingController(text: '1');

  int _type = 1;
  int? _startedAt; // Seconds
  int? _endedAt;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    int val = int.tryParse(_valueController.text) ?? 0;
    if (_type == 1) {
      val = ((double.tryParse(_valueController.text) ?? 0) * 100).toInt();
    }

    final data = {
      'name': _nameController.text,
      'type': _type,
      'value': val,
      'generate_count': int.tryParse(_countController.text) ?? 1,
      'limit_use': int.tryParse(_limitUseController.text),
      if (_startedAt != null) 'started_at': _startedAt,
      if (_endedAt != null) 'ended_at': _endedAt,
    };

    final res = await ApiService.instance.post(
      ApiConstants.adminGiftcardGenerate,
      data: data,
      isAdmin: true,
    );
    if (mounted && res.success) {
      Navigator.pop(context);
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('生成礼品卡'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '名称'),
                  validator: (v) => v!.isEmpty ? '必填' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _type,
                  decoration: const InputDecoration(labelText: '类型'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('余额充值')),
                    DropdownMenuItem(value: 2, child: Text('会员时长')),
                    DropdownMenuItem(value: 3, child: Text('流量包')),
                    DropdownMenuItem(value: 4, child: Text('流量重置')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: _type == 1
                        ? '金额 (元)'
                        : (_type == 3 ? '流量 (GB)' : '数值 (天/次数)'),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? '必填' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countController,
                  decoration: const InputDecoration(labelText: '生成数量'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limitUseController,
                  decoration: const InputDecoration(
                    labelText: '最大使用次数 (不填无限?)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('生成')),
      ],
    );
  }
}
