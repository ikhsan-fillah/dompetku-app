import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/budget_status.dart';
import '../../../core/utils/formatter.dart';
import '../services/recap_calculation_service.dart';
import '../services/recap_data_loader.dart';
import '../../../core/i18n/app_language.dart';
import '../widgets/recap_widgets.dart';
import '../widgets/story_frame.dart';
import '../widgets/story_share.dart';
import 'yearly_recap_page.dart';

/// Recap satu bulan dalam bentuk story: 8 kartu, auto-advance 6 detik.
class MonthlyRecapPage extends StatelessWidget {
  const MonthlyRecapPage({super.key, required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecapData>(
      future: loadRecapData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.ink,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.paper),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: Center(
              child: Text(
                'Gagal memuat rekap.'.tr,
                style: AppText.body(color: AppColors.paper),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final recap = Get.find<RecapCalculationService>().monthly(
          data.transactions,
          year: year,
          month: month,
          now: DateTime.now(),
          budgets: data.budgets,
        );
        if (!recap.hasData) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: SafeArea(
              child: Column(
                children: [
                  AppTitleBar(title: 'Rekap'.tr),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Belum ada transaksi di bulan ini.'.tr,
                        style: AppText.body(color: AppColors.paper),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return StoryFrame(
          footer: 'Tally · ${recapMonthNames[month - 1]} $year',
          cards: _cards(recap, data),
        );
      },
    );
  }

  List<StoryCard> _cards(MonthlyRecap recap, RecapData data) {
    final name = recapMonthNames[month - 1];
    final short = recapMonthShort[month - 1];
    final nextName = recapMonthNames[month % 12];
    final ink = StoryColors.ink;
    final paper = StoryColors.paper;
    final paper2 = StoryColors.paper2;
    final spend = StoryColors.spend;
    final earn = StoryColors.earn;

    return [
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Cover(recap: recap, name: name, short: short),
      ),
      StoryCard(
        background: paper.bg,
        foreground: paper.fg,
        child: _Total(recap: recap, month: month),
      ),
      StoryCard(
        background: paper2.bg,
        foreground: paper2.fg,
        child: _Heatmap(recap: recap, name: name, short: short),
      ),
      StoryCard(
        background: spend.bg,
        foreground: spend.fg,
        child: _TopCategory(recap: recap, data: data),
      ),
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Receipt(
          recap: recap,
          data: data,
          name: name,
          short: short,
          nextName: nextName,
        ),
      ),
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Merchants(recap: recap),
      ),
      if (recap.dailyLimit != null)
        StoryCard(
          background: paper.bg,
          foreground: paper.fg,
          child: _DailyLimit(recap: recap),
        ),
      StoryCard(
        background: paper2.bg,
        foreground: paper2.fg,
        child: _BudgetCard(recap: recap, data: data),
      ),
      StoryCard(
        background: earn.bg,
        foreground: earn.fg,
        child: _Closing(recap: recap, name: name, year: year),
      ),
    ];
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.recap, required this.name, required this.short});

