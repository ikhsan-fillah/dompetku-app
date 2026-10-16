import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../services/auto_detect_service.dart';

/// Auto-detect (Android): penjelasan privasi dan status izin notifikasi.
class AutoDetectPage extends StatefulWidget {
  const AutoDetectPage({super.key});

  @override
  State<AutoDetectPage> createState() => _AutoDetectPageState();
}

class _AutoDetectPageState extends State<AutoDetectPage> {
  late final AutoDetectService _service = Get.find<AutoDetectService>();
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await _service.isAccessEnabled();
    if (mounted) setState(() => _enabled = enabled);
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
            body: _enabled == null
                ? 'Checking…'
                : (_enabled! ? 'On' : 'Off'),
            footer: AppButton(
              label: 'Open notification access',
              onPressed: () async {
                await _service.openAccessSettings();
                await _refresh();
              },
            ),
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
  const _Card({required this.title, required this.body, this.footer});

  final String title;
  final String body;
  final Widget? footer;

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
          const SizedBox(height: 4),
          Text(body, style: AppText.body(size: 12, color: AppColors.ink2)),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}
