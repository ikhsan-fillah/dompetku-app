import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'app_button.dart';
import '../services/app_haptics.dart';

/// Dialog standar aplikasi: kartu bergaris, judul display, dan dua tombol
/// [AppButton] sejajar (batal di kiri, aksi di kanan). Semua dialog konfirmasi
/// dan isian memakai ini supaya tombolnya seragam.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel,
    this.confirmKind = AppButtonKind.primary,
  });

  final String title;

  /// Teks penjelasan di bawah judul. Bisa dikombinasikan dengan [content].
  final String? message;

  /// Isi tambahan, mis. kolom isian.
  final Widget? content;
  final String confirmLabel;

  /// Null membuat tombol aksi nonaktif (mis. menunggu isian valid).
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;
  final String? cancelLabel;
  final AppButtonKind confirmKind;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        side: const BorderSide(color: AppColors.line),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      title: Text(title, style: AppText.display(size: 20)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null)
              Text(
                message!,
                style: AppText.body(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.45,
                ),
              ),
            if (message != null && content != null) const SizedBox(height: 16),
            ?content,
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                kind: AppButtonKind.outline,
                label: cancelLabel ?? 'Batal'.tr,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                kind: confirmKind,
                label: confirmLabel,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Menampilkan dialog konfirmasi ya/tidak. Mengembalikan true hanya bila
/// pengguna menekan tombol aksi; batal atau ketuk di luar menghasilkan false.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
  String? cancelLabel,
}) async {
  if (danger) AppHaptics.warning();
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmKind: danger ? AppButtonKind.danger : AppButtonKind.primary,
      onCancel: () => Navigator.of(dialogContext).pop(false),
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  return result ?? false;
}
