import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/widgets/transaction_form_sheet.dart';
import '../controllers/category_detail_controller.dart';
import '../services/category_detail_service.dart';
import '../utils/category_icons.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({super.key});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final controller = Get.find<CategoryDetailController>();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        controller.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime date) => DateLabel.day(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(
              titleWidget: Obx(
                () => Text(
                  controller.category.value?.displayName ??
                      'Detail kategori'.tr,
                  style: AppText.display(size: 26),
                ),
              ),
              action: Obx(() {
                final selectedSort = controller.sort.value;
                return PopupMenuButton<CategoryTransactionSort>(
                  tooltip: 'Urutkan transaksi'.tr,
                  icon: const Icon(LucideIcons.arrowUpDown, size: 20),
                  onSelected: controller.setSort,
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      value: CategoryTransactionSort.newest,
                      checked: selectedSort == CategoryTransactionSort.newest,
                      child: Text('Tanggal terbaru'.tr),
                    ),
                    CheckedPopupMenuItem(
                      value: CategoryTransactionSort.oldest,
                      checked: selectedSort == CategoryTransactionSort.oldest,
                      child: Text('Tanggal terlama'.tr),
                    ),
                  ],
                );
              }),
            ),
            Expanded(
              child: Obx(() {
                final current = controller.state.value;
                return switch (current.status) {
                  ResourceStatus.idle || ResourceStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ResourceStatus.error => AppErrorView(
                    message:
                        current.message ??
                        'Gagal memuat transaksi kategori.'.tr,
                    onRetry: controller.load,
                  ),
                  ResourceStatus.empty => AppEmptyView(
                    icon: LucideIcons.receipt,
                    title: 'Belum ada transaksi pada kategori ini'.tr,
                    message:
                        'Transaksi dengan kategori ini akan tampil di sini.'.tr,
                  ),
                  ResourceStatus.success => _content(context),
                };
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final category = controller.category.value;
    final summary = controller.summary.value;
    final groups = controller.groups;
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        120,
      ),
      itemCount: groups.length + 2 + (controller.isLoadingMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppCard(
            child: Row(
              children: [
                CategoryIconBox(
                  icon: CategoryIcons.of(category?.iconKey ?? 'more_horiz'),
                  color: Color(category?.colorValue ?? 0xFF90A4AE),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.displayName ?? 'Detail kategori'.tr,
                        style: AppText.body(size: 14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@total · @count transaksi'.trParams({
                          'total': formatIdr(summary?.total ?? 0),
                          'count': '${summary?.count ?? 0}',
                        }),
                        style: AppText.mono(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: AppColors.mut,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (index == groups.length + 1) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final group = groups[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 7, left: 2),
              child: Text(
                _dateLabel(group.date),
                style: AppText.monoLabel(color: AppColors.mut),
              ),
            ),
            for (final transaction in group.transactions)
              _TransactionRow(transaction: transaction),
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type.name == 'income';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          transaction.title,
          style: AppText.body(size: 13, weight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            '${transaction.transactionDate.toLocal().hour.toString().padLeft(2, '0')}:${transaction.transactionDate.toLocal().minute.toString().padLeft(2, '0')}',
            if (transaction.merchantOrSource?.isNotEmpty == true)
              transaction.merchantOrSource!,
            if (transaction.paymentMethod != null)
              transaction.paymentMethod!.name,
          ].join(' · '),
          style: AppText.body(size: 10.5, color: AppColors.mut),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${isIncome ? '+' : '-'}${formatIdr(transaction.amount)}',
              style: AppText.mono(
                size: 12.5,
                weight: FontWeight.w500,
                color: isIncome ? AppColors.earn : AppColors.spend,
              ),
            ),
          ),
        ),
        onTap: () => showTransactionSheet(context, edit: transaction),
      ),
    );
  }
}
