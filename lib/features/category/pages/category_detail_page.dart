import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../transaction/widgets/transaction_form_sheet.dart';
import '../controllers/category_detail_controller.dart';
import '../services/category_detail_service.dart';
import '../utils/category_icons.dart';

class CategoryDetailPage extends GetView<CategoryDetailController> {
  const CategoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail kategori')),
      body: Obx(() {
        final current = controller.state.value;
        return switch (current.status) {
          ResourceStatus.idle || ResourceStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          ResourceStatus.error => AppErrorView(
            message: current.message ?? 'Gagal memuat detail kategori.',
            onRetry: controller.load,
          ),
          ResourceStatus.empty => const AppEmptyView(
            icon: Icons.category_outlined,
            title: 'Kategori tidak ditemukan',
            message: 'Kategori ini mungkin sudah dihapus.',
          ),
          ResourceStatus.success => _Content(data: current.data!),
        };
      }),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final CategoryDetailData data;

  @override
  Widget build(BuildContext context) {
    final category = data.category;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            children: [
              CategoryIconBox(
                icon: CategoryIcons.of(category?.iconKey ?? 'more_horiz'),
                color: Color(category?.colorValue ?? 0xFF90A4AE),
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category?.name ?? 'Kategori diarsipkan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total periode', style: Theme.of(context).textTheme.bodySmall),
              Text(
                formatIdr(data.total),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Stat(label: 'Transaksi', value: '${data.transactionCount}'),
                  _Stat(label: 'Rata-rata', value: formatIdr(data.average)),
                  _Stat(
                    label: 'Dari pengeluaran',
                    value: '${data.percentOfExpenses.toStringAsFixed(0)}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.changePercent == 0
                    ? 'Sama dengan periode sebelumnya.'
                    : '${data.changePercent > 0 ? 'Naik' : 'Turun'} ${data.changePercent.abs().toStringAsFixed(0)}% dari periode sebelumnya.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (data.budget != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Anggaran terpakai ${data.budgetPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (data.budgetPercent / 100).clamp(0, 1),
                  color: data.budgetPercent >= 90
                      ? AppColors.coral
                      : AppColors.teal,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Transaksi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (data.transactions.isEmpty)
          const AppEmptyView(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada transaksi',
            message: 'Tidak ada pengeluaran pada periode ini.',
          )
        else
          for (final transaction in data.transactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(transaction.title),
              subtitle: Text(formatIdr(transaction.amount)),
              trailing: IconButton(
                tooltip: 'Edit transaksi',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showTransactionSheet(
                  context,
                  edit: transaction,
                ),
              ),
            ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}