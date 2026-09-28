sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

class BiometricFailure extends AppFailure {
  const BiometricFailure(super.message);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message);
}

class OcrFailure extends AppFailure {
  const OcrFailure(super.message);
}
