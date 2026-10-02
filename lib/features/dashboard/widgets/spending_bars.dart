import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../models/dashboard_view_models.dart';

/// Grafik batang pengeluaran. Ketuk batang untuk melihat nilai persisnya.
class SpendingBars extends StatefulWidget {
  const SpendingBars({super.key, required this.buckets});

  final List<TrendBucket> buckets;

  @override
  State<SpendingBars> createState() => _SpendingBarsState();
}

class _SpendingBarsState extends State<SpendingBars> {
  static const double _chartHeight = 110;
  int? _selected;

  String _rangeLabel(TrendBucket bucket) {
    final start = bucket.start;
    final end = bucket.end;
    if (start == end) return '${start.day}/${start.month}';
    return '${start.day}/${start.month}–${end.day}/${end.month}';
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    if (buckets.isEmpty) {
      return const Text('Belum ada pengeluaran pada periode ini.');
    }
    final maxAmount = buckets.fold<int>(
      0,
      (m, b) => b.amount > m ? b.amount : m,
    );
    final isZeroState = maxAmount == 0;
    final selected = (_selected != null && _selected! < buckets.length)
        ? _selected
        : null;
    final compactLabels = buckets.every((b) => b.label.length <= 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isZeroState
                  ? 'Belum ada pengeluaran pada periode ini.'
                  : selected == null
                  ? 'Ketuk batang untuk melihat nilai'
                  : '${_rangeLabel(buckets[selected])} · ${formatIdr(buckets[selected].amount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected == null
                    ? FontWeight.w400
                    : FontWeight.w600,
                color: isZeroState || selected == null
                    ? AppColors.muted
                    : AppColors.ink,
              ),
            ),
          ),
        ),
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isZeroState
                          ? null
                          : () => setState(
                              () => _selected = selected == i ? null : i,
                            ),
                      child: Semantics(
                        button: !isZeroState,
                        label:
                            '${_rangeLabel(buckets[i])}: ${formatIdr(buckets[i].amount)}',
                        excludeSemantics: true,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            height: maxAmount == 0
                                ? 6
                                : math.max(
                                    6,
                                    buckets[i].amount /
                                        maxAmount *
                                        _chartHeight,
                                  ),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                                bottom: Radius.circular(3),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isZeroState
                                    ? const [
                                        Color(0xFFD7E9E5),
                                        Color(0xFFB9DAD3),
                                      ]
                                    : selected == i
                                    ? const [AppColors.amber, AppColors.coral]
                                    : const [Color(0xFF99E6DA), AppColors.mint],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < buckets.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    (compactLabels || i.isEven) ? buckets[i].label : '',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontSize: 9, color: AppColors.muted),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
