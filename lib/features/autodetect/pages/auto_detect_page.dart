import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../services/auto_detect_service.dart';
import '../services/auto_detect_settings.dart';

/// Auto-detect (Android): privasi, izin, pilihan app, dan mode simpan.
class AutoDetectPage extends StatefulWidget {
  const AutoDetectPage({super.key});

  @override
  State<AutoDetectPage> createState() => _AutoDetectPageState();
}

class _AutoDetectPageState extends State<AutoDetectPage> {
  static const _apps = {
    'id.co.bca.mobile': 'BCA mobile',
    'com.gojek.gopay': 'GoPay',
    'com.shopee.id': 'ShopeePay',
    'id.dana': 'DANA',
  };

  late final AutoDetectService _service = Get.find<AutoDetectService>();
  final AutoDetectSettings _settings = AutoDetectSettings();
  bool? _enabled;
  Set<String> _selected = {};
  bool _saveAuto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _service.isAccessEnabled();
    final apps = await _settings.getApps();
    final saveAuto = await _settings.getSaveAuto();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _selected = apps;
      _saveAuto = saveAuto;
    });
  }

  Future<void> _toggleApp(String packageName, bool value) async {
    final next = Set<String>.from(_selected);
    value ? next.add(packageName) : next.remove(packageName);
    await _settings.setApps(next);
    if (mounted) setState(() => _selected = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Text('Auto-detect', style: AppText.display(size: 26)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'What we read',
            body:
                'Payment notifications from apps you choose. OTP codes, promos, and raw notification text are never saved.',
          ),
          _Card(
            title: 'Notification access',
            body: _enabled == null ? 'Checking…' : (_enabled! ? 'On' : 'Off'),
            footer: AppButton(
              label: 'Open notification access',
              onPressed: () async {
                await _service.openAccessSettings();
                await _load();
              },
            ),
          ),
          _Card(
            title: 'Apps',
            body: _selected.isEmpty ? 'Choose at least one app.' : '',
            child: Column(
              children: [
                for (final entry in _apps.entries)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    value: _selected.contains(entry.key),
                    onChanged: (value) => _toggleApp(entry.key, value),
                  ),
              ],
            ),
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
          if (child != null) child!,
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
