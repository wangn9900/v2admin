import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/common_widgets.dart';
import 'auth_provider.dart';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _securePathController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 代理相关控制器
  final _proxyHostController = TextEditingController(text: '127.0.0.1');
  final _proxyPortController = TextEditingController(text: '7890');
  bool _proxyEnable = false;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showAdvanced = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    final storage = StorageService.instance;
    final baseUrl = storage.getBaseUrl();
    final securePath = storage.getSecurePath();
    final email = storage.getUserEmail();

    setState(() {
      if (baseUrl != null) _baseUrlController.text = baseUrl;
      if (securePath != null) _securePathController.text = securePath;
      if (email != null) _emailController.text = email;
    });

    // 加载代理设置
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _proxyHostController.text = prefs.getString('proxy_host') ?? '127.0.0.1';
      _proxyPortController.text = prefs.getString('proxy_port') ?? '7890';
      _proxyEnable = prefs.getBool('proxy_enable') ?? false;
    });

    // 初始化时应用一次代理设置
    if (_proxyEnable) {
      ApiService.instance.setProxy(
        _proxyHostController.text,
        _proxyPortController.text,
        _proxyEnable,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _baseUrlController.dispose();
    _securePathController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    // 登录前先应用代理设置
    await ApiService.instance.setProxy(
      _proxyHostController.text.trim(),
      _proxyPortController.text.trim(),
      _proxyEnable,
    );

    final success = await authProvider.login(
      baseUrl: _baseUrlController.text.trim(),
      securePath: _securePathController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? '登录失败'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16162A)],
          ),
        ),
        child: Stack(
          children: [
            // 背景装饰
            _buildBackgroundDecoration(),

            // 主内容
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.1 : 24,
                    vertical: 32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: isWide
                          ? _buildWideLayout(size)
                          : _buildNarrowLayout(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 宽屏布局 (桌面端)
  Widget _buildWideLayout(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 左侧品牌区
        Expanded(child: _buildBrandSection()),
        const SizedBox(width: 60),
        // 右侧登录表单
        SizedBox(width: 420, child: _buildLoginCard()),
      ],
    );
  }

  /// 窄屏布局 (移动端)
  Widget _buildNarrowLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildLogo(), const SizedBox(height: 32), _buildLoginCard()],
    );
  }

  /// 品牌展示区
  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogo(),
        const SizedBox(height: 24),
        const Text(
          'V2Board Admin',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '强大的代理服务管理后台\n支持多平台、多协议、实时统计',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureList(),
      ],
    );
  }

  /// Logo
  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(LucideIcons.shield, color: Colors.white, size: 36),
    );
  }

  /// 特性列表
  Widget _buildFeatureList() {
    final features = [
      ('用户管理', '轻松管理用户账户和套餐'),
      ('订单追踪', '实时查看订单状态和收入'),
      ('节点监控', '全面掌控服务器运行状态'),
      ('数据统计', '直观的图表和报表分析'),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        f.$2,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// 登录卡片
  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '管理员登录',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请输入您的管理员凭证',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 32),

                // 服务器地址
                _buildTextField(
                  controller: _baseUrlController,
                  label: '服务器地址',
                  hint: 'https://your-domain.com',
                  icon: LucideIcons.globe,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入服务器地址';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return '请输入有效的 URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 高级选项切换
                GestureDetector(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.textSecondaryDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '高级选项',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // 安全路径 (高级选项)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildTextField(
                      controller: _securePathController,
                      label: '安全路径',
                      hint: 'admin',
                      icon: LucideIcons.lock,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入安全路径';
                        }
                        return null;
                      },
                    ),
                  ),
                  crossFadeState: _showAdvanced
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 16),

                // 代理设置 (高级选项)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.network,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '代理设置',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _proxyEnable,
                                onChanged: (val) =>
                                    setState(() => _proxyEnable = val),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                          if (_proxyEnable) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _proxyHostController,
                                    label: '主机 (Host)',
                                    hint: '127.0.0.1',
                                    icon: LucideIcons.server,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: _buildTextField(
                                    controller: _proxyPortController,
                                    label: '端口',
                                    hint: '7890',
                                    icon: LucideIcons.plug,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: _showAdvanced
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                const SizedBox(height: 16),

                // 邮箱
                _buildTextField(
                  controller: _emailController,
                  label: '邮箱',
                  hint: 'admin@example.com',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入邮箱';
                    }
                    if (!value.contains('@')) {
                      return '请输入有效的邮箱';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码
                _buildTextField(
                  controller: _passwordController,
                  label: '密码',
                  hint: '请输入密码',
                  icon: LucideIcons.keyRound,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      color: AppColors.textMutedDark,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 32),

                // 登录按钮
                GradientButton(
                  text: '登录',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                  icon: LucideIcons.logIn,
                ),

                const SizedBox(height: 24),

                // 版权信息
                Center(
                  child: Text(
                    'V2Board Admin © 2024',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 输入框组件
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: AppColors.textMutedDark, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// 背景装饰
  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        // 渐变光晕 1
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
        // 渐变光晕 2
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  AppColors.accent.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
