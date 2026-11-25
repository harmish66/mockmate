import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';

/// Overview statistics dashboard.
class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.mockMate,
    required this.onNavigateToRequests,
    required this.onNavigateToScenarios,
  });

  final MockMate mockMate;
  final VoidCallback onNavigateToRequests;
  final VoidCallback onNavigateToScenarios;

  @override
  Widget build(BuildContext context) {
    final history = mockMate.requestHistory;
    final totalRequests = history.length;
    final successCount = history.where((tx) => tx.isSuccess).length;
    final errorCount = history.where((tx) => tx.isError).length;

    final avgDurationMs = totalRequests > 0
        ? (history.fold<int>(0, (sum, tx) => sum + tx.duration.inMilliseconds) /
                totalRequests)
            .round()
        : 0;

    final activeScenario = mockMate.scenarioManager.activeGlobalScenario;
    final registeredRoutesCount = mockMate.router.routes.length;
    final networkProfile = mockMate.network.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('View All Requests'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onNavigateToRequests,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final crossAxisCount = isWide ? 3 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 2.2 : 1.6,
                children: [
                  _MetricCard(
                    title: 'Total Requests',
                    value: '$totalRequests',
                    icon: Icons.swap_horiz,
                    color: const Color(0xFF2563EB),
                  ),
                  _MetricCard(
                    title: 'Successful',
                    value: '$successCount',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                  ),
                  _MetricCard(
                    title: 'Errors / Failures',
                    value: '$errorCount',
                    icon: Icons.error_outline,
                    color: const Color(0xFFEF4444),
                  ),
                  _MetricCard(
                    title: 'Avg Latency',
                    value: '${avgDurationMs}ms',
                    icon: Icons.speed,
                    color: const Color(0xFF8B5CF6),
                  ),
                  _MetricCard(
                    title: 'Active Scenario',
                    value: activeScenario,
                    icon: Icons.alt_route,
                    color: const Color(0xFFF59E0B),
                  ),
                  _MetricCard(
                    title: 'Active Routes',
                    value: '$registeredRoutesCount',
                    icon: Icons.route,
                    color: const Color(0xFF06B6D4),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Network Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Profile: ${networkProfile.displayName}'),
                  Text(
                    'Simulated Latency: ${networkProfile.minLatency.inMilliseconds}ms - ${networkProfile.maxLatency.inMilliseconds}ms',
                  ),
                  Text(
                      'Failure Rate: ${(networkProfile.failureRate * 100).toStringAsFixed(1)}%'),
                  Text(
                      'Offline Mode: ${networkProfile.isOffline ? 'Enabled' : 'Disabled'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
