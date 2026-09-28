import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/utils/formatter.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class HomePage extends GetView<DashboardController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DompetKu'),
        actions: [
          IconButton(
            onPressed: controller.refreshDashboard,
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        final state = controller.state.value;
        return switch (state.status) {
          ResourceStatus.idle || ResourceStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          ResourceStatus.empty => const _DashboardEmptyState(),
          ResourceStatus.error => _DashboardErrorState(
            message: state.message ?? 'Unable to load dashboard.',
            onRetry: controller.refreshDashboard,
          ),
          ResourceStatus.success => _DashboardContent(data: state.data!),
        };
      }),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Current balance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          formatIdr(summary.balance),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                value: formatIdr(summary.income),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expenses',
                value: formatIdr(summary.expense),
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Spending trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('${data.trend.length} days with recorded activity'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(height: 8),
            Text(label),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No transactions in the selected period.'),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