  final MonthlyRecap recap;
  final String name;
  final String short;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(
          '${'1 – @days @short @year · Rekap bulanan'.trParams({'days': '${recap.elapsedDays}', 'short': short, 'year': '${recap.year}'})}${recap.isSoFar ? ' · ${'sejauh ini'.tr}' : ''}',
          color: fg.withValues(alpha: 0.8),
        ),
        const Spacer(),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Ceritamu\ndi bulan @name,\n'.trParams({'name': name}),
              ),
              TextSpan(
                text: 'dalam tinta.'.tr,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: AppText.display(size: 52, color: fg, height: 1.05),
        ),
        const SizedBox(height: 14),
        Text(
          recap.isSoFar
              ? '8 kartu · bulan ini masih berjalan.'.tr
              : '8 kartu · ketuk untuk lanjut.'.tr,
          style: AppText.body(size: 14, color: fg.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 28),
        TallyMarks(count: recap.elapsedDays, color: fg, height: 26),
        const SizedBox(height: 6),
        StoryLabel(
          'Satu goresan per hari'.tr,
          color: fg.withValues(alpha: 0.7),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.recap, required this.month});

  final MonthlyRecap recap;
  final int month;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final prev = recap.previousSpent;
    final prevName = recapMonthNames[(month + 10) % 12];
    final perDay = formatIdr(recap.dailyAverage);
    final diff = prev == null ? 0 : recap.spent - prev;
    final pct = (prev == null || prev == 0) ? null : (diff.abs() * 100 / prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Kamu mengeluarkan'.tr, color: AppColors.mut),
        const SizedBox(height: 8),
        CountUpText(
          value: recap.spent,
          style: AppText.display(size: 44, color: fg),
        ),
        const SizedBox(height: 12),
        if (prev == null)
          Text(
            'Rata-rata @perDay per hari. Belum ada bulan sebelumnya untuk dibandingkan.'
                .trParams({'perDay': perDay}),
            style: AppText.body(size: 15, color: fg),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Rata-rata @perDay per hari, '.trParams({
                    'perDay': perDay,
                  }),
                ),
                TextSpan(
                  text: diff >= 0
                      ? '@amount lebih banyak'.trParams({
                          'amount': formatIdr(diff.abs()),
                        })
                      : '@amount lebih sedikit'.trParams({
                          'amount': formatIdr(diff.abs()),
                        }),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: diff >= 0 ? AppColors.spend : AppColors.earn,
                  ),
                ),
                TextSpan(text: ' dari @prev.'.trParams({'prev': prevName})),
              ],
            ),
            style: AppText.body(size: 15, color: fg),
          ),
        if (pct != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: diff >= 0 ? AppColors.spendSoft : AppColors.earnSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@pct% vs @prev'.trParams({
                'pct':
                    '${diff >= 0 ? '+' : '-'}${pct.toStringAsFixed(1).replaceAll('.', ',')}',
                'prev': prevName,
              }),
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: diff >= 0 ? AppColors.spend : AppColors.earn,
              ),
            ),
          ),
        ],
        const SizedBox(height: 34),
        if (prev != null) ...[
          _Bar(
            label: prevName,
            value: prev,
            max: _max(prev, recap.spent),
            color: AppColors.mut,
          ),
          const SizedBox(height: 14),
        ],
        _Bar(
          label: recapMonthNames[month - 1],
          value: recap.spent,
          max: _max(prev ?? 0, recap.spent),
          color: AppColors.ink,
        ),
      ],
    );
  }

  static int _max(int a, int b) => a > b ? a : (b == 0 ? 1 : b);
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StoryLabel(label, color: AppColors.mut),
            Text(formatIdr(value), style: AppText.mono(size: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 14,
          color: AppColors.paper2,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: ratio,
            child: Container(height: 14, color: color),
          ),
        ),
      ],
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.recap,
    required this.name,
    required this.short,
  });

  final MonthlyRecap recap;
  final String name;
  final String short;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final days = recap.daysInMonth;
    final maxDay = recap.dailySpend.fold<int>(0, (a, b) => b > a ? b : a);
    final heaviest = recap.heaviestDay;
    final offset = DateTime(recap.year, recap.month, 1).weekday - 1;
    final headers = AppLanguage.isEnglish
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(
          'Setiap hari di @name'.trParams({'name': name}),
          color: AppColors.mut,
        ),
        const SizedBox(height: 6),
        Text(
          'Ada hari yang tenang,\nada hari yang ramai.'.tr,
          style: AppText.display(size: 28, color: fg, height: 1.1),
        ),
        const SizedBox(height: 16),
        _HeatGrid(
          headers: headers,
          cells: [
            for (var i = 0; i < offset; i++) null,
            for (var d = 0; d < days; d++)
              _cell(
                day: d + 1,
                value: recap.dailySpend[d],
                maxDay: maxDay,
                future: d >= recap.elapsedDays,
                isHeaviest: heaviest == d + 1,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StoryLabel('Sedikit'.tr, color: AppColors.mut),
            const SizedBox(width: 6),
            for (final a in [0.14, 0.34, 0.6, 0.92]) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: a),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
            ],
            StoryLabel('Banyak'.tr, color: AppColors.mut),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Hari termahal'.tr,
                value: heaviest == null ? '—' : '$heaviest $short',
                sub: heaviest == null
                    ? ''
                    : formatIdr(recap.dailySpend[heaviest - 1]),
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Hari tanpa belanja'.tr,
                value: '${recap.noSpendDays}',
                sub: 'kotak putus-putus'.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell({
    required int day,
    required int value,
    required int maxDay,
    required bool future,
    required bool isHeaviest,
  }) {
    if (future) {
      return Center(
        child: Text(
          '$day',
          style: AppText.mono(size: 11, color: AppColors.line),
        ),
      );
    }
    final ratio = maxDay == 0 ? 0.0 : value / maxDay;
    final alpha = ratio < 0.33
        ? 0.14
        : ratio < 0.66
        ? 0.34
        : ratio < 0.9
        ? 0.6
        : 0.92;
    final cell = Container(
      decoration: BoxDecoration(
        color: value == 0
            ? Colors.transparent
            : AppColors.ink.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(5),
        border: isHeaviest
            ? Border.all(color: AppColors.spend, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: AppText.mono(
          size: 11,
          color: alpha >= 0.6 ? AppColors.paper : AppColors.ink,
        ),
      ),
    );
    if (value == 0) {
      return DashedBox(color: AppColors.line, radius: 5, child: cell);
    }
    return cell;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(label, color: AppColors.mut),
        Text(value, style: AppText.mono(size: 15, weight: FontWeight.w700)),
        if (sub.isNotEmpty)
          Text(sub, style: AppText.body(size: 11, color: AppColors.mut)),
      ],
    );
  }
}

