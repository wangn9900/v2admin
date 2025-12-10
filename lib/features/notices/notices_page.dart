import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 公告管理页面
class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  List<dynamic> _notices = [];
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
        '/notice/fetch',
        isAdmin: true,
      );
      if (mounted) {
        setState(() {
          if (response.success) {
            _notices = response.getData<List>() ?? [];
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
                        '公告管理',
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
                        '管理系统公告和通知',
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
                  text: '添加公告',
                  icon: LucideIcons.plus,
                  onPressed: () => _showNoticeFormDialog(null),
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
                    child: _notices.isEmpty
                        ? const EmptyState(
                            title: '暂无公告',
                            subtitle: '点击右上角添加公告按钮发布新公告',
                            icon: LucideIcons.megaphone,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notices.length,
                            itemBuilder: (context, index) =>
                                _buildNoticeCard(_notices[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(dynamic notice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = notice['id'];
    final title = notice['title'] ?? '无标题';
    final content = notice['content'] ?? '';
    final show = notice['show'] == 1;
    final createdAt = notice['created_at'] ?? 0;

    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Switch(
                  value: show,
                  onChanged: (value) => _toggleNoticeShow(notice, value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content.length > 200
                  ? '${content.substring(0, 200)}...'
                  : content,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 14,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showNoticeFormDialog(notice),
                  icon: Icon(
                    LucideIcons.edit2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirm(notice),
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

  void _showNoticeFormDialog(dynamic notice) {
    final isEdit = notice != null;

    final titleController = TextEditingController(text: notice?['title'] ?? '');
    final contentController = TextEditingController(
      text: notice?['content'] ?? '',
    );
    bool show = notice?['show'] == 1 || notice == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑公告' : '添加公告'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '公告标题',
                      prefixIcon: Icon(LucideIcons.type),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '公告内容',
                      hintText: '支持 Markdown 格式',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('是否显示'),
                    subtitle: const Text('关闭后用户将无法看到此公告'),
                    value: show,
                    onChanged: (v) => setDialogState(() => show = v),
                    activeColor: AppColors.primary,
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
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请填写标题和内容')));
                  return;
                }

                Navigator.pop(context);

                final data = {
                  if (isEdit) 'id': notice['id'],
                  'title': titleController.text,
                  'content': contentController.text,
                  'show': show ? 1 : 0,
                };

                try {
                  final response = await ApiService.instance.post(
                    isEdit ? '/notice/update' : '/notice/save',
                    data: data,
                    isAdmin: true,
                  );

                  if (mounted) {
                    if (response.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? '保存成功' : '发布成功'),
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
              child: Text(isEdit ? '保存' : '发布'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleNoticeShow(dynamic notice, bool show) async {
    try {
      final response = await ApiService.instance.post(
        '/notice/update',
        data: {'id': notice['id'], 'show': show ? 1 : 0},
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

  void _showDeleteConfirm(dynamic notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除公告 "${notice['title']}" 吗？'),
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
                  '/notice/drop',
                  data: {'id': notice['id']},
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
