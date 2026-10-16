import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/app_constant.dart';
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
          : 'Wrong PIN. ${AppConstants.maxBiometricFailures - _auth.biometricFailureCount.value} attempts left.';
    });
    if (_auth.isLockedOut) {
      Get.offAllNamed(AppRoutes.biometricUnlock);
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
                'Enter your PIN',
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
              FutureBuilder<bool>(
                future: _auth.canUseBiometric(),
                builder: (context, snapshot) {
                  if (snapshot.data != true) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.biometricUnlock),
                    child: Text(
                      'Use biometrics',
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
