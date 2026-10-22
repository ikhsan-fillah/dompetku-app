import 'package:get/get.dart';

/// Sapaan menurut jam: pagi 04.00-10.59, siang 11.00-14.59, sore 15.00-17.59,
/// selain itu malam. Mengembalikan teks dalam bahasa aplikasi yang aktif.
String timeGreeting(DateTime now) => switch (now.hour) {
  >= 4 && < 11 => 'Selamat pagi'.tr,
  >= 11 && < 15 => 'Selamat siang'.tr,
  >= 15 && < 18 => 'Selamat sore'.tr,
  _ => 'Selamat malam'.tr,
};
