import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  State<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> {
  final AuthController _auth = Get.find();
  bool _loading = false;
  String? _message;

  Future<void> _enable() async {
    setState(() => _loading = true);
    final available = await _auth.biometricAvailable();
    if (!available) {
      if (mounted) setState(() { _loading = false; _message = 'Biometrik tidak tersedia pada perangkat ini.'; });
      return;
    }
    await _auth.setBiometricEnabled(true);
    if (mounted) Get.offAllNamed(AppRoutes.biometricUnlock);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Aktifkan biometrik')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Biometrik diperlukan untuk melindungi data finansial Anda.', textAlign: TextAlign.center),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_message!)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loading ? null : _enable, child: Text(_loading ? 'Memeriksa…' : 'Aktifkan biometrik')),
          ]),
        )),
      );
}