class _TopCategory extends StatelessWidget {
  const _TopCategory({required this.recap, required this.data});

  final MonthlyRecap recap;
  final RecapData data;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    if (recap.topCategories.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada pengeluaran bulan ini.'.tr,
          style: AppText.body(color: fg),
        ),
      );
    }
    final top = recap.topCategories.first;
    final pct = (top.total * 100 / recap.spent).round();
    final cats = recap.topCategories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Kategori teratasmu'.tr, color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 14),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            CategoryStyle.icon(data.categories[top.categoryId]?.iconKey ?? ''),
            color: AppColors.ink,
            size: 28,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.categoryName(top.categoryId),
          style: AppText.display(size: 64, color: fg, height: 1),
        ),
        const SizedBox(height: 12),
        Text(
          '@pct% dari semua pengeluaranmu.\n@total dari @count pembelian.'
              .trParams({
                'pct': '$pct',
                'total': formatIdr(top.total),
                'count': '${top.count}',
              }),
          style: AppText.body(size: 15, color: fg),
        ),
        const Spacer(),
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              for (final c in cats)
                Expanded(
                  flex: c.total,
                  child: Container(color: _color(c.categoryId)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final c in cats)
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _color(c.categoryId),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${data.categoryName(c.categoryId)} · ${(c.total * 100 / recap.spent).round()}%',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(size: 11, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _color(int categoryId) {
    final stored = data.categories[categoryId]?.colorValue;
    return stored == null ? AppColors.catOther : CategoryStyle.color(stored);
  }
}

