class AppSessionModel {
  const AppSessionModel({
    required this.isRegistered,
    required this.biometricEnabled,
    required this.biometricFailureCount,
    this.biometricLockedUntil,
  });

  final bool isRegistered;
  final bool biometricEnabled;
  final int biometricFailureCount;
  final DateTime? biometricLockedUntil;

  bool get isLockedOut =>
      biometricLockedUntil != null && DateTime.now().isBefore(biometricLockedUntil!);
}
