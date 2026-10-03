import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool busy = false;
  String? error;

  Future<void> start() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final auth = Get.find<AuthController>();
      await auth.markRegistered();
      if (mounted) Get.offAllNamed(AppRoutes.biometricSetup);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Gagal menyiapkan aplikasi. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Mulai kelola uangmu',
    description:
        'DompetKu mencatat pemasukan dan pengeluaran secara pribadi di perangkat ini. Tidak perlu akun atau koneksi internet.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
        ],
        AppButton(
          onPressed: busy ? null : start,
          label: busy ? 'Menyiapkan...' : 'Mulai',
        ),
      ],
    ),
  );
}
