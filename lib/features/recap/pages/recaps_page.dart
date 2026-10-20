import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../transaction/models/transaction_model.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../services/recap_calculation_service.dart';
import 'monthly_recap_page.dart';
import 'yearly_recap_page.dart';

/// Halaman Recaps: pilih tahun, lalu bulan. Bulan masa depan tidak ditampilkan.
class RecapsPage extends StatefulWidget {
  const RecapsPage({super.key});

  @override
  State<RecapsPage> createState() => _RecapsPageState();
}

class _RecapsPageState extends State<RecapsPage> {
  late final RecapCalculationService _recaps = Get.find<RecapCalculationService>();
  late final TransactionRepository _transactions = Get.find<TransactionRepository>();

  bool _loading = true;
  String? _error;
  List<TransactionModel> _data = const [];
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
      if (!mounted) return;
      setState(() {
        _data = all;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat recap.';
        _loading = false;
      });
    }
  }

  int? get _firstYear {
    if (_data.isEmpty) return null;
    return _data
        .map((e) => e.transactionDate.year)
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const AppTitleBar(title: 'Recaps'),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: AppText.body(color: AppColors.spend)));
    }
    final first = _firstYear;
    if (first == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No recaps yet. Add transactions to see your first month.',
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.mut),
          ),
        ),
      );
    }

    final years = [for (var y = first; y <= _now.year; y++) y];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Replay any month or year. Periods without transactions are greyed out, and future periods are not listed.',
          style: AppText.body(size: 12, color: AppColors.mut),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final y in years)
              ChoiceChip(
                label: Text(y == _now.year ? '$y · so far' : '$y'),
                selected: y == _year,
                onSelected: _hasData(y) ? (_) => setState(() => _year = y) : null,
              ),
          ],
        ),
        const SizedBox(height: 14),
        _yearRow(),
        const SizedBox(height: 14),
        Text('Month · $_year', style: AppText.label()),
        const SizedBox(height: 8),
        _monthGrid(),
      ],
    );
  }

  bool _hasData(int year) => _data.any((e) => e.transactionDate.year == year);

  Widget _yearRow() {
    final hasData = _hasData(_year);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: hasData ? () => Get.to(() => YearlyRecapPage(year: _year)) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasData ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$_year recap${_year == _now.year ? ' · so far' : ''}',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: hasData ? AppColors.ink : AppColors.mut,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasData ? AppColors.ink : AppColors.mut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthGrid() {
    final lastMonth = _year == _now.year ? _now.month : 12;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.25,
      children: [
        for (var m = 1; m <= lastMonth; m++) _monthTile(m),
      ],
    );
  }

  Widget _monthTile(int month) {
    final recap = _recaps.monthly(_data, year: _year, month: month, now: _now);
    final isCurrent = _year == _now.year && month == _now.month;
    final label = _monthName(month);

    if (!recap.hasData) {
      return _Tile(
        title: label,
        subtitle: '—',
        dashed: true,
        onTap: null,
      );
    }
    return _Tile(
      title: isCurrent ? '$label · so far' : label,
      subtitle: '${formatIdr(recap.spent)}\nspent',
      dashed: false,
      onTap: () => Get.to(() => MonthlyRecapPage(year: _year, month: month)),
    );
  }

  static String _monthName(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.dashed,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool dashed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = dashed;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: muted ? Colors.transparent : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: muted ? AppColors.mut : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.body(size: 10.5, color: AppColors.mut),
            ),
          ],
        ),
      ),
    );
  }
}
