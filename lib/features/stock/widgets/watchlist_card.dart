import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../controllers/stock_controller.dart';
import '../models/broker_group.dart';
import '../models/watchlist_item.dart';
import '../services/broker_group_calculator.dart';
import 'group_flow_card.dart';
import 'stock_format.dart';
import 'stock_hero.dart';

/// Kartu satu saham di watchlist: kode, status, harga terakhir bila ada, arah
/// dana tiga kelompok pada snapshot Latest terbaru, dan tanggal datanya.
/// Menyentuh kartu membuka detail; saklar mengaktifkan atau menonaktifkan.
class WatchlistCard extends StatelessWidget {
  const WatchlistCard({
    super.key,
    required this.item,
    required this.overview,
    required this.onOpen,
    required this.onToggle,
  });

  final WatchlistItem item;

  /// Null selama ringkasan belum dimuat atau gagal dimuat.
  final TickerOverview? overview;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final active = item.isActive;
    final bar = overview?.bar;
    final flow = overview?.flow;
    final flowDate = overview?.flowDate;
    final change = bar?.changePercent;
    return Opacity(
      opacity: active ? 1 : 0.7,
      child: AppCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(item.ticker, style: AppText.display(size: 24)),
                  const SizedBox(width: 10),
                  StatusPill(
                    label: (active ? 'aktif' : 'nonaktif').tr,
                    background: active
                        ? AppColors.accentSoft
                        : AppColors.paper2,
                    foreground: active ? AppColors.accent : AppColors.ink2,
                  ),
                  const Spacer(),
                  Semantics(
                    label: '${item.ticker} ${'aktif'.tr}',
                    child: Switch(value: active, onChanged: onToggle),
                  ),
                ],
              ),
              if (bar?.close case final int close)
                Padding(
                  padding: const EdgeInsets.only(right: 10, bottom: 2),
                  child: Row(
                    children: [
                      Text(
                        'Rp ${formatPrice(close)}',
                        style: AppText.mono(size: 16, weight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      if (change != null)
                        ChangePill(
                          percent: change,
                          text: formatPercent(change),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10),
                child: flow == null
                    ? _NoFlow(isLoaded: overview != null)
                    : _MiniFlow(summary: flow),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        flowDate == null
                            ? 'Belum ada data broker'.tr
                            : 'Data broker @date (Latest)'.trParams({
                                'date': formatShortDate(flowDate),
                              }),
                        style: AppText.body(size: 11, color: AppColors.mut),
                      ),
                    ),
                    Text(
                      'Buka'.tr,
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiga baris kecil: kelompok, batang dua arah, dan net.
class _MiniFlow extends StatelessWidget {
  const _MiniFlow({required this.summary});

  final GroupSummary summary;

  @override
  Widget build(BuildContext context) {
    final maxAbs = BrokerGroup.values
        .map((group) => summary.of(group).netIdr.abs())
        .fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final group in BrokerGroup.values)
          _MiniFlowRow(group: group, total: summary.of(group), maxAbs: maxAbs),
      ],
    );
  }
}

class _MiniFlowRow extends StatelessWidget {
  const _MiniFlowRow({
    required this.group,
    required this.total,
    required this.maxAbs,
  });

  final BrokerGroup group;
  final GroupTotal total;
  final int maxAbs;

  @override
  Widget build(BuildContext context) {
    final empty = total.brokerCount == 0;
    final valueText = empty
        ? '-'
        : formatBrokerValue(total.netIdr, approx: total.hasApprox);
    return Semantics(
      container: true,
      label: '${group.label.tr}, net $valueText',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  group.label.tr,
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              Expanded(
                child: FlowBar(net: empty ? 0 : total.netIdr, maxAbs: maxAbs),
              ),
              SizedBox(
                width: 78,
                child: Text(
                  valueText,
                  textAlign: TextAlign.end,
                  style: AppText.mono(
                    size: 12,
                    weight: FontWeight.w600,
                    color: empty ? AppColors.mut : netColor(total.netIdr),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pengganti tiga baris kecil bila saham belum punya data broker.
class _NoFlow extends StatelessWidget {
  const _NoFlow({required this.isLoaded});

  final bool isLoaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.chartBar, size: 16, color: AppColors.mut),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (isLoaded
                      ? 'Arah dana muncul setelah data broker saham ini terisi.'
                      : 'Memuat ringkasan...')
                  .tr,
              style: AppText.body(
                size: 11.5,
                color: AppColors.ink2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Penyaring watchlist dengan jumlah di tiap pilihan.
class WatchlistFilterBar extends StatelessWidget {
  const WatchlistFilterBar({
    super.key,
    required this.value,
    required this.all,
    required this.active,
    required this.inactive,
    required this.onChanged,
  });

  final WatchFilter value;
  final int all;
  final int active;
  final int inactive;
  final ValueChanged<WatchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    String capitalized(String text) =>
        text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
    final options = [
      (WatchFilter.all, '${'Semua'.tr} $all'),
      (WatchFilter.active, '${capitalized('aktif'.tr)} $active'),
      (WatchFilter.inactive, '${capitalized('nonaktif'.tr)} $inactive'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (filter, label) in options)
          AppChip(
            label: label,
            selected: value == filter,
            onTap: () => onChanged(filter),
          ),
      ],
    );
  }
}

/// Garis segmen di hero: satu segmen per saham, terang bila aktif.
class WatchlistStrip extends StatelessWidget {
  const WatchlistStrip({super.key, required this.items});

  final List<WatchlistItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.paper.withValues(
                  alpha: item.isActive ? 0.9 : 0.22,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
