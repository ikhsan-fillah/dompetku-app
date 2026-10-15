import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../utils/category_icons.dart';

Future<bool> showCategorySheet(
  BuildContext context, {
  CategoryModel? category,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      side: BorderSide(color: AppColors.line),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: CategoryFormSheet(category: category),
    ),
  );
  return saved == true;
}

class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({super.key, this.category});

  final CategoryModel? category;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  static const _colorPalette = <int>[
    0xFF0E5E55,
    0xFF2E6B3C,
    0xFF4C7A3F,
    0xFF6F8A2E,
    0xFF3F7A9E,
    0xFF4E6A8F,
    0xFF8A5A3B,
    0xFF9A5A6A,
    0xFFC4892A,
    0xFFC9743A,
    0xFFB2556A,
    0xFF5B7B6A,
    0xFF9A6A12,
    0xFF64748B,
    0xFF90A4AE,
  ];

  late final TextEditingController _nameController;
  late TransactionType _type;
  late String _iconKey;
  late int _colorValue;
  late bool _isFavorite;
  String? _error;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<CategoryController>();
    _type = widget.category?.type ?? controller.selectedType.value;
    _iconKey = widget.category?.iconKey ?? CategoryIcons.keys.first;
    _colorValue = widget.category?.colorValue ?? _colorPalette.first;
    _isFavorite = widget.category?.isFavorite ?? false;
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Nama kategori wajib diisi.');
      return;
    }

    final controller = Get.find<CategoryController>();
    final categories = controller.state.value.data ?? const <CategoryModel>[];
    final nextSortOrder =
        categories.where((item) => item.type == _type).fold<int>(-1, (
          current,
          item,
        ) {
          return item.sortOrder > current ? item.sortOrder : current;
        }) +
        1;
    final category = CategoryModel(
      id: widget.category?.id,
      name: trimmed,
      type: _type,
      iconKey: _iconKey,
      colorValue: _colorValue,
      isDefault: widget.category?.isDefault ?? false,
      isFavorite: _isFavorite,
      sortOrder: widget.category?.sortOrder ?? nextSortOrder,
      isArchived: widget.category?.isArchived ?? false,
      createdAt: widget.category?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final ok = await controller.save(category);
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _error = controller.state.value.message ?? 'Gagal menyimpan kategori.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.category == null
                        ? 'Tambah kategori'
                        : 'Edit kategori',
                    style: AppText.display(size: 19),
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(LucideIcons.x, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.paper2,
                foregroundColor: AppColors.mut,
                selectedBackgroundColor: AppColors.card,
                selectedForegroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                textStyle: AppText.body(size: 12.5, weight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.smallButton),
                ),
              ),
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
              selected: {_type},
              onSelectionChanged: widget.category == null
                  ? (selection) => setState(() => _type = selection.first)
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nama kategori',
              hint: 'Contoh: Makan siang',
              prefixIcon: LucideIcons.tag,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Favorit',
                    style: AppText.body(size: 13, weight: FontWeight.w700),
                  ),
                ),
                Switch.adaptive(
                  value: _isFavorite,
                  activeTrackColor: AppColors.ink,
                  activeThumbColor: AppColors.paper,
                  inactiveTrackColor: AppColors.line,
                  inactiveThumbColor: Colors.white,
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ikon',
              style: AppText.label(),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                for (final iconKey in CategoryIcons.keys)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.smallButton),
                    onTap: () => setState(() => _iconKey = iconKey),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _iconKey == iconKey
                            ? AppColors.ink
                            : AppColors.card,
                        borderRadius:
                            BorderRadius.circular(AppRadius.smallButton),
                        border: Border.all(
                          color: _iconKey == iconKey
                              ? AppColors.ink
                              : AppColors.line,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.of(iconKey),
                        size: 20,
                        color: _iconKey == iconKey
                            ? AppColors.paper
                            : AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Warna',
              style: AppText.label(),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              children: [
                for (final value in _colorPalette)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.smallButton),
                    onTap: () => setState(() => _colorValue = value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(value),
                        borderRadius:
                            BorderRadius.circular(AppRadius.smallButton),
                        border: Border.all(
                          color: _colorValue == value
                              ? AppColors.ink
                              : Colors.transparent,
                          width: _colorValue == value ? 2 : 0,
                        ),
                      ),
                      child: _colorValue == value
                          ? const Icon(
                              LucideIcons.check,
                              color: AppColors.paper,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.spend,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: widget.category == null
                  ? 'Simpan kategori'
                  : 'Perbarui kategori',
              icon: LucideIcons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
