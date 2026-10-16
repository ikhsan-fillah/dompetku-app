import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/pin_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/pin_pad.dart';

/// Create PIN dua langkah: masukkan 6 digit, lalu konfirmasi.
class PinCreatePage extends StatefulWidget {
  const PinCreatePage({
    super.key,
    required this.pinService,
    required this.onCreated,
  });

  final PinService pinService;
  final VoidCallback onCreated;

  @override
  State<PinCreatePage> createState() => _PinCreatePageState();
}

class _PinCreatePageState extends State<PinCreatePage> {
  static const _length = 6;

  String _first = '';
  String _value = '';
  bool _confirming = false;
  bool _saving = false;
  String? _error;

  void _onDigit(String digit) {
    if (_saving || _value.length >= _length) return;
    setState(() {
      _value += digit;
      _error = null;
    });
    if (_value.length == _length) _complete();
  }

  void _onDelete() {
    if (_saving || _value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  Future<void> _complete() async {
    if (!_confirming) {
      setState(() {
        _first = _value;
        _value = '';
        _confirming = true;
      });
      return;
    }
    if (_value != _first) {
      setState(() {
        _value = '';
        _first = '';
        _confirming = false;
        _error = "PINs don't match. Try again.";
      });
      return;
    }
    setState(() => _saving = true);
    await widget.pinService.create(_value);
    if (!mounted) return;
    widget.onCreated();
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
                _confirming ? 'Confirm your PIN' : 'Create a PIN',
                textAlign: TextAlign.center,
                style: AppText.display(size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional backup for when biometrics are not available.',
                textAlign: TextAlign.center,
                style: AppText.body(size: 13, color: AppColors.mut),
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
              const Icon(LucideIcons.lock, size: 16, color: AppColors.mut),
            ],
          ),
        ),
      ),
    );
  }
}