class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.recap,
    required this.data,
    required this.name,
    required this.short,
    required this.nextName,
  });

  final MonthlyRecap recap;
  final RecapData data;
  final String name;
  final String short;
  final String nextName;

  @override
  Widget build(BuildContext context) {
    final mm = recap.month.toString().padLeft(2, '0');
    final lastDay = recap.elapsedDays.toString().padLeft(2, '0');
    final perDay = formatIdr(recap.dailyAverage);
    final items = recap.topCategories.fold<int>(0, (a, c) => a + c.count);
    final footer = recap.isSoFar
        ? 'TERIMA KASIH. BERSAMBUNG.'.tr
        : 'TERIMA KASIH. SAMPAI JUMPA DI @month.'.trParams({
            'month': nextName.toUpperCase(),
          });

    final mono = AppText.mono(size: 11, color: AppColors.receiptText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(
          '@name, sebagai struk'.trParams({'name': name}),
          color: AppColors.mut,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.receiptPaper,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Text(
                'TALLY · BULANAN'.tr,
                style: mono.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Text('01/$mm – $lastDay/$mm/${recap.year}', style: mono),
              _Dashes(),
              for (final c in recap.topCategories.take(5))
                _Row(
                  left: '${data.categoryName(c.categoryId)} x${c.count}',
                  right: formatIdr(c.total),
                  style: mono,
                ),
              _Dashes(),
              _Row(left: 'ITEM'.tr, right: '$items', style: mono),
              _Row(left: 'PER HARI'.tr, right: perDay, style: mono),
              _Row(
                left: 'TOTAL'.tr,
                right: formatIdr(recap.spent),
                style: mono.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              _Dashes(),
              Text(footer, style: mono.copyWith(fontSize: 10)),
              const SizedBox(height: 10),
              _Barcode(seed: recap.year * 12 + recap.month),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.left, required this.right, required this.style});

  final String left;
  final String right;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(left, style: style, overflow: TextOverflow.ellipsis),
          ),
          Text(right, style: style),
        ],
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        List.filled(40, '-').join(),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppText.mono(size: 10, color: AppColors.receiptDash),
      ),
    );
  }
}

class _HeatGrid extends StatelessWidget {
  const _HeatGrid({required this.headers, required this.cells});

  final List<String> headers;
  final List<Widget?> cells;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      Row(
        children: [
          for (final h in headers)
            Expanded(
              child: Center(child: Text(h, style: AppText.label(size: 10))),
            ),
        ],
      ),
      const SizedBox(height: 5),
    ];
    for (var start = 0; start < cells.length; start += 7) {
      final end = start + 7 > cells.length ? cells.length : start + 7;
      final slice = cells.sublist(start, end);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: i < slice.length && slice[i] != null
                        ? AspectRatio(aspectRatio: 1, child: slice[i]!)
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          for (var i = 0; i < 36; i++)
            Container(
              width: (1 + ((i * 7 + seed) % 4)).toDouble(),
              margin: const EdgeInsets.only(right: 1),
              color: AppColors.receiptText,
            ),
        ],
      ),
    );
  }
}

class _Merchants extends StatelessWidget {
  const _Merchants({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final top = recap.merchants.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(
          'Kamu sering kembali ke'.tr,
          color: fg.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 6),
        Text(
          'Tempat\nlangananmu.'.tr,
          style: AppText.display(size: 30, color: fg, height: 1.1),
        ),
        const SizedBox(height: 24),
        if (top.isEmpty)
          Text(
            'Belum ada merchant bulan ini.'.tr,
            style: AppText.body(color: fg),
          )
        else
          for (var i = 0; i < top.length; i++) ...[
            _MerchantRow(rank: i + 1, spend: top[i]),
            const SizedBox(height: 18),
          ],
      ],
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.rank, required this.spend});

  final int rank;
  final MerchantSpend spend;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    return Row(
      children: [
        Text(
          '$rank',
          style: AppText.mono(size: 13, color: fg.withValues(alpha: 0.6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spend.name,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(size: 20, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                '@count kunjungan · @total'.trParams({
                  'count': '${spend.visits}',
                  'total': formatIdr(spend.total),
                }),
                style: AppText.mono(size: 11, color: fg.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        TallyMarks(count: spend.visits, color: fg, height: 16),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.recap, required this.data});

  final MonthlyRecap recap;
  final RecapData data;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final items = recap.budgets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Rapor anggaran'.tr, color: AppColors.mut),
        const SizedBox(height: 6),
        Text(
          'Dicap & diarsipkan.'.tr,
          style: AppText.display(size: 30, color: fg),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          Text(
            'Belum ada anggaran aktif di bulan ini.'.tr,
            style: AppText.body(size: 14, color: AppColors.mut),
          )
        else
          for (final item in items) ...[
            _BudgetRow(item: item),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.item});

  final BudgetSpend item;

  @override
  Widget build(BuildContext context) {
    final level = BudgetStatus.levelFor(item.percent);
    final (label, color) = switch (level) {
      BudgetLevel.safe => ('AMAN'.tr, AppColors.earn),
      BudgetLevel.warning => ('WASPADA'.tr, AppColors.warn),
      BudgetLevel.critical => ('KRITIS'.tr, AppColors.crit),
      BudgetLevel.exceeded => ('LEWAT'.tr, AppColors.spend),
    };
    final budget = item.budget;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.name,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(size: 14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatIdr(item.used)} / ${formatIdr(budget.amountLimit)} · ${item.percent.round()}%',
                style: AppText.mono(size: 11, color: AppColors.mut),
              ),
            ],
          ),
        ),
        BudgetStamp(label: label, color: color),
      ],
    );
  }
}

