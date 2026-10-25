import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/report_controller.dart';
import '../../../core/widgets/motion.dart';

/// Pemilih bulan: panah kiri/kanan dengan nama bulan di tengah.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final bool canGoNext;

  /// Dipasang di bagian atas kartu cincin Laporan, jadi tanpa jarak tepi
  /// halaman sendiri.
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ArrowButton(
        icon: LucideIcons.chevronLeft,
        onTap: onPrevious,
        label: 'Bulan sebelumnya'.tr,
      ),
      Expanded(
        child: Column(
          children: [
            Text(
              AppLanguage.monthLong(month.month),
              style: AppText.display(size: 28, weight: FontWeight.w600),
            ),
            Text(
              '${month.year}',
              style: AppText.mono(
                size: 12,
                weight: FontWeight.w500,
                color: AppColors.mut,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
      _ArrowButton(
        icon: LucideIcons.chevronRight,
        onTap: canGoNext ? onNext : null,
        label: 'Bulan berikutnya'.tr,
      ),
    ],
  );
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.paper : AppColors.paper2,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppColors.line : AppColors.ink,
        ),
      ),
    ),
  );
}

/// Cincin pengeluaran per kategori. Ketuk potongan untuk melihat nama,
/// nominal, dan persen kategorinya di tengah (sama seperti donat Beranda);
/// ketuk lagi untuk kembali ke total.
class SpendingRing extends StatefulWidget {
  const SpendingRing({
    super.key,
    required this.items,
    required this.total,
    required this.totalLabel,
    this.money,
  });

  final List<ReportCategoryTotal> items;
  final int total;
  final String totalLabel;

  /// Format nominal kategori terpilih; bawaan memakai [totalLabel] saja.
  final String Function(int)? money;

  @override
  State<SpendingRing> createState() => _SpendingRingState();
}

class _SpendingRingState extends State<SpendingRing> {
  int? _selected;

