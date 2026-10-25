import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../category/repositories/category_repository.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../services/month_palette.dart';
import '../services/recap_calculation_service.dart';
import 'monthly_recap_page.dart';
import 'yearly_recap_page.dart';

/// Halaman Rekap: kartu cerita per bulan yang digeser (bulan terbaru paling
/// besar, terakhir rekap tahunan), ringkasan tahun (total, rata-rata,
/// terbesar), lalu kartu tiap bulan dengan perubahan dari bulan sebelumnya.
/// Warna bulan dari [MonthPalette].
class RecapsPage extends StatefulWidget {
  const RecapsPage({super.key});

  @override
  State<RecapsPage> createState() => _RecapsPageState();
}

class _RecapsPageState extends State<RecapsPage> {
  late final RecapCalculationService _recaps =
      Get.find<RecapCalculationService>();
  late final TransactionRepository _transactions =
      Get.find<TransactionRepository>();
  late final CategoryRepository? _categories =
      Get.isRegistered<CategoryRepository>()
      ? Get.find<CategoryRepository>()
      : null;

  bool _loading = true;
  String? _error;
  List<TransactionModel> _data = const [];
  Map<int, String> _categoryNames = const {};
  late int _year;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _year = _now.year;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _transactions.getAll();
      final categories = await _categories?.getAll(includeArchived: true);
      if (!mounted) return;
      setState(() {
        _data = all;
        _categoryNames = {
          for (final category in categories ?? const [])
            if (category.id != null) category.id!: category.displayName,
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat rekap.'.tr;
        _loading = false;
      });
    }
  }

  int? get _firstYear {
    if (_data.isEmpty) return null;
    return _data
        .map((e) => e.transactionDate.toLocal().year)
        .reduce((a, b) => a < b ? a : b);
  }

  bool _hasData(int year) =>
      _data.any((e) => e.transactionDate.toLocal().year == year);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(title: 'Rekap'.tr),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(_error!, style: AppText.body(color: AppColors.spend)),
      );
    }
    final first = _firstYear;
    if (first == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Belum ada rekap. Tambahkan transaksi untuk melihat bulan pertamamu.'
                .tr,
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.mut),
          ),
        ),
      );
    }

    final years = [for (var y = first; y <= _now.year; y++) y];
    final isCurrentYear = _year == _now.year;
    final lastMonth = isCurrentYear ? _now.month : 12;
    final months = [
      for (var m = 1; m <= 12; m++)
        _recaps.monthly(_data, year: _year, month: m, now: _now),
    ];
    final previousDecember = _recaps.monthly(
      _data,
      year: _year - 1,
      month: 12,
      now: _now,
    );
    final active = [
      for (var m = 1; m <= lastMonth; m++)
        if (months[m - 1].hasData) months[m - 1],
    ];
    final total = active.fold<int>(0, (sum, r) => sum + r.spent);
    final heaviest = active.isEmpty
        ? null
        : active.reduce((a, b) => b.spent > a.spent ? b : a);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, 0, 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.page),
          child: _YearPills(
            years: years,
            selected: _year,
            currentYear: _now.year,
            enabled: _hasData,
            onSelect: (y) => setState(() => _year = y),
          ),
        ),
        const SizedBox(height: 14),
        _StoryCarousel(
          year: _year,
          isCurrentYear: isCurrentYear,
          currentMonth: _now.month,
          months: active.reversed.toList(),
          topName: _topName,
          activeMonths: active.length,
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.page),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total'.tr,
                  value: formatCompactIdr(total),
                  caption: '@count bulan'.trParams({
                    'count': '${active.length}',
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Rata-rata'.tr,
                  value: formatCompactIdr(
                    active.isEmpty ? 0 : (total / active.length).round(),
                  ),
                  caption: 'per bulan'.tr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Terbesar'.tr,
                  value: heaviest == null
                      ? '–'
                      : AppLanguage.monthShort(heaviest.month),
                  caption: heaviest == null
                      ? ''
                      : formatCompactIdr(heaviest.spent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.page),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'BULAN · @year'.trParams({'year': '$_year'}),
                  style: AppText.monoLabel(color: AppColors.mut),
                ),
              ),
              Flexible(
                child: Text(
                  'persen = dibanding bulan sebelumnya'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(size: 10.5, color: AppColors.mut),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.page),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            // Sedikit lebih tinggi supaya aman saat ukuran teks HP diperbesar.
            childAspectRatio: 1.15,
            children: [
              for (var m = 1; m <= 12; m++)
                _MonthTile(
                  recap: months[m - 1],
                  previous: m == 1 ? previousDecember : months[m - 2],
                  isFuture: isCurrentYear && m > _now.month,
                  isCurrent: isCurrentYear && m == _now.month,
                  isHeaviest:
                      heaviest != null &&
                      active.length > 1 &&
                      heaviest.month == m,
                  peak: heaviest?.spent ?? 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _topName(MonthlyRecap recap) {
    if (recap.topCategories.isEmpty) return null;
    return _categoryNames[recap.topCategories.first.categoryId];
  }
}

class _YearPills extends StatelessWidget {
  const _YearPills({
    required this.years,
    required this.selected,
    required this.currentYear,
    required this.enabled,
    required this.onSelect,
  });

  final List<int> years;
  final int selected;
  final int currentYear;
  final bool Function(int year) enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final y in years.reversed) ...[
          _Pill(
            label: y == currentYear
                ? '@year · sejauh ini'.trParams({'year': '$y'})
                : '$y',
            selected: y == selected,
            onTap: enabled(y) ? () => onSelect(y) : null,
          ),
          const SizedBox(width: 6),
        ],
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paper2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 12,
            weight: FontWeight.w700,
            color: selected
                ? AppColors.paper
                : (onTap == null ? AppColors.mut : AppColors.ink2),
          ),
        ),
      ),
    ),
  );
}

