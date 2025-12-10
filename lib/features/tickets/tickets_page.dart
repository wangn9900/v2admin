import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 工单管理页面
class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  // 工单通知
  Timer? _pollingTimer;
  int _lastTicketCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    // 每30秒检查新工单
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNewTickets(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.fetchTickets();
      if (mounted) {
        setState(() {
          if (response.success) {
            _tickets = response.getData<List>() ?? [];
            _pendingCount = _tickets
                .where((t) => t['reply_status'] == 0)
                .length;
            _lastTicketCount = _tickets.length;
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

  /// 检查是否有新工单
  Future<void> _checkNewTickets() async {
    try {
      final response = await ApiService.instance.fetchTickets();
      if (mounted && response.success) {
        final tickets = response.getData<List>() ?? [];
        final newPendingCount = tickets
            .where((t) => t['reply_status'] == 0)
            .length;

        // 如果有新的待回复工单
        if (newPendingCount > _pendingCount) {
          _showNewTicketNotification(newPendingCount - _pendingCount);
        }

        setState(() {
          _tickets = tickets;
          _pendingCount = newPendingCount;
          _lastTicketCount = tickets.length;
        });
      }
    } catch (e) {
      debugPrint('检查新工单失败: $e');
    }
  }

  /// 显示新工单通知
  void _showNewTicketNotification(int count) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.messageSquare, color: Colors.white),
            const SizedBox(width: 12),
            Text('收到 $count 条新工单，请及时处理！'),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '查看',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
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
                      Row(
                        children: [
                          Text(
                            '工单管理',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (_pendingCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_pendingCount 待处理',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '处理用户工单和反馈',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // 统计
                if (_tickets.isNotEmpty) ...[
                  _buildStatChip(
                    '待回复',
                    _tickets.where((t) => t['reply_status'] == 0).length,
                    AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    '已回复',
                    _tickets.where((t) => t['reply_status'] == 1).length,
                    AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    '已关闭',
                    _tickets.where((t) => t['status'] == 1).length,
                    AppColors.success,
                  ),
                  const SizedBox(width: 12),
                ],
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
                    child: _tickets.isEmpty
                        ? const EmptyState(
                            title: '暂无工单',
                            subtitle: '没有用户提交工单',
                            icon: LucideIcons.messageSquare,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _tickets.length,
                            itemBuilder: (context, index) =>
                                _buildTicketCard(_tickets[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = ticket['id'];
    final subject = ticket['subject'] ?? '无主题';
    final status = ticket['status'] ?? 0;
    final level = ticket['level'] ?? 0;
    final userId = ticket['user_id'] ?? 0;
    final createdAt = ticket['created_at'] ?? 0;
    final replyStatus = ticket['reply_status'] ?? 0;

    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    Color statusColor;
    String statusText;
    switch (status) {
      case 0:
        statusColor = replyStatus == 0 ? AppColors.error : AppColors.info;
        statusText = replyStatus == 0 ? '待回复' : '已回复';
        break;
      case 1:
        statusColor = AppColors.success;
        statusText = '已关闭';
        break;
      default:
        statusColor = AppColors.textMutedDark;
        statusText = '未知';
    }

    Color levelColor;
    String levelText;
    switch (level) {
      case 0:
        levelColor = AppColors.info;
        levelText = '低';
        break;
      case 1:
        levelColor = AppColors.warning;
        levelText = '中';
        break;
      case 2:
        levelColor = AppColors.error;
        levelText = '高';
        break;
      default:
        levelColor = AppColors.textMutedDark;
        levelText = '未知';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTicketDetail(ticket),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.messageSquare,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                    subject,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '用户 ID: $userId',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(text: statusText, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatusBadge(text: '优先级: $levelText', color: levelColor),
                      const Spacer(),
                      Icon(
                        LucideIcons.clock,
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
                      const SizedBox(width: 12),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示工单详情对话框
  Future<void> _showTicketDetail(dynamic ticket) async {
    showDialog(
      context: context,
      builder: (context) => _TicketDetailDialog(
        ticketId: ticket['id'],
        subject: ticket['subject'] ?? '无主题',
        onClose: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

/// 工单详情对话框
class _TicketDetailDialog extends StatefulWidget {
  final int ticketId;
  final String subject;
  final VoidCallback onClose;

  const _TicketDetailDialog({
    required this.ticketId,
    required this.subject,
    required this.onClose,
  });

  @override
  State<_TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<_TicketDetailDialog> {
  List<dynamic> _messages = [];
  dynamic _ticketDetail;
  bool _isLoading = true;
  String? _error;
  final _replyController = TextEditingController();
  bool _isSending = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTicketDetail();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.get(
        '/ticket/fetch',
        queryParameters: {'id': widget.ticketId},
        isAdmin: true,
      );

      if (mounted) {
        setState(() {
          if (response.success) {
            _ticketDetail = response.data['data'];
            _messages = _ticketDetail?['message'] ?? [];
          } else {
            _error = response.getMessage();
          }
          _isLoading = false;
        });

        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
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

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final response = await ApiService.instance.replyTicket(
        widget.ticketId,
        _replyController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          _replyController.clear();
          _loadTicketDetail();
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
          SnackBar(content: Text('发送失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认关闭'),
        content: const Text('确定要关闭此工单吗？'),
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

    try {
      final response = await ApiService.instance.closeTicket(widget.ticketId);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('工单已关闭'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onClose();
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
          SnackBar(content: Text('关闭失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _ticketDetail?['status'] ?? 0;
    final isClosed = status == 1;

    return Dialog(
      child: Container(
        width: 600,
        height: 600,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.messageSquare,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '工单 #${widget.ticketId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          widget.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isClosed)
                    TextButton.icon(
                      onPressed: _closeTicket,
                      icon: const Icon(LucideIcons.checkCircle, size: 16),
                      label: const Text('关闭工单'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),

            // 消息列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  : _messages.isEmpty
                  ? const Center(child: Text('暂无消息'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessageBubble(_messages[index]),
                    ),
            ),

            // 回复输入框
            if (!isClosed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(
                          hintText: '输入回复内容...',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surfaceDark
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _isSending ? null : _sendReply,
                      mini: true,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.send),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMe = message['is_me'] == true; // 管理员发送
    final content = message['message'] ?? '';
    final createdAt = message['created_at'] ?? 0;

    final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final timeStr =
        '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : (isDark ? AppColors.cardDark : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: _buildMessageContent(content, isMe, isDark),
            ),
            const SizedBox(height: 4),
            Text(
              '${isMe ? "管理员" : "用户"} · $timeStr',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 解析消息内容，支持 Markdown 图片语法
  Widget _buildMessageContent(String content, bool isMe, bool isDark) {
    // Markdown 图片正则: ![alt](url)
    final imageRegex = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
    final matches = imageRegex.allMatches(content);

    if (matches.isEmpty) {
      // 没有图片，直接显示文本
      return Text(
        content,
        style: TextStyle(
          color: isMe
              ? Colors.white
              : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
        ),
      );
    }

    // 有图片，需要解析并混合显示
    List<Widget> widgets = [];
    int lastEnd = 0;

    for (final match in matches) {
      // 添加图片前的文本
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          widgets.add(
            Text(
              textBefore,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
              ),
            ),
          );
        }
      }

      // 添加图片
      final imageUrl = match.group(2) ?? '';
      if (imageUrl.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          GestureDetector(
            onTap: () => _showFullImage(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 250,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imageOff, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          '图片加载失败',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }

      lastEnd = match.end;
    }

    // 添加最后剩余的文本
    if (lastEnd < content.length) {
      final textAfter = content.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        widgets.add(
          Text(
            textAfter,
            style: TextStyle(
              color: isMe
                  ? Colors.white
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 显示全屏图片
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
