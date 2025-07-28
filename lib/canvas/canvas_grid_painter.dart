import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Defines the type of grid to be rendered on the canvas.
enum GridType {
  /// Do not draw any grid.
  none,

  /// Draw a grid with lines.
  line,

  /// Draw a grid with dots at the intersections.
  dot,
}

abstract class GridPainter extends CustomPainter {
  final Matrix4 transform;
  final Rect visibleWorldRect;

  GridPainter({required this.transform, required this.visibleWorldRect});

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.visibleWorldRect != visibleWorldRect;
  }
}

class LineGridPainter extends GridPainter {
  final Paint _minorGridPaint = Paint()
    ..color = Colors.grey.withAlpha(77)
    ..strokeWidth = 0.5;

  final Paint _majorGridPaint = Paint()
    ..color = Colors.grey.withAlpha(128)
    ..strokeWidth = 1.0;

  LineGridPainter({required super.transform, required super.visibleWorldRect});

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
  bool shouldRepaint(covariant LineGridPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.visibleWorldRect != visibleWorldRect;
  }
}

class DotGridPainter extends GridPainter {
  final Paint _minorDotPaint = Paint()
    ..color = Colors.grey.withAlpha(77)
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;

  final Paint _majorDotPaint = Paint()
    ..color = Colors.grey.withAlpha(128)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;

  DotGridPainter({required super.transform, required super.visibleWorldRect});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transform.getMaxScaleOnAxis();
    const double majorGridStep = 30.0;
    const double minorGridStep = 30.0;

    canvas.save();
    canvas.transform(transform.storage);

    _drawGridDots(canvas, visibleWorldRect, majorGridStep, _majorDotPaint);

    final double minorStepOnScreen = minorGridStep * scale;
    if (minorStepOnScreen > 8.0) {
      _drawGridDots(
        canvas,
        visibleWorldRect,
        minorGridStep,
        _minorDotPaint,
        skipEvery: (majorGridStep / minorGridStep).round(),
      );
    }
    canvas.restore();
  }

  void _drawGridDots(
    Canvas canvas,
    Rect rect,
    double step,
    Paint paint, {
    int skipEvery = 0,
  }) {
    final double startX = (rect.left / step).floorToDouble() * step;
    final double startY = (rect.top / step).floorToDouble() * step;
    final List<double> points = [];

    for (int i = 0; startX + i * step < rect.right; i++) {
      if (skipEvery > 0 && i % skipEvery == 0) continue;
      final double x = startX + i * step;
      for (int j = 0; startY + j * step < rect.bottom; j++) {
        if (skipEvery > 0 && j % skipEvery == 0) continue;
        final double y = startY + j * step;
        points.addAll([x, y]);
      }
    }

    if (points.isNotEmpty) {
      canvas.drawRawPoints(
        PointMode.points,
        Float32List.fromList(points),
        paint,
      );
    }
  }
}
