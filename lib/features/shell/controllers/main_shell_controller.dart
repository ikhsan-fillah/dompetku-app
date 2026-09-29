import 'package:get/get.dart';

class MainShellController extends GetxController {
  final tabIndex = 0.obs;

  void select(int index) => tabIndex.value = index;
}