/// Kartu cerita yang digeser: bulan terbaru paling besar dengan tombol
/// Putar, lalu bulan sebelumnya, terakhir kartu rekap tahunan.
class _StoryCarousel extends StatefulWidget {
  const _StoryCarousel({
    required this.year,
    required this.isCurrentYear,
    required this.currentMonth,
    required this.months,
    required this.topName,
    required this.activeMonths,
  });

  final int year;
  final bool isCurrentYear;
  final int currentMonth;

  /// Bulan yang ada transaksinya, terbaru dulu.
  final List<MonthlyRecap> months;
  final String? Function(MonthlyRecap recap) topName;
  final int activeMonths;

  @override
  State<_StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<_StoryCarousel> {
  static const _bigWidth = 226.0;
  static const _smallWidth = 150.0;
  static const _gap = 10.0;

  final _scroll = ScrollController();
  int _index = 0;

  int get _count => widget.months.length + 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final offset = _scroll.offset;
      final index = offset < _bigWidth / 2
          ? 0
          : 1 + ((offset - _bigWidth - _gap) / (_smallWidth + _gap)).round();
      final clamped = index.clamp(0, _count - 1);
      if (clamped != _index) setState(() => _index = clamped);
    });
  }

  @override
  void didUpdateWidget(covariant _StoryCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = widget.months;
    return Column(
      children: [
        SizedBox(
          height: 290,
          child: ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppSpacing.page),
            itemCount: _count,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              if (i == months.length) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: _YearStory(
                    year: widget.year,
                    isSoFar: widget.isCurrentYear,
                    activeMonths: widget.activeMonths,
                  ),
                );
              }
              final recap = months[i];
              return Align(
                alignment: Alignment.bottomCenter,
                child: _MonthStory(
                  recap: recap,
                  big: i == 0,
                  isSoFar:
                      widget.isCurrentYear &&
                      recap.month == widget.currentMonth,
                  topName: widget.topName(recap),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.page),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _index ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.ink : AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthStory extends StatelessWidget {
  const _MonthStory({
    required this.recap,
    required this.big,
    required this.isSoFar,
    required this.topName,
  });

  final MonthlyRecap recap;
  final bool big;
  final bool isSoFar;
  final String? topName;

  @override
  Widget build(BuildContext context) {
    final color = MonthPalette.of(recap.year, recap.month);
    final white = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.85);
    return _StoryShell(
      width: big ? 226 : 150,
      height: big ? 290 : 240,
      color: color,
      semantics: AppLanguage.monthLong(recap.month),
      onTap: () =>
          Get.to(() => MonthlyRecapPage(year: recap.year, month: recap.month)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSoFar ? 'SEJAUH INI'.tr : '${recap.year}',
            style: AppText.mono(size: 10, color: soft, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            big
                ? AppLanguage.monthLong(recap.month)
                : AppLanguage.monthShort(recap.month),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.display(size: big ? 30 : 22, color: white),
          ),
          const Spacer(),
          Text('dibelanjakan'.tr, style: AppText.body(size: 11, color: soft)),
          Text(
            formatCompactIdr(recap.spent),
            style: AppText.display(size: big ? 26 : 18, color: white),
          ),
          if (topName != null) ...[
            const SizedBox(height: 4),
            Text(
              'terbanyak: @name'.trParams({'name': topName!}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 11, color: soft),
            ),
          ],
          if (big) ...[
            const SizedBox(height: 12),
            const _PlayPill(dark: false),
          ],
        ],
      ),
    );
  }
}

