import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
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
  List<ServerRank> _serverRanks = [];
  List<UserRank> _userRanks = [];
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
        api.getUserTodayRank(),
      ]);

      if (mounted) {
        setState(() {
          // 统计概览
          if (results[0].success) {
            _statOverview = StatOverview.fromJson(results[0].data);
          }

          // 服务器排行
          if (results[1].success) {
            final data = results[1].getData<List>();
            if (data != null) {
              _serverRanks = data.map((e) => ServerRank.fromJson(e)).toList();
            }
          }

          // 用户排行
          if (results[2].success) {
            final data = results[2].getData<List>();
            if (data != null) {
              _userRanks = data.map((e) => UserRank.fromJson(e)).toList();
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
          Text(
            '欢迎回来，这是您的系统概览',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
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
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildServerRankCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildUserRankCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildServerRankCard(),
                    const SizedBox(height: 20),
                    _buildUserRankCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// 统计卡片网格
  Widget _buildStatCards() {
    final stats = _statOverview ?? StatOverview();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 500) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              title: '在线用户',
              value: stats.onlineUser.toString(),
              subtitle: '本月新增 ${stats.monthRegisterTotal}',
              icon: LucideIcons.users,
              iconColor: AppColors.primary,
            ),
            StatCard(
              title: '今日收入',
              value: '¥${stats.formattedDayIncome}',
              subtitle: '今日注册 ${stats.dayRegisterTotal}',
              icon: LucideIcons.dollarSign,
              iconColor: AppColors.success,
            ),
            StatCard(
              title: '本月收入',
              value: '¥${stats.formattedMonthIncome}',
              subtitle: '上月 ¥${stats.formattedLastMonthIncome}',
              icon: LucideIcons.trendingUp,
              iconColor: AppColors.accent,
            ),
            StatCard(
              title: '待处理工单',
              value: stats.ticketPendingTotal.toString(),
              icon: LucideIcons.messageSquare,
              iconColor: stats.ticketPendingTotal > 0
                  ? AppColors.warning
                  : AppColors.textMutedDark,
            ),
          ],
        );
      },
    );
  }

  /// 收入趋势图表
  Widget _buildRevenueChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                child: const Text(
                  '近7天',
                  style: TextStyle(
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
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                        const days = ['一', '二', '三', '四', '五', '六', '日'];
                        return Text(
                          days[value.toInt() % 7],
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4),
                      FlSpot(5, 6),
                      FlSpot(6, 5.5),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 服务器排行卡片
  Widget _buildServerRankCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.server, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                '服务器流量排行',
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
                '昨日',
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
          if (_serverRanks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('暂无数据')),
            )
          else
            ...List.generate(
              _serverRanks.take(5).length,
              (index) => _buildRankItem(
                rank: index + 1,
                title: _serverRanks[index].serverName,
                subtitle: _serverRanks[index].typeName,
                value: _serverRanks[index].formattedTotal,
              ),
            ),
        ],
      ),
    );
  }

  /// 用户排行卡片
  Widget _buildUserRankCard() {
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
                '用户流量排行',
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
                '今日',
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
          if (_userRanks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('暂无数据')),
            )
          else
            ...List.generate(
              _userRanks.take(5).length,
              (index) => _buildRankItem(
                rank: index + 1,
                title: _userRanks[index].maskedEmail,
                subtitle: 'ID: ${_userRanks[index].userId}',
                value: _userRanks[index].formattedTotal,
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
