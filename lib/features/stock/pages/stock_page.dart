import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_bar_icon_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/stock_controller.dart';
import '../models/watchlist_item.dart';
import '../widgets/stock_format.dart';
import '../widgets/stock_hero.dart';
import '../widgets/stock_login_dialog.dart';
import '../widgets/watchlist_card.dart';

/// Modul Saham: watchlist dengan ringkasan tiap saham. Masuk ke Supabase
/// lewat dialog yang muncul sendiri begitu halaman dibuka tanpa sesi. Satu-
/// satunya bagian app yang memakai jaringan; data keuangan tidak pernah
/// dikirim ke sini.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final StockController _controller = Get.find<StockController>();
  Worker? _worker;
  bool _dialogOpen = false;

  /// Keluar dari tombol di halaman ini tidak boleh langsung memunculkan
  /// dialog masuk lagi.
  bool _skipNextPrompt = false;

  @override
  void initState() {
    super.initState();
    _worker = ever(_controller.access, (_) => _maybePrompt());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }

  void _maybePrompt() {
    if (!mounted || _dialogOpen) return;
    if (_controller.access.value != StockAccess.signedOut) return;
    if (_skipNextPrompt) {
      _skipNextPrompt = false;
      return;
    }
    unawaited(_prompt());
  }

  Future<void> _prompt() async {
    _dialogOpen = true;
    try {
      await showStockLoginDialog(context, _controller);
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _signOut() {
    _skipNextPrompt = true;
    return _controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => AppTitleBar(
                title: 'Saham'.tr,
                action: controller.access.value == StockAccess.signedIn
                    ? AppBarIconButton(
                        tooltip: 'Tambah saham'.tr,
                        icon: LucideIcons.plus,
                        onPressed: () => _showAddSheet(context, controller),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(() {
                switch (controller.access.value) {
                  case StockAccess.checking:
                    return const ListSkeleton(rows: 3);
                  case StockAccess.notConfigured:
                    return AppEmptyView(
                      icon: LucideIcons.plugZap,
                      title: 'Supabase belum dikonfigurasi'.tr,
                      message:
                          'Jalankan app dengan --dart-define=SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY.'
                              .tr,
                    );
                  case StockAccess.signedOut:
                    return AppEmptyView(
                      icon: LucideIcons.lock,
                      title: 'Watchlist terkunci'.tr,
                      message:
                          'Masuk ke akun Supabase untuk membuka watchlist dan data broker.'
                              .tr,
                      action: AppButton(
                        label: 'Masuk ke Supabase'.tr,
                        expand: false,
                        onPressed: _maybeReopen,
                      ),
                    );
                  case StockAccess.signedIn:
                    return _Watchlist(
                      controller: controller,
                      onSignOut: _signOut,
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeReopen() {
    _skipNextPrompt = false;
    if (!_dialogOpen) unawaited(_prompt());
  }
}

Future<void> _showAddSheet(BuildContext context, StockController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _AddTickerSheet(controller: controller),
    ),
  );
}

/// Lembar tambah saham. Controller teks dimiliki State agar baru dibuang
/// setelah animasi tutup lembar selesai.
class _AddTickerSheet extends StatefulWidget {
  const _AddTickerSheet({required this.controller});

  final StockController controller;

  @override
  State<_AddTickerSheet> createState() => _AddTickerSheetState();
}

class _AddTickerSheetState extends State<_AddTickerSheet> {
  final _ticker = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final message = await widget.controller.addTicker(_ticker.text);
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        20,
        AppSpacing.page,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tambah saham'.tr, style: AppText.display(size: 22)),
          const SizedBox(height: 14),
          TextField(
            controller: _ticker,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Kode saham'.tr,
              hintText: 'BBCA',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Tambah'.tr, loading: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}

class _Watchlist extends StatelessWidget {
  const _Watchlist({required this.controller, required this.onSignOut});

  final StockController controller;
  final Future<void> Function() onSignOut;

  Future<void> _toggle(WatchlistItem item, bool active) async {
    final ok = await controller.setActive(item, active);
    if (!ok) {
      AppToast.show(
        title: 'Gagal mengubah status saham.'.tr,
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.watchlist.value;
      switch (state.status) {
        case ResourceStatus.idle:
        case ResourceStatus.loading:
          return const ListSkeleton(rows: 3);
        case ResourceStatus.error:
          return AppEmptyView(
            icon: LucideIcons.wifiOff,
            message: state.message ?? 'Gagal memuat watchlist.'.tr,
            action: AppButton(
              label: 'Coba lagi'.tr,
              expand: false,
              onPressed: controller.load,
            ),
          );
        case ResourceStatus.empty:
          return AppEmptyView(
            icon: LucideIcons.chartCandlestick,
            title: 'Watchlist masih kosong'.tr,
            message: 'Tambah saham yang ingin dipantau, contoh BBCA.'.tr,
            action: AppButton(
              label: 'Tambah saham'.tr,
              icon: LucideIcons.plus,
              expand: false,
              onPressed: () => _showAddSheet(context, controller),
            ),
          );
        case ResourceStatus.success:
          return _WatchlistBody(
            controller: controller,
            onToggle: _toggle,
            onSignOut: onSignOut,
          );
      }
    });
  }
}

class _WatchlistBody extends StatelessWidget {
  const _WatchlistBody({
    required this.controller,
    required this.onToggle,
    required this.onSignOut,
  });

  final StockController controller;
  final Future<void> Function(WatchlistItem item, bool active) onToggle;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Obx(() {
    final items = controller.items;
    final activeCount = controller.activeCount;
    final visible = controller.visibleItems;
    final flowDate = controller.latestFlowDate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        40,
      ),
      children: [
        FadeSlideIn(
          child: StockHero(
            label: 'SAHAM DIPANTAU'.tr,
            title: '@count aktif'.trParams({'count': '$activeCount'}),
            caption: flowDate == null
                ? '@count nonaktif, riwayat datanya tetap tersimpan'.trParams({
                    'count': '${items.length - activeCount}',
                  })
                : '@count nonaktif · data broker terbaru @date'.trParams({
                    'count': '${items.length - activeCount}',
                    'date': formatShortDate(flowDate),
                  }),
            footer: WatchlistStrip(items: items),
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        FadeSlideIn(
          index: 1,
          child: WatchlistFilterBar(
            value: controller.filter.value,
            all: items.length,
            active: activeCount,
            inactive: items.length - activeCount,
            onChanged: controller.setFilter,
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'Tidak ada saham pada pilihan ini.'.tr,
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.mut),
            ),
          ),
        for (final (index, item) in visible.indexed) ...[
          FadeSlideIn(
            index: index + 2,
            child: WatchlistCard(
              item: item,
              overview: controller.overviews[item.ticker],
              onOpen: () =>
                  Get.toNamed(AppRoutes.stockDetail, arguments: item.ticker),
              onToggle: (active) => onToggle(item, active),
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
        ],
        const SizedBox(height: 4),
        _AddTile(onTap: () => _showAddSheet(context, controller)),
        const SizedBox(height: 22),
        _AccountRow(email: controller.email, onSignOut: onSignOut),
      ],
    );
  });
}

/// Petak putus-putus di ujung daftar untuk menambah saham.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      label: 'Tambah saham'.tr,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus, size: 18, color: AppColors.ink2),
                const SizedBox(width: 8),
                Text(
                  'Tambah saham'.tr,
                  style: AppText.body(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.ink2,
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

/// Akun Supabase yang sedang masuk, dengan tombol keluar.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.email, required this.onSignOut});

  final String? email;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.cloud, size: 16, color: AppColors.mut),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            email == null
                ? 'Tersambung ke Supabase'.tr
                : 'Masuk sebagai @email'.trParams({'email': email!}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size: 12, color: AppColors.mut),
          ),
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'Keluar dari Supabase'.tr,
          kind: AppButtonKind.outline,
          expand: false,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
