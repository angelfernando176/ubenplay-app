import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

/// Puente de Cristal final: Inspector Gadget, celebración, flechas, meta correcta
class GlassBridge extends StatefulWidget {
  final int totalSteps, currentStep, errorStep;
  final String avatarEmoji;
  final List<String?> placed;
  final List<String> labels;
  final bool showCelebration;
  final int wordScore; // ✅ puntaje de la palabra completada

  const GlassBridge({
    super.key, required this.totalSteps, required this.currentStep,
    this.errorStep = -1, this.avatarEmoji = '🧑', required this.placed,
    required this.labels, this.showCelebration = false, this.wordScore = 0,
  });

  @override
  State<GlassBridge> createState() => _GlassBridgeState();
}

class _GlassBridgeState extends State<GlassBridge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _lastError = -1;
  bool _wasComplete = false;

  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000)); }

  @override
  void didUpdateWidget(covariant GlassBridge old) {
    super.didUpdateWidget(old);
    if (widget.errorStep >= 0 && widget.errorStep != _lastError) { _lastError = widget.errorStep; _ctrl.forward(from: 0); }
    if (widget.errorStep < 0) _lastError = -1;
    // Disparar celebración al completar
    if (widget.showCelebration && !_wasComplete) { _wasComplete = true; _ctrl.forward(from: 0); }
    if (!widget.showCelebration) _wasComplete = false;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (ctx, _) => _build(_ctrl.value));
  }

  Offset _stepPos(int step, int cols, double cw, double ch) {
    final r = step ~/ cols, c = step % cols;
    final isRev = r % 2 == 1;
    final x = 28 + (isRev ? (cols - 1 - c) : c) * cw + cw / 2;
    final y = 8 + r * ch + ch / 2;
    return Offset(x, y);
  }

  Widget _build(double t) {
    return LayoutBuilder(builder: (ctx, cts) {
      final W = cts.maxWidth, H = cts.maxHeight;
      final cols = 4;
      final rows = (widget.totalSteps / cols).ceil();
      final cw = (W - 40) / cols;
      final ch = min(cw * 1.15, 52.0);
      final totalH = rows * ch + 100;
      final animH = max(H, totalH);

      final errorPos = widget.errorStep >= 0 ? _stepPos(widget.errorStep, cols, cw, ch) : null;
      final avatarPos = widget.currentStep < widget.totalSteps ? _stepPos(widget.currentStep, cols, cw, ch) : _stepPos(widget.totalSteps - 1, cols, cw, ch);
      final lastRow = (widget.totalSteps - 1) ~/ cols;
      final lastRowReversed = lastRow % 2 == 1;

      // Avatar position
      double ax, ay;
      if (t > 0 && errorPos != null) {
        ax = errorPos.dx + sin(t * pi * 3) * 20;
        ay = errorPos.dy + (t * t * animH * 0.9);
      } else if (widget.showCelebration) {
        ax = avatarPos.dx - 14 + sin(t * pi * 4) * 8; // saltar
        ay = avatarPos.dy - 40 - (t < 0.4 ? t * 40 : (1 - t) * 40); // saltar arriba
      } else {
        ax = avatarPos.dx - 14;
        ay = avatarPos.dy - 40;
      }

      return SizedBox(width: W, height: animH, child: Stack(children: [
        // Flechas de continuación entre filas
        ...List.generate(rows - 1, (r) {
          final lastStepOfRow = (r + 1) * cols - 1;
          final nextStep = lastStepOfRow + 1;
          if (lastStepOfRow >= widget.totalSteps || nextStep >= widget.totalSteps) return const SizedBox.shrink();
          final p1 = _stepPos(lastStepOfRow, cols, cw, ch);
          final p2 = _stepPos(nextStep, cols, cw, ch);
          final midX = (p1.dx + p2.dx) / 2;
          final midY = p1.dy;
          final isRight = r % 2 == 0 ? true : false; // primera fila va izq→der, flecha derecha
          return Positioned(
            left: midX - 10, top: midY - 10,
            child: Icon(isRight ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 16, color: Colors.blueGrey[300]),
          );
        }),

        // Cristales
        ...List.generate(widget.totalSteps, (i) {
          final pos = _stepPos(i, cols, cw, ch);
          final done = i < widget.currentStep;
          final isErr = i == widget.errorStep;
          final val = i < widget.placed.length ? widget.placed[i] : null;

          return Positioned(
            left: pos.dx - cw / 2 + 4, top: pos.dy - ch / 2 + 4,
            child: Stack(children: [
              Container(
                width: cw - 8, height: ch - 8,
                decoration: BoxDecoration(
                  color: isErr && t > 0.1 ? Colors.red[200] : (done ? Colors.green[200] : (val != null ? Colors.red[100] : Colors.blueGrey[50])),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isErr ? Colors.red : (done ? Colors.green : Colors.blueGrey[300]!), width: 1.5),
                ),
                child: Center(child: Text(val ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: done ? Colors.green[800] : Colors.black54))),
              ),
              if (isErr && t > 0.05) CustomPaint(size: Size(cw - 8, ch - 8), painter: _ShatterPainter((t - 0.05).clamp(0.0, 0.95))),
            ]),
          );
        }),

        // Meta - posición correcta
        if (widget.errorStep < 0 || t < 0.1)
          Positioned(
            left: (lastRowReversed ? _stepPos(widget.totalSteps - 1, cols, cw, ch).dx - cw / 2 - 10 : _stepPos(widget.totalSteps - 1, cols, cw, ch).dx + cw / 2 - 10),
            top: _stepPos(widget.totalSteps - 1, cols, cw, ch).dy - ch / 2 - 8,
            child: const Text('🏁', style: TextStyle(fontSize: 28)))
        else
          Positioned(
            left: (lastRowReversed ? _stepPos(widget.totalSteps - 1, cols, cw, ch).dx - cw / 2 - 10 : _stepPos(widget.totalSteps - 1, cols, cw, ch).dx + cw / 2 - 10),
            top: _stepPos(widget.totalSteps - 1, cols, cw, ch).dy - 20,
            child: Opacity(opacity: 1 - t, child: Text(t > 0.5 ? '💥' : '🏁', style: const TextStyle(fontSize: 24)))),

        // Plataforma inicio
        Positioned(left: 4, top: 8 + ch / 2 - 22, child: Container(width: 36, height: 44, decoration: BoxDecoration(color: Colors.brown[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.brown[300]!, width: 2)), child: const Center(child: Text('🏠', style: TextStyle(fontSize: 20))))),

        // Avatar
        if (t > 0 && errorPos != null && t < 0.9)
          Positioned(left: ax, top: ay, child: Transform.rotate(angle: t * pi * 3, child: _inspectorGadget(t > 0.6)))
        else if (widget.showCelebration)
          Positioned(left: ax, top: ay, child: _inspectorGadget(true))
        else if (widget.errorStep < 0)
          Positioned(left: ax, top: ay, child: _inspectorGadget(false)),

        // Celebración: sombrero volando
        if (widget.showCelebration && t > 0.2)
          Positioned(left: avatarPos.dx + 8 + sin(t * pi * 3) * 30, top: avatarPos.dy - 50 - t * 30, child: Transform.rotate(angle: t * pi * 2, child: _hatIcon())),

        // Mensaje "Has fallado"
        if (widget.errorStep >= 0 && t > 0.2)
          Positioned(left: W / 2 - 80, top: animH - 50, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(10)), child: const Text('💀 ¡Has fallado!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),

        // Burbuja "Ich habe es geschafft...!"
        if (widget.showCelebration && t > 0.1)
          // Burbuja "Ich habe es geschafft...!" + puntos
          if (widget.showCelebration && t > 0.1) ...[
            Positioned(left: W / 2 - 90, top: animH - 80, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green, width: 2)), child: Text('Ich habe es geschafft...!', style: TextStyle(color: Colors.green[800], fontSize: 14, fontWeight: FontWeight.bold)))),
            Positioned(left: W / 2 - 40, top: animH - 50, child: Text('+${widget.wordScore}', style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold))),
          ],
      ]));
    });
  }

  Widget _inspectorGadget(bool celebrating) {
    return SizedBox(width: 40, height: 52, child: CustomPaint(painter: _InspectorGadgetPainter(celebrating: celebrating)));
  }

  Widget _hatIcon() {
    return SizedBox(width: 20, height: 12, child: CustomPaint(painter: _HatPainter()));
  }
}

