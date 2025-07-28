import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Matrix4 transform;
  final Rect visibleWorldRect;

  final Paint _minorGridPaint = Paint()
    ..color = Colors.grey.withAlpha(77)
    ..strokeWidth = 0.5;

  final Paint _majorGridPaint = Paint()
    ..color = Colors.grey.withAlpha(128)
    ..strokeWidth = 1.0;

  GridPainter({required this.transform, required this.visibleWorldRect});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transform.getMaxScaleOnAxis();

    const double majorGridStep = 200.0;
    const double minorGridStep = 50.0;

    canvas.save();
    canvas.transform(transform.storage);

    _drawGridLines(canvas, visibleWorldRect, majorGridStep, _majorGridPaint);

    final double minorStepOnScreen = minorGridStep * scale;
    if (minorStepOnScreen > 5.0) {
      _drawGridLines(
        canvas,
        visibleWorldRect,
        minorGridStep,
        _minorGridPaint,
        skipEvery: (majorGridStep / minorGridStep).round(),
      );
    }

    canvas.restore();
  }

  void _drawGridLines(
    Canvas canvas,
    Rect rect,
    double step,
    Paint paint, {
    int skipEvery = 0,
  }) {
    final double startX = (rect.left / step).floorToDouble() * step;
    final double startY = (rect.top / step).floorToDouble() * step;

    final List<double> points = [];
    int lineNum = 0;

    for (double x = startX; x < rect.right; x += step) {
      lineNum++;
      if (skipEvery > 0 && lineNum % skipEvery == 1) continue;
      points.addAll([x, rect.top, x, rect.bottom]);
    }

    lineNum = 0;
    for (double y = startY; y < rect.bottom; y += step) {
      lineNum++;
      if (skipEvery > 0 && lineNum % skipEvery == 1) continue;
      points.addAll([rect.left, y, rect.right, y]);
    }

    if (points.isNotEmpty) {
      canvas.drawRawPoints(
        PointMode.lines,
        Float32List.fromList(points),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.visibleWorldRect != visibleWorldRect;
  }
}
