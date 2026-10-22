import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/app_constant.dart';
import '../../../core/services/local_data_reset_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/auth_controller.dart';
import '../widgets/pin_pad.dart';

/// Unlock dengan PIN cadangan. Tautan "Use biometrics" hanya bila perangkat punya biometrik.
class PinUnlockPage extends StatefulWidget {
  const PinUnlockPage({super.key});

  @override
  State<PinUnlockPage> createState() => _PinUnlockPageState();
}

class _PinUnlockPageState extends State<PinUnlockPage> {
  static const _length = 6;

  final AuthController _auth = Get.find<AuthController>();
  String _value = '';
  String? _error;
  bool _checking = false;

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await _auth.unlockWithPin(_value);
    if (!mounted) return;
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }
    setState(() {
      _checking = false;
      _value = '';
      _error = _auth.isLockedOut
          ? null
          : 'PIN salah. Sisa @count percobaan.'.trParams({
              'count':
                  '${AppConstants.maxBiometricFailures - _auth.biometricFailureCount.value}',
            });
    });
    if (_auth.isLockedOut) {
      Get.offAllNamed(AppRoutes.biometricUnlock);
    }
  }

  Future<void> _forgotPin() async {
    final confirmation = TextEditingController();
    var canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Lupa PIN?'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datamu tidak bisa dibuka tanpa PIN. Kamu hanya bisa menghapus semua data di ponsel ini dan memulai dari awal. Tindakan ini tidak dapat dibatalkan.'
                    .tr,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmation,
                decoration: InputDecoration(
                  labelText: 'Ketik HAPUS untuk melanjutkan'.tr,
                ),
                onChanged: (value) =>
                    setDialogState(() => canDelete = value == 'HAPUS'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Batal'.tr),
            ),
            FilledButton(
              onPressed: canDelete
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text('Hapus semua data'.tr),
            ),
          ],
        ),
      ),
    );
    confirmation.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await Get.find<LocalDataResetService>().resetAll();
      _auth.resetSessionState();
      if (mounted) Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menghapus data. Coba lagi.'.tr);
    }
  }

  void _onDigit(String digit) {
    if (_checking || _value.length >= _length) return;
    setState(() {
      _value += digit;
      _error = null;
    });
    if (_value.length == _length) _submit();
  }

  void _onDelete() {
    if (_checking || _value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukkan PIN kamu'.tr,
                textAlign: TextAlign.center,
                style: AppText.display(size: 26),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.spend,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              PinPad(
                value: _value,
                length: _length,
                onDigit: _onDigit,
                onDelete: _onDelete,
              ),
              const Spacer(),
              TextButton(
                onPressed: _forgotPin,
                child: Text(
                  'Lupa PIN?'.tr,
                  style: AppText.body(size: 13, color: AppColors.mut),
                ),
              ),
              FutureBuilder<bool>(
                future: _auth.canUseBiometric(),
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.biometricUnlock),
                    child: Text(
                      'Pakai biometrik'.tr,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