  @override
  void didUpdateWidget(SpendingRing old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) _selected = null;
  }

  /// Potongan pada titik [position] (relatif ke kotak berukuran [side]).
  int? _sliceAt(Offset position, double side) {
    if (widget.total <= 0) return null;
    final stroke = side * _RingPainter.strokeFactor;
    final radius = (side - stroke) / 2;
    final delta = position - Offset(side / 2, side / 2);
    final distance = delta.distance;
    // Area ketuk sedikit lebih lebar dari cincinnya.
    if (distance < radius - stroke || distance > side / 2 + 6) return null;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var start = 0.0;
    for (var i = 0; i < widget.items.length; i++) {
      final sweep = widget.items[i].amount / widget.total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.35,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxHeight, constraints.maxWidth);
        final selected = _selected != null && _selected! < widget.items.length
            ? _selected
            : null;
        final item = selected == null ? null : widget.items[selected];
        final percent = item == null || widget.total <= 0
            ? 0
            : (item.amount * 100 / widget.total).round();
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = _sliceAt(details.localPosition, side);
              if (index == null) return;
              setState(() => _selected = _selected == index ? null : index);
            },
            child: SizedBox.square(
              dimension: side,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(side),
                    painter: _RingPainter(widget.items, widget.total, selected),
                  ),
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.all(side * 0.2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item?.name ?? 'Total pengeluaran'.tr,
                              style: AppText.body(
                                size: 11,
                                color: AppColors.mut,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RollingText(
                              item == null
                                  ? widget.totalLabel
                                  : (widget.money?.call(item.amount) ??
                                        '${item.amount}'),
                              style: AppText.mono(
                                size: 22,
                                weight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: item == null
                                    ? AppColors.ink
                                    : Color(item.colorValue),
                              ),
                            ),
                            if (item != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$percent%',
                                style: AppText.mono(
                                  size: 12,
                                  color: AppColors.ink2,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.items, this.total, this.selected);

  static const strokeFactor = 0.13;

  final List<ReportCategoryTotal> items;
  final int total;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * strokeFactor;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.paper2;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;

    const gap = 0.035;
    var start = -math.pi / 2;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final sweep = item.amount / total * math.pi * 2;
      if (sweep <= 0) continue;
      final isSelected = selected == i;
      final color = Color(item.colorValue);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? stroke * 1.25 : stroke
        ..strokeCap = StrokeCap.butt
        ..color = selected == null || isSelected
            ? color
            : color.withValues(alpha: 0.3);
      final visible = items.length > 1 && sweep > gap * 2 ? sweep - gap : sweep;
      canvas.drawArc(
        rect,
        start + (sweep - visible) / 2,
        visible,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.total != total || old.items != items || old.selected != selected;
}

/// Pemasukan vs pengeluaran: persen pemasukan yang tersisa sebagai angka
/// utama, satu batang terbagi (merah terpakai, hijau tersisa), dua kartu kecil
/// dengan perbandingan bulan lalu, lalu selisihnya.
class IncomeExpenseOverview extends StatelessWidget {
  const IncomeExpenseOverview({
    super.key,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.previousExpense,
    required this.previousLabel,
    required this.money,
  });

  final int income;
  final int expense;
  final int previousIncome;
  final int previousExpense;

  /// Nama singkat bulan pembanding, mis. "Sep".
  final String previousLabel;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    final spentShare = income <= 0
        ? (expense > 0 ? 1.0 : 0.0)
        : (expense / income).clamp(0.0, 1.0);
    final over = expense > income;
    final String headline;
    final String caption;
    if (income == 0 && expense == 0) {
      headline = '0%';
      caption = 'belum ada transaksi bulan ini'.tr;
    } else if (income == 0) {
      headline = 'Defisit'.tr;
      caption = 'pengeluaran tanpa pemasukan bulan ini'.tr;
    } else if (over) {
      headline = '${((expense - income) * 100 / income).round()}%';
      caption = 'pengeluaran melebihi pemasukan'.tr;
    } else {
      headline = '${(balance * 100 / income).round()}%';
      caption = 'pemasukan tersisa bulan ini'.tr;
    }
    final headColor = income == 0 && expense == 0
        ? AppColors.mut
        : (over ? AppColors.spend : AppColors.earn);
    final spentPercent = (spentShare * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            RollingText(
              headline,
              style: AppText.display(size: 34, color: headColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                caption,
                style: AppText.body(size: 12.5, color: AppColors.ink2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SplitBar(spent: spentShare),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'terpakai @percent%'.trParams({'percent': '$spentPercent'}),
                style: AppText.mono(
                  size: 10,
                  color: AppColors.mut,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              'tersisa @percent%'.trParams({
                'percent': '${100 - spentPercent}',
              }),
              style: AppText.mono(
                size: 10,
                color: AppColors.mut,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FlowTile(
                label: 'Pemasukan'.tr,
                icon: LucideIcons.arrowDownLeft,
                color: AppColors.earn,
                value: money(income),
                current: income,
                previous: previousIncome,
                previousLabel: previousLabel,
                higherIsBetter: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FlowTile(
                label: 'Pengeluaran'.tr,
                icon: LucideIcons.arrowUpRight,
                color: AppColors.spend,
                value: money(expense),
                current: expense,
                previous: previousExpense,
                previousLabel: previousLabel,
                higherIsBetter: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: AppColors.line2),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Selisih'.tr,
                style: AppText.body(size: 12, weight: FontWeight.w700),
              ),
            ),
            RollingText(
              '${balance >= 0 ? '+' : '\u2212'} ${money(balance.abs())}',
              style: AppText.mono(
                size: 15,
                weight: FontWeight.w600,
                color: balance >= 0 ? AppColors.earn : AppColors.spend,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Satu batang: bagian merah = terpakai, sisanya hijau = tersisa.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.spent});

  final double spent;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Container(
      height: 16,
      color: AppColors.earn,
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: spent),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, factor, _) => FractionallySizedBox(
          widthFactor: factor,
          heightFactor: 1,
          child: const ColoredBox(color: AppColors.spend),
        ),
      ),
    ),
  );
}

/// Kartu kecil pemasukan atau pengeluaran dengan perubahan dari bulan lalu.
/// Panah hijau berarti membaik (pemasukan naik, pengeluaran turun).
class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.current,
    required this.previous,
    required this.previousLabel,
    required this.higherIsBetter,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final int current;
  final int previous;
  final String previousLabel;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final String change;
    final Color changeColor;
    if (previous == 0) {
      change = 'belum ada data @month'.trParams({'month': previousLabel});
      changeColor = AppColors.mut;
    } else if (current == previous) {
      change = 'sama dengan @month'.trParams({'month': previousLabel});
      changeColor = AppColors.mut;
    } else {
      final up = current > previous;
      final percent = ((current - previous).abs() * 100 / previous).round();
      change =
          '${up ? '\u25B2' : '\u25BC'} '
          '${'@percent% dari @month'.trParams({'percent': '$percent', 'month': previousLabel})}';
      changeColor = up == higherIsBetter ? AppColors.earn : AppColors.spend;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 11, color: AppColors.mut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RollingText(
              value,
              style: AppText.mono(
                size: 14,
                weight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            change,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 10.5, color: changeColor),
          ),
        ],
      ),
    );
  }
}
