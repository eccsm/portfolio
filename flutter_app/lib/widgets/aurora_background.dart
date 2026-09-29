import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Slowly drifting colour fields over a faint dot grid. Replaces the old
/// photo background: no image download, theme-aware, and it stays still
/// when the OS asks for reduced motion.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 28));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.getColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.background),
        RepaintBoundary(
          child: CustomPaint(
            painter: _AuroraPainter(_controller, isDark: isDark),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _DotGridPainter(
              colors.text.withValues(alpha: isDark ? 0.07 : 0.08),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> t;
  final bool isDark;
  _AuroraPainter(this.t, {required this.isDark}) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t.value * 2 * math.pi;
    final strength = isDark ? 1.0 : 0.7;
    void blob(Offset center, double radius, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: alpha * strength),
            color.withValues(alpha: 0),
          ]).createShader(rect),
      );
    }

    final w = size.width, h = size.height;
    final r = math.max(w, h);
    blob(
        Offset(
            w * (0.18 + 0.08 * math.sin(a)), h * (0.12 + 0.06 * math.cos(a))),
        r * 0.55,
        AppTheme.primaryColor,
        0.16);
    blob(
        Offset(w * (0.88 + 0.06 * math.cos(a * 1.3)),
            h * (0.30 + 0.10 * math.sin(a * 0.9))),
        r * 0.50,
        AppTheme.secondaryColor,
        0.18);
    blob(
        Offset(w * (0.55 + 0.12 * math.sin(a * 0.7 + 1)),
            h * (0.95 + 0.05 * math.cos(a * 1.1))),
        r * 0.45,
        const Color(0xFF14B8A6),
        0.10);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.isDark != isDark;
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 28.0;
    final points = <Offset>[
      for (double y = gap / 2; y < size.height; y += gap)
        for (double x = gap / 2; x < size.width; x += gap) Offset(x, y),
    ];
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
