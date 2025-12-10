import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:v2board_admin/core/constants/api_constants.dart';
import 'package:v2board_admin/core/theme/app_colors.dart';
import 'package:v2board_admin/data/services/api_service.dart';

class QueueMonitorPage extends StatefulWidget {
  const QueueMonitorPage({super.key});

  @override
  State<QueueMonitorPage> createState() => _QueueMonitorPageState();
}

class _QueueMonitorPageState extends State<QueueMonitorPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _systemStatus;
  List<dynamic>? _workload;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final statusRes = await ApiService.instance.get(
        ApiConstants.adminSystemStatus,
        isAdmin: true,
      );
      final workloadRes = await ApiService.instance.get(
        ApiConstants.adminQueueWorkload,
        isAdmin: true,
      );
      final statsRes = await ApiService.instance.get(
        ApiConstants.adminQueueStats,
        isAdmin: true,
      );

      if (mounted) {
        setState(() {
          if (statusRes.success) _systemStatus = statusRes.data['data'];
          if (workloadRes.success) _workload = workloadRes.data['data'];
          if (statsRes.success) _stats = statsRes.data['data'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('队列监控'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(LucideIcons.refreshCw),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading && _systemStatus == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_systemStatus != null) _buildSystemStatusCard(),
                    const SizedBox(height: 16),
                    if (_stats != null) _buildStatsCard(),
                    const SizedBox(height: 16),
                    if (_workload != null) _buildWorkloadCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSystemStatusCard() {
    final scheduleFn = _systemStatus!['schedule'] == true;
    final horizonFn = _systemStatus!['horizon'] == true;
    final lastCheckVal = _systemStatus!['schedule_last_runtime'];

    int? lastCheck;
    if (lastCheckVal is int) {
      lastCheck = lastCheckVal;
    } else if (lastCheckVal is String) {
      lastCheck = int.tryParse(lastCheckVal);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '系统状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusItem('计划任务', scheduleFn),
                const SizedBox(width: 32),
                _buildStatusItem('Horizon 队列系统', horizonFn),
              ],
            ),
            if (lastCheck != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '上次调度检查: ${DateTime.fromMillisecondsSinceEpoch(lastCheck * 1000)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isOk) {
    return Row(
      children: [
        Icon(
          isOk ? LucideIcons.checkCircle : LucideIcons.xCircle,
          color: isOk ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isOk ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isOk ? '运行中' : '停止',
            style: TextStyle(
              color: isOk ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    dynamic parseStart(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final jobsPerMin = parseStart(_stats!['jobsPerMinute']);
    final failed = parseStart(_stats!['failedJobs']);
    final processes = parseStart(_stats!['processes']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '实时统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('每分钟任务', '$jobsPerMin'),
                _buildStatItem('进程数', '$processes'),
                _buildStatItem('最近失败', '$failed', isError: failed > 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isError = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red : null,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildWorkloadCard() {
    if (_workload!.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '队列负载',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _workload!.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final q = _workload![index];
                return ListTile(
                  title: Text(q['name'] ?? 'Queue'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Length: ${q['length'] ?? 0}'),
                          Text(
                            'Wait: ${q['wait'] ?? 0}s',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
