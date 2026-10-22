import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_bar_icon_button.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBarIconButton(
      tooltip: 'Kembali'.tr,
      onPressed: Get.back,
      icon: LucideIcons.arrowLeft,
    );
  }
}