class _YearStory extends StatelessWidget {
  const _YearStory({
    required this.year,
    required this.isSoFar,
    required this.activeMonths,
  });

  final int year;
  final bool isSoFar;
  final int activeMonths;

  @override
  Widget build(BuildContext context) {
    final soft = AppColors.paper.withValues(alpha: 0.75);
    return _StoryShell(
      width: 150,
      height: 240,
      color: AppColors.ink,
      decorated: false,
      semantics: 'Rekap @year'.trParams({'year': '$year'}),
      onTap: () => Get.to(() => YearlyRecapPage(year: year)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAHUNAN'.tr,
            style: AppText.mono(size: 10, color: soft, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekap @year'.trParams({'year': '$year'}),
            style: AppText.display(size: 22, color: AppColors.paper),
          ),
          const Spacer(),
          Text(
            isSoFar
                ? '@count bulan sejauh ini'.trParams({'count': '$activeMonths'})
                : '@count bulan'.trParams({'count': '$activeMonths'}),
            style: AppText.body(size: 11, color: soft),
          ),
          const SizedBox(height: 10),
          const _PlayPill(dark: true),
        ],
      ),
    );
  }
}

class _StoryShell extends StatelessWidget {
  const _StoryShell({
    required this.width,
    required this.height,
    required this.color,
    required this.semantics,
    required this.onTap,
    required this.child,
    this.decorated = true,
  });

  final double width;
  final double height;
  final Color color;
  final String semantics;
  final VoidCallback onTap;
  final Widget child;

  /// Lingkaran hiasan di sudut, seperti kartu cerita di mockup.
  final bool decorated;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              if (decorated) ...[
                Positioned(
                  right: -34,
                  top: -34,
                  child: _Circle(
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: _Circle(
                    size: 110,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ],
              Padding(padding: const EdgeInsets.all(16), child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.dark});

  /// Kartu tahunan (latar tinta) memakai pil kertas.
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: dark ? AppColors.paper : Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.play, size: 12, color: AppColors.ink),
        const SizedBox(width: 6),
        Text(
          'Putar'.tr,
          style: AppText.body(
            size: 12,
            weight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(size: 10, color: AppColors.mut)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.display(size: 18)),
        ),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(size: 9.5, color: AppColors.mut),
        ),
      ],
    ),
  );
}

/// Kartu satu bulan: titik dan garis berwarna bulan itu, garis tidak penuh,
/// dan di kanannya perubahan dari bulan sebelumnya (merah naik, hijau turun).
class _MonthTile extends StatelessWidget {
  const _MonthTile({
    required this.recap,
    required this.previous,
    required this.isFuture,
    required this.isCurrent,
    required this.isHeaviest,
    required this.peak,
  });

  final MonthlyRecap recap;
  final MonthlyRecap previous;
  final bool isFuture;
  final bool isCurrent;
  final bool isHeaviest;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final label = AppLanguage.monthShort(recap.month);
    if (isFuture || !recap.hasData) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w800,
                color: AppColors.mut,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFuture ? 'belum tiba'.tr : 'tidak ada transaksi'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 10, color: AppColors.mut),
            ),
          ],
        ),
      );
    }
    final color = MonthPalette.of(recap.year, recap.month);
    final String change;
    final Color changeColor;
    if (previous.spent <= 0) {
      change = '–';
      changeColor = AppColors.mut;
    } else {
      final diff = recap.spent - previous.spent;
      final percent = (diff.abs() * 100 / previous.spent).round();
      change = diff == 0 ? '0%' : '${diff > 0 ? '▲' : '▼'} $percent%';
      changeColor = diff == 0
          ? AppColors.mut
          : (diff > 0 ? AppColors.spend : AppColors.earn);
    }
    final fraction = peak <= 0 ? 0.0 : (recap.spent / peak).clamp(0.0, 1.0);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.to(
          () => MonthlyRecapPage(year: recap.year, month: recap.month),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(size: 12, weight: FontWeight.w800),
                    ),
                  ),
                  if (isCurrent)
                    _Tag(
                      label: 'berjalan'.tr,
                      background: AppColors.ink,
                      foreground: AppColors.paper,
                    )
                  else if (isHeaviest)
                    _Tag(
                      label: 'terbesar'.tr,
                      background: AppColors.spendSoft,
                      foreground: AppColors.spend,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formatCompactIdr(recap.spent),
                style: AppText.mono(
                  size: 12,
                  weight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 5,
                        color: AppColors.paper2,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fraction,
                          heightFactor: 1,
                          child: ColoredBox(color: color),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    change,
                    style: AppText.body(
                      size: 9.5,
                      weight: FontWeight.w800,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: AppText.body(
        size: 8.5,
        weight: FontWeight.w800,
        color: foreground,
      ),
    ),
  );
}
