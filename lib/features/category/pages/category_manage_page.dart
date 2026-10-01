import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../utils/category_icons.dart';
import '../widgets/category_form_sheet.dart';

/// Halaman kelola kategori: filter tipe, favorit, urutan, dan arsip.
class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  late final CategoryController _controller = Get.find<CategoryController>();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  void _showError() {
    final message = _controller.state.value.message ?? 'Terjadi kesalahan.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleFavorite(CategoryModel category) async {
    final ok = await _controller.toggleFavorite(category);
    if (!mounted || ok) return;
    _showError();
  }

  Future<void> _move(int oldIndex, int newIndex) async {
    final ok = await _controller.moveWithinType(oldIndex, newIndex);
    if (!mounted || ok) return;
    _showError();
  }

  Future<void> _showAddOrEditForm([CategoryModel? category]) async {
    final ok = await showCategorySheet(context, category: category);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          category == null ? 'Kategori ditambahkan.' : 'Kategori diperbarui.',
        ),
      ),
    );
  }

  Future<void> _confirmArchive(CategoryModel category) async {
    final id = category.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Arsipkan kategori?'),
        content: Text(
          '"${category.name}" tidak muncul lagi untuk transaksi baru. Transaksi lama tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _controller.archive(id);
    if (!mounted) return;
    if (!ok) {
      _showError();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kategori diarsipkan.')));
  }

  Widget _message(String text, {bool retry = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          if (retry) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Coba lagi',
              expand: false,
              onPressed: () => _controller.load(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    final state = _controller.state.value;
    final items = _controller.visibleCategories;
    final textTheme = Theme.of(context).textTheme;

    if (state.status == ResourceStatus.loading ||
        state.status == ResourceStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ResourceStatus.error) {
      return _message(state.message ?? 'Gagal memuat kategori.', retry: true);
    }
    if (items.isEmpty) {
      return _message('Belum ada kategori.');
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: (oldIndex, newIndex) {
        _move(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final category = items[index];
        return AppCard(
          key: ValueKey(category.id),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showAddOrEditForm(category),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(category.colorValue),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CategoryIcons.of(category.iconKey),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        category.isDefault ? 'Bawaan' : 'Kustom',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: category.isFavorite
                      ? 'Hapus dari favorit'
                      : 'Jadikan favorit',
                  onPressed: () => _toggleFavorite(category),
                  icon: Icon(
                    category.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: category.isFavorite
                        ? AppColors.amber
                        : AppColors.muted,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddOrEditForm(category);
                      return;
                    }
                    _confirmArchive(category);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                      value: 'archive',
                      child: Text('Arsipkan'),
                    ),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            12,
            AppSpacing.page,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: IconButton(
                      tooltip: 'Kembali',
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Kategori', style: textTheme.titleLarge),
                  ),
                  AppButton(
                    label: 'Tambah',
                    expand: false,
                    icon: Icons.add_rounded,
                    onPressed: () => _showAddOrEditForm(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<TransactionType>(
                        value: TransactionType.expense,
                        label: Text('Pengeluaran'),
                      ),
                      ButtonSegment<TransactionType>(
                        value: TransactionType.income,
                        label: Text('Pemasukan'),
                      ),
                    ],
                    selected: {_controller.selectedType.value},
                    onSelectionChanged: (selection) =>
                        _controller.setType(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(child: Obx(_buildList)),
            ],
          ),
        ),
      ),
    );
  }
}
