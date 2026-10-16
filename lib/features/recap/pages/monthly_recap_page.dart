import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/budget_status.dart';
import '../../../core/utils/formatter.dart';
import '../services/recap_calculation_service.dart';
import '../services/recap_data_loader.dart';
import '../widgets/recap_widgets.dart';
import '../widgets/story_frame.dart';
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
            body: Center(child: CircularProgressIndicator(color: AppColors.paper)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: Center(
              child: Text('Gagal memuat recap.', style: AppText.body(color: AppColors.paper)),
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
            appBar: AppBar(backgroundColor: AppColors.ink, foregroundColor: AppColors.paper),
            body: Center(
              child: Text(
                'Belum ada transaksi di bulan ini.',
                style: AppText.body(color: AppColors.paper),
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
        child: _Receipt(recap: recap, data: data, name: name, short: short, nextName: nextName),
      ),
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Merchants(recap: recap),
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
          '1 – ${recap.elapsedDays} $short ${recap.year} · Monthly recap${recap.isSoFar ? ' · so far' : ''}',
          color: fg.withValues(alpha: 0.8),
        ),
        const Spacer(),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Your\n$name,\n'),
              TextSpan(
                text: 'in ink.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: AppText.display(size: 52, color: fg, height: 1.05),
        ),
        const SizedBox(height: 14),
        Text(
          recap.isSoFar
              ? '8 cards · this month is still open.'
              : '8 cards · tap to move on.',
          style: AppText.body(size: 14, color: fg.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 28),
        TallyMarks(count: recap.elapsedDays, color: fg, height: 26),
        const SizedBox(height: 6),
        StoryLabel('One stroke per day', color: fg.withValues(alpha: 0.7)),
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
        StoryLabel('You spent', color: AppColors.mut),
        const SizedBox(height: 8),
        CountUpText(
          value: recap.spent,
          style: AppText.display(size: 44, color: fg),
        ),
        const SizedBox(height: 12),
        if (prev == null)
          Text(
            "That's $perDay a day. Nothing earlier to compare with.",
            style: AppText.body(size: 15, color: fg),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "That's $perDay a day, "),
                TextSpan(
                  text:
                      '${formatIdr(diff.abs())} ${diff >= 0 ? 'more' : 'less'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: diff >= 0 ? AppColors.spend : AppColors.earn,
                  ),
                ),
                TextSpan(text: ' than $prevName.'),
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
              '${diff >= 0 ? '+' : '-'}${pct.toStringAsFixed(1).replaceAll('.', ',')}% vs $prevName',
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
          _Bar(label: prevName, value: prev, max: _max(prev, recap.spent), color: AppColors.mut),
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
  const _Heatmap({required this.recap, required this.name, required this.short});

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
    final headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Every day of $name', color: AppColors.mut),
        const SizedBox(height: 6),
        Text(
          'Some days quiet,\none day loud.',
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
            StoryLabel('Less', color: AppColors.mut),
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
            StoryLabel('More', color: AppColors.mut),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Priciest day',
                value: heaviest == null ? '—' : '$heaviest $short',
                sub: heaviest == null ? '' : formatIdr(recap.dailySpend[heaviest - 1]),
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'No-spend days',
                value: '${recap.noSpendDays}',
                sub: 'dashed squares',
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
        child: Text('$day', style: AppText.mono(size: 11, color: AppColors.line)),
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
        color: value == 0 ? Colors.transparent : AppColors.ink.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(5),
        border: isHeaviest ? Border.all(color: AppColors.spend, width: 2) : null,
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
        child: Text('Tidak ada pengeluaran bulan ini.', style: AppText.body(color: fg)),
      );
    }
    final top = recap.topCategories.first;
    final pct = (top.total * 100 / recap.spent).round();
    final cats = recap.topCategories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Your top category', color: fg.withValues(alpha: 0.8)),
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
          '$pct% of everything you spent.\n${formatIdr(top.total)} across ${top.count} purchases.',
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
        ? 'THANK YOU. TO BE CONTINUED.'
        : 'THANK YOU. SEE YOU IN ${nextName.toUpperCase()}.';

    final mono = AppText.mono(size: 11, color: AppColors.receiptText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('$name, as a receipt', color: AppColors.mut),
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
                'TALLY · MONTHLY',
                style: mono.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.4),
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
              _Row(left: 'ITEMS', right: '$items', style: mono),
              _Row(left: 'PER DAY', right: perDay, style: mono),
              _Row(
                left: 'TOTAL',
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
          Expanded(child: Text(left, style: style, overflow: TextOverflow.ellipsis)),
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
        StoryLabel('You kept coming back to', color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          'Your regular\nspots.',
          style: AppText.display(size: 30, color: fg, height: 1.1),
        ),
        const SizedBox(height: 24),
        if (top.isEmpty)
          Text('Belum ada merchant bulan ini.', style: AppText.body(color: fg))
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
        Text('$rank', style: AppText.mono(size: 13, color: fg.withValues(alpha: 0.6))),
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
                '${spend.visits} visits · ${formatIdr(spend.total)}',
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
        StoryLabel('Budget report card', color: AppColors.mut),
        const SizedBox(height: 6),
        Text('Stamped & filed.', style: AppText.display(size: 30, color: fg)),
        const SizedBox(height: 18),
        if (items.isEmpty)
          Text(
            'Belum ada anggaran aktif di bulan ini.',
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
      BudgetLevel.safe => ('SAFE', AppColors.earn),
      BudgetLevel.warning => ('WATCH', AppColors.warn),
      BudgetLevel.critical => ('CRITICAL', AppColors.crit),
      BudgetLevel.exceeded => ('OVER', AppColors.spend),
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

class _Closing extends StatelessWidget {
  const _Closing({required this.recap, required this.name, required this.year});

  final MonthlyRecap recap;
  final String name;
  final int year;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final income = recap.income;
    final kept = income == 0 ? 0 : (recap.net * 100 / income).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('$name, net${recap.isSoFar ? ' so far' : ''}', color: fg.withValues(alpha: 0.8)),
        const Spacer(),
        Text('You kept', style: AppText.body(size: 16, color: fg)),
        const SizedBox(height: 4),
        CountUpText(
          value: recap.net,
          style: AppText.display(size: 54, color: fg),
        ),
        const SizedBox(height: 12),
        Text(
          income == 0
              ? 'Belum ada pemasukan tercatat bulan ini.'
              : "That's $kept% of the ${formatIdr(income)} that came in.",
          style: AppText.body(size: 15, color: fg),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              side: BorderSide(color: fg),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Get.off(() => YearlyRecapPage(year: year)),
            child: Text('Watch your $year recap'),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
