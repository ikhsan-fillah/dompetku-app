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

/// Teks angka yang bergulir per digit: saat teks berubah, hanya karakter
/// yang berbeda yang bergeser naik (seperti odometer); karakter lain diam.
/// Posisi dihitung dari kanan supaya satuan tetap sejajar. Di luar animasi
/// tampil sebagai satu [Text] biasa.
class RollingText extends StatefulWidget {
  const RollingText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..addStatusListener(_onStatus);
  String? _from;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _from = null);
    }
  }

  @override
  void didUpdateWidget(RollingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && !_reduceMotion(context)) {
      _from = old.text;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    if (from == null) {
      return Text(widget.text, maxLines: 1, style: widget.style);
    }
    final next = widget.text.characters.toList();
    final prev = from.characters.toList();
    final shift = next.length - prev.length;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < next.length; i++)
            _RollingChar(
              to: next[i],
              from: i - shift >= 0 && i - shift < prev.length
                  ? prev[i - shift]
                  : null,
              animation: curve,
              style: widget.style,
            ),
        ],
      ),
    );
  }
}

class _RollingChar extends StatelessWidget {
  const _RollingChar({
    required this.to,
    required this.from,
    required this.animation,
    required this.style,
  });

  final String to;
  final String? from;
  final Animation<double> animation;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (from == to) return Text(to, style: style);
    return ClipRect(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              FractionalTranslation(
                translation: Offset(0, 0.9 * (1 - t)),
                child: Opacity(
                  opacity: t,
                  child: Text(to, style: style),
                ),
              ),
              if (from != null)
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(0, -0.9 * t),
                    child: Opacity(
                      opacity: 1 - t,
                      child: Text(from!, style: style, softWrap: false),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Nominal yang bergulir per digit saat berubah (lihat [RollingText]).
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({
    super.key,
    required this.value,
    required this.format,
    required this.style,
  });

  final int value;
  final String Function(int value) format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) =>
      RollingText(format(value), style: style);
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
