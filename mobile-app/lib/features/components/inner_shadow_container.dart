import 'package:flutter/material.dart';

class InnerShadowContainer extends StatelessWidget {
  final Widget child;
  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  const InnerShadowContainer({
    super.key,
    required this.child,
    required this.shadows,
    this.borderRadius = BorderRadius.zero,
  });

  factory InnerShadowContainer.standard({required Widget child}) {
    return InnerShadowContainer(
      shadows: const [
        BoxShadow(color: Color(0x19FFFFFF), offset: Offset(-2, -2), blurRadius: 12, spreadRadius: 2),
        BoxShadow(color: Color(0x19FFFFFF), offset: Offset(2, 2), blurRadius: 12, spreadRadius: 2),
      ],
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(foregroundPainter: _InnerShadowPainter(shadows, borderRadius), child: child);
  }
}

class _InnerShadowPainter extends CustomPainter {
  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  _InnerShadowPainter(this.shadows, this.borderRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = borderRadius.toRRect(rect);

    canvas.clipRRect(rrect);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);

      final outerRect = rect.inflate(shadow.blurRadius + shadow.spreadRadius + 20);

      final path = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outerRect)
        ..addRRect(rrect.shift(-shadow.offset));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.shadows != shadows || oldDelegate.borderRadius != borderRadius;
  }
}
