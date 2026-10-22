import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../services/receipt_ocr_service.dart';

/// Item struk untuk visualisasi kertas struk
class ReceiptLineItem {
  const ReceiptLineItem({required this.name, required this.amount});

  final String name;
  final int amount;
}

/// Halaman review "Periksa struk".tr sesuai mockup:
/// - Kertas struk bergaya realistis
/// - Field yang kurang yakin ditandai "Periksa".tr (latar amber + ikon lonceng)
/// - Field yang yakin ditandai "Yakin".tr (ikon centang hijau)
/// - Ubah kategori yang disarankan
/// - Peringatan: "Belum ada yang tersimpan sampai kamu menekan Konfirmasi"
/// - Tombol Foto ulang & Konfirmasi
/// - Tidak ada yang tersimpan sebelum Konfirmasi
class ReceiptReviewPage extends StatefulWidget {
  const ReceiptReviewPage({
    super.key,
    this.scanResult,
    this.initialMerchant,
    this.initialDate,
    this.initialTotal,
    this.onRetake,
  });

  final ReceiptScanResult? scanResult;
  final String? initialMerchant;
  final DateTime? initialDate;
  final int? initialTotal;
  final VoidCallback? onRetake;

  @override
  State<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

class _ReceiptReviewPageState extends State<ReceiptReviewPage> {
  late String _merchant;
  late DateTime _date;
  late int _total;
  bool _totalDoubtful = true; // Field kurang yakin ditandai "Periksa".tr
  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  bool _saving = false;

  late final List<ReceiptLineItem> _receiptItems;

  @override
  void initState() {
    super.initState();
    final parsed = widget.scanResult?.receipt;

    _merchant = widget.initialMerchant ?? parsed?.merchant ?? '';
    _date = widget.initialDate ?? parsed?.date ?? DateTime.now();
    _total = widget.initialTotal ?? parsed?.total ?? 0;
    _receiptItems = const [];

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (Get.isRegistered<CategoryRepository>()) {
      final repo = Get.find<CategoryRepository>();
      final list = await repo.getAll();
      if (mounted) {
        setState(() {
          _categories = list
              .where((c) => c.type == TransactionType.expense)
              .toList();
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.firstWhere(
              (c) =>
                  c.name.toLowerCase().contains('belanja') ||
                  c.name.toLowerCase().contains('shop'),
              orElse: () => _categories.first,
            );
          }
        });
      }
    }
  }

