import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 简单的防抖辅助类
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

/// 系统配置页面
class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _configData = {};

  // 用于表单状态管理
  final Map<String, TextEditingController> _controllers = {};

  // 记录正在保存的字段，用于显示行内 loading 状态
  final Set<String> _savingFields = {};

  // 防抖器，用于文本输入
  final _debouncer = Debouncer(milliseconds: 1000);

  final List<String> _tabs = [
    '站点',
    '安全',
    '订阅',
    '充值',
    '工单',
    '邀请',
    '个性化',
    '节点',
    '邮件',
    'Telegram',
    'APP',
  ];

  // 选项映射
  final Map<int, String> _resetTrafficMethods = {
    0: '每月1号',
    1: '下单日重置',
    2: '不重置',
    3: '每年1月1日',
    4: '不重置(流量包)',
  };

  final Map<int, String> _ticketStatus = {
    0: '完全开放工单',
    1: '仅允许回复工单',
    2: '关闭工单功能',
  };

  final Map<int, String> _showSubscribeMethods = {0: '永久有效', 1: '仅订阅期间有效'};

  final Map<int, String> _eventActions = {0: '不触发', 1: '重置用户流量'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.instance.get(
        '/config/fetch',
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
          final data = response.getData<Map<String, dynamic>>() ?? {};
          setState(() {
            _configData = data;
            _initControllers(data);
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

  // 初始化所有文本控制器
  void _initControllers(Map<String, dynamic> data) {
    _initControllerForSection(data['site'], [
      'app_name',
      'app_description',
      'app_url',
      'subscribe_url',
      'subscribe_path',
      'tos_url',
      'currency',
      'currency_symbol',
      'try_out_hour',
      'try_out_plan_id',
      'logo',
    ]);
    _initControllerForSection(data['safe'], [
      'secure_path',
      'email_whitelist_suffix',
      'recaptcha_site_key',
      'recaptcha_key',
      'register_limit_count',
      'register_limit_expire',
      'password_limit_count',
      'password_limit_expire',
    ]);
    _initControllerForSection(data['invite'], [
      'invite_commission',
      'invite_gen_limit',
      'commission_withdraw_limit',
      'commission_distribution_l1',
      'commission_distribution_l2',
      'commission_distribution_l3',
    ]);
    _initControllerForSection(data['email'], [
      'email_host',
      'email_port',
      'email_username',
      'email_password',
      'email_encryption',
      'email_from_address',
      'email_template',
    ]);
    _initControllerForSection(data['telegram'], [
      'telegram_bot_token',
      'telegram_discuss_link',
    ]);
    _initControllerForSection(data['server'], [
      'server_api_url',
      'server_token',
      'server_pull_interval',
      'server_push_interval',
      'server_node_report_min_traffic',
      'server_device_online_min_traffic',
    ]);
    _initControllerForSection(data['frontend'], ['frontend_background_url']);
    _initControllerForSection(data['app'], [
      'windows_version',
      'windows_download_url',
      'macos_version',
      'macos_download_url',
      'android_version',
      'android_download_url',
    ]);

    // 特殊处理 deposit_bounus (List -> String)
    if (data['deposit'] != null && data['deposit']['deposit_bounus'] != null) {
      final bonusList = data['deposit']['deposit_bounus'];
      if (bonusList is List) {
        _controllers['deposit_bounus'] = TextEditingController(
          text: bonusList.join(','),
        );
      } else {
        _controllers['deposit_bounus'] = TextEditingController();
      }
    } else {
      _controllers['deposit_bounus'] = TextEditingController();
    }
  }

  void _initControllerForSection(dynamic sectionData, List<String> keys) {
    if (sectionData is! Map) return;
    for (var key in keys) {
      if (!_controllers.containsKey(key)) {
        _controllers[key] = TextEditingController(
          text: sectionData[key]?.toString() ?? '',
        );
      } else {
        _controllers[key]!.text = sectionData[key]?.toString() ?? '';
      }
    }
  }

  // 核心方法：更新单个配置项
  Future<void> _updateConfig(String key, dynamic value) async {
    setState(() => _savingFields.add(key));

    try {
      final Map<String, dynamic> submitData = {key: value};

      // 特殊逻辑：如果是更新 deposit_bounus，需要解析为数组 List
      if (key == 'deposit_bounus' && value is String) {
        if (value.isNotEmpty) {
          submitData[key] = value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          submitData[key] = [];
        }
      }

      final response = await ApiService.instance.post(
        '/config/save',
        data: submitData,
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('保存成功'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              // margin: const EdgeInsets.all(16), // REMOVED: cannot use with width
              width: 150, // Small nice feedback
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存失败: ${response.getMessage()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('网络错误: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _savingFields.remove(key));
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
                        '系统配置',
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
                        '修改配置后将自动保存并更新服务端缓存',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadData,
                  tooltip: '刷新配置',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              tabs: _tabs.map((e) => Tab(text: e)).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: '加载系统配置...')
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
                : TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSiteTab(),
                      _buildSafeTab(),
                      _buildSubscribeTab(),
                      _buildDepositTab(),
                      _buildTicketTab(),
                      _buildInviteTab(),
                      _buildFrontendTab(),
                      _buildServerTab(),
                      _buildEmailTab(),
                      _buildTelegramTab(),
                      _buildAppTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: children
            .map(
              (widget) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: widget,
              ),
            )
            .toList(),
      ),
    );
  }

  // --- Tabs ---

  Widget _buildSiteTab() {
    return _buildConfigSection(
      children: [
        _buildCard('基础设置', [
          _buildTextField('app_name', '站点名称', '用于显示站点名称'),
          const SizedBox(height: 16),
          _buildTextField('app_description', '站点描述', '用于站点SEO描述'),
          const SizedBox(height: 16),
          _buildTextField('app_url', '站点网址', '当前网站最新网址'),
          const SizedBox(height: 16),
          _buildTextField('logo', 'Logo URL', '用于显示站点Logo的URL'),
        ]),
        _buildCard('订阅设置', [
          _buildTextField('subscribe_url', '订阅URL', '留空则为站点URL。多个域名请用逗号分割'),
          const SizedBox(height: 16),
          _buildTextField(
            'subscribe_path',
            '订阅路径',
            '默认为 /api/v1/client/subscribe',
          ),
        ]),
        _buildCard('其他设置', [
          _buildTextField('tos_url', '用户条款 URL', '用户注册时显示的条款链接'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('currency', '货币单位', '如: CNY')),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('currency_symbol', '货币符号', '如: ¥'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitch('site', 'stop_register', '停止新用户注册'),
          _buildSwitch('site', 'force_https', '强制 HTTPS'),
        ]),
        _buildCard('试用设置', [
          Row(
            children: [
              Expanded(
                child: _buildTextField('try_out_hour', '试用时长 (小时)', '0代表不试用'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('try_out_plan_id', '试用订阅ID', '绑定此ID的订阅'),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildSafeTab() {
    final safe = _configData['safe'] ?? {};
    return _buildConfigSection(
      children: [
        _buildCard('验证设置', [
          _buildSwitch('safe', 'email_verify', '邮箱验证'),
          _buildSwitch('safe', 'email_whitelist_enable', '邮箱白名单'),
          if (safe['email_whitelist_enable'] == 1) ...[
            const SizedBox(height: 16),
            _buildTextField(
              'email_whitelist_suffix',
              '允许的邮箱后缀',
              'gmail.com, outlook.com',
            ),
          ],
          _buildSwitch('safe', 'register_limit_by_ip_enable', '注册IP限制'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField('register_limit_count', '单IP注册限制数量'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('register_limit_expire', '限制周期 (分钟)'),
              ),
            ],
          ),
        ]),
        _buildCard('安全设置', [
          _buildTextField('secure_path', '安全路径', '后台管理访问路径'),
          const SizedBox(height: 16),
          _buildSwitch(
            'safe',
            'safe_mode_enable',
            '安全模式',
            subtitle: '开启后将不会向客户端下发具体的节点地址',
          ),
          _buildSwitch('safe', 'password_limit_enable', '密码重试限制'),
        ]),
        _buildCard('reCaptcha', [
          _buildSwitch('safe', 'recaptcha_enable', '启用 reCaptcha'),
          if (safe['recaptcha_enable'] == 1) ...[
            const SizedBox(height: 16),
            _buildTextField('recaptcha_site_key', 'Site Key'),
            const SizedBox(height: 16),
            _buildTextField('recaptcha_key', 'Secret Key'),
          ],
        ]),
      ],
    );
  }

  Widget _buildSubscribeTab() {
    return _buildConfigSection(
      children: [
        _buildCard('用户设置', [
          _buildSwitch(
            'subscribe',
            'plan_change_enable',
            '允许用户更改订阅',
            subtitle: '开启后用户将可以对订阅计划进行更改',
          ),
        ]),
        _buildCard('流量设置', [
          _buildSelect(
            'subscribe',
            'reset_traffic_method',
            '月流量重置方式',
            _resetTrafficMethods,
            subtitle: '全局流量重置方式，默认每月1号',
          ),
          _buildSwitch(
            'subscribe',
            'surplus_enable',
            '开启折抵方案',
            subtitle: '开启后用户更换订阅系统会对原有订阅进行折抵',
          ),
          _buildSwitch(
            'subscribe',
            'allow_new_period',
            '允许提前开启流量周期',
            subtitle: '开启后用户流量用尽时可以选择扣除订阅时长为代价重置流量',
          ),
        ]),
        _buildCard('事件设置', [
          _buildSelect(
            'subscribe',
            'new_order_event_id',
            '当订阅购买时触发事件',
            _eventActions,
          ),
          _buildSelect(
            'subscribe',
            'renew_order_event_id',
            '当订阅续费时触发事件',
            _eventActions,
          ),
          _buildSelect(
            'subscribe',
            'change_order_event_id',
            '当订阅更变时触发事件',
            _eventActions,
          ),
        ]),
        _buildCard('显示设置', [
          _buildSwitch(
            'subscribe',
            'show_info_to_server_enable',
            '在订阅中展示订阅信息',
            subtitle: '开启后将会向用户订阅节点时输出订阅信息',
          ),
          _buildSelect(
            'subscribe',
            'show_subscribe_method',
            '订阅链接生效模式',
            _showSubscribeMethods,
          ),
        ]),
      ],
    );
  }

  Widget _buildDepositTab() {
    return _buildConfigSection(
      children: [
        _buildCard('充值奖励', [
          _buildTextField(
            'deposit_bounus',
            '充值奖励规则',
            '充值一定金额可以获得的奖励。\n格式：充值金额:赠送金额，多个规则用逗号分割。例如：50:5,100:10',
          ),
        ]),
      ],
    );
  }

  Widget _buildTicketTab() {
    return _buildConfigSection(
      children: [
        _buildCard('工单设置', [
          _buildSelect('ticket', 'ticket_status', '工单状态设置', _ticketStatus),
        ]),
      ],
    );
  }

  Widget _buildInviteTab() {
    final invite = _configData['invite'] ?? {};
    return _buildConfigSection(
      children: [
        _buildCard('邀请设置', [
          _buildSwitch('invite', 'invite_force', '强制邀请码注册'),
          const SizedBox(height: 16),
          _buildTextField('invite_commission', '默认佣金比例 (%)'),
          const SizedBox(height: 16),
          _buildTextField('invite_gen_limit', '邀请码生成上限'),
          const SizedBox(height: 16),
          _buildSwitch('invite', 'invite_never_expire', '邀请码永不过期'),
        ]),
        _buildCard('佣金设置', [
          _buildTextField('commission_withdraw_limit', '最低提现金额'),
          const SizedBox(height: 16),
          _buildSwitch('invite', 'commission_first_time_enable', '仅首充返佣'),
          _buildSwitch(
            'invite',
            'commission_auto_check_enable',
            '佣金自动确认',
            subtitle: '订单完成后自动确认佣金',
          ),
          _buildSwitch('invite', 'withdraw_close_enable', '关闭提现功能'),
          _buildSwitch('invite', 'commission_distribution_enable', '三级分销'),
          if (invite['commission_distribution_enable'] == 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'commission_distribution_l1',
                    '一级 (%)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    'commission_distribution_l2',
                    '二级 (%)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    'commission_distribution_l3',
                    '三级 (%)',
                  ),
                ),
              ],
            ),
          ],
        ]),
      ],
    );
  }

  Widget _buildFrontendTab() {
    return _buildConfigSection(
      children: [
        _buildCard('个性化设置', [
          _buildTextField('frontend_background_url', '背景图片 URL'),
        ]),
      ],
    );
  }

  Widget _buildServerTab() {
    return _buildConfigSection(
      children: [
        _buildCard('API 对接', [
          _buildTextField('server_api_url', '节点对接API地址', 'v2node节点一键对接专用地址'),
          const SizedBox(height: 16),
          _buildTextField('server_token', '通讯密钥', 'V2Board与节点通讯的密钥'),
        ]),
        _buildCard('动作与阈值', [
          _buildTextField('server_pull_interval', '节点拉取动作轮询间隔 (秒)'),
          const SizedBox(height: 16),
          _buildTextField('server_push_interval', '节点推送动作轮询间隔 (秒)'),
          const SizedBox(height: 16),
          _buildTextField(
            'server_node_report_min_traffic',
            '节点用户流量上报最低阈值 (KB)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'server_device_online_min_traffic',
            '节点用户设备数统计最低阈值 (KB)',
          ),
          const SizedBox(height: 16),
          _buildSwitch(
            'server',
            'device_limit_mode',
            '全局设备数宽松模式',
            subtitle: '开启后同一IP多个连接只算一个设备',
          ),
        ]),
      ],
    );
  }

  Widget _buildEmailTab() {
    return _buildConfigSection(
      children: [
        _buildCard('SMTP 设置', [
          _buildTextField('email_host', 'SMTP 服务器'),
          const SizedBox(height: 16),
          _buildTextField('email_port', 'SMTP 端口'),
          const SizedBox(height: 16),
          _buildTextField('email_username', 'SMTP 用户名'),
          const SizedBox(height: 16),
          _buildTextField('email_password', 'SMTP 密码'),
          const SizedBox(height: 16),
          _buildTextField('email_encryption', '加密方式 (ssl/tls)'),
          const SizedBox(height: 16),
          _buildTextField('email_from_address', '发件人地址'),
          const SizedBox(height: 16),
          _buildTextField('email_template', '邮件模板', '留空则使用默认'),
        ]),
      ],
    );
  }

  Widget _buildTelegramTab() {
    return _buildConfigSection(
      children: [
        _buildCard('Telegram Bot', [
          _buildSwitch('telegram', 'telegram_bot_enable', '启用 Telegram Bot'),
          const SizedBox(height: 16),
          _buildTextField('telegram_bot_token', 'Bot Token'),
          const SizedBox(height: 16),
          _buildTextField('telegram_discuss_link', '群组链接'),
        ]),
      ],
    );
  }

  Widget _buildAppTab() {
    return _buildConfigSection(
      children: [
        _buildCard('Windows', [
          _buildTextField('windows_version', '版本号'),
          const SizedBox(height: 16),
          _buildTextField('windows_download_url', '下载链接'),
        ]),
        _buildCard('macOS', [
          _buildTextField('macos_version', '版本号'),
          const SizedBox(height: 16),
          _buildTextField('macos_download_url', '下载链接'),
        ]),
        _buildCard('Android', [
          _buildTextField('android_version', '版本号'),
          const SizedBox(height: 16),
          _buildTextField('android_download_url', '下载链接'),
        ]),
      ],
    );
  }

  // --- Components ---

  Widget _buildCard(String title, List<Widget> children) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String key, String label, [String? helperText]) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
    }

    // Check if this specific field is currently saving
    bool isSaving = _savingFields.contains(key);

    return TextField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      minLines: 1,
      maxLines: 3,
      onChanged: (value) {
        _debouncer.run(() => _updateConfig(key, value));
      },
    );
  }

  Widget _buildSelect(
    String section,
    String key,
    String label,
    Map<int, String> options, {
    String? subtitle,
  }) {
    final sectionData = _configData[section] ?? {};
    int? currentDate = int.tryParse(sectionData[key]?.toString() ?? '0');
    currentDate ??= 0;

    bool isSaving = _savingFields.contains(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (isSaving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: options.containsKey(currentDate) ? currentDate : null,
              hint: const Text('请选择'),
              isExpanded: true,
              items: options.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    if (_configData[section] == null) {
                      _configData[section] = {};
                    }
                    _configData[section][key] = newValue;
                  });
                  _updateConfig(key, newValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitch(
    String section,
    String key,
    String label, {
    String? subtitle,
  }) {
    final sectionData = _configData[section] ?? {};
    bool value = false;
    var rawValue = sectionData[key];
    if (rawValue is bool)
      value = rawValue;
    else if (rawValue is int)
      value = rawValue == 1;
    else if (rawValue is String)
      value = rawValue == '1' || rawValue == 'true';

    bool isSaving = _savingFields.contains(key);

    return SwitchListTile(
      title: Row(
        children: [
          Text(label),
          if (isSaving) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      value: value,
      onChanged: (newValue) {
        setState(() {
          if (_configData[section] == null) {
            _configData[section] = {};
          }
          _configData[section][key] = newValue ? 1 : 0;
        });
        _updateConfig(key, newValue ? 1 : 0);
      },
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }
}
