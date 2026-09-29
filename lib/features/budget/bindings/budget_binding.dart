import 'package:get/get.dart';

import '../../category/repositories/category_repository.dart';
import '../controllers/budget_controller.dart';
import '../controllers/budget_form_controller.dart';
import '../repositories/budget_repository.dart';

class BudgetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BudgetController>(
      () => BudgetController(Get.find<BudgetRepository>()),
      fenix: true,
    );
    Get.lazyPut<BudgetFormController>(
      () => BudgetFormController(
        Get.find<BudgetRepository>(),
        Get.find<CategoryRepository>(),
      ),
      fenix: true,
    );
  }
}
