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
            const AppTitleBar(title: 'Auto-detect'),
            Expanded(
              child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          _Card(
            title: 'What we read',
            body:
                'Payment notifications from apps you choose. OTP codes, promos, and raw notification text are never saved.',
          ),
          _Card(
            title: 'Notification access',
            body: _enabled == null
                ? 'Checking…'
                : (_enabled!
                      ? 'On'
                      : 'Off. If the toggle is greyed out (Android 13+), open App info, tap ⋮ > "Allow restricted settings", then come back and enable it.'),
            footer: Column(
              children: [
                AppButton(
                  label: 'Open notification access',
                  onPressed: () async {
                    await _service.openAccessSettings();
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Open app info',
                  kind: AppButtonKind.outline,
                  onPressed: () => _service.openAppDetails(),
                ),
              ],
            ),
          ),
          _Card(
            title: 'Apps',
            body: 'Read automatically from: ${_apps.join(', ')}.',
          ),
          _Card(
            title: 'Save automatically',
            body: 'Off: detected payments wait in Drafts.',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Save automatically'),
              value: _saveAuto,
              onChanged: (value) async {
                await _settings.setSaveAuto(value);
                if (mounted) setState(() => _saveAuto = value);
              },
            ),
          ),
          _Card(
            title: 'Quiet mode',
            body: 'No pop-ups while you use other apps. Drafts wait on Home.',
          ),
          _Card(
            title: 'Battery',
            body:
                'Set Tally battery use to Unrestricted so Android does not stop detection.',
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
