import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/sort_chip.dart';
import '../../dashboard/models/dashboard_view_models.dart';
import '../controllers/transaction_controller.dart';
import '../services/transaction_list_service.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/swipe_actions.dart';
import '../../../core/widgets/sort_filter_sheet.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/utils/date_range.dart';

/// Tab Transaksi: cari, filter jenis, ringkasan, dan daftar per hari.
class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late final TransactionController _controller =
      Get.find<TransactionController>();
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final RxnInt _expanded = RxnInt();

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _controller.loadNextPage();
      }
    });
  }

  void _snack(String message) {
    AppToast.show(context: context, title: message, kind: ToastKind.error);
  }

  void _toggle(int id) {
    _expanded.value = _expanded.value == id ? null : id;
  }

  Future<void> _edit(int id) async {
    final model = _controller.findById(id);
    if (model == null) return;
    _expanded.value = null;
    await showTransactionSheet(context, edit: model);
  }

  /// Hapus langsung tanpa dialog; toast Urungkan mengembalikannya.
  Future<void> _delete(int id) async {
    final removed = _controller.findById(id);
    final ok = await _controller.delete(id);
    if (!mounted) return;
    _expanded.value = null;
    if (!ok) {
      _snack('Gagal menghapus transaksi.'.tr);
      return;
    }
    if (removed == null) return;
    AppToast.show(
      context: context,
      title: 'Transaksi dihapus'.tr,
      message: '${removed.title} · ${formatIdr(removed.amount)}',
      kind: ToastKind.undo,
      actionLabel: 'Urungkan'.tr,
      onAction: () => _controller.restore(removed),
      duration: const Duration(seconds: 4),
    );
  }

  /// Satu lembar untuk urutan dan saringan (kategori, nominal, tanggal).
  Future<void> _openSortFilter() async {
    final c = _controller;
    final type = c.filter.value;
    final categories = [
      for (final category in c.categories)
        if (!category.isArchived &&
            category.id != null &&
            (type == TransactionTypeFilter.all ||
                (type == TransactionTypeFilter.income) ==
                    (category.type == TransactionType.income)))
          FilterCategory(
            id: category.id!,
            name: category.displayName,
            iconKey: category.iconKey,
            color: CategoryStyle.color(category.colorValue),
          ),
    ];
    final range = c.filterRange.value;
    DateRange? toRange(DateTimeRange? value) =>
        value == null ? null : DateRange(start: value.start, end: value.end);
    final result = await showSortFilterSheet<TransactionSort>(
      context,
      value: SortFilterValue(
        sort: c.sort.value,
        categoryIds: {...c.categoryIds},
        minAmount: c.minAmount.value,
        maxAmount: c.maxAmount.value,
        range: range == null
            ? null
            : DateTimeRange(start: range.start, end: range.end),
      ),
      defaultSort: TransactionSort.terbaru,
      sortOptions: TransactionSort.values,
      sortLabel: _sortLabel,
      categories: categories,
      countFor: (value) => c.countFor(
        categoryIds: value.categoryIds,
        minAmount: value.minAmount,
        maxAmount: value.maxAmount,
        range: toRange(value.range),
      ),
    );
    if (result == null) return;
    c.applySortFilter(
      sort: result.sort,
      categoryIds: result.categoryIds,
      minAmount: result.minAmount,
      maxAmount: result.maxAmount,
      range: toRange(result.range),
    );
  }

  String _groupLabel(DateTime date) {
    final relative = DateLabel.relativeDay(date);
    final full = DateLabel.day(date);
    return relative == full ? full : '$relative · $full';
  }

  String _sortLabel(TransactionSort sort) => switch (sort) {
    TransactionSort.terbaru => 'Terbaru'.tr,
    TransactionSort.terlama => 'Terlama'.tr,
    TransactionSort.nominalTerbesar => 'Nominal terbesar'.tr,
    TransactionSort.nominalTerkecil => 'Nominal terkecil'.tr,
    TransactionSort.namaAZ => 'Nama A-Z'.tr,
    TransactionSort.namaZA => 'Nama Z-A'.tr,
    TransactionSort.kategoriAZ => 'Kategori A-Z'.tr,
  };

  String _sortChipLabel(TransactionSort sort) => switch (sort) {
    TransactionSort.terbaru => 'Terbaru'.tr,
    TransactionSort.terlama => 'Terlama'.tr,
    TransactionSort.nominalTerbesar => 'Terbesar'.tr,
    TransactionSort.nominalTerkecil => 'Terkecil'.tr,
    TransactionSort.namaAZ => 'A-Z'.tr,
    TransactionSort.namaZA => 'Z-A'.tr,
    TransactionSort.kategoriAZ => 'Kategori'.tr,
  };

  Widget _body() {
    final state = _controller.state.value;
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const ListSkeleton();
      case ResourceStatus.error:
        return AppErrorView(
          message: state.message ?? 'Gagal memuat transaksi.'.tr,
          onRetry: () => _controller.load(),
        );
      case ResourceStatus.empty:
        return AppEmptyView(
          icon: LucideIcons.receiptText,
          title: 'Belum ada transaksi'.tr,
          message: 'Catat pengeluaran atau pemasukan pertamamu.'.tr,
          action: AppButton(
            label: 'Tambah transaksi'.tr,
            icon: LucideIcons.plus,
            expand: false,
            onPressed: () => showTransactionSheet(context),
          ),
        );
      case ResourceStatus.success:
        final result = _controller.list;
        if (result.isEmpty) {
          return AppEmptyView(
            icon: LucideIcons.search,
            title: 'Tidak ada hasil'.tr,
            message: 'Coba kata kunci atau filter lain.'.tr,
          );
        }
        final expandedId = _expanded.value;
        final entries = <_TransactionEntry>[];
        if (result.isGrouped) {
          for (final group in result.groups) {
            entries.add(_TransactionEntry.header(group.date));
            entries.addAll(group.items.map(_TransactionEntry.item));
          }
        } else {
          entries.addAll(result.items.map(_TransactionEntry.item));
        }
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            4,
            AppSpacing.page,
            130,
          ),
          itemCount:
              entries.length + 1 + (_controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == entries.length + 1) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (index == 0) {
              return _SummaryRow(
                income: result.income,
                expense: result.expense,
              );
            }
            final entry = entries[index - 1];
            if (entry.date != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6, left: 2),
                child: Text(
                  _groupLabel(entry.date!).toUpperCase(),
                  style: AppText.monoLabel(),
                ),
              );
            }
            final item = entry.item!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SwipeActions(
                key: ValueKey('tx-${item.id}'),
                groupTag: 'transactions',
                onEdit: () => _edit(item.id),
                onDelete: () => _delete(item.id),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  margin: EdgeInsets.zero,
                  child: TransactionTile(
                    item: item,
                    expanded: expandedId == item.id,
                    onTap: () => _toggle(item.id),
                    onEdit: () => _edit(item.id),
                    onDelete: () => _delete(item.id),
                  ),
                ),
              ),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Transaksi'.tr,
          actions: [
            Obx(
              () => SortFilterChip(
                label: _sortChipLabel(_controller.sort.value),
                activeCount: _controller.activeFilterCount,
                tooltip: 'Urutkan & saring'.tr,
                onTap: _openSortFilter,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            4,
            AppSpacing.page,
            2,
          ),
          child: AppTextField(
            controller: _search,
            hint: 'Cari transaksi…'.tr,
            prefixIcon: LucideIcons.search,
            onChanged: _controller.setQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: 8,
          ),
          child: Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final entry in [
                    (TransactionTypeFilter.all, 'Semua'.tr),
                    (TransactionTypeFilter.expense, 'Pengeluaran'.tr),
                    (TransactionTypeFilter.income, 'Pemasukan'.tr),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: entry.$2,
                        selected: _controller.filter.value == entry.$1,
                        onTap: () => _controller.setFilter(entry.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: Obx(_body)),
      ],
    );
  }
}

class _TransactionEntry {
  const _TransactionEntry._({this.date, this.item});

  const _TransactionEntry.header(DateTime date) : this._(date: date);

  const _TransactionEntry.item(RecentTransactionItem item) : this._(item: item);

  final DateTime? date;
  final RecentTransactionItem? item;
}

/// Ringkasan satu kartu: pemasukan dan pengeluaran berdampingan.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.income, required this.expense});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Pemasukan'.tr,
              amount: income,
              color: AppColors.earn,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 34, color: AppColors.line),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryItem(
              label: 'Pengeluaran'.tr,
              amount: expense,
              color: AppColors.spend,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(size: 10.5, color: AppColors.mut)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RollingText(
            formatIdr(amount),
            style: AppText.mono(
              size: 15,
              weight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
