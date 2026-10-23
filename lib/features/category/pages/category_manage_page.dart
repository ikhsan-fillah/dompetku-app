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
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../utils/category_icons.dart';
import '../widgets/category_form_sheet.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';

/// Halaman kelola kategori: filter tipe, favorit (maks. 4, selalu di atas),
/// urutan, dan hapus.
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
    final message =
        _controller.lastError.value ??
        _controller.state.value.message ??
        'Terjadi kesalahan.'.tr;
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

  Future<void> _confirmDelete(CategoryModel category) async {
    final id = category.id;
    if (id == null || category.isFallback) return;
    final confirmed = await showAppConfirm(
      context,
      title: 'Hapus kategori?'.tr,
      message:
          '"@name" dihapus permanen. Transaksinya dipindah ke kategori @other, dan anggaran khusus kategori ini ikut dihapus.'
              .trParams({
                'name': category.displayName,
                'other': CategoryModel.fallbackName.tr,
              }),
      confirmLabel: 'Hapus'.tr,
      danger: true,
    );
    if (!confirmed) return;
    final ok = await _controller.delete(id);
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
              label: 'Coba lagi'.tr,
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
      return _message(
        state.message ?? 'Gagal memuat kategori.'.tr,
        retry: true,
      );
    }
    if (items.isEmpty) {
      return _message('Belum ada kategori.'.tr);
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
                        category.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 13, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.isFallback
                            ? 'Bawaan · penampung, tidak bisa dihapus'.tr
                            : category.isDefault
                            ? 'Bawaan'.tr
                            : 'Kustom'.tr,
                        style: AppText.body(size: 10.5, color: AppColors.mut),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: category.isFavorite
                      ? 'Hapus dari favorit'.tr
                      : 'Jadikan favorit'.tr,
                  onPressed: () => _toggleFavorite(category),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      category.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      key: ValueKey(category.isFavorite),
                      size: 24,
                      color: category.isFavorite
                          ? AppColors.favorite
                          : AppColors.mut,
                    ),
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
                    _confirmDelete(category);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'.tr),
                    ),
                    if (!category.isFallback)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          'Hapus'.tr,
                          style: AppText.body(size: 14, color: AppColors.spend),
                        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitleBar(
              title: 'Daftar kategori'.tr,
              action: AppBarIconButton(
                tooltip: 'Tambah kategori'.tr,
                icon: LucideIcons.plus,
                onPressed: () => _showAddOrEditForm(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    showSelectedIcon: false,
                    style: _segmentStyle,
                    segments: [
                      ButtonSegment<TransactionType>(
                        value: TransactionType.expense,
                        label: Text('Pengeluaran'.tr),
                      ),
                      ButtonSegment<TransactionType>(
                        value: TransactionType.income,
                        label: Text('Pemasukan'.tr),
                      ),
                    ],
                    selected: {_controller.selectedType.value},
                    onSelectionChanged: (selection) =>
                        _controller.setType(selection.first),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                10,
                AppSpacing.page,
                10,
              ),
              child: Obx(() {
                _controller.state.value;
                final count = _controller.favoriteCount(
                  _controller.selectedType.value,
                );
                return Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.favorite,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '@count dari @max favorit · tampil di Beranda'
                            .trParams({
                              'count': '$count',
                              'max': '${CategoryController.maxFavorites}',
                            }),
                        style: AppText.body(size: 11.5, color: AppColors.ink2),
                      ),
                    ),
                  ],
                );
              }),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Obx(_buildList),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
