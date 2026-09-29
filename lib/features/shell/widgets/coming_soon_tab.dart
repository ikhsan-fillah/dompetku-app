import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_state_view.dart';

/// Penanda sementara untuk tab yang dibangun pada tahap berikutnya.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            12,
            AppSpacing.page,
            0,
          ),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: AppEmptyView(
            icon: icon,
            title: 'Segera hadir',
            message: 'Halaman $title dibangun pada tahap berikutnya.',
          ),
        ),
      ],
    );
  }
}
