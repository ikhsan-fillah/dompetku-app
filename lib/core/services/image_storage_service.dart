abstract interface class ImageStorageService {
  /// Moves an image chosen by the user into app-managed local storage.
  Future<String> saveReceipt(String sourcePath);

  Future<void> deleteReceipt(String path);
}
