import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../services/recap_calculation_service.dart';
import '../services/recap_data_loader.dart';
import '../widgets/recap_widgets.dart';
import '../widgets/story_frame.dart';
import '../widgets/story_share.dart';

/// Recap satu tahun dalam bentuk story: 7 kartu, auto-advance 6 detik.
class YearlyRecapPage extends StatelessWidget {
  const YearlyRecapPage({super.key, required this.year});

  final int year;

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
                'Gagal memuat recap.',
                style: AppText.body(color: AppColors.paper),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final recap = Get.find<RecapCalculationService>().yearly(
          data.transactions,
          year: year,
          now: DateTime.now(),
          budgets: data.budgets,
        );
        if (recap.activeMonths == 0) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: SafeArea(
              child: Column(
                children: [
                  const AppTitleBar(title: 'Recap'),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Belum ada transaksi di tahun ini.',
                        style: AppText.body(color: AppColors.paper),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return StoryFrame(footer: 'Tally · $year', cards: _cards(recap, data));
      },
    );
  }

  List<StoryCard> _cards(YearlyRecap recap, RecapData data) {
    final ink = StoryColors.ink;
    final paper = StoryColors.paper;
    final paper2 = StoryColors.paper2;
    final earn = StoryColors.earn;

    return [
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Cover(recap: recap),
      ),
      StoryCard(
        background: paper.bg,
        foreground: paper.fg,
        child: _InOut(recap: recap),
      ),
      StoryCard(
        background: paper2.bg,
        foreground: paper2.fg,
        child: _MonthBars(recap: recap),
      ),
      StoryCard(
        background: ink.bg,
        foreground: ink.fg,
        child: _Categories(recap: recap, data: data),
      ),
      StoryCard(
        background: paper.bg,
        foreground: paper.fg,
        child: _TopMerchant(recap: recap),
      ),
      StoryCard(
        background: paper.bg,
        foreground: paper.fg,
        child: _QuietStreak(recap: recap),
      ),
      StoryCard(
        background: paper2.bg,
        foreground: paper2.fg,
        child: _BudgetMonths(recap: recap),
      ),
      StoryCard(
        background: earn.bg,
        foreground: earn.fg,
        child: _Closing(recap: recap),
      ),
    ];
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(
          '1 Jan – ${_endLabel(recap)} · Yearly recap',
          color: fg.withValues(alpha: 0.8),
        ),
        const Spacer(),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${recap.year},\n'),
              TextSpan(
                text: recap.isSoFar ? 'so far.' : 'in full.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: AppText.display(size: 60, color: fg, height: 1.05),
        ),
        const SizedBox(height: 14),
        Text(
          '${recap.activeMonths} months with notes.',
          style: AppText.body(size: 14, color: fg.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 28),
        TallyMarks(count: recap.activeMonths, color: fg, height: 26),
        const SizedBox(height: 6),
        StoryLabel(
          'One stroke per month with notes',
          color: fg.withValues(alpha: 0.7),
        ),
        const Spacer(),
      ],
    );
  }

  static String _endLabel(YearlyRecap recap) {
    if (!recap.isSoFar) return '31 Dec ${recap.year}';
    final now = DateTime.now();
    return '${now.day} ${recapMonthShort[now.month - 1]} ${recap.year}';
  }
}

