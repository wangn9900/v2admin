import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/navigation_provider.dart';
import '../../data/models/stat_model.dart';
import '../../data/services/api_service.dart';
import '../../shared/widgets/common_widgets.dart';

/// 仪表盘页面
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StatOverview? _statOverview;
  List<ServerRank> _serverLastRanks = [];
  List<ServerRank> _serverTodayRanks = [];
  List<UserRank> _userLastRanks = [];
  List<UserRank> _userTodayRanks = [];
  List<Map<String, dynamic>> _revenueData = []; // 收入趋势数据
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
      final api = ApiService.instance;

      // 并行加载数据
      final results = await Future.wait([
        api.getStatOverride(),
        api.getServerLastRank(),
        api.getServerTodayRank(),
        api.getUserTodayRank(),
        api.getUserLastRank(),
        api.getStatOrder(), // 获取收入趋势数据
      ]);

      if (mounted) {
        setState(() {
          // 统计概览
          if (results[0].success) {
            _statOverview = StatOverview.fromJson(results[0].data);
          }

          // 服务器排行 (昨日)
          if (results[1].success) {
            final data = results[1].getData<List>();
            if (data != null) {
              _serverLastRanks = data
                  .map((e) => ServerRank.fromJson(e))
                  .toList();
            }
          }
          // 服务器排行 (今日)
          if (results[2].success) {
            final data = results[2].getData<List>();
            if (data != null) {
              _serverTodayRanks = data
                  .map((e) => ServerRank.fromJson(e))
                  .toList();
            }
          }

          // 用户排行 (今日)
          if (results[3].success) {
            final data = results[3].getData<List>();
            if (data != null) {
              _userTodayRanks = data.map((e) => UserRank.fromJson(e)).toList();
            }
          }
          // 用户排行 (昨日)
          if (results[4].success) {
            final data = results[4].getData<List>();
            if (data != null) {
              _userLastRanks = data.map((e) => UserRank.fromJson(e)).toList();
            }
          }

          // 收入趋势数据
          if (results[5].success) {
            final data = results[5].getData<List>();
            if (data != null) {
              _revenueData = data.cast<Map<String, dynamic>>();
            }
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const LoadingIndicator(message: '加载中...')
            : _error != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return EmptyState(
      title: '加载失败',
      subtitle: _error,
      icon: LucideIcons.alertCircle,
      action: GradientButton(text: '重试', onPressed: _loadData, width: 120),
    );
  }

  Widget _buildContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎语
          Text(
            '仪表盘',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '欢迎回来，这是您的系统概览',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              if ((_statOverview?.ticketPendingTotal ?? 0) > 0) ...[
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<NavigationProvider>().jumpTo(
                        NavigationProvider.tickets,
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 12,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_statOverview?.ticketPendingTotal} 个待处理工单',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // 统计卡片网格
          _buildStatCards(),
          const SizedBox(height: 24),

          // 收入趋势图表 (占位)
          _buildRevenueChart(),
          const SizedBox(height: 24),

          // 排行榜区域
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // 2x2 Grid
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildServerRankCard(
                            '今日节点流量排行',
                            _serverTodayRanks,
                            '今日',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildServerRankCard(
                            '昨日节点流量排行',
                            _serverLastRanks,
                            '昨日',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildUserRankCard(
                            '今日用户流量排行',
                            _userTodayRanks,
                            '今日',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildUserRankCard(
                            '昨日用户流量排行',
                            _userLastRanks,
                            '昨日',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Single Column
                return Column(
                  children: [
                    _buildServerRankCard('今日节点流量排行', _serverTodayRanks, '今日'),
                    const SizedBox(height: 20),
                    _buildServerRankCard('昨日节点流量排行', _serverLastRanks, '昨日'),
                    const SizedBox(height: 20),
                    _buildUserRankCard('今日用户流量排行', _userTodayRanks, '今日'),
                    const SizedBox(height: 20),
                    _buildUserRankCard('昨日用户流量排行', _userLastRanks, '昨日'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// 统计区域
  Widget _buildStatCards() {
    final stats = _statOverview ?? StatOverview();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 第一行：主要数据
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMajorStat(
                  title: '在线人数',
                  value: stats.onlineUser.toString(),
                  icon: LucideIcons.users,
                  valueColor: isDark ? Colors.white : Colors.black,
                ),
              ),
              Expanded(
                child: _buildMajorStat(
                  title: '今日收入',
                  value: stats.formattedDayIncome,
                  suffix: 'CNY',
                  icon: LucideIcons.barChart2,
                  valueColor: isDark ? Colors.white : Colors.black,
                ),
              ),
              Expanded(
                child: _buildMajorStat(
                  title: '今日注册',
                  value: stats.dayRegisterTotal.toString(),
                  icon: LucideIcons.userPlus,
                  valueColor: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 24),
          // 第二行：次要数据
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMinorStat(
                  title: '本月收入',
                  value: '${stats.formattedMonthIncome} CNY',
                ),
              ),
              Expanded(
                child: _buildMinorStat(
                  title: '上月收入',
                  value: '${stats.formattedLastMonthIncome} CNY',
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.read<NavigationProvider>().jumpTo(
                        NavigationProvider.tickets,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildMinorStat(
                        title: '待处理工单',
                        value: stats.ticketPendingTotal.toString(),
                        valueColor: stats.ticketPendingTotal > 0
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildMinorStat(
                  title: '本月新增用户',
                  value: stats.monthRegisterTotal.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMajorStat({
    required String title,
    required String value,
    String? suffix,
    required IconData icon,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 16,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: valueColor,
                height: 1.0,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMinorStat({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color:
                valueColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  /// 收入趋势图表
  Widget _buildRevenueChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 从API数据中提取收款金额（类型为"收款金额"）
    final revenueItems = _revenueData
        .where((item) => item['type'] == '收款金额')
        .toList();

    // 获取最近7天的数据
    final last7Days = revenueItems.take(7).toList().reversed.toList();

    // 生成图表数据点
    final spots = <FlSpot>[];
    final dateLabels = <String>[];
    double maxY = 0;

    for (int i = 0; i < last7Days.length; i++) {
      final value = (last7Days[i]['value'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
      dateLabels.add(last7Days[i]['date']?.toString() ?? '');
      if (value > maxY) maxY = value;
    }

    // 如果没有数据，显示占位
    if (spots.isEmpty) {
      spots.addAll([
        const FlSpot(0, 0),
        const FlSpot(1, 0),
        const FlSpot(2, 0),
        const FlSpot(3, 0),
        const FlSpot(4, 0),
        const FlSpot(5, 0),
        const FlSpot(6, 0),
      ]);
      dateLabels.addAll(['', '', '', '', '', '', '']);
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '收入趋势',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '近${last7Days.length}天',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '¥${value.toInt()}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dateLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateLabels[index],
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.1 : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? AppColors.cardDark
                              : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final date = index < dateLabels.length
                            ? dateLabels[index]
                            : '';
                        return LineTooltipItem(
                          '$date\n¥${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 服务器排行卡片
  Widget _buildServerRankCard(String title, List<ServerRank> data, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalTraffic = data.fold(0.0, (sum, item) => sum + item.total);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.server, color: AppColors.accent, size: 20),
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalTraffic.toStringAsFixed(2)} GB',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace',
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('暂无数据')),
            )
          else
            ...List.generate(
              data.take(5).length,
              (index) => _buildRankItem(
                rank: index + 1,
                title: data[index].serverName,
                subtitle: data[index].typeName,
                value: data[index].formattedTotal,
              ),
            ),
        ],
      ),
    );
  }

  /// 用户排行卡片
  Widget _buildUserRankCard(String title, List<UserRank> data, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.users, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('暂无数据')),
            )
          else
            ...List.generate(
              data.take(5).length,
              (index) => _buildRankItem(
                rank: index + 1,
                title: data[index].maskedEmail,
                subtitle: 'ID: ${data[index].userId}',
                value: data[index].formattedTotal,
              ),
            ),
        ],
      ),
    );
  }

  /// 排行项
  Widget _buildRankItem({
    required int rank,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
