import 'package:flutter/material.dart';
import 'dart:math';

class MascotHitAnimation extends StatefulWidget {
  final bool walking, pointing;
  final int errorLevel; // 0-4
  final VoidCallback? onComplete;
  const MascotHitAnimation({super.key, this.walking = true, this.pointing = false, this.errorLevel = 0, this.onComplete});
  @override
  State<MascotHitAnimation> createState() => _MascotHitAnimationState();
}

class _MascotHitAnimationState extends State<MascotHitAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _lastError = 0;

  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(); }

  @override
  void didUpdateWidget(covariant MascotHitAnimation old) {
    super.didUpdateWidget(old);
    if (widget.errorLevel > 0 && widget.errorLevel != _lastError) {
      _lastError = widget.errorLevel;
      _ctrl.stop();
      _ctrl.forward(from: 0).then((_) { _ctrl.repeat(); widget.onComplete?.call(); });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final sz = min(constraints.maxWidth, constraints.maxHeight);
      return AnimatedBuilder(animation: _ctrl, builder: (ctx, _) => CustomPaint(size: Size(sz, sz), painter: _DetectivePainter(
        t: _ctrl.value, walking: widget.walking, pointing: widget.pointing, errorLevel: widget.errorLevel,
      )));
    });
  }
}

class _DetectivePainter extends CustomPainter {
  final double t; final bool walking, pointing; final int errorLevel;
  _DetectivePainter({required this.t, this.walking = true, this.pointing = false, this.errorLevel = 0});

  static const _mustard = Color(0xFFD4A017), _brown = Color(0xFF6D4C41), _beige = Color(0xFFD7CCC8);
  static const _navy = Color(0xFF1A237E), _skin = Color(0xFFFFCC80), _black = Color(0xFF212121);
  static const _lens = Color(0xFFB3E5FC), _red = Color(0xFFE53935);

  static const _msgs = ['', 'Aua!', 'Es tut weh.', 'Es ist furchtbar!', 'Es zerreißt mich!'];

