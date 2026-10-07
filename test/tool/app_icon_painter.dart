import 'package:flutter/material.dart';

/// Newaka-App-Icon: weiße Tonne mit Blatt auf Dunkelgrün.
///
/// Wird nur vom Render-Test benutzt, der daraus die PNG-Quellen für
/// `flutter_launcher_icons` erzeugt. Alle Maße sind relativ zur Kantenlänge.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({required this.withBackground, this.inset = 0.0});

  /// `false` für den adaptiven Android-Vordergrund (Hintergrund kommt separat).
  final bool withBackground;

  /// Zusätzlicher Rand (Anteil der Kantenlänge), damit der Vordergrund in der
  /// sicheren Zone adaptiver Icons bleibt.
  final double inset;

  static const background = Color(0xFF1B5E3A);
  static const bin = Color(0xFFFFFFFF);
  static const leaf = Color(0xFF8FE0AF);
  static const leafVein = Color(0xFF1B5E3A);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (withBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background);
    }

    // Motiv in ein Quadrat legen, das um `inset` eingerückt ist.
    final scale = 1 - 2 * inset;
    canvas.translate(size.width * inset, size.height * inset);
    canvas.scale(scale, scale);

    final white = Paint()..color = bin;

    // Deckel: breiter Balken mit Griff.
    final lidTop = s * 0.30;
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.22, lidTop, s * 0.56, s * 0.075),
      Radius.circular(s * 0.03),
    );
    final handle = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.42, lidTop - s * 0.05, s * 0.16, s * 0.07),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(handle, white);
    canvas.drawRRect(lidRect, white);

    // Körper: nach unten leicht schmaler, abgerundet.
    final bodyTop = lidTop + s * 0.105;
    final bodyBottom = s * 0.78;
    final body = Path()
      ..moveTo(s * 0.265, bodyTop)
      ..lineTo(s * 0.735, bodyTop)
      ..lineTo(s * 0.70, bodyBottom - s * 0.04)
      ..quadraticBezierTo(s * 0.695, bodyBottom, s * 0.655, bodyBottom)
      ..lineTo(s * 0.345, bodyBottom)
      ..quadraticBezierTo(s * 0.305, bodyBottom, s * 0.30, bodyBottom - s * 0.04)
      ..close();
    canvas.drawPath(body, white);

    // Rippen im Körper.
    final rib = Paint()
      ..color = background
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    for (final x in [0.42, 0.50, 0.58]) {
      canvas.drawLine(
        Offset(s * x, bodyTop + s * 0.06),
        Offset(s * x, bodyBottom - s * 0.07),
        rib,
      );
    }

    // Blatt oben rechts, überlappt den Deckel.
    canvas.save();
    canvas.translate(s * 0.745, s * 0.335);
    canvas.rotate(-1.05);
    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(s * 0.17, -s * 0.17, s * 0.27, -s * 0.03)
      ..quadraticBezierTo(s * 0.10, s * 0.15, 0, 0)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = leaf);
    canvas.drawLine(
      Offset(s * 0.03, -s * 0.005),
      Offset(s * 0.22, -s * 0.035),
      Paint()
        ..color = leafVein
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppIconPainter old) =>
      old.withBackground != withBackground || old.inset != inset;
}
