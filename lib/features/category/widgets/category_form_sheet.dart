import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
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
    0xFF0F766E,
    0xFF10B981,
    0xFF14B8A6,
    0xFF22C55E,
    0xFF38BDF8,
    0xFF3B82F6,
    0xFF8B5CF6,
    0xFFC084FC,
    0xFFF97316,
    0xFFF59E0B,
    0xFFF43F5E,
    0xFFEC4899,
    0xFFEAB308,
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
    final categories =
      controller.state.value.data ?? const <CategoryModel>[];
    final nextSortOrder = categories
        .where((item) => item.type == _type)
        .fold<int>(-1, (current, item) {
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
    final textTheme = Theme.of(context).textTheme;
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
                    widget.category == null ? 'Tambah kategori' : 'Edit kategori',
                    style: textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
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
              prefixIcon: Icons.label_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Favorit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch.adaptive(
                  value: _isFavorite,
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ikon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
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
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _iconKey = iconKey),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _iconKey == iconKey ? Color(_colorValue) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _iconKey == iconKey
                              ? Color(_colorValue).withAlpha((255 * 0.7).round())
                              : AppColors.line,
                          width: _iconKey == iconKey ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        CategoryIcons.of(iconKey),
                        color: _iconKey == iconKey ? Colors.white : AppColors.teal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Warna',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
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
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _colorValue = value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(value),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _colorValue == value ? Colors.black : Colors.transparent,
                          width: _colorValue == value ? 2.5 : 0,
                        ),
                      ),
                      child: _colorValue == value
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: widget.category == null ? 'Simpan kategori' : 'Perbarui kategori',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}