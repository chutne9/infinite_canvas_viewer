import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_layout.dart';

class CanvasParentData extends ContainerBoxParentData<RenderBox> {
  Offset? position;
  Matrix4? finalTransform;
}

class CanvasItem extends ParentDataWidget<CanvasParentData> {
  final Offset position;

  const CanvasItem({super.key, required this.position, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is CanvasParentData);
    final parentData = renderObject.parentData as CanvasParentData;
    if (parentData.position != position) {
      parentData.position = position;
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => CanvasLayoutWidget;
}