class _InOut extends StatelessWidget {
  const _InOut({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final total = recap.totalIncome + recap.totalSpent;
    final keptPct = recap.totalIncome == 0
        ? 0
        : (recap.net * 100 / recap.totalIncome).round();
    final outShare = total == 0 ? 0.0 : recap.totalSpent / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        StoryLabel('In', color: AppColors.mut),
        CountUpText(
          value: recap.totalIncome,
          style: AppText.display(size: 44, color: AppColors.earn),
        ),
        const SizedBox(height: 22),
        StoryLabel('Out', color: AppColors.mut),
        CountUpText(
          value: recap.totalSpent,
          style: AppText.display(size: 44, color: AppColors.spend),
        ),
        const SizedBox(height: 22),
        Container(
          height: 16,
          color: AppColors.spend,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: 1 - outShare,
            child: Container(height: 16, color: fg),
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'You kept '),
              TextSpan(
                text: formatIdr(recap.net),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ', $keptPct% of what came in.'),
            ],
          ),
          style: AppText.body(size: 15, color: fg),
        ),
        const Spacer(),
      ],
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final max = recap.months.fold<int>(0, (a, m) => m.spent > a ? m.spent : a);
    final heavy = recap.heaviestMonth;
    final light = recap.lightestMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Month by month', color: AppColors.mut),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Where the year\n'),
              TextSpan(
                text: 'got heavy.',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: AppText.display(size: 28, color: fg, height: 1.1),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final m in recap.months)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: m.hasData
                        ? FractionallySizedBox(
                            heightFactor: max == 0
                                ? 0.02
                                : (m.spent / max).clamp(0.02, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: m.month == heavy
                                    ? AppColors.spend
                                    : m.month == light
                                    ? AppColors.earn
                                    : AppColors.ink,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                          )
                        : DashedBox(
                            color: AppColors.line,
                            radius: 2,
                            child: const SizedBox(height: 6),
                          ),
                  ),
                ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.line),
        Row(
          children: [
            for (var i = 0; i < 12; i++)
              Expanded(
                child: Text(
                  recapMonthShort[i][0],
                  textAlign: TextAlign.center,
                  style: AppText.label(size: 9.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (heavy != null)
              Expanded(
                child: _Extreme(
                  label: 'Heaviest · ${recapMonthShort[heavy - 1]}',
                  value: formatIdr(recap.months[heavy - 1].spent),
                  color: AppColors.spend,
                ),
              ),
            if (light != null)
              Expanded(
                child: _Extreme(
                  label: 'Lightest · ${recapMonthShort[light - 1]}',
                  value: formatIdr(recap.months[light - 1].spent),
                  color: AppColors.earn,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Dashed boxes are months without transactions.',
          style: AppText.body(size: 11, color: AppColors.mut),
        ),
      ],
    );
  }
}

class _Extreme extends StatelessWidget {
  const _Extreme({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel(label, color: color),
        Text(value, style: AppText.mono(size: 15, weight: FontWeight.w700)),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.recap, required this.data});

  final YearlyRecap recap;
  final RecapData data;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final cats = recap.topCategories;
    final total = recap.totalSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Where it went', color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 6),
        Text(
          'Your year in\nfive categories.',
          style: AppText.display(size: 28, color: fg, height: 1.1),
        ),
        const SizedBox(height: 22),
        if (cats.isEmpty)
          Text('Tidak ada pengeluaran.', style: AppText.body(color: fg))
        else
          for (var i = 0; i < cats.length; i++) ...[
            _CategoryRow(
              rank: i + 1,
              name: data.categoryName(cats[i].categoryId),
              color: _color(cats[i].categoryId),
              share: total == 0 ? 0 : cats[i].total / total,
              amount: cats[i].total,
              big: i == 0,
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Color _color(int categoryId) {
    final stored = data.categories[categoryId]?.colorValue;
    return stored == null ? AppColors.catOther : CategoryStyle.color(stored);
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.rank,
    required this.name,
    required this.color,
    required this.share,
    required this.amount,
    required this.big,
  });

  final int rank;
  final String name;
  final Color color;
  final double share;
  final int amount;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final pct = (share * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                name,
                style: AppText.display(
                  size: big ? 30 : 22,
                  color: fg,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                color: fg.withValues(alpha: 0.18),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: share.clamp(0.0, 1.0),
                  child: Container(height: 4, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$pct%',
              style: AppText.mono(size: 14, color: fg, weight: FontWeight.w700),
            ),
            Text(
              formatIdr(amount),
              style: AppText.mono(size: 11, color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopMerchant extends StatelessWidget {
  const _TopMerchant({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final top = recap.topMerchant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Most visited', color: AppColors.mut),
        const SizedBox(height: 6),
        if (top == null)
          Text(
            'Belum ada merchant tercatat.',
            style: AppText.body(color: AppColors.mut),
          )
        else ...[
          Text(
            top.name,
            style: AppText.display(size: 28, color: fg, height: 1.1),
          ),
          Text(
            '${top.visits} times.',
            style: AppText.display(
              size: 28,
              color: fg,
              height: 1.1,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < top.visits.clamp(0, 60); i++)
                TallyMarks(count: 1, color: fg, height: 18),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatIdr(top.total),
            style: AppText.display(size: 24, color: fg),
          ),
          Text(
            'spent there this year',
            style: AppText.body(size: 12, color: AppColors.mut),
          ),
          if (recap.biggestExpense != null) ...[
            const SizedBox(height: 18),
            StoryLabel('Biggest single expense', color: AppColors.mut),
            const SizedBox(height: 4),
            Text(
              formatIdr(recap.biggestExpense!.amount),
              style: AppText.display(size: 24, color: fg),
            ),
            Text(
              recap.biggestExpense!.name,
              style: AppText.body(size: 12, color: AppColors.mut),
            ),
          ],
        ],
      ],
    );
  }
}

class _BudgetMonths extends StatelessWidget {
  const _BudgetMonths({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    final withData = recap.budgetMonthsWithData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Budget months', color: AppColors.mut),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${recap.budgetMonthsInside} of $withData',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
              const TextSpan(text: ' months\ninside your limit.'),
            ],
          ),
          style: AppText.display(size: 28, color: fg, height: 1.1),
        ),
        const SizedBox(height: 20),
        _BudgetGrid(recap: recap),
      ],
    );
  }
}

class _BudgetGrid extends StatelessWidget {
  const _BudgetGrid({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var r = 0; r < 4; r++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (var c = 0; c < 3; c++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: c == 0 ? 0 : 8),
                    child: _tile(r * 3 + c),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _tile(int index) {
    final m = recap.months[index];
    final status = m.budgetStatus;
    final label = recapMonthShort[index];
    final box = AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: status == BudgetMonthStatus.inside
              ? AppColors.ink
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.label(
                size: 10,
                color: status == BudgetMonthStatus.inside
                    ? AppColors.paper.withValues(alpha: 0.8)
                    : AppColors.mut,
              ),
            ),
            Text(
              switch (status) {
                BudgetMonthStatus.noData => 'no data',
                BudgetMonthStatus.inside => 'inside',
                BudgetMonthStatus.over => 'over',
              },
              style: AppText.mono(
                size: 10,
                color: switch (status) {
                  BudgetMonthStatus.inside => AppColors.paper,
                  BudgetMonthStatus.over => AppColors.spend,
                  BudgetMonthStatus.noData => AppColors.mut,
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (status == BudgetMonthStatus.noData) {
      return DashedBox(color: AppColors.line, radius: 8, child: box);
    }
    if (status == BudgetMonthStatus.over) {
      return DashedBox(color: AppColors.spend, radius: 8, child: box);
    }
    return box;
  }
}

class _Closing extends StatefulWidget {
  const _Closing({required this.recap});

  final YearlyRecap recap;

  @override
  State<_Closing> createState() => _ClosingState();
}

class _ClosingState extends State<_Closing> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.paper;
    final recap = widget.recap;
    final monthsToGo = 12 - recap.monthsSoFar;
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
                    '${recap.year}, net${recap.isSoFar ? ' so far' : ''}',
                    color: fg.withValues(alpha: 0.8),
                  ),
                  const Spacer(),
                  Text('You kept', style: AppText.body(size: 16, color: fg)),
                  const SizedBox(height: 4),
                  CountUpText(
                    value: recap.net,
                    style: AppText.display(size: 48, color: fg),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recap.isSoFar
                        ? '$monthsToGo months to go. Your yearly recap refreshes on 31 Dec.'
                        : 'That is the whole year.',
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
                  fileName: 'tally-recap-${recap.year}',
                  text: 'Tally · ${recap.year}',
                ),
                child: const Text('Save as image'),
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
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to Tally'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuietStreak extends StatelessWidget {
  const _QuietStreak({required this.recap});

  final YearlyRecap recap;

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryLabel('Quiet streak', color: AppColors.mut),
        const SizedBox(height: 6),
        Text(
          '${recap.quietStreak}',
          style: AppText.display(size: 72, color: fg, height: 1),
        ),
        Text(
          'days in a row without spending.',
          style: AppText.body(size: 13, color: AppColors.ink2),
        ),
        const SizedBox(height: 18),
        Text(
          '${recap.quietDays} no-spend days since your first entry.',
          style: AppText.body(size: 12, color: AppColors.mut),
        ),
      ],
    );
  }
}
