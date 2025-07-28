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
    final visibleRect = visibleWorldRect;

    const double majorGridStep = 200.0;
    const double minorGridStep = 50.0;

    canvas.save();
    canvas.transform(transform.storage);

    // Major grid lines
    final double startXMajor =
        (visibleRect.left / majorGridStep).floorToDouble() * majorGridStep;
    final double startYMajor =
        (visibleRect.top / majorGridStep).floorToDouble() * majorGridStep;

    int majorLineCount = 0;
    for (double x = startXMajor; x < visibleRect.right; x += majorGridStep) {
      majorLineCount++;
    }
    for (double y = startYMajor; y < visibleRect.bottom; y += majorGridStep) {
      majorLineCount++;
    }

    if (majorLineCount > 0) {
      final majorPoints = Float32List(majorLineCount * 4);
      int index = 0;
      for (double x = startXMajor; x < visibleRect.right; x += majorGridStep) {
        majorPoints[index++] = x;
        majorPoints[index++] = visibleRect.top;
        majorPoints[index++] = x;
        majorPoints[index++] = visibleRect.bottom;
      }
      for (double y = startYMajor; y < visibleRect.bottom; y += majorGridStep) {
        majorPoints[index++] = visibleRect.left;
        majorPoints[index++] = y;
        majorPoints[index++] = visibleRect.right;
        majorPoints[index++] = y;
      }
      canvas.drawRawPoints(PointMode.lines, majorPoints, _majorGridPaint);
    }

    // Minor grid lines
    final double minorStepOnScreen = minorGridStep * scale;
    if (minorStepOnScreen > 5.0) {
      final double startXMinor =
          (visibleRect.left / minorGridStep).floorToDouble() * minorGridStep;
      final double startYMinor =
          (visibleRect.top / minorGridStep).floorToDouble() * minorGridStep;

      int minorLineCount = 0;
      for (double x = startXMinor; x < visibleRect.right; x += minorGridStep) {
        if ((x % majorGridStep).abs() > 0.01) minorLineCount++;
      }
      for (double y = startYMinor; y < visibleRect.bottom; y += minorGridStep) {
        if ((y % majorGridStep).abs() > 0.01) minorLineCount++;
      }

      if (minorLineCount > 0) {
        final minorPoints = Float32List(minorLineCount * 4);
        int index = 0;
        for (
          double x = startXMinor;
          x < visibleRect.right;
          x += minorGridStep
        ) {
          if ((x % majorGridStep).abs() < 0.01) continue;
          minorPoints[index++] = x;
          minorPoints[index++] = visibleRect.top;
          minorPoints[index++] = x;
          minorPoints[index++] = visibleRect.bottom;
        }
        for (
          double y = startYMinor;
          y < visibleRect.bottom;
          y += minorGridStep
        ) {
          if ((y % majorGridStep).abs() < 0.01) continue;
          minorPoints[index++] = visibleRect.left;
          minorPoints[index++] = y;
          minorPoints[index++] = visibleRect.right;
          minorPoints[index++] = y;
        }
        canvas.drawRawPoints(PointMode.lines, minorPoints, _minorGridPaint);
      }
    }

    canvas.restore();
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