/// Inspector Gadget: detective caricaturesco
class _InspectorGadgetPainter extends CustomPainter {
  final bool celebrating;
  _InspectorGadgetPainter({this.celebrating = false});

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2, h = s.height;
    // Sombrero fedora
    c.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.08), width: 28, height: 8), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromLTRBAndCorners(cx - 10, h * -0.04, cx + 10, h * 0.06, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), Paint()..color = const Color(0xFF6D4C41));
    c.drawRect(Rect.fromLTRB(cx - 10, h * 0.02, cx + 10, h * 0.06), Paint()..color = const Color(0xFFD7CCC8));
    // Cabeza
    c.drawCircle(Offset(cx, h * 0.18), 12, Paint()..color = const Color(0xFFFFCC80));
    // Ojos (grandes, caricatura)
    c.drawCircle(Offset(cx - 4, h * 0.16), 4.5, Paint()..color = Colors.white);
    c.drawCircle(Offset(cx + 4, h * 0.16), 4.5, Paint()..color = Colors.white);
    c.drawCircle(Offset(cx - 3, h * 0.16), 2, Paint()..color = Colors.black);
    c.drawCircle(Offset(cx + 5, h * 0.16), 2, Paint()..color = Colors.black);
    // Nariz larga
    c.drawPath(Path()..moveTo(cx, h * 0.18)..quadraticBezierTo(cx + 6, h * 0.26, cx - 2, h * 0.30)..quadraticBezierTo(cx - 4, h * 0.28, cx - 2, h * 0.18)..close(), Paint()..color = const Color(0xFFE6AC6D));
    // Boca (sonrisa si celebra)
    if (celebrating) {
      c.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.32), radius: 5), pi * 0.1, pi * 0.8, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    } else {
      c.drawArc(Rect.fromCircle(center: Offset(cx, h * 0.32), radius: 3), 0.2, pi - 0.4, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    // Abrigo amarillo mostaza
    c.drawRRect(RRect.fromLTRBAndCorners(cx - 12, h * 0.36, cx + 12, h * 0.62, topLeft: const Radius.circular(5)), Paint()..color = const Color(0xFFD4A017));
    // Brazos (se agitan si celebra)
    final armY = h * 0.42;
    final armSwing = celebrating ? 15 : 0;
    c.drawLine(Offset(cx - 12, armY), Offset(cx - 24 - armSwing, h * 0.50), Paint()..color = const Color(0xFFD4A017)..strokeWidth = 10..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + 12, armY), Offset(cx + 24 + armSwing, h * 0.50), Paint()..color = const Color(0xFFD4A017)..strokeWidth = 10..strokeCap = StrokeCap.round);
    // Manos
    c.drawCircle(Offset(cx - 24 - armSwing, h * 0.52), 5, Paint()..color = const Color(0xFFFFCC80));
    c.drawCircle(Offset(cx + 24 + armSwing, h * 0.52), 5, Paint()..color = const Color(0xFFFFCC80));
    // Piernas
    c.drawRect(Rect.fromLTRB(cx - 8, h * 0.62, cx - 1, h * 0.84), Paint()..color = const Color(0xFF1A237E));
    c.drawRect(Rect.fromLTRB(cx + 1, h * 0.62, cx + 8, h * 0.84), Paint()..color = const Color(0xFF1A237E));
    // Zapatos
    c.drawOval(Rect.fromCenter(center: Offset(cx - 5, h * 0.85), width: 14, height: 6), Paint()..color = Colors.black);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 5, h * 0.85), width: 14, height: 6), Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _InspectorGadgetPainter o) => celebrating != o.celebrating;
}

