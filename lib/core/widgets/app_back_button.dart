import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_bar_icon_button.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: AppBarIconButton(
        tooltip: 'Kembali',
        onPressed: Get.back,
        icon: Icons.arrow_back_rounded,
      ),
    );
  }
}
