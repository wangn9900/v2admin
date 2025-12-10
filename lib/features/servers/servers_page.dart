import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 节点管理页面
class ServersPage extends StatefulWidget {
  const ServersPage({super.key});

  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  List<dynamic> _servers = [];
  List<dynamic> _groups = [];
  List<dynamic> _routes = [];
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
      final results = await Future.wait([
        ApiService.instance.getServerNodes(),
        ApiService.instance.getServerGroups(),
        ApiService.instance.get('/server/route/fetch', isAdmin: true),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].success) {
            _servers = results[0].getData<List>() ?? [];
          } else {
            _error = results[0].getMessage();
          }
          if (results[1].success) {
            _groups = results[1].getData<List>() ?? [];
          }
          if (results[2].success) {
            _routes = results[2].getData<List>() ?? [];
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
                        '节点管理',
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
                        '管理所有代理服务器节点 (${_servers.length} 个)',
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
                  text: '添加节点',
                  icon: LucideIcons.plus,
                  onPressed: () => _showServerFormDialog(null),
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
                    child: _servers.isEmpty
                        ? const EmptyState(
                            title: '暂无节点',
                            subtitle: '点击添加节点按钮创建新节点',
                            icon: LucideIcons.server,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _servers.length,
                            itemBuilder: (context, index) =>
                                _buildServerCard(_servers[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(dynamic server) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = server['id'];
    final name = server['name'] ?? 'Unknown';
    final type = server['type'] ?? 'unknown';
    final host = server['host'] ?? '';
    final port = server['port'] ?? server['server_port'] ?? 0;
    final show = server['show'] == 1;
    final rate = server['rate'] ?? 1.0;
    final tags = server['tags'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#$id',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$host:$port',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: show,
                  onChanged: (value) => _toggleServerShow(server, value),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatusBadge(
                  text: type.toString().toUpperCase(),
                  color: _getTypeColor(type),
                ),
                const SizedBox(width: 8),
                StatusBadge(text: '${rate}x', color: AppColors.info),
                if (tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ...tags
                      .take(2)
                      .map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: StatusBadge(
                            text: tag.toString(),
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                ],
                const Spacer(),
                // 在线人数显示
                Builder(
                  builder: (context) {
                    final onlineCount =
                        int.tryParse(server['online']?.toString() ?? '0') ?? 0;
                    final isOnline = onlineCount > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 14,
                            color: isOnline
                                ? AppColors.success
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$onlineCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline
                                  ? AppColors.success
                                  : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showServerFormDialog(server),
                  icon: const Icon(
                    LucideIcons.edit2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: () => _copyServer(server),
                  icon: Icon(
                    LucideIcons.copy,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  tooltip: '复制',
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirm(server),
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

  /// 显示排序对话框
  void _showSortDialog(dynamic server) {
    final sortController = TextEditingController(
      text: (server['sort'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置排序 - ${server['name']}'),
        content: TextField(
          controller: sortController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '排序值',
            hintText: '数值越小越靠前',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final newSort = int.tryParse(sortController.text) ?? 0;
              await _updateServerSort(server, newSort);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 更新节点排序
  Future<void> _updateServerSort(dynamic server, int sort) async {
    try {
      final type = server['type'] ?? 'shadowsocks';
      final response = await ApiService.instance.post(
        '/server/manage/sort',
        data: {
          type: {server['id'].toString(): sort},
        },
        isAdmin: true,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('排序已保存'),
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
          SnackBar(content: Text('保存失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showServerFormDialog(dynamic server) {
    final isEdit = server != null;
    String selectedType = server?['type'] ?? 'shadowsocks';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => _ServerFormDialog(
        server: server,
        isEdit: isEdit,
        initialType: selectedType,
        groups: _groups,
        routes: _routes,
        servers: _servers,
        onSave: (data, type) async {
          // 先关闭对话框
          Navigator.of(dialogContext).pop();

          try {
            debugPrint('正在${isEdit ? "更新" : "创建"}节点: $data');
            final response = await ApiService.instance.post(
              isEdit ? '/server/$type/update' : '/server/$type/save',
              data: data,
              isAdmin: true,
            );

            debugPrint(
              'API 响应: ${response.success} - ${response.getMessage()}',
            );

            if (mounted) {
              if (response.success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? '保存成功' : '创建成功'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadData();
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(response.getMessage()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('操作失败: $e');
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('操作失败: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleServerShow(dynamic server, bool show) async {
    try {
      final type = server['type'] ?? 'shadowsocks';
      final response = await ApiService.instance.post(
        '/server/$type/update',
        data: {'id': server['id'], 'show': show ? 1 : 0},
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

  void _copyServer(dynamic server) {
    final copy = Map<String, dynamic>.from(server);
    copy.remove('id');
    copy['name'] = '${copy['name']} (副本)';
    _showServerFormDialog(copy);
  }

  void _showDeleteConfirm(dynamic server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除节点 "${server['name']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final type = server['type'] ?? 'shadowsocks';
              final response = await ApiService.instance.post(
                '/server/$type/drop',
                data: {'id': server['id']},
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
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'shadowsocks':
        return Colors.blue;
      case 'vmess':
        return Colors.purple;
      case 'trojan':
        return Colors.orange;
      case 'vless':
        return Colors.teal;
      case 'hysteria':
        return Colors.pink;
      case 'anytls':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'shadowsocks':
        return LucideIcons.shield;
      case 'vmess':
        return LucideIcons.lock;
      case 'trojan':
        return LucideIcons.shield;
      case 'vless':
        return LucideIcons.zap;
      case 'hysteria':
        return LucideIcons.rocket;
      case 'anytls':
        return LucideIcons.key;
      default:
        return LucideIcons.server;
    }
  }
}

/// 节点表单对话框
class _ServerFormDialog extends StatefulWidget {
  final dynamic server;
  final bool isEdit;
  final String initialType;
  final List<dynamic> groups;
  final List<dynamic> routes;
  final List<dynamic> servers;
  final Future<void> Function(Map<String, dynamic> data, String type) onSave;

  const _ServerFormDialog({
    this.server,
    required this.isEdit,
    required this.initialType,
    required this.groups,
    required this.routes,
    required this.servers,
    required this.onSave,
  });

  @override
  State<_ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<_ServerFormDialog> {
  late String _selectedType;
  final _formKey = GlobalKey<FormState>();

  // 通用字段
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _serverPortController;
  late TextEditingController _rateController;
  late TextEditingController _tagsController;
  bool _show = true;
  int? _parentId;
  int? _routeId;
  List<String> _selectedGroups = [];

  // Shadowsocks
  String _ssCipher = 'aes-256-gcm';

  // VMess/VLESS 通用
  String _network = 'tcp';
  int _tls = 0; // 0: 无, 1: TLS, 2: Reality
  late TextEditingController _sniController;
  bool _allowInsecure = false;

  // VLESS 特有
  String _vlessFlow = '';
  late TextEditingController _realityPrivateKey;
  late TextEditingController _realityPublicKey;
  late TextEditingController _realityShortId;
  String _fingerprint = 'chrome';
  late TextEditingController _realityServerAddr;
  late TextEditingController _realityServerPort;
  int _realityProxyProtocol = 0;

  // Hysteria
  int _hyVersion = 2;
  late TextEditingController _hyUpMbps;
  late TextEditingController _hyDownMbps;
  late TextEditingController _hyObfs;
  late TextEditingController _hyObfsPassword;

  // AnyTLS
  late TextEditingController _paddingScheme;

  final List<String> _serverTypes = [
    'shadowsocks',
    'vmess',
    'trojan',
    'vless',
    'hysteria',
    'anytls',
  ];
  final List<String> _ssCiphers = [
    'aes-128-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
  ];
  final List<String> _networks = ['tcp', 'ws', 'grpc', 'h2', 'quic'];
  final List<String> _vlessFlows = [
    '',
    'xtls-rprx-vision',
    'xtls-rprx-vision-udp443',
  ];
  final List<String> _fingerprints = [
    'chrome',
    'firefox',
    'safari',
    'ios',
    'android',
    'edge',
    'random',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _initControllers();
  }

  void _initControllers() {
    final s = widget.server;

    _nameController = TextEditingController(text: s?['name'] ?? '');
    _hostController = TextEditingController(text: s?['host'] ?? '');
    _portController = TextEditingController(
      text: (s?['port'] ?? 443).toString(),
    );
    _serverPortController = TextEditingController(
      text: (s?['server_port'] ?? s?['port'] ?? 443).toString(),
    );
    _rateController = TextEditingController(text: (s?['rate'] ?? 1).toString());
    _tagsController = TextEditingController(
      text: (s?['tags'] as List?)?.join(',') ?? '',
    );
    _show = s?['show'] == 1 || s == null;
    _parentId = s?['parent_id'];
    _routeId = s?['route_id'];

    // Groups
    final groupId = s?['group_id'];
    if (groupId != null) {
      if (groupId is List) {
        _selectedGroups = groupId.map((e) => e.toString()).toList();
      } else {
        _selectedGroups = [groupId.toString()];
      }
    }

    // Shadowsocks
    _ssCipher = s?['cipher'] ?? 'aes-256-gcm';

    // VMess/VLESS/Trojan
    _network = s?['network'] ?? 'tcp';
    _tls = s?['tls'] ?? 0;
    _sniController = TextEditingController(text: s?['server_name'] ?? '');
    _allowInsecure = s?['allow_insecure'] == 1 || s?['insecure'] == 1;

    // VLESS
    _vlessFlow = s?['flow'] ?? '';

    // Reality settings from tls_settings
    final tlsSettings = s?['tls_settings'] ?? {};
    _realityPrivateKey = TextEditingController(
      text: tlsSettings['private_key'] ?? '',
    );
    _realityPublicKey = TextEditingController(
      text: tlsSettings['public_key'] ?? '',
    );
    _realityShortId = TextEditingController(
      text: tlsSettings['short_id'] ?? '',
    );
    _fingerprint = tlsSettings['fingerprint'] ?? 'chrome';
    _realityServerAddr = TextEditingController(
      text: tlsSettings['server_name'] ?? '',
    );
    _realityServerPort = TextEditingController(
      text: (tlsSettings['server_port'] ?? 443).toString(),
    );
    _realityProxyProtocol = tlsSettings['proxy_protocol'] ?? 0;

    // Hysteria
    _hyVersion = s?['version'] ?? 2;
    _hyUpMbps = TextEditingController(text: (s?['up_mbps'] ?? 100).toString());
    _hyDownMbps = TextEditingController(
      text: (s?['down_mbps'] ?? 100).toString(),
    );
    _hyObfs = TextEditingController(text: s?['obfs'] ?? '');
    _hyObfsPassword = TextEditingController(text: s?['obfs_password'] ?? '');

    // AnyTLS
    final paddingScheme = s?['padding_scheme'];
    if (paddingScheme is String) {
      _paddingScheme = TextEditingController(text: paddingScheme);
    } else if (paddingScheme != null) {
      _paddingScheme = TextEditingController(text: jsonEncode(paddingScheme));
    } else {
      _paddingScheme = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _serverPortController.dispose();
    _rateController.dispose();
    _tagsController.dispose();
    _sniController.dispose();
    _realityPrivateKey.dispose();
    _realityPublicKey.dispose();
    _realityShortId.dispose();
    _realityServerAddr.dispose();
    _realityServerPort.dispose();
    _hyUpMbps.dispose();
    _hyDownMbps.dispose();
    _hyObfs.dispose();
    _hyObfsPassword.dispose();
    _paddingScheme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    widget.isEdit ? '编辑节点' : '添加节点',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 协议类型
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '节点类型',
                          prefixIcon: Icon(LucideIcons.server),
                        ),
                        items: _serverTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: widget.isEdit
                            ? null
                            : (v) => setState(() => _selectedType = v!),
                      ),
                      const SizedBox(height: 16),
                      _buildCommonFields(),
                      const SizedBox(height: 16),
                      _buildProtocolFields(),
                      const SizedBox(height: 16),
                      _buildGroupSelector(),
                      const SizedBox(height: 16),
                      _buildParentAndRouteSelector(),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('是否显示'),
                        subtitle: const Text('关闭后用户将无法看到此节点'),
                        value: _show,
                        onChanged: (v) => setState(() => _show = v),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(widget.isEdit ? '保存' : '创建'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '节点名称',
                  hintText: '如：香港-HK01',
                  prefixIcon: Icon(LucideIcons.tag),
                ),
                validator: (v) => v?.isEmpty == true ? '请输入节点名称' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '倍率'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: '节点标签',
            hintText: '多个标签用逗号分隔',
            prefixIcon: Icon(LucideIcons.tags),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hostController,
          decoration: const InputDecoration(
            labelText: '节点地址',
            hintText: 'server.example.com',
            prefixIcon: Icon(LucideIcons.globe),
          ),
          validator: (v) => v?.isEmpty == true ? '请输入节点地址' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '连接端口'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _serverPortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '服务端口'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProtocolFields() {
    switch (_selectedType) {
      case 'shadowsocks':
        return _buildShadowsocksFields();
      case 'vmess':
        return _buildVMessFields();
      case 'trojan':
        return _buildTrojanFields();
      case 'vless':
        return _buildVLESSFields();
      case 'hysteria':
        return _buildHysteriaFields();
      case 'anytls':
        return _buildAnyTLSFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildShadowsocksFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shadowsocks 配置',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _ssCipher,
          decoration: const InputDecoration(
            labelText: '加密方式',
            prefixIcon: Icon(LucideIcons.lock),
          ),
          items: _ssCiphers
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _ssCipher = v!),
        ),
      ],
    );
  }

  Widget _buildVMessFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VMess 配置', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _network,
          decoration: const InputDecoration(labelText: '传输协议'),
          items: _networks
              .map(
                (n) => DropdownMenuItem(value: n, child: Text(n.toUpperCase())),
              )
              .toList(),
          onChanged: (v) => setState(() => _network = v!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('启用 TLS'),
          value: _tls == 1,
          onChanged: (v) => setState(() => _tls = v ? 1 : 0),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        if (_tls == 1) ...[
          TextFormField(
            controller: _sniController,
            decoration: const InputDecoration(labelText: 'SNI'),
          ),
        ],
      ],
    );
  }

  Widget _buildTrojanFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Trojan 配置', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sniController,
          decoration: const InputDecoration(
            labelText: 'SNI (服务器名称指示)',
            prefixIcon: Icon(LucideIcons.shield),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('允许不安全连接'),
          value: _allowInsecure,
          onChanged: (v) => setState(() => _allowInsecure = v),
          activeColor: AppColors.warning,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildVLESSFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VLESS 配置', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _network,
          decoration: const InputDecoration(labelText: '传输协议'),
          items: _networks
              .map(
                (n) => DropdownMenuItem(value: n, child: Text(n.toUpperCase())),
              )
              .toList(),
          onChanged: (v) => setState(() => _network = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _vlessFlow,
          decoration: const InputDecoration(labelText: 'XTLS 流控算法'),
          items: _vlessFlows
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.isEmpty ? '无' : f),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _vlessFlow = v!),
        ),
        const SizedBox(height: 12),
        // 安全性选择
        DropdownButtonFormField<int>(
          value: _tls,
          decoration: const InputDecoration(labelText: '安全性'),
          items: const [
            DropdownMenuItem(value: 0, child: Text('无')),
            DropdownMenuItem(value: 1, child: Text('TLS')),
            DropdownMenuItem(value: 2, child: Text('Reality')),
          ],
          onChanged: (v) => setState(() => _tls = v!),
        ),
        const SizedBox(height: 12),
        if (_tls == 1) ...[
          // TLS 配置
          TextFormField(
            controller: _sniController,
            decoration: const InputDecoration(labelText: 'SNI'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('允许不安全连接'),
            value: _allowInsecure,
            onChanged: (v) => setState(() => _allowInsecure = v),
            activeColor: AppColors.warning,
            contentPadding: EdgeInsets.zero,
          ),
        ],
        if (_tls == 2) ...[
          // Reality 配置
          const Divider(),
          const Text(
            'Reality 配置',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _realityServerAddr,
            decoration: const InputDecoration(labelText: 'Server Name (SNI)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _realityServerPort,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Server Port'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _realityProxyProtocol,
                  decoration: const InputDecoration(
                    labelText: 'Proxy Protocol',
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0')),
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                  ],
                  onChanged: (v) => setState(() => _realityProxyProtocol = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _realityPrivateKey,
            decoration: const InputDecoration(labelText: 'Private Key'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _realityPublicKey,
            decoration: const InputDecoration(labelText: 'Public Key'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _realityShortId,
            decoration: const InputDecoration(labelText: 'ShortId'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _fingerprint,
            decoration: const InputDecoration(labelText: 'FingerPrint'),
            items: _fingerprints
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) => setState(() => _fingerprint = v!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Allow Insecure'),
            value: _allowInsecure,
            onChanged: (v) => setState(() => _allowInsecure = v),
            activeColor: AppColors.warning,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildHysteriaFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hysteria 配置',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _hyVersion,
          decoration: const InputDecoration(labelText: 'Hysteria 版本'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('Hysteria 1')),
            DropdownMenuItem(value: 2, child: Text('Hysteria 2')),
          ],
          onChanged: (v) => setState(() => _hyVersion = v!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hyUpMbps,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '上行带宽 (Mbps)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _hyDownMbps,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '下行带宽 (Mbps)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sniController,
          decoration: const InputDecoration(labelText: 'SNI'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hyObfs,
          decoration: InputDecoration(
            labelText: _hyVersion == 1 ? '混淆密码' : '混淆类型',
          ),
        ),
        if (_hyVersion == 2) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _hyObfsPassword,
            decoration: const InputDecoration(labelText: '混淆密码'),
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('允许不安全连接'),
          value: _allowInsecure,
          onChanged: (v) => setState(() => _allowInsecure = v),
          activeColor: AppColors.warning,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAnyTLSFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AnyTLS 配置', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sniController,
          decoration: const InputDecoration(
            labelText: 'SNI (服务器名称指示)',
            prefixIcon: Icon(LucideIcons.shield),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('允许不安全连接'),
          value: _allowInsecure,
          onChanged: (v) => setState(() => _allowInsecure = v),
          activeColor: AppColors.warning,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        // 编辑填充方案
        Row(
          children: [
            const Text('编辑填充方案', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _showPaddingSchemeEditor,
              child: const Text('编辑配置'),
            ),
          ],
        ),
        if (_paddingScheme.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _paddingScheme.text.length > 100
                  ? '${_paddingScheme.text.substring(0, 100)}...'
                  : _paddingScheme.text,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
      ],
    );
  }

  void _showPaddingSchemeEditor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑填充方案'),
        content: SizedBox(
          width: 500,
          height: 300,
          child: TextFormField(
            controller: _paddingScheme,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: '输入 JSON 格式的填充配置...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('权限组', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              '(必选)',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: widget.groups.map((group) {
            final groupId = group['id'].toString();
            final isSelected = _selectedGroups.contains(groupId);
            return FilterChip(
              label: Text(
                group['name'] ?? 'Group $groupId',
                style: const TextStyle(fontSize: 12),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGroups.add(groupId);
                  } else {
                    _selectedGroups.remove(groupId);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParentAndRouteSelector() {
    // 根据当前类型筛选可用的父节点
    final availableParents = widget.servers
        .where(
          (s) => s['type'] == _selectedType && s['id'] != widget.server?['id'],
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          value: _parentId,
          decoration: const InputDecoration(labelText: '父节点', isDense: true),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('无')),
            ...availableParents.map(
              (s) => DropdownMenuItem<int?>(
                value: s['id'],
                child: Text(
                  '${s['name']} (#${s['id']})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _parentId = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: _routeId,
          decoration: const InputDecoration(labelText: '路由组', isDense: true),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('无')),
            ...widget.routes.map(
              (r) => DropdownMenuItem<int?>(
                value: r['id'],
                child: Text(
                  r['remarks'] ?? 'Route #${r['id']}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _routeId = v),
        ),
      ],
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    // 验证权限组
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个权限组'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 不要在这里关闭对话框，让 onSave 回调处理

    final data = <String, dynamic>{
      if (widget.isEdit) 'id': widget.server['id'],
      'name': _nameController.text,
      'host': _hostController.text,
      'port': int.tryParse(_portController.text) ?? 443,
      'server_port':
          int.tryParse(_serverPortController.text) ??
          int.tryParse(_portController.text) ??
          443,
      'rate': double.tryParse(_rateController.text) ?? 1.0,
      'show': _show ? 1 : 0,
      'group_id': _selectedGroups,
      if (_parentId != null) 'parent_id': _parentId,
      if (_routeId != null) 'route_id': _routeId,
    };

    if (_tagsController.text.isNotEmpty) {
      data['tags'] = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    // 协议特定字段
    switch (_selectedType) {
      case 'shadowsocks':
        data['cipher'] = _ssCipher;
        break;
      case 'vmess':
        data['network'] = _network;
        data['tls'] = _tls;
        if (_sniController.text.isNotEmpty)
          data['server_name'] = _sniController.text;
        break;
      case 'trojan':
        if (_sniController.text.isNotEmpty)
          data['server_name'] = _sniController.text;
        data['allow_insecure'] = _allowInsecure ? 1 : 0;
        break;
      case 'vless':
        data['network'] = _network;
        data['tls'] = _tls;
        data['flow'] = _vlessFlow;
        if (_tls == 1) {
          if (_sniController.text.isNotEmpty)
            data['server_name'] = _sniController.text;
          data['allow_insecure'] = _allowInsecure ? 1 : 0;
        } else if (_tls == 2) {
          // Reality
          data['tls_settings'] = {
            'server_name': _realityServerAddr.text,
            'server_port': int.tryParse(_realityServerPort.text) ?? 443,
            'proxy_protocol': _realityProxyProtocol,
            'private_key': _realityPrivateKey.text,
            'public_key': _realityPublicKey.text,
            'short_id': _realityShortId.text,
            'fingerprint': _fingerprint,
            'allow_insecure': _allowInsecure ? 1 : 0,
          };
        }
        break;
      case 'hysteria':
        data['version'] = _hyVersion;
        data['up_mbps'] = int.tryParse(_hyUpMbps.text) ?? 100;
        data['down_mbps'] = int.tryParse(_hyDownMbps.text) ?? 100;
        if (_sniController.text.isNotEmpty)
          data['server_name'] = _sniController.text;
        data['insecure'] = _allowInsecure ? 1 : 0;
        if (_hyObfs.text.isNotEmpty) data['obfs'] = _hyObfs.text;
        if (_hyVersion == 2 && _hyObfsPassword.text.isNotEmpty) {
          data['obfs_password'] = _hyObfsPassword.text;
        }
        break;
      case 'anytls':
        if (_sniController.text.isNotEmpty)
          data['server_name'] = _sniController.text;
        data['insecure'] = _allowInsecure ? 1 : 0;
        if (_paddingScheme.text.isNotEmpty) {
          try {
            data['padding_scheme'] = jsonDecode(_paddingScheme.text);
          } catch (e) {
            data['padding_scheme'] = _paddingScheme.text;
          }
        }
        break;
    }

    widget.onSave(data, _selectedType);
  }
}
