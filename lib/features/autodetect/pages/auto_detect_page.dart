import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../services/auto_detect_service.dart';
import '../services/auto_detect_settings.dart';

/// Auto-detect (Android): privasi, izin, pilihan app, dan mode simpan.
class AutoDetectPage extends StatefulWidget {
  const AutoDetectPage({super.key});

  @override
  State<AutoDetectPage> createState() => _AutoDetectPageState();
}

class _AutoDetectPageState extends State<AutoDetectPage>
    with WidgetsBindingObserver {
  static const _apps = [
    'BCA mobile',
    'GoPay',
    'ShopeePay',
    'DANA',
    'BRImo',
    'Jago',
    'OVO',
    'LinkAja',
    "Livin' by Mandiri",
    'BNI Mobile',
    'BSI Mobile',
    'blu by BCA',
    'SeaBank',
    'Jenius',
  ];

  late final AutoDetectService _service = Get.find<AutoDetectService>();
  final AutoDetectSettings _settings = AutoDetectSettings();
  bool? _enabled;
  bool _saveAuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isAccessEnabled();
    final saveAuto = await _settings.getSaveAuto();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _saveAuto = saveAuto;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(title: 'Deteksi otomatis'.tr),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  _Card(
                    title: 'Yang kami baca'.tr,
                    body:
                        'Notifikasi pembayaran dari aplikasi yang kamu pilih. Kode OTP, promo, dan teks notifikasi mentah tidak pernah disimpan.'
                            .tr,
                  ),
                  _Card(
                    title: 'Akses notifikasi'.tr,
                    body: _enabled == null
                        ? 'Memeriksa…'.tr
                        : (_enabled!
                              ? 'Aktif'.tr
                              : 'Nonaktif. Jika tombolnya abu-abu (Android 13+), buka Info aplikasi, ketuk ⋮ > "Izinkan pengaturan terbatas", lalu kembali dan aktifkan.'
                                    .tr),
                    footer: Column(
                      children: [
                        AppButton(
                          label: 'Buka akses notifikasi'.tr,
                          onPressed: () async {
                            await _service.openAccessSettings();
                          },
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Buka info aplikasi'.tr,
                          kind: AppButtonKind.outline,
                          onPressed: () => _service.openAppDetails(),
                        ),
                      ],
                    ),
                  ),
                  _Card(
                    title: 'Aplikasi'.tr,
                    body: 'Dibaca otomatis dari: @apps.'.trParams({
                      'apps': _apps.join(', '),
                    }),
                  ),
                  _Card(
                    title: 'Simpan otomatis'.tr,
                    body: _saveAuto
                        ? 'Aktif: pembayaran yang terdeteksi langsung dicatat ke kategori Lainnya. Ubah kategorinya nanti di Transaksi.'
                              .tr
                        : 'Nonaktif: pembayaran yang terdeteksi menunggu di Draf.'
                              .tr,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Simpan otomatis'.tr),
                      value: _saveAuto,
                      onChanged: (value) async {
                        await _settings.setSaveAuto(value);
                        if (mounted) setState(() => _saveAuto = value);
                      },
                    ),
                  ),
                  _Card(
                    title: 'Mode senyap'.tr,
                    body:
                        'Tanpa pop-up saat kamu memakai aplikasi lain. Draf menunggu di Beranda.'
                            .tr,
                  ),
                  _Card(
                    title: 'Baterai'.tr,
                    body:
                        'Atur penggunaan baterai Tally ke Tidak dibatasi agar Android tidak menghentikan deteksi.'
                            .tr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.body,
    this.footer,
    this.child,
  });

  final String title;
  final String body;
  final Widget? footer;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body(size: 13, weight: FontWeight.w700)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body, style: AppText.body(size: 12, color: AppColors.ink2)),
          ],
          ?child,
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
