import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/stock_controller.dart';

/// Membuka dialog masuk Supabase. Mengembalikan true bila berhasil masuk,
/// false bila dibatalkan.
Future<bool> showStockLoginDialog(
  BuildContext context,
  StockController controller,
) async {
  controller.clearLoginError();
  final signedIn = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => StockLoginDialog(controller: controller),
  );
  return signedIn ?? false;
}

/// Dialog masuk ke akun Supabase: email dan password. Controller teks dimiliki
/// State, jadi baru dibuang setelah animasi tutup dialog selesai.
class StockLoginDialog extends StatefulWidget {
  const StockLoginDialog({super.key, required this.controller});

  final StockController controller;

  @override
  State<StockLoginDialog> createState() => _StockLoginDialogState();
}

class _StockLoginDialogState extends State<StockLoginDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.controller.signIn(_email.text, _password.text);
    if (!mounted || !ok) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        side: const BorderSide(color: AppColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.cloud,
                      size: 24,
                      color: AppColors.paper,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Masuk ke Supabase'.tr, style: AppText.display(size: 22)),
                const SizedBox(height: 6),
                Text(
                  'Hanya data saham yang disinkronkan. Transaksi, anggaran, dan tabungan tetap di perangkat ini.'
                      .tr,
                  style: AppText.body(
                    size: 13,
                    color: AppColors.ink2,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _email,
                  label: 'Email'.tr,
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _password,
                  label: 'Password'.tr,
                  prefixIcon: LucideIcons.lock,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  suffix: IconButton(
                    tooltip:
                        (_hidePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password')
                            .tr,
                    icon: Icon(
                      _hidePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                Obx(() {
                  final message = controller.loginError.value;
                  if (message == null) return const SizedBox(height: 18);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.circleAlert,
                            size: 15,
                            color: AppColors.spend,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            message,
                            style: AppText.body(
                              size: 12,
                              color: AppColors.spend,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        kind: AppButtonKind.outline,
                        label: 'Batal'.tr,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => AppButton(
                          label: 'Masuk akun'.tr,
                          loading: controller.signingIn.value,
                          onPressed: _submit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 14,
                        color: AppColors.mut,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Password tidak disimpan di perangkat, hanya sesi masuknya.'
                            .tr,
                        style: AppText.body(
                          size: 11,
                          color: AppColors.mut,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
