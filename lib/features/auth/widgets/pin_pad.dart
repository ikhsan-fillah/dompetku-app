import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Indikator 6 titik dan keypad angka (1–9, 0, hapus). Tidak ada tombol 000.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onDigit,
    required this.onDelete,
    this.length = 6,
  });

  final String value;
  final int length;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final filled = index < value.length;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.ink : Colors.transparent,
                border: Border.all(color: AppColors.ink, width: 1.4),
              ),
            );
          }),
        ),
        const SizedBox(height: 22),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            children: [
              for (final digit in row) _key(digit, () => onDigit(digit)),
            ],
          ),
        Row(
          children: [
            const Expanded(child: SizedBox(height: 56)),
            _key('0', () => onDigit('0')),
            _iconKey(Icons.backspace_outlined, onDelete),
          ],
        ),
      ],
    );
  }

  Widget _key(String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(label, style: AppText.display(size: 24)),
          ),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Icon(icon, color: AppColors.ink2),
          ),
        ),
      ),
    );
  }
}
