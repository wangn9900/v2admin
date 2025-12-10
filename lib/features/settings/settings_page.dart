import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/storage_service.dart';
import '../../shared/widgets/common_widgets.dart';
import '../auth/auth_provider.dart';
import '../theme/theme_provider.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
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
              '管理应用配置和账户',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),

            // 账户信息
            _buildSectionTitle('账户信息'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: LucideIcons.mail,
                    title: '邮箱',
                    value: user?.email ?? '未登录',
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    icon: LucideIcons.shield,
                    title: '角色',
                    value: (user?.isAdmin == true || user?.isStaff == true)
                        ? '管理员'
                        : '用户',
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    icon: LucideIcons.globe,
                    title: '服务器地址',
                    value: _storage.getBaseUrl() ?? '未配置',
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    icon: LucideIcons.mapPin,
                    title: '本次登录IP',
                    value: authProvider.currentLoginIp ?? '检测中...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 外观设置
            _buildSectionTitle('外观设置'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '主题模式',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildThemeOption(
                        icon: LucideIcons.smartphone,
                        label: '跟随系统',
                        value: 0,
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        icon: LucideIcons.sun,
                        label: '浅色',
                        value: 1,
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        icon: LucideIcons.moon,
                        label: '深色',
                        value: 2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 关于
            _buildSectionTitle('关于'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: LucideIcons.info,
                    title: '版本',
                    value: '1.0.0',
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    icon: LucideIcons.github,
                    title: '开源地址',
                    value: 'v2board/admin',
                    onTap: () {
                      // TODO: 打开 GitHub 链接
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 危险操作
            _buildSectionTitle('危险操作'),
            const SizedBox(height: 12),
            GlassCard(
              borderColor: AppColors.error.withOpacity(0.3),
              child: Column(
                children: [
                  _buildSettingRow(
                    icon: LucideIcons.logOut,
                    title: '退出登录',
                    value: '',
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    onTap: () => _showLogoutDialog(context),
                  ),
                  const Divider(height: 24),
                  _buildSettingRow(
                    icon: LucideIcons.trash2,
                    title: '清除所有数据',
                    value: '',
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    onTap: () => _showClearDataDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                iconColor ??
                (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    titleColor ??
                    (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required int value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.read<ThemeProvider>();
    final isSelected = themeProvider.themeModeIndex == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          themeProvider.setThemeMode(value);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.15)
                : (isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除数据'),
        content: const Text('这将清除所有本地数据，包括登录信息和设置。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storage.clearAll();
              if (context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
            child: const Text('清除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
