import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../models/monthly_trend.dart';
import 'trend_chart.dart';

/// Kartu tren harian di Laporan: "Tren pengeluaran" atau "Tren pemasukan"
/// menurut jenis [trend]. Bulannya diatur pemilih bulan Laporan, jadi kartu
/// ini tidak punya panah sendiri.
///
/// Pengeluaran memakai batang tinta, batang tertinggi merah, dan garis
/// rata-rata per hari. Pemasukan memakai batang hijau tanpa garis rata-rata
/// karena pemasukan jarang terjadi setiap hari.
class ReportTrendCard extends StatefulWidget {
  const ReportTrendCard({super.key, required this.trend});

  final MonthlyTrend trend;

  @override
  State<ReportTrendCard> createState() => _ReportTrendCardState();
}

class _ReportTrendCardState extends State<ReportTrendCard> {
  int? _selected;

  bool get _isIncome => widget.trend.type == TransactionType.income;

  @override
  void didUpdateWidget(ReportTrendCard old) {
    super.didUpdateWidget(old);
    if (old.trend.month != widget.trend.month) _selected = null;
  }

  void _select(int index) => setState(() {
    final trend = widget.trend;
    _selected = index == _selected || index >= trend.elapsedDays ? null : index;
  });

  String _info(MonthlyTrend trend) {
    if (!_isIncome) {
      return 'Rata-rata @amount per hari'.trParams({
        'amount': formatIdr(trend.average.round()),
      });
    }
    return trend.transactionCount == 0
        ? 'Belum ada pemasukan bulan ini'.tr
        : '@count pemasukan'.trParams({'count': '${trend.transactionCount}'});
  }

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
            _isIncome ? 'Tren pemasukan'.tr : 'Tren pengeluaran'.tr,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              letterSpacing: 0.13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(_info(trend), style: infoStyle)),
              if (_selected == null && trend.total > 0)
                Text('Ketuk batang'.tr, style: infoStyle),
            ],
          ),
          TrendChart(
            trend: trend,
            selected: _selected,
            onTapDay: _select,
            accent: _isIncome ? AppColors.earn : AppColors.ink,
            peakColor: _isIncome ? AppColors.earn : AppColors.spend,
            showAverage: !_isIncome,
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
