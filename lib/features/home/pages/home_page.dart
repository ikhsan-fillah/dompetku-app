import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/utils/date_range.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/widgets/expense_donut.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (!auth.isUnlocked.value) {
        return Scaffold(
          body: Center(child: FilledButton(
            onPressed: () => Get.offAllNamed(AppRoutes.biometricUnlock),
            child: const Text('Buka dengan biometrik'),
          )),
        );
      }
      final controller = Get.find<DashboardController>();
      return Scaffold(
        appBar: AppBar(
          title: const Text('DompetKu'),
          actions: [IconButton(
            tooltip: 'Segarkan dashboard',
            onPressed: controller.refreshDashboard,
            icon: const Icon(Icons.refresh_rounded),
          )],
        ),
        body: Obx(() {
          final state = controller.state.value;
          if (state.status == ResourceStatus.loading || state.status == ResourceStatus.idle) {
            return const AppLoadingView();
          }
          if (state.status == ResourceStatus.error) {
            return AppErrorView(message: state.message ?? 'Gagal memuat dashboard.', onRetry: controller.refreshDashboard);
          }
          return RefreshIndicator(
            onRefresh: controller.refreshDashboard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _PeriodPicker(controller: controller),
                const SizedBox(height: 20),
                if (state.status == ResourceStatus.empty)
                  const AppEmptyView(message: 'Belum ada transaksi pada periode ini.')
                else if (state.data != null) ...[
                  _BalanceCard(data: state.data!),
                  const SizedBox(height: 16),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 540 ? (width - 12) / 2 : width;
                    return Wrap(spacing: 12, runSpacing: 12, children: [
                      _MetricCard(label: 'Pemasukan', amount: state.data!.summary.income, icon: Icons.south_west_rounded, accent: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7DD9A6) : const Color(0xFF15803D), width: cardWidth),
                      _MetricCard(label: 'Pengeluaran', amount: state.data!.summary.expense, icon: Icons.north_east_rounded, accent: Theme.of(context).colorScheme.error, width: cardWidth),
                    ]);
                  }),
                  const SizedBox(height: 20),
                  Text('Pengeluaran per kategori', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(20), child: ExpenseDonut(slices: state.data!.expenses))),
                  const SizedBox(height: 20),
                  Text('Tren pengeluaran', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(child: Padding(padding: const EdgeInsets.all(20), child: _TrendBars(points: state.data!.trend))),
                ],
              ],
            ),
          );
        }),
      );
    });
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final range = controller.range.value;
    final label = '${range.start.day}/${range.start.month}/${range.start.year} – ${range.end.day}/${range.end.month}/${range.end.year}';
    return Semantics(
      button: true, label: 'Pilih periode, $label',
      child: OutlinedButton.icon(
        onPressed: () async {
          final selected = await showDateRangePicker(
            context: context,
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(start: range.start, end: range.end),
          );
          if (selected != null) {
            await controller.setRange(DateRange(start: selected.start, end: selected.end));
          }
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(label),
      ),
    );
  });
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Saldo periode terpilih', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimary)),
          const SizedBox(height: 12),
          FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(formatIdr(data.summary.balance), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimary))),
          const SizedBox(height: 12),
          Text('Pemasukan − pengeluaran pada periode ini', style: TextStyle(color: scheme.onPrimary)),
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.amount, required this.icon, required this.accent, required this.width});
  final String label;
  final int amount;
  final IconData icon;
  final Color accent;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: accent),
        const SizedBox(height: 10),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(formatIdr(amount), style: Theme.of(context).textTheme.titleLarge)),
      ]),
    )),
  );
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});
  final List<dynamic> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Text('Belum ada pengeluaran pada periode ini.');
    final maxAmount = points.fold<int>(0, (maxValue, point) => point.amount > maxValue ? point.amount as int : maxValue);
    return Column(children: [
      for (final point in points) Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 46, child: Text('${point.date.day}/${point.date.month}')),
            Expanded(child: LinearProgressIndicator(
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
              value: maxAmount == 0 ? 0 : point.amount / maxAmount,
            )),
          ]),
          Padding(padding: const EdgeInsets.only(left: 46, top: 3), child: Text(formatIdr(point.amount))),
        ]),
      ),
    ]);
  }
}
