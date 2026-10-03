import 'package:flutter/material.dart';

import '../../../core/utils/date_range.dart';
import '../../../core/widgets/app_chip.dart';

/// Baris chip pilihan periode. Memilih Kustom diserahkan ke pemanggil.
class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final DateRangePreset selected;
  final ValueChanged<DateRangePreset> onSelect;

  static const _items = [
    (DateRangePreset.today, 'Hari ini'),
    (DateRangePreset.week, '1 Minggu'),
    (DateRangePreset.currentMonth, 'Bulan ini'),
    (DateRangePreset.month, '1 Bulan'),
    (DateRangePreset.threeMonths, '3 Bulan'),
    (DateRangePreset.yearToDate, 'Tahun ini'),
    (DateRangePreset.custom, 'Kustom'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (final (preset, label) in _items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppChip(
                label: label,
                selected: selected == preset,
                onTap: () => onSelect(preset),
              ),
            ),
        ],
      ),
    );
  }
}
