import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

enum ToastKind { success, error, info, undo }

/// Toast yang turun dari atas layar, pengganti snackbar. Hanya satu toast
/// tampil sekaligus; yang baru menggantikan yang lama. Hilang sendiri setelah
/// [duration], bisa ditutup dengan tombol silang atau digeser ke atas.
abstract final class AppToast {
  static OverlayEntry? _entry;

  static void show({
    BuildContext? context,
    required String title,
    String? message,
    ToastKind kind = ToastKind.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = context != null
        ? Overlay.maybeOf(context, rootOverlay: true)
        : Get.key.currentState?.overlay;
    if (overlay == null) return;
    hide();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        title: title,
        message: message,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) _entry = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void hide() {
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.title,
    required this.message,
    required this.kind,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  final String title;
  final String? message;
  final ToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  // Memakai AnimationController, bukan Timer, supaya ikut berhenti saat
  // widget dibuang (tidak ada timer menggantung).
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _slide.forward();
    _life
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _close();
      })
      ..forward();
  }

  @override
  void dispose() {
    _slide.dispose();
    _life.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _life.stop();
    await _slide.reverse();
    widget.onDismissed();
  }

  ({Color soft, Color strong, IconData icon}) get _look =>
      switch (widget.kind) {
        ToastKind.success => (
          soft: AppColors.earnSoft,
          strong: AppColors.earn,
          icon: LucideIcons.check,
        ),
        ToastKind.error => (
          soft: AppColors.spendSoft,
          strong: AppColors.spend,
          icon: LucideIcons.circleAlert,
        ),
        ToastKind.info => (
          soft: AppColors.accentSoft,
          strong: AppColors.accent,
          icon: LucideIcons.info,
        ),
        ToastKind.undo => (
          soft: AppColors.paper.withValues(alpha: 0.12),
          strong: AppColors.paper,
          icon: LucideIcons.trash2,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final dark = widget.kind == ToastKind.undo;
    final look = _look;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final top = MediaQuery.paddingOf(context).top + 8;
    final card = Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: dark ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: dark ? null : Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x291A2724),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: look.soft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(look.icon, size: 18, color: look.strong),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppText.body(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: dark ? AppColors.paper : AppColors.ink,
                          ),
                        ),
                        if (widget.message != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            widget.message!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              size: 11.5,
                              color: dark
                                  ? AppColors.paper.withValues(alpha: 0.75)
                                  : AppColors.ink2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null && widget.onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 6),
                      child: TextButton(
                        onPressed: () {
                          widget.onAction!();
                          _close();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: dark
                              ? AppColors.paper
                              : AppColors.paper2,
                          foregroundColor: AppColors.ink,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Tutup'.tr,
                      onPressed: _close,
                      icon: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: dark
                            ? AppColors.paper.withValues(alpha: 0.7)
                            : AppColors.mut,
                      ),
                    ),
                ],
              ),
            ),
            // Garis sisa waktu.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _life,
                builder: (_, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - _life.value,
                  child: Container(
                    height: 3,
                    color: look.strong.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      left: 14,
      right: 14,
      top: top,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < 0) _close();
            },
            child: reduceMotion
                ? FadeTransition(opacity: _slide, child: card)
                : SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -1.4),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slide,
                            curve: Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: _slide, child: card),
                  ),
          ),
        ),
      ),
    );
  }
}
