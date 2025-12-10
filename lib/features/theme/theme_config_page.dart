import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 主题配置页面
class ThemeConfigPage extends StatefulWidget {
  const ThemeConfigPage({super.key});

  @override
  State<ThemeConfigPage> createState() => _ThemeConfigPageState();
}

class _ThemeConfigPageState extends State<ThemeConfigPage> {
  Map<String, dynamic> _themes = {};
  String _activeTheme = 'v2board';
  String? _selectedTheme;
  Map<String, dynamic> _themeConfig = {};
  bool _isLoading = true;
  bool _isSaving = false;
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
        '/theme/getThemes',
        isAdmin: true,
      );

      if (mounted) {
        setState(() {
          if (response.success) {
            final data = response.data['data'] ?? {};
            _themes = Map<String, dynamic>.from(data['themes'] ?? {});
            _activeTheme = data['active'] ?? 'v2board';
            _selectedTheme = _activeTheme;
            if (_selectedTheme != null && _themes.isNotEmpty) {
              _loadThemeConfig(_selectedTheme!);
            }
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

  Future<void> _loadThemeConfig(String themeName) async {
    try {
      final response = await ApiService.instance.get(
        '/theme/getThemeConfig',
        queryParameters: {'name': themeName},
        isAdmin: true,
      );

      if (mounted && response.success) {
        setState(() {
          _themeConfig = Map<String, dynamic>.from(
            response.getData<Map>() ?? {},
          );
        });
      }
    } catch (e) {
      debugPrint('加载主题配置失败: $e');
    }
  }

  Future<void> _saveThemeConfig() async {
    if (_selectedTheme == null) return;

    setState(() => _isSaving = true);

    try {
      final configJson = jsonEncode(_themeConfig);
      final configBase64 = base64Encode(utf8.encode(configJson));

      final response = await ApiService.instance.post(
        '/theme/saveThemeConfig',
        data: {'name': _selectedTheme, 'config': configBase64},
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('保存成功'),
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
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                        '主题配置',
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
                        '管理前端主题和样式',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
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
                : _themes.isEmpty
                ? const EmptyState(
                    title: '暂无主题',
                    subtitle: '没有可用的主题',
                    icon: LucideIcons.palette,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 主题选择
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.palette,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '选择主题',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  StatusBadge(
                                    text: '当前: $_activeTheme',
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _themes.keys.map((themeName) {
                                  final isSelected =
                                      _selectedTheme == themeName;
                                  final themeInfo =
                                      _themes[themeName]
                                          as Map<String, dynamic>?;
                                  final displayName =
                                      themeInfo?['name'] ?? themeName;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(
                                        () => _selectedTheme = themeName,
                                      );
                                      _loadThemeConfig(themeName);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(
                                                0.15,
                                              )
                                            : (isDark
                                                  ? AppColors.cardDark
                                                  : Colors.grey[200]),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSelected
                                            ? Border.all(
                                                color: AppColors.primary,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSelected
                                                ? LucideIcons.checkCircle
                                                : LucideIcons.circle,
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                      ? AppColors.textMutedDark
                                                      : AppColors
                                                            .textMutedLight),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            displayName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 主题配置表单
                        if (_selectedTheme != null &&
                            _themes[_selectedTheme] != null)
                          _buildThemeConfigForm(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeConfigForm() {
    final themeInfo = _themes[_selectedTheme] as Map<String, dynamic>?;
    final configs = themeInfo?['configs'] as List<dynamic>? ?? [];

    if (configs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '该主题没有配置项',
            style: TextStyle(color: AppColors.textMutedDark),
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sliders, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                '主题配置 - $_selectedTheme',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveThemeConfig,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.save, size: 18),
                label: Text(_isSaving ? '保存中...' : '保存配置'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...configs.map((config) {
            final fieldName = config['field_name'] ?? '';
            final label = config['label'] ?? fieldName;
            final placeholder = config['placeholder'] ?? '';
            final fieldType = config['field_type'] ?? 'input';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildConfigField(
                fieldName: fieldName,
                label: label,
                placeholder: placeholder,
                fieldType: fieldType,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfigField({
    required String fieldName,
    required String label,
    required String placeholder,
    required String fieldType,
  }) {
    final currentValue = _themeConfig[fieldName]?.toString() ?? '';

    switch (fieldType) {
      case 'switch':
        return SwitchListTile(
          title: Text(label),
          value: currentValue == '1' || currentValue == 'true',
          onChanged: (value) {
            setState(() {
              _themeConfig[fieldName] = value ? '1' : '0';
            });
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      case 'textarea':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: currentValue,
              decoration: InputDecoration(hintText: placeholder),
              maxLines: 5,
              onChanged: (value) {
                _themeConfig[fieldName] = value;
              },
            ),
          ],
        );
      default:
        return TextFormField(
          initialValue: currentValue,
          decoration: InputDecoration(labelText: label, hintText: placeholder),
          onChanged: (value) {
            _themeConfig[fieldName] = value;
          },
        );
    }
  }
}
