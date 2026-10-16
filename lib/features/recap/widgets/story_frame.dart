import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class StoryCard {
  const StoryCard({
    required this.background,
    required this.foreground,
    required this.child,
  });

  final Color background;
  final Color foreground;
  final Widget child;
}

/// Pemutar kartu recap: progress bar, auto-advance per kartu, tap kiri/kanan.
class StoryFrame extends StatefulWidget {
  const StoryFrame({super.key, required this.cards, required this.footer});

  final List<StoryCard> cards;
  final String footer;

  static const cardDuration = Duration(seconds: 6);

  @override
  State<StoryFrame> createState() => _StoryFrameState();
}

class _StoryFrameState extends State<StoryFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  int _index = 0;

  int get _last => widget.cards.length - 1;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: StoryFrame.cardDuration)
      ..addStatusListener(_onStatus)
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _index < _last) {
      _show(_index + 1);
    }
  }

  void _show(int index) {
    setState(() => _index = index);
    _progress.forward(from: 0);
  }

  void _next() {
    if (_index < _last) _show(_index + 1);
  }

  void _prev() {
    if (_index > 0) _show(_index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    final fg = card.foreground;
    return Scaffold(
      backgroundColor: card.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i <= _last; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: _Segment(
                                progress: _progress,
                                index: i,
                                current: _index,
                                color: fg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: fg),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _prev,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_index),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        child: card.child,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 16),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.footer,
                      style: AppText.mono(
                        size: 10.5,
                        color: fg.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Text(
                    '${_index + 1} / ${_last + 1}',
                    style: AppText.mono(
                      size: 10.5,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.progress,
    required this.index,
    required this.current,
    required this.color,
  });

  final Animation<double> progress;
  final int index;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final value = index < current
            ? 1.0
            : index == current
            ? progress.value
            : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 3,
            color: color.withValues(alpha: 0.25),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: Container(height: 3, color: color),
            ),
          ),
        );
      },
    );
  }
}

abstract final class StoryColors {
  static const ink = (bg: AppColors.ink, fg: AppColors.paper);
  static const paper = (bg: AppColors.paper, fg: AppColors.ink);
  static const paper2 = (bg: AppColors.paper2, fg: AppColors.ink);
  static const spend = (bg: AppColors.spend, fg: AppColors.paper);
  static const earn = (bg: AppColors.earn, fg: AppColors.paper);
}
