import 'package:image_picker/image_picker.dart';

enum ReceiptImageSource { camera, gallery }

/// Mengambil gambar struk. Mengembalikan path file, atau null bila dibatalkan.
/// Dapat melempar exception platform (misalnya izin kamera ditolak);
/// pemanggil bertugas menampilkan pesannya.
abstract class ReceiptImagePicker {
  Future<String?> pick(ReceiptImageSource source);

  /// Android dapat mematikan aplikasi saat kamera terbuka. Panggil saat start
  /// untuk mengambil foto yang hilang.
  Future<String?> recoverLostImage();
}

class DeviceReceiptImagePicker implements ReceiptImagePicker {
  DeviceReceiptImagePicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(ReceiptImageSource source) async {
    final file = await _picker.pickImage(
      source: source == ReceiptImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 90,
    );
    return file?.path;
  }

  @override
  Future<String?> recoverLostImage() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    final files = response.files;
    if (files == null || files.isEmpty) return null;
    return files.first.path;
  }
}