  // Daño acumulado: más heridas con cada error
  List<Offset> get _wounds {
    switch (errorLevel) {
      case 1: return [const Offset(0.02, 0.01)];
      case 2: return [const Offset(0.02, 0.01), const Offset(-0.05, 0.04)];
      case 3: return [const Offset(0.02, 0.01), const Offset(-0.05, 0.04), const Offset(0.08, -0.03)];
      case 4: return [const Offset(0.02, 0.01), const Offset(-0.05, 0.04), const Offset(0.08, -0.03), const Offset(-0.02, 0.08)];
      default: return [];
    }
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height, cx = w * 0.28;
    final shake = errorLevel > 0 ? sin(t * pi * 5) * (3 * errorLevel) : 0.0;
    final walkCycle = sin(t * pi * 2);

    c.save();
    if (errorLevel > 0 && t > 0.25) c.translate(shake, 0);

    // ── SOMBRA ──
    c.drawOval(Rect.fromCenter(center: Offset(cx + (walking ? walkCycle * 3 : 0), h - 8), width: 55, height: 12), Paint()..color = Colors.black12);

    // ── PIERNAS ──
    final lp = Paint()..color = _navy; final ls = walking ? walkCycle * 8 : 0;
    c.drawRRect(RRect.fromLTRBAndCorners(cx - 10 + ls, h * 0.58, cx + 2 + ls, h * 0.76, topLeft: const Radius.circular(4)), lp);
    c.drawRRect(RRect.fromLTRBAndCorners(cx + 3 - ls, h * 0.58, cx + 14 - ls, h * 0.76, topRight: const Radius.circular(4)), lp);
    c.drawOval(Rect.fromCenter(center: Offset(cx - 4 + ls, h * 0.78), width: 18, height: 7), Paint()..color = _black);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 9 - ls, h * 0.78), width: 18, height: 7), Paint()..color = _black);

    // ── ABRIGO ──
    c.drawPath(Path()..moveTo(cx - 22, h * 0.28)..lineTo(cx + 18, h * 0.28)..lineTo(cx + 20, h * 0.60)..lineTo(cx - 20, h * 0.60)..close(), Paint()..color = _mustard);
    c.drawPath(Path()..moveTo(cx - 12, h * 0.26)..lineTo(cx, h * 0.36)..lineTo(cx + 12, h * 0.26), Paint()..color = const Color(0xFFC8940F));

    // ── BRAZO IZQ ──
    c.drawLine(Offset(cx - 20, h * 0.36 + (walking ? walkCycle * 6 : 0)), Offset(cx - 16, h * 0.48 + (walking ? walkCycle * 6 : 0)), Paint()..color = _mustard..strokeWidth = 14..strokeCap = StrokeCap.round);

    // ── BRAZO DER ──
    final hx = pointing ? cx + 55 + sin(t * pi * 3) * 5 : cx + 28;
    final hy = pointing ? h * 0.24 : h * 0.50;
    c.drawLine(Offset(cx + 14, h * 0.38), Offset(hx, hy), Paint()..color = _mustard..strokeWidth = 14..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(hx, hy), 7, Paint()..color = _skin);
    if (!pointing) {
      c.drawLine(Offset(hx + 4 - 5, hy - 10 + 20), Offset(hx + 4 + 5, hy - 10 + 8), Paint()..color = _black..strokeWidth = 6..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(hx + 4 + 12, hy - 10 - 4), 16, Paint()..color = Colors.grey[600]!..style = PaintingStyle.stroke..strokeWidth = 3);
      c.drawCircle(Offset(hx + 4 + 12, hy - 10 - 4), 13, Paint()..color = _lens);
    }

    // ── CABEZA ──
    final headY = h * 0.14;
    c.drawCircle(Offset(cx, headY), 20, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: Offset(cx - 4, headY - 6), radius: 19), pi * 0.1, pi * 0.8, true, Paint()..color = _black);

    // ── OJOS ──
    if (errorLevel <= 2) {
      c.drawCircle(Offset(cx - 5, headY - 5), errorLevel > 0 ? 8 : 7, Paint()..color = Colors.white);
      c.drawCircle(Offset(cx + 7, headY - 5), errorLevel > 0 ? 8 : 7, Paint()..color = Colors.white);
      c.drawCircle(Offset(cx - 4, headY - 5), errorLevel > 0 ? 2.5 : 3.5, Paint()..color = _black);
      c.drawCircle(Offset(cx + 8, headY - 5), errorLevel > 0 ? 2.5 : 3.5, Paint()..color = _black);
    } else {
      final xp = Paint()..color = _black..strokeWidth = 2;
      c.drawLine(Offset(cx - 11, headY - 10), Offset(cx - 1, headY), xp); c.drawLine(Offset(cx - 1, headY - 10), Offset(cx - 11, headY), xp);
      c.drawLine(Offset(cx + 1, headY - 10), Offset(cx + 11, headY), xp); c.drawLine(Offset(cx + 11, headY - 10), Offset(cx + 1, headY), xp);
    }
    // Nariz
    c.drawPath(Path()..moveTo(cx, headY + 2)..quadraticBezierTo(cx + 4, headY + 8, cx - 2, headY + 12)..quadraticBezierTo(cx - 4, headY + 10, cx - 2, headY + 2)..close(), Paint()..color = const Color(0xFFE6AC6D));
    // Boca
    if (errorLevel == 0) c.drawArc(Rect.fromCircle(center: Offset(cx, headY + 14), radius: 4), 0.2, pi - 0.4, false, Paint()..color = _black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    else if (errorLevel <= 2) c.drawOval(Rect.fromCircle(center: Offset(cx, headY + 15), radius: 4), Paint()..color = Colors.red..style = PaintingStyle.fill);
    else c.drawLine(Offset(cx - 4, headY + 15), Offset(cx + 4, headY + 15), Paint()..color = _black..strokeWidth = 2);

    // ── SOMBRERO ──
    final htY = headY - 17;
    c.drawOval(Rect.fromCenter(center: Offset(cx, htY + 3), width: 52, height: 14), Paint()..color = _brown);
    c.drawRRect(RRect.fromLTRBAndCorners(cx - 14, htY - 12, cx + 14, htY + 5, topLeft: const Radius.circular(8), topRight: const Radius.circular(8)), Paint()..color = _brown);
    c.drawRect(Rect.fromLTRB(cx - 14, htY - 3, cx + 14, htY + 3), Paint()..color = _beige);

    // ── HERIDAS ACUMULADAS ──
    for (final w in _wounds) {
      c.drawCircle(Offset(cx + w.dx * 200, h * 0.14 + w.dy * 200), 4, Paint()..color = _red.withAlpha(160)..style = PaintingStyle.fill);
    }
    // Parches/curitas
    if (errorLevel >= 2) {
      c.drawRRect(RRect.fromLTRBAndCorners(cx + 12, headY + 6, cx + 22, headY + 12, topLeft: const Radius.circular(2)), Paint()..color = const Color(0xFFFFCDD2));
    }
    if (errorLevel >= 3) {
      c.drawLine(Offset(cx - 25, h * 0.30 - 3), Offset(cx - 15, h * 0.30 + 3), Paint()..color = Colors.white..strokeWidth = 5);
      c.drawLine(Offset(cx - 25, h * 0.30 + 3), Offset(cx - 15, h * 0.30 - 3), Paint()..color = Colors.white..strokeWidth = 5);
    }

    // ── BOCADILLO DE PENSAMIENTO ──
    if (errorLevel > 0 && t > 0.1 && t < 0.85) {
      final bx = cx + 20, by = headY - 45;
      final msg = _msgs[errorLevel];
      final tp = TextPainter(text: TextSpan(text: msg, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      final bw = tp.width + 16, bh = tp.height + 10;
      // Nube
      final bubble = RRect.fromLTRBAndCorners(bx, by, bx + bw, by + bh, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10));
      c.drawRRect(bubble, Paint()..color = Colors.white);
      c.drawRRect(bubble, Paint()..color = Colors.grey[300]!..style = PaintingStyle.stroke..strokeWidth = 1.5);
      // Pico
      final peak = Path()..moveTo(bx + 8, by + bh)..lineTo(bx + 2, by + bh + 10)..lineTo(bx + 16, by + bh)..close();
      c.drawPath(peak, Paint()..color = Colors.white);
      c.drawPath(peak, Paint()..color = Colors.grey[300]!..style = PaintingStyle.stroke..strokeWidth = 1.5);
      tp.paint(c, Offset(bx + 8, by + 5));
    }

    // ── FLECHA (derecha → izquierda, 0.5s) ──
    if (errorLevel > 0 && t <= 0.25) {
      final arrT = t / 0.25; // 0→1 en 0.5s
      final arrX = w - arrT * (w - cx - 20);
      final arrY = h * 0.32 + sin(arrT * pi * 2) * 4;
      c.drawLine(Offset(arrX + 35, arrY), Offset(arrX, arrY), Paint()..color = Colors.brown[700]!..strokeWidth = 4..strokeCap = StrokeCap.round);
      final tip = Path()..moveTo(arrX, arrY)..lineTo(arrX + 14, arrY - 8)..lineTo(arrX + 12, arrY)..lineTo(arrX + 14, arrY + 8)..close();
      c.drawPath(tip, Paint()..color = Colors.grey[400]!);
    }

    // ── IMPACTO ──
    if (errorLevel > 0 && t > 0.2) {
      final bi = ((t - 0.2) * 3).clamp(0.0, 1.0);
      c.drawCircle(Offset(cx, h * 0.32), 6 * bi, Paint()..color = _red.withAlpha((bi * 180).round()));
    }

    c.restore();
  }

  @override
  bool shouldRepaint(covariant _DetectivePainter o) => true;
}
