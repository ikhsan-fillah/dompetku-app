import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../services/risk_analysis.dart';
import '../services/risk_inputs.dart';
import 'stock_format.dart';

/// Tab Risiko: seberapa liar harga bergerak, seberapa sering CL tersentuh, dan
/// ukuran posisi yang menjaga rugi di CL tetap di batas. Semua angka dihitung
/// dari harga harian (bukan keluaran model) dan tidak memberi petunjuk arah.
class RiskSection extends StatelessWidget {
  const RiskSection({
    super.key,
    required this.ticker,
    required this.analysis,
    required this.inputs,
    required this.onEditInputs,
    this.peers = const {},
  });

  final String ticker;
  final RiskAnalysis analysis;
  final RiskInputs inputs;

  /// Saham aktif lain di watchlist dan analisisnya, untuk perbandingan CL.
  final Map<String, RiskAnalysis> peers;

  /// Dipanggil saat pemakai mengetuk isian modal, risiko, atau CL.
  final VoidCallback onEditInputs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '@days HARI BURSA KE DEPAN · DATA SAMPAI @date'.trParams({
            'days': '$riskHorizon',
            'date': formatShortDate(analysis.lastDate),
          }),
          style: AppText.monoLabel(color: AppColors.ink2, size: 11),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${'Seberapa'.tr} '),
              TextSpan(
                text: 'liar'.tr,
                style: AppText.display(
                  size: 30,
                  weight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              TextSpan(text: ' ${'harganya.'.tr}'),
            ],
          ),
          style: AppText.display(
            size: 30,
            weight: FontWeight.w400,
            height: 1.05,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        _MoveCard(analysis: analysis),
        _TouchCard(
          ticker: ticker,
          analysis: analysis,
          cutLoss: inputs.cutLossPercent,
        ),
        if (peers.isNotEmpty)
          _PeersCard(peers: peers, cutLoss: inputs.cutLossPercent),
        _SizeCard(analysis: analysis, inputs: inputs, onEdit: onEditInputs),
        const _TrustCard(),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(LucideIcons.info, size: 14, color: AppColors.ink2),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Alat bantu menakar risiko, bukan rekomendasi beli atau jual. Bukan nasihat keuangan.'
                      .tr,
                  style: AppText.body(
                    size: 12,
                    color: AppColors.ink2,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

TextStyle _cap() => AppText.label(color: AppColors.mut, size: 11);

/// Persen dengan satu desimal dan koma: 3,1.
String _oneDecimal(double v) => formatIndicator(v, digits: 1);

/// Persen bulat tanpa tanda: 22%.
String _whole(double fraction) => '${(fraction * 100).round()}%';

// ------------------------------------------------------------ gerak harian

class _MoveCard extends StatelessWidget {
  const _MoveCard({required this.analysis});

  final RiskAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (analysis.state) {
      VolatilityState.calm => ('Tenang'.tr, AppColors.earn, AppColors.earnSoft),
      VolatilityState.usual => (
        'Biasa'.tr,
        AppColors.accent,
        AppColors.accentSoft,
      ),
      VolatilityState.wild => (
        'Cukup liar'.tr,
        AppColors.warn,
        AppColors.warnSoft,
      ),
      VolatilityState.veryWild => (
        'Sangat liar'.tr,
        AppColors.spend,
        AppColors.spendSoft,
      ),
    };
    final ratio = analysis.ratio;
    final sentence = switch (analysis.state) {
      VolatilityState.calm =>
        'Sekitar @x kali lebih tenang dari biasanya.'.trParams({
          'x': _oneDecimal(1 / ratio),
        }),
      VolatilityState.usual => 'Sekitar sama dengan biasanya.'.tr,
      _ => 'Sekitar @x kali lebih liar dari biasanya.'.trParams({
        'x': _oneDecimal(ratio),
      }),
    };
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('GERAK HARIAN TERUKUR'.tr, style: _cap())),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  label,
                  style: AppText.body(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text.rich(
                TextSpan(
                  text: _oneDecimal(analysis.moveNow),
                  children: [
                    TextSpan(
                      text: '%',
                      style: AppText.display(size: 24, letterSpacing: 0),
                    ),
                  ],
                ),
                style: AppText.display(
                  size: 56,
                  weight: FontWeight.w400,
                  height: 0.9,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'naik atau turun per hari bursa, rata-rata 20 hari terakhir'
                        .tr,
                    style: AppText.body(
                      size: 12,
                      color: AppColors.ink2,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MoveRange(typical: analysis.moveTypical, now: analysis.moveNow),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Text(
              sentence,
              style: AppText.body(
                size: 13,
                color: AppColors.ink,
                weight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ini besarnya gerak, bukan arahnya. Tidak ada petunjuk harga akan naik atau turun.'
                .tr,
            style: AppText.body(
              size: 12.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dua penanda di satu lintasan: gerak biasa (median setahun) dan gerak
/// 20 hari terakhir.
class _MoveRange extends StatelessWidget {
  const _MoveRange({required this.typical, required this.now});

  final double typical;
  final double now;

  @override
  Widget build(BuildContext context) {
    final top = (typical > now ? typical : now) * 1.35;
    double at(double v) => (v / top).clamp(0.0, 1.0);
    final nowColor = now > typical * 1.25 ? AppColors.warn : AppColors.ink;
    return Semantics(
      container: true,
      label: 'Gerak biasa @a persen, 20 hari terakhir @b persen'.trParams({
        'a': _oneDecimal(typical),
        'b': _oneDecimal(now),
      }),
      child: ExcludeSemantics(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                return SizedBox(
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 10,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.paper2,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 10,
                        child: Container(
                          width: w * at(now),
                          height: 8,
                          decoration: BoxDecoration(
                            color: nowColor == AppColors.warn
                                ? AppColors.warnSoft
                                : AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Positioned(
                        left: w * at(typical) - 1,
                        top: 4,
                        child: Container(
                          width: 2,
                          height: 20,
                          color: AppColors.mut,
                        ),
                      ),
                      Positioned(
                        left: w * at(now) - 7,
                        top: 7,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: nowColor,
                            border: Border.all(color: AppColors.card, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${'biasanya'.tr} ${_oneDecimal(typical)}%',
                    style: AppText.mono(size: 10.5, color: AppColors.mut),
                  ),
                ),
                Text(
                  '${'20 hari terakhir'.tr} ${_oneDecimal(now)}%',
                  style: AppText.mono(
                    size: 10.5,
                    color: nowColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- frekuensi CL

class _TouchCard extends StatelessWidget {
  const _TouchCard({
    required this.ticker,
    required this.analysis,
    required this.cutLoss,
  });

  final String ticker;
  final RiskAnalysis analysis;

  /// CL pemakai dalam persen.
  final double cutLoss;

  @override
  Widget build(BuildContext context) {
    final own = analysis.rateAt(cutLoss);
    final cls = <double>{
      for (final r in analysis.rates) r.cutLoss,
      cutLoss,
    }.toList()..sort();
    final year = analysis.firstDate.year;
    final recent = own.recent;
    final trend = recent == null
        ? null
        : recent >= own.all + 0.05
        ? 'Setahun terakhir lebih sering kena daripada rata-rata sejak @year: pasar belakangan lebih keras.'
        : recent <= own.all - 0.05
        ? 'Setahun terakhir lebih jarang kena daripada rata-rata sejak @year: pasar belakangan lebih tenang.'
        : null;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEBERAPA SERING CL-MU KENA'.tr, style: _cap()),
          const SizedBox(height: 6),
          Text(
            '@ticker, dari @n jendela 10 hari bursa sejak @year: berapa kali harga sempat turun sampai batas ini.'
                .trParams({
                  'ticker': ticker,
                  'n': '${analysis.windows}',
                  'year': '$year',
                }),
            style: AppText.body(
              size: 12.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 84),
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 44,
                child: Text(
                  'sejak @year'.trParams({'year': '$year'}),
                  textAlign: TextAlign.right,
                  style: AppText.body(size: 10, color: AppColors.mut),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  'setahun'.tr,
                  textAlign: TextAlign.right,
                  style: AppText.body(size: 10, color: AppColors.mut),
                ),
              ),
            ],
          ),
          for (final cl in cls)
            _TouchRow(rate: analysis.rateAt(cl), mine: cl == cutLoss),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Text(
              [
                'Dengan CL @cl%, @ticker tersentuh sekitar @n dari 10 jendela.'
                    .trParams({
                      'cl': _plain(cutLoss),
                      'ticker': ticker,
                      'n': '${(own.all * 10).round()}',
                    }),
                if (trend != null) trend.trParams({'year': '$year'}),
              ].join(' '),
              style: AppText.body(
                size: 12.5,
                color: AppColors.ink2,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Frekuensi masa lalu dari harga terendah harian, bukan keluaran model. Tidak memperhitungkan lompat harga saat buka.'
                .tr,
            style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _plain(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatIndicator(v, digits: 1);

class _TouchRow extends StatelessWidget {
  const _TouchRow({required this.rate, required this.mine});

  final TouchRate rate;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = mine ? AppColors.spend : AppColors.warn;
    return Semantics(
      container: true,
      label: 'CL @cl persen: @all sejak awal, @recent setahun terakhir'
          .trParams({
            'cl': _plain(rate.cutLoss),
            'all': _whole(rate.all),
            'recent': rate.recent == null ? '-' : _whole(rate.recent!),
          }),
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: mine ? AppColors.spendSoft : null,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text.rich(
                  TextSpan(
                    text: 'CL −@cl%'.trParams({'cl': _plain(rate.cutLoss)}),
                    children: [
                      if (mine)
                        TextSpan(
                          text: '\n${'batasmu'.tr}',
                          style: AppText.body(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppColors.spend,
                          ),
                        ),
                    ],
                  ),
                  style: AppText.mono(size: 12, weight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Container(
                  height: 10,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: rate.all.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  _whole(rate.all),
                  textAlign: TextAlign.right,
                  style: AppText.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  rate.recent == null ? '-' : _whole(rate.recent!),
                  textAlign: TextAlign.right,
                  style: AppText.mono(size: 12, color: AppColors.ink2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- saham lain

class _PeersCard extends StatelessWidget {
  const _PeersCard({required this.peers, required this.cutLoss});

  final Map<String, RiskAnalysis> peers;
  final double cutLoss;

  @override
  Widget build(BuildContext context) {
    final entries = peers.entries.toList();
    final rates = [for (final e in entries) e.value.rateAt(cutLoss)];
    final worst = rates.fold<double>(0, (m, r) => r.all > m ? r.all : m);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAHAM LAIN, CL @cl% TERSENTUH'.trParams({'cl': _plain(cutLoss)}),
            style: _cap(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _PeerTile(code: entries[i].key, rate: rates[i]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            [
              'Angka besar adalah rata-rata sejak awal riwayat; angka kecil adalah setahun terakhir.'
                  .tr,
              if (worst >= 0.4)
                'Di saham yang lebih liar, CL ini lebih sering kena. Pilihannya: perkecil lot, atau terima CL lebih lebar dengan lot lebih sedikit.'
                    .tr,
            ].join(' '),
            style: AppText.body(size: 12, color: AppColors.ink2, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.code, required this.rate});

  final String code;
  final TouchRate rate;

  @override
  Widget build(BuildContext context) {
    final recent = rate.recent;
    return Semantics(
      container: true,
      label: '@code: @all sejak awal, @recent setahun terakhir'.trParams({
        'code': code,
        'all': _whole(rate.all),
        'recent': recent == null ? '-' : _whole(recent),
      }),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Column(
            children: [
              Text(code, style: AppText.body(size: 10.5, color: AppColors.mut)),
              Text(
                _whole(rate.all),
                style: AppText.mono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.spend,
                ),
              ),
              Text(
                recent == null ? '-' : _whole(recent),
                style: AppText.mono(size: 10.5, color: AppColors.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- ukuran posisi

class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.analysis,
    required this.inputs,
    required this.onEdit,
  });

  final RiskAnalysis analysis;
  final RiskInputs inputs;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final price = analysis.lastClose;
    final main = positionSize(
      capital: inputs.capital,
      riskPercent: inputs.riskPercent,
      cutLossPercent: inputs.cutLossPercent,
      price: price,
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('HITUNG UKURAN POSISI'.tr, style: _cap())),
              if (inputs.isExample)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper2,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'contoh angka'.tr,
                    style: AppText.body(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.ink2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputTile(
                  label: 'Modal'.tr,
                  value: 'Rp ${formatPrice(inputs.capital.round())}',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InputTile(
                  label: 'Rugi maksimal'.tr,
                  value: '${_plain(inputs.riskPercent)}% ${'modal'.tr}',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InputTile(
                  label: 'CL-mu'.tr,
                  value: '−${_plain(inputs.cutLossPercent)}%',
                  danger: true,
                  onTap: onEdit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (main == null)
            Text(
              'Satu lot pun melebihi batas risiko atau modalmu pada CL ini. Perkecil CL, naikkan batas rugi, atau tambah modal.'
                  .tr,
              style: AppText.body(
                size: 12.5,
                color: AppColors.ink2,
                height: 1.45,
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    text: '${main.lots}',
                    children: [
                      TextSpan(
                        text: ' lot',
                        style: AppText.display(size: 20, letterSpacing: 0),
                      ),
                    ],
                  ),
                  style: AppText.display(
                    size: 44,
                    weight: FontWeight.w400,
                    height: 0.9,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Rp @cost pada harga Rp @price. Kena CL di Rp @stop, rugi sekitar Rp @loss.'
                        .trParams({
                          'cost': formatPrice(main.cost.round()),
                          'price': formatPrice(price.round()),
                          'stop': formatPrice(main.stopPrice.round()),
                          'loss': formatPrice(main.loss.round()),
                        }),
                    style: AppText.body(
                      size: 12,
                      color: AppColors.ink2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (main.limitedByCapital) ...[
              const SizedBox(height: 8),
              Text(
                'Jumlah lot dibatasi modal, jadi rugi di CL lebih kecil dari batas risikomu.'
                    .tr,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.warn,
                  height: 1.4,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final cl in const [3.0, 5.0]) ...[
                if (cl != 3.0) const SizedBox(width: 6),
                Expanded(
                  child: _CompareTile(
                    cutLoss: cl,
                    size: positionSize(
                      capital: inputs.capital,
                      riskPercent: inputs.riskPercent,
                      cutLossPercent: cl,
                      price: price,
                    ),
                    rate: analysis.rateAt(cl),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'CL lebih ketat memberi lot lebih banyak untuk risiko yang sama, tetapi lebih sering kena oleh gerak biasa. Rugi per kejadian sama, jumlah kejadiannya yang naik.'
                .tr,
            style: AppText.body(size: 12, color: AppColors.ink2, height: 1.45),
          ),
          const SizedBox(height: 8),
          Text(
            'Rumus: risiko yang kamu tetapkan dibagi selisih harga ke CL. Tidak memperhitungkan biaya dan fraksi harga.'
                .tr,
            style: AppText.body(size: 12, color: AppColors.mut, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.spend : AppColors.ink;
    return Semantics(
      button: true,
      label: '$label, $value',
      hint: 'Ketuk untuk mengubah'.tr,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: danger ? AppColors.spendSoft : AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(
                color: danger ? AppColors.spend : AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.body(
                    size: 11,
                    color: danger ? AppColors.spend : AppColors.mut,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppText.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareTile extends StatelessWidget {
  const _CompareTile({
    required this.cutLoss,
    required this.size,
    required this.rate,
  });

  final double cutLoss;
  final PositionSize? size;
  final TouchRate rate;

  @override
  Widget build(BuildContext context) {
    final recent = rate.recent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CL −@cl%'.trParams({'cl': _plain(cutLoss)}),
            style: AppText.body(size: 11, color: AppColors.mut),
          ),
          const SizedBox(height: 2),
          Text(
            size == null ? '-' : '${size!.lots} lot',
            style: AppText.mono(size: 12.5, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            recent == null
                ? '${'kena'.tr} ${_whole(rate.all)}'
                : '${'kena'.tr} ${_whole(rate.all)} · ${'setahun'.tr} ${_whole(recent)}',
            style: AppText.body(size: 11, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- kepercayaan

class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEBERAPA BISA DIPERCAYA'.tr, style: _cap()),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    value: '5 / 5',
                    color: AppColors.ink,
                    text:
                        'periode uji: model yang menimbang kondisi terkini sedikit lebih akurat dari frekuensi biasa'
                            .tr,
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.line2,
                ),
                Expanded(
                  child: _Stat(
                    value: '11 ${'poin'.tr}',
                    color: AppColors.warn,
                    text:
                        'selisih terbesar angka persen model dari kenyataan di pasar terakhir'
                            .tr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Karena angka persen model meleset, tab ini memakai frekuensi harga nyata dan membandingkannya dengan setahun terakhir. Angka model tidak ditampilkan.'
                .tr,
            style: AppText.body(
              size: 12.5,
              color: AppColors.ink2,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warnSoft,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Text(
              'Frekuensi masa lalu bukan jaminan. Pakai untuk menakar risiko, bukan untuk menebak arah.'
                  .tr,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w700,
                color: AppColors.warn,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uji balik 2023 sampai 2026 · 44 saham · 5 periode berurutan'.tr,
            style: AppText.body(size: 11, color: AppColors.mut),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.color, required this.text});

  final String value;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.display(size: 26, color: color, height: 1)),
        const SizedBox(height: 6),
        Text(
          text,
          style: AppText.body(size: 11, color: AppColors.ink2, height: 1.35),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ dialog isian

/// Dialog mengubah modal, rugi maksimal, dan CL. Mengembalikan isian baru atau
/// null bila dibatalkan.
Future<RiskInputs?> showRiskInputsDialog(
  BuildContext context,
  RiskInputs current,
) => showDialog<RiskInputs>(
  context: context,
  builder: (_) => _InputsDialog(current: current),
);

class _InputsDialog extends StatefulWidget {
  const _InputsDialog({required this.current});

  final RiskInputs current;

  @override
  State<_InputsDialog> createState() => _InputsDialogState();
}

class _InputsDialogState extends State<_InputsDialog> {
  late final TextEditingController _capital;
  late final TextEditingController _risk;
  late final TextEditingController _cutLoss;
  String? _error;

  @override
  void initState() {
    super.initState();
    _capital = TextEditingController(
      text: widget.current.capital.round().toString(),
    );
    _risk = TextEditingController(text: _plain(widget.current.riskPercent));
    _cutLoss = TextEditingController(
      text: _plain(widget.current.cutLossPercent),
    );
  }

  @override
  void dispose() {
    _capital.dispose();
    _risk.dispose();
    _cutLoss.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _save() {
    final capital = _parse(_capital);
    final risk = _parse(_risk);
    final cutLoss = _parse(_cutLoss);
    if (capital == null || capital < 1000000) {
      setState(() => _error = 'Modal minimal Rp 1.000.000.'.tr);
      return;
    }
    if (risk == null || risk < 0.1 || risk > 10) {
      setState(
        () => _error = 'Rugi maksimal antara 0,1% dan 10% dari modal.'.tr,
      );
      return;
    }
    if (cutLoss == null || cutLoss < 0.5 || cutLoss > 20) {
      setState(() => _error = 'CL antara 0,5% dan 20%.'.tr);
      return;
    }
    Navigator.of(context).pop(
      widget.current.copyWith(
        capital: capital,
        riskPercent: risk,
        cutLossPercent: cutLoss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Ukuran posisi'.tr,
      message:
          'Angka ini disimpan di perangkat ini dan berlaku untuk semua saham.'
              .tr,
      confirmLabel: 'Simpan'.tr,
      onConfirm: _save,
      onCancel: () => Navigator.of(context).pop(),
      content: Column(
        children: [
          AppTextField(
            controller: _capital,
            label: 'Modal (Rp)'.tr,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _risk,
            label: 'Rugi maksimal (% modal)'.tr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _cutLoss,
            label: 'CL (% turun dari harga beli)'.tr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.spend,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
