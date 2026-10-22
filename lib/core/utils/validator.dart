import 'package:get/get.dart';

String? requiredText(String? value, {String? fieldName}) {
  if (value == null || value.trim().isEmpty) {
    return '@field wajib diisi'.trParams({
      'field': fieldName ?? 'Kolom ini'.tr,
    });
  }
  return null;
}

String? positiveAmount(int? amount) {
  if (amount == null || amount <= 0) {
    return 'Nominal harus lebih dari nol'.tr;
  }
  return null;
}
