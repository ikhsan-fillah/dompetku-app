import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_bar_icon_button.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../utils/category_icons.dart';
import '../widgets/category_form_sheet.dart';
import '../../../app/routes/app_routes.dart';

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

  static final _segmentStyle = SegmentedButton.styleFrom(
    backgroundColor: AppColors.paper2,
    foregroundColor: AppColors.mut,
    selectedBackgroundColor: AppColors.card,
    selectedForegroundColor: AppColors.ink,
    side: const BorderSide(color: AppColors.line),
    textStyle: AppText.body(size: 12.5, weight: FontWeight.w700),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.smallButton),
    ),
  );

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
  }

  Future<void> _confirmArchive(CategoryModel category) async {
    final id = category.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Text('Arsipkan kategori?', style: AppText.display(size: 20)),
        content: Text(
          '"${category.name}" tidak muncul lagi untuk transaksi baru. Transaksi lama tetap aman.',
          style: AppText.body(size: 13, color: AppColors.mut, height: 1.45),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Batal',
              style: AppText.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Arsipkan',
              style: AppText.body(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.paper,
              ),
            ),
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
  }

  Widget _message(String text, {bool retry = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.ink2),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => Get.toNamed(
              AppRoutes.categoryDetail,
              arguments: {'categoryId': category.id},
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Icon(
                      LucideIcons.gripVertical,
                      color: AppColors.line,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CategoryIconBox(
                  icon: CategoryIcons.of(category.iconKey),
                  color: Color(category.colorValue),
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
                        style: AppText.body(size: 13, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.isDefault
                            ? 'Bawaan · tidak bisa dihapus bila dipakai'
                            : 'Kustom',
                        style: AppText.body(size: 10.5, color: AppColors.mut),
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
                    LucideIcons.star,
                    size: 20,
                    color: category.isFavorite
                        ? AppColors.ink
                        : AppColors.line,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    LucideIcons.ellipsis,
                    color: AppColors.mut,
                    size: 18,
                  ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Kategori', style: AppText.display(size: 26)),
                  ),
                  AppBarIconButton(
                    tooltip: 'Tambah kategori',
                    icon: LucideIcons.plus,
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
                    style: _segmentStyle,
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
