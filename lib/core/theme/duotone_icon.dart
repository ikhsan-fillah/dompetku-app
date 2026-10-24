import 'package:flutter/widgets.dart';

/// Ikon Phosphor duotone: lapisan isian ([fill], ditampilkan pudar) dan
/// lapisan garis ([line]) dari font `PhosphorDuotone` di `assets/fonts`.
/// Kode titik diambil dari phosphor_flutter 2.1.0.
class DuotoneIcon {
  const DuotoneIcon._(this.line, this.fill);

  final IconData line;
  final IconData fill;

  static const _family = 'PhosphorDuotone';

  static const forkKnife = DuotoneIcon._(
    IconData(0xe263, fontFamily: _family),
    IconData(0xe262, fontFamily: _family),
  );
  static const bus = DuotoneIcon._(
    IconData(0xe107, fontFamily: _family),
    IconData(0xe106, fontFamily: _family),
  );
  static const shoppingBag = DuotoneIcon._(
    IconData(0xe417, fontFamily: _family),
    IconData(0xe416, fontFamily: _family),
  );
  static const receipt = DuotoneIcon._(
    IconData(0xe3f1, fontFamily: _family),
    IconData(0xe3ec, fontFamily: _family),
  );
  static const heart = DuotoneIcon._(
    IconData(0xe2a9, fontFamily: _family),
    IconData(0xe2a8, fontFamily: _family),
  );
  static const graduationCap = DuotoneIcon._(
    IconData(0xe62d, fontFamily: _family),
    IconData(0xe62c, fontFamily: _family),
  );
  static const barbell = DuotoneIcon._(
    IconData(0xe0b7, fontFamily: _family),
    IconData(0xe0b6, fontFamily: _family),
  );
  static const filmSlate = DuotoneIcon._(
    IconData(0xe8c3, fontFamily: _family),
    IconData(0xe8c2, fontFamily: _family),
  );
  static const usersThree = DuotoneIcon._(
    IconData(0xe68f, fontFamily: _family),
    IconData(0xe68e, fontFamily: _family),
  );
  static const dotsThree = DuotoneIcon._(
    IconData(0xe1ff, fontFamily: _family),
    IconData(0xe1fe, fontFamily: _family),
  );
  static const wallet = DuotoneIcon._(
    IconData(0xe68b, fontFamily: _family),
    IconData(0xe68a, fontFamily: _family),
  );
  static const briefcase = DuotoneIcon._(
    IconData(0xe0ef, fontFamily: _family),
    IconData(0xe0ee, fontFamily: _family),
  );
  static const trendUp = DuotoneIcon._(
    IconData(0xe4af, fontFamily: _family),
    IconData(0xe4ae, fontFamily: _family),
  );
  static const gift = DuotoneIcon._(
    IconData(0xe277, fontFamily: _family),
    IconData(0xe276, fontFamily: _family),
  );
  static const squaresFour = DuotoneIcon._(
    IconData(0xe465, fontFamily: _family),
    IconData(0xe464, fontFamily: _family),
  );
}

/// Menggambar [DuotoneIcon]: isian pudar di bawah, garis tegas di atas.
class DuotoneIconView extends StatelessWidget {
  const DuotoneIconView(
    this.icon, {
    super.key,
    required this.color,
    this.size = 20,
    this.fillOpacity = 0.3,
  });

  final DuotoneIcon icon;
  final Color color;
  final double size;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Icon(
        icon.fill,
        size: size,
        color: color.withValues(alpha: fillOpacity),
      ),
      Icon(icon.line, size: size, color: color),
    ],
  );
}
