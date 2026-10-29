import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Pemilih dua atau tiga bagian selebar layar. Bagian terpilih berlatar tinta,
/// sama dengan chip aktif di bagian lain app.
class StockSegmented<T> extends StatelessWidget {
  const StockSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;

  /// Pasangan nilai dan teks, dalam urutan tampil.
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.button + 2),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final (option, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == value
                          ? AppColors.ink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.button - 1),
                    ),
                    child: Text(
                      label,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color: option == value
                            ? AppColors.paper
                            : AppColors.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
