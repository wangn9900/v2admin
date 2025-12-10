import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 用户管理页面
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  // 数据源
  List<UserInfo> _users = [];
  List<dynamic> _plans = [];

  // 状态
  bool _isLoading = true;
  String? _error;

  // 分页
  int _currentPage = 1;
  int _totalUsers = 0;
  final int _pageSize = 15;

  // 筛选器
  final TextEditingController _searchController = TextEditingController();
  int? _selectedPlanId;
  String? _selectedStatus; // 'all', 'banned', 'normal'

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载订阅计划列表（用于筛选和编辑）
  Future<void> _loadPlans() async {
    try {
      final response = await ApiService.instance.get(
        '/plan/fetch',
        isAdmin: true,
      );
      if (response.success && mounted) {
        setState(() {
          _plans = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load plans: $e');
    }
  }

  /// 加载用户列表
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService.instance;
      List<Map<String, dynamic>> filter = [];

      // 邮箱搜索
      if (_searchController.text.isNotEmpty) {
        filter.add({
          'key': 'email',
          'condition': '模糊',
          'value': _searchController.text.trim(),
        });
      }

      // 套餐筛选
      if (_selectedPlanId != null) {
        filter.add({
          'key': 'plan_id',
          'condition': '=',
          'value': _selectedPlanId,
        });
      }

      // 状态筛选
      if (_selectedStatus == 'banned') {
        filter.add({'key': 'banned', 'condition': '=', 'value': 1});
      } else if (_selectedStatus == 'normal') {
        filter.add({'key': 'banned', 'condition': '=', 'value': 0});
      }

      final response = await api.fetchUsers(
        current: _currentPage,
        pageSize: _pageSize,
        filter: filter.isNotEmpty ? filter : null,
      );

      if (mounted) {
        if (response.success) {
          final List<dynamic> dataList = response.data['data'] ?? [];
          setState(() {
            _users = dataList.map((e) => UserInfo.fromJson(e)).toList();
            _totalUsers = response.data['total'] ?? 0;
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

  void _resetFilter() {
    _searchController.clear();
    setState(() {
      _selectedPlanId = null;
      _selectedStatus = null;
      _currentPage = 1;
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题和筛选栏
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 24),
                    _buildFilterBar(isDark, isWide),
                  ],
                ),
              ),

              // 内容区域
              Expanded(
                child: _isLoading
                    ? const LoadingIndicator(message: '加载中...')
                    : _error != null
                    ? _buildErrorState()
                    : _users.isEmpty
                    ? const EmptyState(
                        title: '暂无用户',
                        subtitle: '没有找到匹配的用户',
                        icon: LucideIcons.users,
                      )
                    : isWide
                    ? _buildDataTable(isDark)
                    : _buildListView(isDark),
              ),

              // 分页
              if (!_isLoading && _users.isNotEmpty) _buildPagination(isDark),
            ],
          );
        },
      ),
    );
  }

  // ... (Header, Filter, Views, Actions) Implementation ...

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '用户管理',
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
              '共 $_totalUsers 个用户',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        GradientButton(
          text: '添加用户',
          icon: LucideIcons.userPlus,
          onPressed: () {
            // TODO: 实现添加用户
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('功能开发中')));
          },
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark, bool isWide) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 搜索框
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            decoration: inputDecoration.copyWith(
              hintText: '搜索邮箱...',
              prefixIcon: Icon(
                LucideIcons.search,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            onSubmitted: (_) {
              _currentPage = 1;
              _loadUsers();
            },
          ),
        ),

        // 套餐筛选
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<int>(
            value: _selectedPlanId,
            decoration: inputDecoration.copyWith(labelText: '订阅套餐'),
            items: [
              const DropdownMenuItem(value: null, child: Text('所有套餐')),
              ..._plans.map(
                (e) => DropdownMenuItem<int>(
                  value: e['id'],
                  child: Text(e['name'] ?? '', overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() => _selectedPlanId = val);
              _currentPage = 1;
              _loadUsers();
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            dropdownColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
          ),
        ),

        // 状态筛选
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: inputDecoration.copyWith(labelText: '状态'),
            items: const [
              DropdownMenuItem(value: null, child: Text('全部')),
              DropdownMenuItem(value: 'normal', child: Text('正常')),
              DropdownMenuItem(value: 'banned', child: Text('已封禁')),
            ],
            onChanged: (val) {
              setState(() => _selectedStatus = val);
              _currentPage = 1;
              _loadUsers();
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            dropdownColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
          ),
        ),

        // 按钮组
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                _currentPage = 1;
                _loadUsers();
              },
              icon: const Icon(LucideIcons.refreshCw),
              tooltip: '刷新',
            ),
            IconButton(
              onPressed: _resetFilter,
              icon: const Icon(LucideIcons.filterX),
              tooltip: '重置',
            ),
          ],
        ),
      ],
    );
  }

  // 桌面端表格视图
  Widget _buildDataTable(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            horizontalMargin: 24,
            columnSpacing: 24,
            headingRowHeight: 56,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            columns: [
              const DataColumn(label: Text('ID')),
              const DataColumn(label: Text('用户')),
              const DataColumn(label: Text('订阅信息')),
              const DataColumn(label: Text('流量使用')),
              const DataColumn(label: Text('在线设备')),
              const DataColumn(label: Text('余额/佣金')),
              const DataColumn(label: Text('到期时间')),
              const DataColumn(label: Text('状态')),
              const DataColumn(label: Text('操作')),
            ],
            rows: _users
                .map(
                  (user) => DataRow(
                    cells: [
                      DataCell(Text('#${user.id}')),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                user.email.isNotEmpty
                                    ? user.email[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.planName != null
                                    ? AppColors.primary.withOpacity(0.1)
                                    : isDark
                                    ? Colors.white10
                                    : Colors.black12,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: user.planName != null
                                      ? AppColors.primary.withOpacity(0.3)
                                      : isDark
                                      ? Colors.white24
                                      : Colors.black26,
                                ),
                              ),
                              child: Text(
                                user.planName ?? '无订阅',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.planName != null
                                      ? AppColors.primary
                                      : (isDark ? Colors.grey : Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.formatTraffic(user.totalUsed)),
                            Text(
                              '/ ${user.transferEnable == null ? "无限" : user.formatTraffic(user.transferEnable!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text('${user.aliveIp} / ${user.deviceLimit ?? "无限"}'),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¥${user.formattedBalance}'),
                            Text(
                              '佣 ¥${user.formattedCommission}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          user.expiredAt == null
                              ? '长期有效'
                              : DateFormat('yyyy/MM/dd HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    user.expiredAt! * 1000,
                                  ),
                                ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DataCell(
                        StatusBadge(
                          text: user.banned ? '已封禁' : '正常',
                          color: user.banned
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                      DataCell(_buildActionMenu(user)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  // 移动端列表视图
  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showUserDetail(user),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(user.email[0].toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.planName ?? "无订阅"} · ¥${user.formattedBalance}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionMenu(user, isIconMode: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 统一操作菜单
  Widget _buildActionMenu(UserInfo user, {bool isIconMode = false}) {
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.moreHorizontal,
        size: 20,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey
            : Colors.grey[600],
      ),
      onSelected: (value) => _handleAction(value, user),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.edit2, size: 16),
              SizedBox(width: 8),
              Text('编辑'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'assign',
          child: Row(
            children: [
              Icon(LucideIcons.shoppingCart, size: 16),
              SizedBox(width: 8),
              Text('分配订单'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(LucideIcons.copy, size: 16),
              SizedBox(width: 8),
              Text('复制订阅URL'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(LucideIcons.refreshCcw, size: 16),
              SizedBox(width: 8),
              Text('重置订阅信息'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text('删除用户', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(String action, UserInfo user) async {
    switch (action) {
      case 'edit':
        _showEditDialog(user);
        break;
      case 'assign':
        // 简化版：直接打开可以修改套餐的编辑对话框
        _showEditDialog(user, initialTab: 1);
        break;
      case 'copy':
        if (user.subscribeUrl != null) {
          await Clipboard.setData(ClipboardData(text: user.subscribeUrl!));
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('已复制订阅链接')));
        } else {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('无订阅链接')));
        }
        break;
      case 'reset':
        _showConfirmDialog(
          '重置订阅信息',
          '确定要重置该用户的 UUID 和 Token 吗？此操作会导致用户旧的订阅链接失效。',
          () async {
            final res = await ApiService.instance.resetUserSecret(user.id);
            if (res.success) {
              if (mounted)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('重置成功')));
              _loadUsers();
            }
          },
        );
        break;
      case 'delete':
        _showConfirmDialog('删除用户', '确定要彻底删除该用户吗？此操作不可恢复。', () async {
          final res = await ApiService.instance.deleteUser(user.id);
          if (res.success) {
            if (mounted)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('删除成功')));
            _loadUsers();
          }
        });
        break;
    }
  }

  void _showConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(UserInfo user, {int initialTab = 0}) {
    // 简单的编辑对话框实现
    showDialog(
      context: context,
      builder: (context) =>
          _UserEditDialog(user: user, plans: _plans, onUpdate: _loadUsers),
    );
  }

  // 移动端详情展示
  void _showUserDetail(UserInfo user) {
    // 复用之前的 Sheet 逻辑，或者简单弹个 Dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... 简单详情 ...
            Text(
              user.email,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // 操作按钮
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.edit2),
                  label: const Text('编辑'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditDialog(user);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.shoppingCart),
                  label: const Text('套餐'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditDialog(user, initialTab: 1);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                  label: const Text(
                    '删除',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _handleAction('delete', user);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? '未知错误'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUsers, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    final totalPages = (_totalUsers / _pageSize).ceil();
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '共 $_totalUsers 条 · $totalPages 页',
            style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    _currentPage--;
                    _loadUsers();
                  }
                : null,
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          Text('$_currentPage'),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    _currentPage++;
                    _loadUsers();
                  }
                : null,
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }
}

/// 用户编辑对话框
class _UserEditDialog extends StatefulWidget {
  final UserInfo user;
  final List<dynamic> plans;
  final VoidCallback onUpdate;

  const _UserEditDialog({
    required this.user,
    required this.plans,
    required this.onUpdate,
  });

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  // Controllers
  final _emailController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _balanceController = TextEditingController();
  final _commissionController = TextEditingController();
  final _uController = TextEditingController();
  final _dController = TextEditingController();
  final _transferEnableController = TextEditingController();
  final _deviceLimitController = TextEditingController();
  final _speedLimitController = TextEditingController();
  final _commissionRateController = TextEditingController();
  final _discountController = TextEditingController();
  final _remarksController = TextEditingController();

  // State
  int? _planId;
  int? _expiredAt; // Timestamp seconds
  int _commissionType = 0; // 0: System, 1: Cycle, 2: First Time
  bool _banned = false;
  bool _isAdmin = false;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _inviteEmailController.dispose();
    _passwordController.dispose();
    _balanceController.dispose();
    _commissionController.dispose();
    _uController.dispose();
    _dController.dispose();
    _transferEnableController.dispose();
    _deviceLimitController.dispose();
    _speedLimitController.dispose();
    _commissionRateController.dispose();
    _discountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetail() async {
    try {
      final res = await ApiService.instance.getUserInfoById(widget.user.id);
      if (mounted) {
        if (res.success) {
          final data = res.data['data'];
          _populateData(data);
          setState(() => _isLoading = false);
        } else {
          setState(() {
            _error = res.getMessage();
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

  void _populateData(Map<String, dynamic> data) {
    _emailController.text = data['email'] ?? '';
    // Invite User
    if (data['invite_user'] != null) {
      _inviteEmailController.text = data['invite_user']['email'] ?? '';
    }

    _balanceController.text = ((data['balance'] ?? 0) / 100).toString();
    _commissionController.text = ((data['commission_balance'] ?? 0) / 100)
        .toString();

    // Traffic (Bytes -> GB)
    _uController.text = _bytesToGb(data['u'] ?? 0);
    _dController.text = _bytesToGb(data['d'] ?? 0);
    _transferEnableController.text = _bytesToGb(data['transfer_enable'] ?? 0);

    _deviceLimitController.text = (data['device_limit'] ?? '').toString();
    _speedLimitController.text = (data['speed_limit'] ?? '').toString();

    _commissionRateController.text = (data['commission_rate'] ?? '').toString();
    _discountController.text = (data['discount'] ?? '').toString();
    _remarksController.text = data['remarks'] ?? '';

    setState(() {
      _planId = data['plan_id'];
      _expiredAt = data['expired_at'];
      _commissionType = data['commission_type'] ?? 0;
      _banned = data['banned'] == 1;
      _isAdmin = data['is_admin'] == 1;
      _isStaff = data['is_staff'] == 1;
    });
  }

  String _bytesToGb(int bytes) {
    if (bytes == 0) return '0';
    return (bytes / 1073741824).toStringAsFixed(2); // Keep 2 decimals
  }

  int _gbToBytes(String gbStr) {
    if (gbStr.isEmpty) return 0;
    final gb = double.tryParse(gbStr) ?? 0;
    return (gb * 1073741824).toInt();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'id': widget.user.id,
      'email': _emailController.text,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
      if (_inviteEmailController.text.isNotEmpty)
        'invite_user_email': _inviteEmailController.text,
      'balance': (double.parse(_balanceController.text) * 100).toInt(),
      'commission_balance': (double.parse(_commissionController.text) * 100)
          .toInt(),
      'plan_id': _planId,
      'expired_at': _expiredAt,
      'u': _gbToBytes(_uController.text),
      'd': _gbToBytes(_dController.text),
      'transfer_enable': _gbToBytes(_transferEnableController.text),
      'device_limit': int.tryParse(_deviceLimitController.text),
      'speed_limit': int.tryParse(_speedLimitController.text),
      'commission_type': _commissionType,
      'commission_rate': double.tryParse(_commissionRateController.text),
      'discount': int.tryParse(_discountController.text),
      'remarks': _remarksController.text,
      'banned': _banned ? 1 : 0,
      'is_admin': _isAdmin ? 1 : 0,
      'is_staff': _isStaff ? 1 : 0,
    };

    final res = await ApiService.instance.updateUser(data);
    if (mounted) {
      if (res.success) {
        Navigator.pop(context);
        widget.onUpdate();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('更新成功')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.getMessage()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _expiredAt != null
        ? DateTime.fromMillisecondsSinceEpoch(_expiredAt! * 1000)
        : now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // Pick time as well? Web usually allows date.
      // Let's just set to end of day or current time?
      // Or just date. Usually backend takes timestamp.
      // I'll assume 00:00:00 or current time.
      // Let's set to end of day 23:59:59 seems safer for "expire".
      final endOfDay = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
      setState(() {
        _expiredAt = endOfDay.millisecondsSinceEpoch ~/ 1000;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('编辑用户'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 600,
        height: 600,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              )
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
                    tabs: const [
                      Tab(text: '基础信息'),
                      Tab(text: '连接配置'),
                      Tab(text: '高级设置'),
                    ],
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBasicTab(isDark),
                          _buildConnectionTab(isDark),
                          _buildAdvancedTab(isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        if (!_isLoading) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(onPressed: _submit, child: const Text('保存')),
        ] else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
      ],
    );
  }

  Widget _buildBasicTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextField(
            label: '邮箱',
            controller: _emailController,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '邀请人邮箱',
            controller: _inviteEmailController,
            hint: '留空则保持现状/无邀请人',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '密码',
            controller: _passwordController,
            hint: '留空则不修改',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '余额 (元)',
                  controller: _balanceController,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: '佣金 (元)',
                  controller: _commissionController,
                  isNumber: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDropdown<int>(
            label: '订阅套餐',
            value: _planId,
            items: [
              const DropdownMenuItem(value: null, child: Text('无订阅')),
              ...widget.plans.map(
                (e) => DropdownMenuItem<int>(
                  value: e['id'],
                  child: Text(e['name'] ?? ''),
                ),
              ),
              if (_planId != null &&
                  !widget.plans.any((e) => e['id'] == _planId))
                DropdownMenuItem(
                  value: _planId,
                  child: Text('未知套餐 (ID: $_planId)'),
                ),
            ],
            onChanged: (v) => setState(() => _planId = v),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '到期时间',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: Text(
                _expiredAt == null
                    ? '长期有效'
                    : DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(_expiredAt! * 1000),
                      ),
                style: TextStyle(
                  color: _expiredAt == null
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
          if (_expiredAt != null)
            TextButton(
              onPressed: () => setState(() => _expiredAt = null),
              child: const Text('设为长期有效'),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '已用上行 (GB)',
                  controller: _uController,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: '已用下行 (GB)',
                  controller: _dController,
                  isNumber: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '总流量配额 (GB)',
            controller: _transferEnableController,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '设备数限制 (留空不限)',
            controller: _deviceLimitController,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '端口限速 (Mbps, 留空不限)',
            controller: _speedLimitController,
            isNumber: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDropdown<int>(
            label: '推荐返利类型',
            value: _commissionType,
            items: const [
              DropdownMenuItem(value: 0, child: Text('跟随系统设置')),
              DropdownMenuItem(value: 1, child: Text('循环返利 (每次调用)')),
              DropdownMenuItem(value: 2, child: Text('首次返利 (仅首单)')),
            ],
            onChanged: (v) => setState(() => _commissionType = v!),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: '返利比例 (%)',
                  controller: _commissionRateController,
                  isNumber: true,
                  hint: '留空跟随系统',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: '折扣比例 (%)',
                  controller: _discountController,
                  isNumber: true,
                  hint: '留空无折扣',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: '备注',
            controller: _remarksController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _banned,
            onChanged: (v) => setState(() => _banned = v!),
            title: const Text('账户封禁'),
          ),
          CheckboxListTile(
            value: _isAdmin,
            onChanged: (v) => setState(() => _isAdmin = v!),
            title: const Text('管理员权限'),
          ),
          CheckboxListTile(
            value: _isStaff,
            onChanged: (v) => setState(() => _isStaff = v!),
            title: const Text('员工权限'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required ? (v) => v!.isEmpty ? '不能为空' : null : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<T>(
      value: value as T?,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      dropdownColor: isDark ? const Color(0xFF2C2C3E) : Colors.white,
    );
  }
}
