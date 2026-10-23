import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// Header tab utama (tanpa tombol kembali). Gaya judul mengikuti [AppTitleBar].
///
/// Jarak bawah sama dengan app bar Beranda ([bottomGap]); isi di bawahnya
/// cukup menambah 4 px supaya jarak header ke kartu pertama 14 px di semua tab.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  /// Sama dengan padding bawah `HomeAppBar`.
  static const double bottomGap = 10;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        bottomGap,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.display(size: 26))),
          ...actions,
        ],
      ),
    );
  }
}