  Future<void> _editMerchant() async {
    final controller = TextEditingController(text: _merchant);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Merchant'.tr, style: AppText.display(size: 19)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Nama Merchant'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Simpan'.tr),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _merchant = result);
    }
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _editTotal() async {
    final controller = TextEditingController(text: _total.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Total'.tr, style: AppText.display(size: 19)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Total Pembayaran'.tr,
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal'.tr),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(
                controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
              );
              Navigator.of(ctx).pop(parsed);
            },
            child: Text('Simpan'.tr),
          ),
        ],
      ),
    );
    if (result != null && result > 0 && mounted) {
      setState(() {
        _total = result;
        _totalDoubtful = false; // Sudah diperiksa dan dikonfirmasi pengguna
      });
    }
  }

  void _chooseCategory() {
    if (_categories.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pilih Kategori'.tr, style: AppText.display(size: 18)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (_, index) {
                    final cat = _categories[index];
                    final isSelected = cat.id == _selectedCategory?.id;
                    return ListTile(
                      title: Text(cat.name, style: AppText.body(size: 14)),
                      trailing: isSelected
                          ? const Icon(LucideIcons.check, color: AppColors.ink)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final category = _selectedCategory?.id;
      if (category == null || _total <= 0) {
        throw StateError('Total dan kategori wajib diisi.');
      }
      final repo = Get.find<TransactionRepository>();
      final now = DateTime.now();
      await repo.insert(
        TransactionModel(
          type: TransactionType.expense,
          title: _merchant.isEmpty ? _selectedCategory!.displayName : _merchant,
          amount: _total,
          currency: 'IDR',
          transactionDate: _date,
          categoryId: category,
          merchantOrSource: _merchant,
          paymentMethod: PaymentMethod.cash,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi. Coba lagi.'.tr),
            backgroundColor: AppColors.spend,
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _selectedCategory?.displayName ?? '-';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Top Bar
            AppTitleBar(title: 'Periksa struk'.tr),
            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  // Realistic Receipt Paper Card
                  _ReceiptPaperCard(
                    merchant: _merchant.toUpperCase(),
                    items: _receiptItems,
                    total: _total,
                    dateTimeText:
                        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year} ${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 16),

                  // Card 1: Merchant
                  _ReviewFieldCard(
                    label: 'Merchant'.tr,
                    value: _merchant,
                    statusText: 'Yakin'.tr,
                    isSure: true,
                    onTap: _editMerchant,
                  ),
                  const SizedBox(height: 10),

                  // Card 2: Tanggal
                  _ReviewFieldCard(
                    label: 'Tanggal'.tr,
                    value: DateLabel.day(_date),
                    statusText: 'Yakin'.tr,
                    isSure: true,
                    onTap: _editDate,
                  ),
                  const SizedBox(height: 10),

                  // Card 3: Total (Field yang kurang yakin ditandai "Periksa".tr)
                  _ReviewFieldCard(
                    label: 'Total'.tr,
                    value: formatIdr(_total),
                    statusText: _totalDoubtful ? 'Periksa'.tr : 'Yakin'.tr,
                    isSure: !_totalDoubtful,
                    isWarn: _totalDoubtful,
                    onTap: _editTotal,
                  ),
                  const SizedBox(height: 10),

                  // Card 4: Kategori Disarankan
                  _ReviewFieldCard(
                    label: 'Kategori disarankan'.tr,
                    value: categoryName,
                    actionText: 'Ubah'.tr,
                    onTap: _chooseCategory,
                  ),
                  const SizedBox(height: 20),

                  // Privacy disclaimer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.lock,
                        size: 13,
                        color: AppColors.mut,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Belum ada yang tersimpan sampai kamu menekan Konfirmasi.'
                              .tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 11.5, color: AppColors.mut),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bottom Action Buttons: Foto ulang & Konfirmasi
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onRetake?.call();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.paper2,
                              foregroundColor: AppColors.ink,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Foto ulang'.tr,
                              style: AppText.body(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _saving ? null : _confirmAndSave,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: AppColors.paper,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.paper,
                                    ),
                                  )
                                : Text(
                                    'Konfirmasi'.tr,
                                    style: AppText.body(
                                      size: 14,
                                      weight: FontWeight.w700,
                                      color: AppColors.paper,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visualisasi kertas struk realistis
class _ReceiptPaperCard extends StatelessWidget {
  const _ReceiptPaperCard({
    required this.merchant,
    required this.items,
    required this.total,
    required this.dateTimeText,
  });

  final String merchant;
  final List<ReceiptLineItem> items;
  final int total;
  final String dateTimeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.receiptPaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Accent Line
          Container(
            height: 3.5,
            decoration: const BoxDecoration(
              color: Color(0xFF4E7D73),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  merchant,
                  textAlign: TextAlign.center,
                  style: AppText.mono(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppColors.receiptText,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Jl. Kaliurang Km 7, Sleman',
                  textAlign: TextAlign.center,
                  style: AppText.mono(
                    size: 11,
                    color: AppColors.mut,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                const _DashedLine(),
                const SizedBox(height: 12),
                for (final item in items) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: AppText.mono(
                          size: 11.5,
                          color: AppColors.receiptText,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        _formatNumber(item.amount),
                        style: AppText.mono(
                          size: 11.5,
                          color: AppColors.receiptText,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 8),
                const _DashedLine(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: AppText.mono(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.receiptText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _formatNumber(total),
                      style: AppText.mono(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.receiptText,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateTimeText,
                  style: AppText.mono(
                    size: 11,
                    color: AppColors.receiptText,
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

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.receiptDash),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Kartu review data struk (Merchant, Tanggal, Total, Kategori)
class _ReviewFieldCard extends StatelessWidget {
  const _ReviewFieldCard({
    required this.label,
    required this.value,
    this.statusText,
    this.actionText,
    this.isSure = false,
    this.isWarn = false,
    required this.onTap,
  });

  final String label;
  final String value;
  final String? statusText;
  final String? actionText;
  final bool isSure;
  final bool isWarn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isWarn ? AppColors.warnSoft : AppColors.card;
    final borderColor = isWarn ? AppColors.warn : AppColors.line;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: isWarn ? 1.2 : 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.body(size: 11, color: AppColors.mut),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusText != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWarn ? LucideIcons.bell : LucideIcons.check,
                      size: 14,
                      color: isWarn ? AppColors.warn : AppColors.earn,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText!,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: isWarn ? AppColors.warn : AppColors.earn,
                      ),
                    ),
                  ],
                ),
              if (actionText != null)
                Text(
                  actionText!,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
