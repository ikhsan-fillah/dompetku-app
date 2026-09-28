import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';

import 'package:flutter/material.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _auth.savePin(_pinController.text.trim());
    if (mounted) {
      Get.back();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat PIN"),
      ),
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
                  decoration: const InputDecoration(
                    labelText: 'Masukkan PIN 4-6 digit',
                  ),
                  validator: (value){
                    final pin = value?.trim() ?? '';
                    final numeric = RegExp(r'^\d+$').hasMatch(pin);
                    if(pin.length < 4 || pin.length > 6 || !numeric) {
                      return 'PIN harus 4-6 digit angka';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text("Simpan PIN"))
              ],
            ),
        ),
      ),
    );
  }
}