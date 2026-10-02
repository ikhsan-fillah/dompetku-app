import '../constant/app_constant.dart';

class AppLockService {
  DateTime? _backgroundedAt;

  void onBackgrounded(DateTime now) => _backgroundedAt = now;

  void onForegrounded() => _backgroundedAt = null;

  bool shouldLock(
    DateTime now, {
    Duration duration = AppConstants.defaultAutoLockDuration,
  }) {
    final backgroundedAt = _backgroundedAt;
    return backgroundedAt != null && now.difference(backgroundedAt) >= duration;
  }
}
