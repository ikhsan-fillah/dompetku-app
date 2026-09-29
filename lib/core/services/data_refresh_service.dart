import 'package:get/get.dart';

/// Sinyal sederhana: naikkan [version] setiap kali data keuangan berubah
/// agar layar yang mendengarkan memuat ulang otomatis.
class DataRefreshService extends GetxService {
  final version = 0.obs;

  void bump() => version.value++;
}
