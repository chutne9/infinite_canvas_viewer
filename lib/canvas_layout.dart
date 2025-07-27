import 'dart:typed_data';
import 'dart:ui';
import 'package:infinite_canvas_viewer/canvas_controller.dart';
import 'package:infinite_canvas_viewer/canvas_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CanvasLayoutWidget extends MultiChildRenderObjectWidget {
  final CanvasController controller;

  const CanvasLayoutWidget({
    super.key,
    required this.controller,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      CanvasLayoutRenderBox(controller: controller);

  @override
  void updateRenderObject(
    BuildContext context,
    CanvasLayoutRenderBox renderObject,
  ) => renderObject.controller = controller;
}

class CanvasLayoutRenderBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, CanvasParentData> {
  CanvasLayoutRenderBox({required CanvasController controller})
    : _controller = controller {
    _controller.addListener(markNeedsLayout);
  }

  CanvasController _controller;

  Matrix4 get _transform => _controller.transform;

  late Rect _visibleWorldRect;

  final Paint _minorGridPaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.3)
    ..strokeWidth = 0.5;

  final Paint _majorGridPaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.5)
    ..strokeWidth = 1.0;

  set controller(CanvasController newController) {
    if (_controller == newController) return;
    _controller.removeListener(markNeedsLayout);
    _controller = newController;
    _controller.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CanvasParentData) {
      child.parentData = CanvasParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    final inverseMatrix = Matrix4.inverted(_controller.transform);
    _visibleWorldRect = MatrixUtils.transformRect(
      inverseMatrix,
      Offset.zero & size,
    );

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as CanvasParentData;
      final childPosition = childParentData.position;

      childParentData.finalTransform = null;

      if (childPosition != null) {
        child.layout(const BoxConstraints(), parentUsesSize: true);

        final childWorldRect = Rect.fromLTWH(
          childPosition.dx,
          childPosition.dy,
          child.size.width,
          child.size.height,
        );

        if (_visibleWorldRect.overlaps(childWorldRect)) {
          childParentData.finalTransform = _transform.clone()
            ..translate(childPosition.dx, childPosition.dy);
          childParentData.offset = MatrixUtils.transformPoint(
            _transform,
            childPosition,
          );
        } else {
          childParentData.offset = const Offset(-99999, -99999);
        }
      } else {
        childParentData.offset = const Offset(-99999, -99999);
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final backgroundPaint = Paint()..color = const Color(0xFF212121);
    context.canvas.drawRect(offset & size, backgroundPaint);

    context.canvas.save();
    context.canvas.clipRect(offset & size);
    _paintGrid(context, offset);
    context.canvas.restore();

    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData as CanvasParentData;

      if (childParentData.finalTransform != null) {
        context.pushTransform(
          needsCompositing,
          offset,
          childParentData.finalTransform!,
          (PaintingContext context, Offset offset) {
            context.paintChild(child!, offset);
          },
        );
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData as CanvasParentData;

      if (childParentData.finalTransform != null) {
        final bool isHit = result.addWithPaintTransform(
          transform: childParentData.finalTransform,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            return child!.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsLayout);
    super.detach();
  }

  void _paintGrid(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final scale = _transform.getMaxScaleOnAxis();
    final visibleRect = _visibleWorldRect;

    const double majorGridStep = 200.0;
    const double minorGridStep = 50.0;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.transform(_transform.storage);

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
}
