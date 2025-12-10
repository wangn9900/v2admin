// Refresh
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:v2board_admin/core/constants/api_constants.dart';
import 'package:v2board_admin/core/theme/app_colors.dart';
import 'package:v2board_admin/data/services/api_service.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  bool _isLoading = false;
  List<dynamic> _knowledgeList = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.adminKnowledgeFetch,
        isAdmin: true,
      );
      final catRes = await ApiService.instance.get(
        ApiConstants.adminKnowledgeCategory,
        isAdmin: true,
      );

      if (mounted) {
        if (res.success) {
          setState(() {
            _knowledgeList = res.data['data'] as List<dynamic>;
          });
        }
        if (catRes.success) {
          setState(() {
            _categories = List<String>.from(catRes.data['data']);
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleShow(int id) async {
    try {
      await ApiService.instance.post(
        ApiConstants.adminKnowledgeShow,
        data: {'id': id},
        isAdmin: true,
      );
      _loadData(); // Refresh to update state
    } catch (e) {
      // Handle error
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
      final res = await ApiService.instance.post(
        ApiConstants.adminKnowledgeDrop,
        data: {'id': id},
        isAdmin: true,
      );
      if (res.success) {
        _loadData();
      }
    }
  }

  void _showEditDialog([Map<String, dynamic>? item]) {
    showDialog(
      context: context,
      builder: (context) => _KnowledgeEditDialog(
        item: item,
        categories: _categories,
        onUpdate: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库管理'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(LucideIcons.refreshCw),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showEditDialog(),
            icon: const Icon(LucideIcons.plus),
            label: const Text('新建文档'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _knowledgeList.isEmpty
          ? const Center(child: Text('暂无相关数据'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      isDark ? const Color(0xFF2C2C3E) : Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('标题')),
                      DataColumn(label: Text('分类')),
                      DataColumn(label: Text('最后更新')),
                      DataColumn(label: Text('显示')),
                      DataColumn(label: Text('操作')),
                    ],
                    rows: _knowledgeList.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text('#${item['id']}')),
                          DataCell(Text(item['title'] ?? '')),
                          DataCell(
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
                                item['category'] ?? '未分类',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  (int.tryParse(
                                            item['updated_at']?.toString() ??
                                                '0',
                                          ) ??
                                          0) *
                                      1000,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Switch(
                              value: item['show'] == 1,
                              onChanged: (_) => _toggleShow(item['id']),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('编辑'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    '删除',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') _showEditDialog(item);
                                if (v == 'delete') _delete(item['id']);
                              },
                              child: const Icon(
                                LucideIcons.moreHorizontal,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _KnowledgeEditDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<String> categories;
  final VoidCallback onUpdate;

  const _KnowledgeEditDialog({
    this.item,
    required this.categories,
    required this.onUpdate,
  });

  @override
  State<_KnowledgeEditDialog> createState() => _KnowledgeEditDialogState();
}

class _KnowledgeEditDialogState extends State<_KnowledgeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _bodyController;
  late TextEditingController _langController;
  bool _show = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?['title']);
    _categoryController = TextEditingController(text: widget.item?['category']);
    _bodyController = TextEditingController();
    _langController = TextEditingController(
      text: widget.item?['language'] ?? 'zh-CN',
    );

    if (widget.item != null) {
      _show = widget.item!['show'] == 1;
      _fetchDetail();
    }
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final res = await ApiService.instance.get(
      ApiConstants.adminKnowledgeFetch,
      queryParameters: {'id': widget.item!['id']},
      isAdmin: true,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (res.success) {
        final data = res.data['data'];
        _titleController.text = data['title'];
        _categoryController.text = data['category'];
        _bodyController.text = data['body'] ?? '';
        _langController.text = data['language'] ?? 'zh-CN';
        _show = data['show'] == 1;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      if (widget.item != null) 'id': widget.item!['id'],
      'title': _titleController.text,
      'category': _categoryController.text,
      'body': _bodyController.text,
      'language': _langController.text,
      'show': _show ? 1 : 0,
      'sort': widget.item?['sort'] ?? 1,
    };

    final res = await ApiService.instance.post(
      ApiConstants.adminKnowledgeSave,
      data: data,
      isAdmin: true,
    );
    if (mounted && res.success) {
      Navigator.pop(context);
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? '新建文档' : '编辑文档'),
      content: SizedBox(
        width: 800,
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: '标题',
                              ),
                              validator: (v) => v!.isEmpty ? '必填' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _langController,
                              decoration: const InputDecoration(
                                labelText: '语言 (例如 zh-CN)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        optionsBuilder: (v) {
                          return widget.categories.where(
                            (e) => e.contains(v.text),
                          );
                        },
                        onSelected: (v) => _categoryController.text = v,
                        fieldViewBuilder:
                            (context, controller, focus, onSubmitted) {
                              if (controller.text != _categoryController.text) {
                                controller.text = _categoryController.text;
                              }
                              return TextFormField(
                                controller: controller,
                                focusNode: focus,
                                decoration: const InputDecoration(
                                  labelText: '分类 (输入或选择)',
                                ),
                                onChanged: (v) => _categoryController.text = v,
                                validator: (v) => v!.isEmpty ? '必填' : null,
                              );
                            },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: '内容 (Markdown/HTML)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 15,
                        validator: (v) => v!.isEmpty ? '必填' : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('显示'),
                        value: _show,
                        onChanged: (v) => setState(() => _show = v),
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
        ElevatedButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
