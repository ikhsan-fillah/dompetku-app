import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';

class UnlockPinPage extends StatefulWidget {
  const UnlockPinPage({super.key});

  @override
  State<UnlockPinPage> createState() => _UnlockPinPageState();
}

class _UnlockPinPageState extends State<UnlockPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _auth = Get.find<AuthController>();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _auth.verifyPin(_pinController.text.trim());
    if (!mounted) return;
    if (!ok) {
      setState(() => _errorText = 'PIN salah, silakan coba lagi');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buka Aplikasi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  errorText: _errorText,
                ),
                validator: (value) {
                  final pin = value?.trim() ?? '';
                  if (pin.isEmpty) return 'PIN wajib diisi';
                  if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                    return 'PIN harus 4-6 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Unlock"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
