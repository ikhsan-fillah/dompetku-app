import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'app_back_button.dart';

/// Header halaman dengan tombol kembali di kiri, judul, dan aksi di kanan.
/// Jarak kiri dan kanan mengikuti [AppSpacing.page] agar sejajar dengan konten.
class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, this.title, this.titleWidget, this.action});

  final String? title;
  final Widget? titleWidget;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        0,
      ),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child:
                titleWidget ??
                Text(title ?? '', style: AppText.display(size: 26)),
          ),
          ?action,
        ],
      ),
    );
  }
}
