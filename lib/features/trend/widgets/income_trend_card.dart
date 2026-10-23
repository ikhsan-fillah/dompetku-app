import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../models/monthly_trend.dart';
import 'spending_trend_card.dart';

/// Kartu "Tren pemasukan" di Laporan: batang per hari untuk bulan yang sedang
/// dibuka di halaman (bulannya diatur pemilih bulan Laporan, jadi kartu ini
/// tidak punya panah sendiri). Memakai grafik yang sama dengan tren pengeluaran,
/// berwarna hijau dan tanpa garis rata-rata karena pemasukan jarang harian.
class IncomeTrendCard extends StatefulWidget {
  const IncomeTrendCard({super.key, required this.trend});

  final MonthlyTrend trend;

  @override
  State<IncomeTrendCard> createState() => _IncomeTrendCardState();
}

class _IncomeTrendCardState extends State<IncomeTrendCard> {
  int? _selected;

  @override
  void didUpdateWidget(IncomeTrendCard old) {
    super.didUpdateWidget(old);
    if (old.trend.month != widget.trend.month) _selected = null;
  }

  void _select(int index) => setState(() {
    final trend = widget.trend;
    _selected = index == _selected || index >= trend.elapsedDays ? null : index;
  });

  @override
  Widget build(BuildContext context) {
    final trend = widget.trend;
    final infoStyle = AppText.mono(
      size: 11,
      weight: FontWeight.w400,
      color: AppColors.ink2,
      letterSpacing: 0,
    );
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren pemasukan'.tr,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              letterSpacing: 0.13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  trend.transactionCount == 0
                      ? 'Belum ada pemasukan bulan ini'.tr
                      : '@count pemasukan'.trParams({
                          'count': '${trend.transactionCount}',
                        }),
                  style: infoStyle,
                ),
              ),
              if (_selected == null && trend.total > 0)
                Text('Ketuk batang'.tr, style: infoStyle),
            ],
          ),
          SpendingTrendChart(
            trend: trend,
            selected: _selected,
            onTapDay: _select,
            accent: AppColors.earn,
            peakColor: AppColors.earn,
            showAverage: false,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.line2),
          const SizedBox(height: 10),
          TrendTotalLine(trend: trend),
        ],
      ),
    );
  }
}
