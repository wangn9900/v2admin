import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';

import '../../core/providers/navigation_provider.dart';
import '../../features/auth/auth_provider.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/users/users_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/servers/servers_page.dart';
import '../../features/plans/plans_page.dart';
import '../../features/coupons/coupons_page.dart';
import '../../features/notices/notices_page.dart';
import '../../features/tickets/tickets_page.dart';
import '../../features/system/system_config_page.dart';
import '../../features/payment/payment_config_page.dart';
import '../../features/theme/theme_config_page.dart';
import '../../features/gift_cards/gift_cards_page.dart';
import '../../features/knowledge/knowledge_page.dart';
import '../../features/monitor/queue_monitor_page.dart';

/// 主布局 - 支持响应式侧边栏/底部导航
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 导航分组...
  final List<_NavGroup> _navGroups = [
    _NavGroup(
      title: null, // 无标题的主导航
      items: [
        _NavItem(
          icon: LucideIcons.layoutDashboard,
          label: '仪表盘',
          page: const DashboardPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '用户',
      items: [
        _NavItem(
          icon: LucideIcons.users,
          label: '用户管理',
          page: const UsersPage(),
        ),
        _NavItem(
          icon: LucideIcons.megaphone,
          label: '公告管理',
          page: const NoticesPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '服务器',
      items: [
        _NavItem(
          icon: LucideIcons.server,
          label: '节点管理',
          page: const ServersPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '财务',
      items: [
        _NavItem(
          icon: LucideIcons.package,
          label: '订阅管理',
          page: const PlansPage(),
        ),
        _NavItem(
          icon: LucideIcons.shoppingCart,
          label: '订单管理',
          page: const OrdersPage(),
        ),
        _NavItem(
          icon: LucideIcons.ticket,
          label: '优惠券管理',
          page: const CouponsPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '运营',
      items: [
        _NavItem(
          icon: LucideIcons.gift,
          label: '礼品卡管理',
          page: const GiftCardsPage(),
        ),
        _NavItem(
          icon: LucideIcons.bookOpen,
          label: '知识库管理',
          page: const KnowledgePage(),
        ),
      ],
    ),
    _NavGroup(
      title: '工单',
      items: [
        _NavItem(
          icon: LucideIcons.messageSquare,
          label: '工单管理',
          page: const TicketsPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '指标',
      items: [
        _NavItem(
          icon: LucideIcons.activity,
          label: '队列监控',
          page: const QueueMonitorPage(),
        ),
      ],
    ),
    _NavGroup(
      title: '设置',
      items: [
        _NavItem(
          icon: LucideIcons.settings2,
          label: '系统配置',
          page: const SystemConfigPage(),
        ),
        _NavItem(
          icon: LucideIcons.creditCard,
          label: '支付配置',
          page: const PaymentConfigPage(),
        ),
        _NavItem(
          icon: LucideIcons.palette,
          label: '主题配置',
          page: const ThemeConfigPage(),
        ),
        _NavItem(
          icon: LucideIcons.settings,
          label: '应用设置',
          page: const SettingsPage(),
        ),
      ],
    ),
  ];

  // 获取所有导航项的扁平列表
  List<_NavItem> get _allNavItems {
    final items = <_NavItem>[];
    for (final group in _navGroups) {
      items.addAll(group.items);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 800;
    // 获取当前导航索引
    final currentIndex = context.watch<NavigationProvider>().currentIndex;

    return Scaffold(
      body: isDesktop
          ? _buildDesktopLayout(currentIndex)
          : _buildMobileLayout(currentIndex),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(currentIndex),
    );
  }

  /// 桌面端布局 - 侧边导航栏
  Widget _buildDesktopLayout(int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isExpanded = size.width >= 1100;

    return Row(
      children: [
        // 侧边导航栏
        Container(
          width: isExpanded ? 220 : 72,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo 区域
              Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.shield,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'V2Board',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 导航项
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 10 : 8,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildNavGroups(isExpanded, currentIndex),
                  ),
                ),
              ),

              // 用户信息 & 登出
              _buildUserSection(isExpanded),
            ],
          ),
        ),

        // 主内容区
        Expanded(child: _allNavItems[currentIndex].page),
      ],
    );
  }

  /// 构建导航分组
  List<Widget> _buildNavGroups(bool isExpanded, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final group in _navGroups) {
      // 分组标题
      if (group.title != null && isExpanded) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
            child: Text(
              group.title!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else if (group.title != null && !isExpanded) {
        widgets.add(const SizedBox(height: 12));
        widgets.add(
          Center(
            child: Container(
              width: 24,
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }

      // 分组内的导航项
      for (final item in group.items) {
        final index = globalIndex;
        widgets.add(
          _buildNavItem(
            item: item,
            isSelected: currentIndex == index,
            isExpanded: isExpanded,
            onTap: () => context.read<NavigationProvider>().jumpTo(index),
          ),
        );
        globalIndex++;
      }
    }

    return widgets;
  }

  /// 移动端布局
  Widget _buildMobileLayout(int currentIndex) {
    return _allNavItems[currentIndex].page;
  }

  /// 导航项
  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 12 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 用户区域
  Widget _buildUserSection(bool isExpanded) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Container(
      padding: EdgeInsets.all(isExpanded ? 12 : 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (isExpanded && user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    user.email.isNotEmpty ? user.email[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '管理员',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 登出按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 12 : 0,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.logOut,
                      size: 18,
                      color: AppColors.error,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 10),
                      const Text(
                        '退出登录',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部导航栏 (移动端 - 只显示主要功能)
  Widget _buildBottomNav(int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 移动端只显示5个主要功能
    final mobileItems = [
      (0, LucideIcons.layoutDashboard, '仪表盘'),
      (1, LucideIcons.users, '用户'),
      (5, LucideIcons.shoppingCart, '订单'),
      (9, LucideIcons.messageSquare, '工单'),
      (11, LucideIcons.settings, '设置'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: mobileItems.map((item) {
              final isSelected = currentIndex == item.$1;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        context.read<NavigationProvider>().jumpTo(item.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$2,
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 登出确认对话框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// 导航分组
class _NavGroup {
  final String? title;
  final List<_NavItem> items;

  const _NavGroup({this.title, required this.items});
}

/// 导航项
class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;

  const _NavItem({required this.icon, required this.label, required this.page});
}