class _HatPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    c.drawOval(Rect.fromCenter(center: Offset(cx, s.height * 0.6), width: s.width, height: s.height * 0.5), Paint()..color = const Color(0xFF6D4C41));
    c.drawRRect(RRect.fromLTRBAndCorners(cx - 5, 0, cx + 5, s.height * 0.5, topLeft: const Radius.circular(3), topRight: const Radius.circular(3)), Paint()..color = const Color(0xFF6D4C41));
  }
  @override
  bool shouldRepaint(covariant _HatPainter o) => false;
}

class _ShatterPainter extends CustomPainter {
  final double t;
  _ShatterPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final rng = Random(42);
    final cx = s.width / 2, cy = s.height / 2;
    final cp = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final ang = rng.nextDouble() * pi * 2;
      final len = rng.nextDouble() * min(s.width, s.height) * 0.6 * t;
      c.drawLine(Offset(cx, cy), Offset(cx + cos(ang) * len, cy + sin(ang) * len), cp);
    }
    if (t > 0.4) {
      final fp = Paint()..color = Colors.blueGrey[400]!;
      for (var i = 0; i < 5; i++) {
        final fx = rng.nextDouble() * s.width, fy = s.height + rng.nextDouble() * 20 * (t - 0.4);
        c.drawRRect(RRect.fromLTRBAndCorners(fx, fy, fx + rng.nextDouble() * 8 + 2, fy + rng.nextDouble() * 6 + 2, topLeft: const Radius.circular(1)), fp);
      }
    }
  }
  @override
  bool shouldRepaint(covariant _ShatterPainter o) => t != o.t;
}
