import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/date_range.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

/// Popover / Bottom sheet pilihan periode sesuai mockup:
/// - Preset periode: Hari ini, 1 Minggu, 1 Bulan, 3 Bulan, Tahun ini
/// - Memilih preset langsung menutup popover dan memperbarui semua kartu
/// - Rentang kustom: Mulai, Selesai, dan tombol Terapkan rentang
class PeriodPickerSheet extends StatefulWidget {
  const PeriodPickerSheet({
    super.key,
    required this.controller,
  });

  final DashboardController controller;

  static Future<void> show(BuildContext context, DashboardController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PeriodPickerSheet(controller: controller),
    );
  }

  @override
  State<PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<PeriodPickerSheet> {
  late DateTime _customStart;
  late DateTime _customEnd;

  static const _presets = <(DateRangePreset, String)>[
    (DateRangePreset.today, 'Hari ini'),
    (DateRangePreset.week, '1 Minggu'),
    (DateRangePreset.month, '1 Bulan'),
    (DateRangePreset.threeMonths, '3 Bulan'),
    (DateRangePreset.yearToDate, 'Tahun ini'),
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.controller.range.value;
    _customStart = current.start;
    _customEnd = current.end;
  }

  String _formatDate(DateTime date) => DateLabel.day(date);

  String _presetSubtitle(DateRangePreset preset) {
    final range = DateRange.fromPreset(preset);
    if (preset == DateRangePreset.today) {
      return _formatDate(range.end);
    }
    return DateLabel.range(range);
  }

  Future<void> _selectPreset(DateRangePreset preset) async {
    Navigator.of(context).pop();
    await widget.controller.setPreset(preset);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStart,
      firstDate: DateTime(2000),
      lastDate: _customEnd.isBefore(DateTime.now()) ? _customEnd : DateTime.now(),
    );
    if (picked != null) {
      setState(() => _customStart = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEnd.isAfter(today) ? today : _customEnd,
      firstDate: _customStart,
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _customEnd = picked);
    }
  }

  Future<void> _applyCustomRange() async {
    Navigator.of(context).pop();
    await widget.controller.setRange(
      DateRange.history(start: _customStart, end: _customEnd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = widget.controller.preset.value;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PILIH PERIODE',
              style: AppText.monoLabel(
                color: AppColors.mut,
                size: 11.5,
              ),
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.line2,
                ),
            ],
            const SizedBox(height: 22),
            Text(
              'RENTANG KUSTOM',
              style: AppText.monoLabel(
                color: AppColors.mut,
                size: 11.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'Mulai',
                    value: _formatDate(_customStart),
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: 'Selesai',
                    value: _formatDate(_customEnd),
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _applyCustomRange,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.paper,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Terapkan rentang',
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
          color: isSelected ? AppColors.paper2 : Colors.transparent,
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
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppText.mono(
                      size: 11.5,
                      color: AppColors.mut,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                color: AppColors.ink,
                size: 20,
              ),
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
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.body(size: 11, color: AppColors.mut),
              ),
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
