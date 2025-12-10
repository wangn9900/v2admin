import 'package:flutter/material.dart';

/// V2Board Admin 应用配色方案
/// 现代深色主题，支持浅色模式切换
class AppColors {
  AppColors._();

  // ============ 深色主题配色 ============
  
  /// 主色调 - 靛蓝紫
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  /// 渐变主色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// 强调色 - 青色
  static const Color accent = Color(0xFF22D3EE);
  static const Color accentLight = Color(0xFF67E8F9);
  
  /// 背景色
  static const Color backgroundDark = Color(0xFF0F0F23);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceVariantDark = Color(0xFF252542);
  static const Color cardDark = Color(0xFF16162A);
  
  /// 边框色
  static const Color borderDark = Color(0xFF2A2A4A);
  static const Color borderLightDark = Color(0xFF3A3A5A);
  
  /// 文字色
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);
  
  // ============ 浅色主题配色 ============
  
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderLightLight = Color(0xFFCBD5E1);
  
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  
  // ============ 语义色彩 ============
  
  /// 成功色 - 翠绿
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successBg = Color(0xFF10B98120);
  
  /// 警告色 - 琥珀
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningBg = Color(0xFFF59E0B20);
  
  /// 错误色 - 玫红
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorBg = Color(0xFFEF444420);
  
  /// 信息色 - 天蓝
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoBg = Color(0xFF3B82F620);
  
  // ============ 图表配色 ============
  
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFF22D3EE),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];
  
  // ============ 玻璃拟态效果 ============
  
  static Color glassBackground(bool isDark) => isDark 
      ? const Color(0xFF1A1A2E).withOpacity(0.7)
      : Colors.white.withOpacity(0.7);
      
  static Color glassBorder(bool isDark) => isDark
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.1);
}
