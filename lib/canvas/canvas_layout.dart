import 'package:infinite_canvas_viewer/canvas/canvas_controller.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_grid_painter.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CanvasLayoutWidget extends MultiChildRenderObjectWidget {
  final CanvasController controller;
  final GridType gridType;

  const CanvasLayoutWidget({
    super.key,
    required this.controller,
    required super.children,
    this.gridType = GridType.none,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      CanvasLayoutRenderBox(controller: controller, gridType: gridType);

  @override
  void updateRenderObject(
    BuildContext context,
    CanvasLayoutRenderBox renderObject,
  ) {
    renderObject.controller = controller;
    renderObject.gridType = gridType;
  }
}

class CanvasLayoutRenderBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, CanvasParentData> {
  CanvasLayoutRenderBox({
    required CanvasController controller,
    required GridType gridType,
  }) : _controller = controller,
       _gridType = gridType {
    _controller.addListener(markNeedsLayout);
  }

  late Rect _visibleWorldRect;
  GridPainter? _gridPainter;
  Matrix4 get _transform => _controller.transform;

  CanvasController _controller;
  set controller(CanvasController newController) {
    if (_controller == newController) return;
    _controller.removeListener(markNeedsLayout);
    _controller = newController;
    _controller.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  GridType _gridType;
  set gridType(GridType gridType) {
    if (_gridType == gridType) return;
    _gridType = gridType;
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

    _gridPainter = createGridPainter(_controller.transform, _visibleWorldRect);

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
    context.canvas.save();
    context.canvas.clipRect(offset & size);
    _gridPainter?.paint(context.canvas, size);
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

  GridPainter? createGridPainter(Matrix4 transform, Rect rect) {
    switch (_gridType) {
      case GridType.line:
        return LineGridPainter(transform: transform, visibleWorldRect: rect);
      case GridType.dot:
        return DotGridPainter(transform: transform, visibleWorldRect: rect);
      case GridType.none:
        return null;
    }
  }
}
