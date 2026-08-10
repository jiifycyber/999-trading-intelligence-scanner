import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/scan_result.dart';

class MarketRadar extends StatelessWidget {
  const MarketRadar({
    super.key,
    required this.results,
    this.lockedSymbol,
    this.confirmingSymbol,
  });

  final List<ScanResult> results;
  final String? lockedSymbol;
  final String? confirmingSymbol;

  @override
  Widget build(BuildContext context) {
    final visible = results.take(8).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11151E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DUKE MARKET RADAR',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: .7,
                  ),
                ),
              ),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const SizedBox(
              height: 260,
              child: Center(
                child: Text(
                  'Waiting for market data...',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return CustomPaint(
                    size: Size.square(size),
                    painter: _RadarPainter(
                      results: visible,
                      lockedSymbol: lockedSymbol,
                      confirmingSymbol: confirmingSymbol,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _legend('CALL', Icons.arrow_upward),
              _legend('PUT', Icons.arrow_downward),
              _legend('WAIT', Icons.hourglass_top),
              _legend('LOCKED', Icons.lock),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Radar updates with the live scanner. '
            'The locked trade remains frozen while surrounding '
            'assets continue changing every tick.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.results,
    required this.lockedSymbol,
    required this.confirmingSymbol,
  });

  final List<ScanResult> results;
  final String? lockedSymbol;
  final String? confirmingSymbol;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = math.min(size.width, size.height) * .39;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = const Color(0xFFB998FF).withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final scale in [.25, .50, .75, 1.0]) {
      canvas.drawCircle(
        center,
        radius * scale,
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    final sweep = Paint()
      ..color = const Color(0xFFB998FF).withValues(alpha: .18)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        -math.pi / 2,
        math.pi / 4,
        false,
      )
      ..close();

    canvas.drawPath(path, sweep);

    canvas.drawCircle(
      center,
      35,
      Paint()..color = const Color(0xFF2A2039),
    );

    _drawCenteredText(
      canvas,
      center.translate(0, -6),
      'DUKE',
      13,
      FontWeight.w900,
      Colors.white,
    );

    _drawCenteredText(
      canvas,
      center.translate(0, 10),
      'AI',
      9,
      FontWeight.w700,
      Colors.white60,
    );

    if (results.isEmpty) return;

    final step = (math.pi * 2) / results.length;

    for (var i = 0; i < results.length; i++) {
      final result = results[i];

      final angle = (-math.pi / 2) + (step * i);

      final strength = .48 + (.45 * (result.score / 100));

      final point = Offset(
        center.dx + math.cos(angle) * radius * strength,
        center.dy + math.sin(angle) * radius * strength,
      );

      final isLocked = result.symbol == lockedSymbol;

      final isConfirming = result.symbol == confirmingSymbol;

      Color color;

      if (isLocked) {
        color = Colors.amberAccent;
      } else {
        switch (result.stableSignal) {
          case SignalSide.call:
            color = Colors.greenAccent;
            break;

          case SignalSide.put:
            color = Colors.redAccent;
            break;

          case SignalSide.wait:
            color = Colors.white54;
            break;
        }
      }

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      if (isConfirming) {
        canvas.drawCircle(
          point,
          14,
          accentPaint,
        );
      }

      canvas.drawCircle(
        point,
        isLocked ? 8 : 6,
        dotPaint,
      );

      if (isLocked) {
        canvas.drawCircle(
          point,
          13,
          Paint()
            ..color = color.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final labelOffset = Offset(
        point.dx,
        point.dy + (point.dy < center.dy ? -17 : 18),
      );

      _drawCenteredText(
        canvas,
        labelOffset,
        _shortSymbol(result.symbol),
        9,
        FontWeight.w800,
        Colors.white,
      );

      _drawCenteredText(
        canvas,
        labelOffset.translate(0, 11),
        '${result.score}',
        8,
        FontWeight.w700,
        color,
      );
    }
  }

  static String _shortSymbol(String value) {
    var result = value.replaceAll('_otc', ' OTC').replaceAll('_OTC', ' OTC');

    if (result.length > 11) {
      result = result.substring(0, 11);
    }

    return result;
  }

  static void _drawCenteredText(
    Canvas canvas,
    Offset center,
    String text,
    double fontSize,
    FontWeight weight,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _RadarPainter oldDelegate,
  ) {
    return true;
  }
}
