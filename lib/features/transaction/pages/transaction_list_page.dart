import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../dashboard/models/dashboard_view_models.dart';
import '../controllers/transaction_controller.dart';
import '../services/transaction_list_service.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/transaction_tile.dart';

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _duplicate(int id) async {
    final model = _controller.findById(id);
    if (model == null) return;
    final ok = await _controller.duplicate(model);
    if (!mounted) return;
    _expanded.value = null;
    _snack(ok ? 'Transaksi digandakan ke hari ini.' : 'Gagal menggandakan.');
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _controller.delete(id);
    if (!mounted) return;
    _expanded.value = null;
    _snack(ok ? 'Transaksi dihapus.' : 'Gagal menghapus transaksi.');
  }

  String _groupLabel(DateTime date) {
    final relative = DateLabel.relativeDay(date);
    final full = DateLabel.day(date);
    return relative == full ? full : '$relative · $full';
  }

  String _sortLabel(TransactionSort sort) => switch (sort) {
    TransactionSort.terbaru => 'Terbaru',
    TransactionSort.terlama => 'Terlama',
    TransactionSort.nominalTerbesar => 'Nominal terbesar',
    TransactionSort.nominalTerkecil => 'Nominal terkecil',
    TransactionSort.namaAZ => 'Nama A-Z',
    TransactionSort.namaZA => 'Nama Z-A',
    TransactionSort.kategoriAZ => 'Kategori A-Z',
  };

  Widget _body() {
    final state = _controller.state.value;
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ResourceStatus.error:
        return AppErrorView(
          message: state.message ?? 'Gagal memuat transaksi.',
          onRetry: () => _controller.load(),
        );
      case ResourceStatus.empty:
        return AppEmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'Belum ada transaksi',
          message: 'Catat pengeluaran atau pemasukan pertamamu.',
          action: AppButton(
            label: 'Tambah transaksi',
            icon: Icons.add_rounded,
            expand: false,
            onPressed: () => showTransactionSheet(context),
          ),
        );
      case ResourceStatus.success:
        final result = _controller.list;
        if (result.isEmpty) {
          return const AppEmptyView(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada hasil',
            message: 'Coba kata kunci atau filter lain.',
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
                  _groupLabel(entry.date!),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              );
            }
            final item = entry.item!;
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              child: TransactionTile(
                item: item,
                expanded: expandedId == item.id,
                onTap: () => _toggle(item.id),
                onEdit: () => _edit(item.id),
                onDuplicate: () => _duplicate(item.id),
                onDelete: () => _delete(item.id),
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
          title: 'Transaksi',
          actions: [
            Obx(() {
              final selectedSort = _controller.sort.value;
              return PopupMenuButton<TransactionSort>(
                tooltip: 'Urutkan transaksi',
                icon: const Icon(Icons.sort_rounded),
                onSelected: _controller.setSort,
                itemBuilder: (context) => [
                  for (final sort in TransactionSort.values)
                    CheckedPopupMenuItem(
                      value: sort,
                      checked: selectedSort == sort,
                      child: Text(_sortLabel(sort)),
                    ),
                ],
              );
            }),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            2,
            AppSpacing.page,
            2,
          ),
          child: AppTextField(
            controller: _search,
            hint: 'Cari transaksi…',
            prefixIcon: Icons.search_rounded,
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
                  for (final entry in const [
                    (TransactionTypeFilter.all, 'Semua'),
                    (TransactionTypeFilter.expense, 'Pengeluaran'),
                    (TransactionTypeFilter.income, 'Pemasukan'),
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
              label: 'Pemasukan',
              amount: income,
              color: AppColors.income,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 34, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryItem(
              label: 'Pengeluaran',
              amount: expense,
              color: AppColors.coral,
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
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatIdr(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
