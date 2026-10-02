import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../budget/views/budget_page.dart';
import '../../home/pages/home_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../transaction/pages/transaction_list_page.dart';
import '../../transaction/widgets/transaction_form_sheet.dart';
import '../controllers/main_shell_controller.dart';

class MainShellPage extends GetView<MainShellController> {
  const MainShellPage({super.key});

  Widget _tab(int index) => switch (index) {
    0 => const HomePage(),
    1 => const TransactionListPage(),
    2 => const BudgetPage(),
    _ => const ProfilePage(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Obx(() => _tab(controller.tabIndex.value)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Obx(
                  () => AppBottomNav(
                    currentIndex: controller.tabIndex.value,
                    onSelect: controller.select,
                    onAdd: () => showTransactionSheet(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
