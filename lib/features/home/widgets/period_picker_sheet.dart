import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/date_range.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../core/widgets/app_date_picker.dart';

/// Lembar pilihan periode Beranda:
/// - Preset periode: Hari ini, 1 Minggu, Bulan ini, 1 Bulan, 3 Bulan, Tahun ini
/// - Rentang kustom: Mulai dan Selesai lewat kalender rentang
/// - Pilihan baru diterapkan ke Beranda hanya lewat tombol Terapkan, jadi
///   pengguna bisa mencoba beberapa pilihan dulu.
class PeriodPickerSheet extends StatefulWidget {
  const PeriodPickerSheet({super.key, required this.controller});

  final DashboardController controller;

  static Future<void> show(
    BuildContext context,
    DashboardController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Latar, garis, dan sudut mengikuti tema lembar (sama dengan Catat
      // Keuangan dan kalender rentang).
      builder: (_) => PeriodPickerSheet(controller: controller),
    );
  }

  @override
  State<PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<PeriodPickerSheet> {
  late DateTime _customStart;
  late DateTime _customEnd;

  /// Pilihan yang belum diterapkan; [DateRangePreset.custom] = rentang kustom.
  late DateRangePreset _selected;

  static List<(DateRangePreset, String)> get _presets => [
    (DateRangePreset.today, 'Hari ini'.tr),
    (DateRangePreset.week, '1 Minggu'.tr),
    (DateRangePreset.currentMonth, 'Bulan ini'.tr),
    (DateRangePreset.month, '1 Bulan'.tr),
    (DateRangePreset.threeMonths, '3 Bulan'.tr),
    (DateRangePreset.yearToDate, 'Tahun ini'.tr),
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.controller.range.value;
    _customStart = current.start;
    _customEnd = current.end;
    _selected = widget.controller.preset.value;
  }

  String _formatDate(DateTime date) => DateLabel.day(date);

  String _presetSubtitle(DateRangePreset preset) {
    final range = DateRange.fromPreset(preset);
    if (preset == DateRangePreset.today) {
      return _formatDate(range.end);
    }
    return DateLabel.range(range);
  }

  /// Hanya menandai pilihan; tanggal Mulai/Selesai ikut menampilkan
  /// rentangnya. Beranda berubah setelah Terapkan.
  void _selectPreset(DateRangePreset preset) {
    final range = DateRange.fromPreset(preset);
    setState(() {
      _selected = preset;
      _customStart = range.start;
      _customEnd = range.end;
    });
  }

  /// Membuka kalender rentang (B); [editEnd] mengaktifkan kolom "Sampai".
  Future<void> _pickRange({required bool editEnd}) async {
    final now = DateTime.now();
    final picked = await showAppDateRangePicker(
      context,
      initialRange: DateTimeRange(start: _customStart, end: _customEnd),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      editEnd: editEnd,
    );
    if (picked != null) {
      setState(() {
        _selected = DateRangePreset.custom;
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }

  Future<void> _apply() async {
    Navigator.of(context).pop();
    if (_selected == DateRangePreset.custom) {
      await widget.controller.setRange(
        DateRange.history(start: _customStart, end: _customEnd),
      );
    } else {
      await widget.controller.setPreset(_selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _selected;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PILIH PERIODE'.tr,
              style: AppText.monoLabel(color: AppColors.mut, size: 11.5),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _presets.length; i++) ...[
              _buildPresetTile(
                preset: _presets[i].$1,
                title: _presets[i].$2,
                subtitle: _presetSubtitle(_presets[i].$1),
                isSelected: selectedPreset == _presets[i].$1,
              ),
              if (i < _presets.length - 1 &&
                  selectedPreset != _presets[i].$1 &&
                  selectedPreset != _presets[i + 1].$1)
                const Divider(height: 1, thickness: 1, color: AppColors.line2),
            ],
            const SizedBox(height: 22),
            Text(
              'RENTANG KUSTOM'.tr,
              style: AppText.monoLabel(color: AppColors.mut, size: 11.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'Mulai'.tr,
                    value: _formatDate(_customStart),
                    onTap: () => _pickRange(editEnd: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: 'Selesai'.tr,
                    value: _formatDate(_customEnd),
                    onTap: () => _pickRange(editEnd: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Terapkan'.tr,
                  style: AppText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.paper,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTile({
    required DateRangePreset preset,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectPreset(preset),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: isSelected ? AppColors.paper : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppText.mono(
                      size: 11.5,
                      color: isSelected
                          ? AppColors.paper.withValues(alpha: 0.75)
                          : AppColors.ink2,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.check, color: AppColors.paper, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.body(size: 11, color: AppColors.mut)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.mono(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
