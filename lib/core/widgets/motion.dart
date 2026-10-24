import 'package:flutter/material.dart';

/// Animasi mikro bersama. Semuanya sekali jalan, di bawah 400 ms, dan diam
/// bila HP meminta gerak dikurangi (`MediaQuery.disableAnimations`).

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Kartu muncul memudar sambil naik 12 px. [index] memberi jeda bergiliran
/// 60 ms per kartu. Hanya saat pertama kali tampil; membangun ulang dengan
/// data baru tidak mengulang animasinya.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  static const _base = Duration(milliseconds: 320);
  static const _step = Duration(milliseconds: 60);
  static const _maxSteps = 5;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    final steps = index.clamp(0, _maxSteps);
    final total = _base + _step * steps;
    // Jeda dibuat dengan bagian awal kurva yang datar.
    final start = (_step * steps).inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Angka yang bergulir dari nilai lama ke nilai baru saat berubah.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.maxLines = 1,
  });

  final int value;
  final String Function(int value) format;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) {
      return Text(format(value), maxLines: maxLines, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, current, _) =>
          Text(format(current.round()), maxLines: maxLines, style: style),
    );
  }
}

/// Memantul sekali (membesar 1,25x lalu kembali) setiap [trigger] berubah,
/// mis. bintang favorit. Tidak memantul saat pertama kali tampil.
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.trigger, required this.child});

  final Object trigger;
  final Widget child;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void didUpdateWidget(PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !_reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (_, child) {
      final t = _controller.value;
      final scale = t < 0.45
          ? 1 + 0.25 * Curves.easeOut.transform(t / 0.45)
          : 1.25 - 0.25 * Curves.easeOutBack.transform((t - 0.45) / 0.55);
      return Transform.scale(scale: scale, child: child);
    },
  );
}