class _Closing extends StatefulWidget {
  const _Closing({required this.recap, required this.name, required this.year});

  final MonthlyRecap recap;
  final String name;
  final int year;

  @override
  State<_Closing> createState() => _ClosingState();
}

class _ClosingState extends State<_Closing> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final recap = widget.recap;
    final income = recap.income;
    final kept = income == 0 ? 0 : (recap.net * 100 / income).round();
    final month = recap.month.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RepaintBoundary(
            key: _shareKey,
            child: Container(
              color: AppColors.earn,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoryLabel(
                    recap.isSoFar
                        ? '@name, bersih sejauh ini'.trParams({
                            'name': widget.name,
                          })
                        : '@name, bersih'.trParams({'name': widget.name}),
                    color: fg.withValues(alpha: 0.8),
                  ),
                  const Spacer(),
                  Text(
                    'Kamu menyimpan'.tr,
                    style: AppText.body(size: 16, color: fg),
                  ),
                  const SizedBox(height: 4),
                  CountUpText(
                    value: recap.net,
                    style: AppText.display(size: 54, color: fg),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    income == 0
                        ? 'Belum ada pemasukan tercatat bulan ini.'.tr
                        : 'Itu @kept% dari @income pemasukanmu.'.trParams({
                            'kept': '$kept',
                            'income': formatIdr(income),
                          }),
                    style: AppText.body(size: 15, color: fg),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(color: fg),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => StoryShare.shareImage(
                  key: _shareKey,
                  fileName: 'tally-recap-${widget.year}-$month',
                  text: 'Tally · ${widget.name} ${widget.year}',
                ),
                child: Text('Simpan sebagai gambar'.tr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(color: fg),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () =>
                    Get.off(() => YearlyRecapPage(year: widget.year)),
                child: Text(
                  'Lihat rekap @year'.trParams({'year': '${widget.year}'}),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyLimit extends StatelessWidget {
  const _DailyLimit({required this.recap});

  final MonthlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final limit = recap.dailyLimit ?? 0;
    final values = recap.dailySpend.take(recap.elapsedDays).toList();
    final peak = values.fold<int>(limit, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Batas harian'.tr, color: AppColors.mut),
        const SizedBox(height: 6),
        Text(
          '@under dari @days hari\ndi bawah garis.'.trParams({
            'under': '${recap.daysUnderLimit}',
            'days': '${recap.elapsedDays}',
          }),
          style: AppText.display(size: 28, color: AppColors.ink, height: 1.1),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, box) {
              final lineY = peak == 0
                  ? 0.0
                  : box.maxHeight * (1 - limit / peak);
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final v in values)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: peak == 0
                                ? 2
                                : (v / peak * box.maxHeight).clamp(
                                    2,
                                    box.maxHeight,
                                  ),
                            color: v > limit ? AppColors.spend : AppColors.ink,
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: lineY,
                    child: DashedBox(
                      color: AppColors.mut,
                      radius: 0,
                      child: const SizedBox(height: 1),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Batas @limit per hari (anggaran ÷ hari).'.trParams({
            'limit': formatIdr(limit),
          }),
          style: AppText.body(size: 12, color: AppColors.mut),
        ),
      ],
    );
  }
}
