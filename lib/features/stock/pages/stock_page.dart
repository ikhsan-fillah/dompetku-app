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
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/stock_controller.dart';
import '../models/watchlist_item.dart';
import '../widgets/stock_hero.dart';

/// Modul Saham: login ke Supabase dan watchlist. Satu-satunya bagian app yang
/// memakai jaringan; data keuangan tidak pernah dikirim ke sini.
class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockController>();
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
                    return _LoginForm(controller: controller);
                  case StockAccess.signedIn:
                    return _Watchlist(controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
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

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.controller});

  final StockController controller;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.controller.signIn(_email.text, _password.text);
    if (ok) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
            label: 'MODUL SAHAM'.tr,
            title: 'Masuk ke akun Supabase'.tr,
            caption:
                'Hanya data saham yang disinkronkan. Transaksi, anggaran, dan tabungan tetap di perangkat ini.'
                    .tr,
          ),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _email,
          label: 'Email'.tr,
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _password,
          label: 'Password'.tr,
          prefixIcon: LucideIcons.lock,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
        ),
        Obx(() {
          final message = controller.loginError.value;
          if (message == null) return const SizedBox(height: 16);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              message,
              style: AppText.body(size: 12, color: AppColors.spend),
            ),
          );
        }),
        Obx(
          () => AppButton(
            label: 'Masuk ke Supabase'.tr,
            loading: controller.signingIn.value,
            onPressed: _submit,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Password tidak disimpan di perangkat, hanya sesi masuknya.'.tr,
          style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
        ),
      ],
    );
  }
}

class _Watchlist extends StatelessWidget {
  const _Watchlist({required this.controller});

  final StockController controller;

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
          );
        case ResourceStatus.success:
          final items = controller.items;
          final activeCount = items.where((item) => item.isActive).length;
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
                  caption: '@count nonaktif, riwayat datanya tetap tersimpan'
                      .trParams({'count': '${items.length - activeCount}'}),
                ),
              ),
              const SizedBox(height: AppSpacing.gap),
              FadeSlideIn(
                index: 1,
                child: AppCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      for (final item in items)
                        _WatchlistRow(
                          item: item,
                          onOpen: () => Get.toNamed(
                            AppRoutes.stockDetail,
                            arguments: item.ticker,
                          ),
                          onToggle: (active) => _toggle(item, active),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: AppButton(
                  label: 'Keluar dari Supabase'.tr,
                  kind: AppButtonKind.outline,
                  expand: false,
                  onPressed: controller.signOut,
                ),
              ),
            ],
          );
      }
    });
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.item,
    required this.onOpen,
    required this.onToggle,
  });

  final WatchlistItem item;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Text(
                    item.ticker,
                    style: AppText.display(
                      size: 18,
                      color: item.isActive ? AppColors.ink : AppColors.mut,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isActive ? 'aktif'.tr : 'nonaktif'.tr,
                    style: AppText.body(size: 11, color: AppColors.mut),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.mut,
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          label: '${item.ticker} ${'aktif'.tr}',
          child: Switch(value: item.isActive, onChanged: onToggle),
        ),
      ],
    );
  }
}
