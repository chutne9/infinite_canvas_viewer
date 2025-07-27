import 'package:flutter/material.dart';
import 'package:infinite_canvas_viewer/rect_transform/sizer.dart';

class RectTransformHandles extends StatelessWidget {
  const RectTransformHandles({
    super.key,
    required this.moveable,
    required this.rotatorSize,
    required this.cornerSizerSize,
    required this.strokeHandleSize,
    required this.strokeSize,
    required this.padding,
    this.onMove,
    this.onResizeStart,
    this.onResize,
    this.onResizeEnd,
    this.onRotateStart,
    this.onRotate,
    this.onRotateEnd,
  });

  final bool moveable;
  final double rotatorSize;
  final double cornerSizerSize;
  final double strokeHandleSize;
  final double strokeSize;
  final double padding;
  final Function(Offset)? onMove;
  final Function(Sizer)? onResizeStart;
  final Function(Offset)? onResize;
  final VoidCallback? onResizeEnd;
  final Function(DragStartDetails)? onRotateStart;
  final Function(DragUpdateDetails)? onRotate;
  final VoidCallback? onRotateEnd;

  Widget _buildMoveHandle(BuildContext context) {
    return moveable
        ? GestureDetector(
          onPanUpdate: (details) {
            onMove?.call(details.delta);
          },
        )
        : SizedBox.shrink();
  }

  Widget _buildEdgeResizeHandle(BuildContext context, Sizer sizer) {
    bool hasWidth = sizer == Sizer.left || sizer == Sizer.right;
    bool hasHeight = sizer == Sizer.top || sizer == Sizer.bottom;

    return GestureDetector(
      onPanStart: (details) {
        onResizeStart?.call(sizer);
      },
      onPanUpdate: (details) {
        onResize?.call(details.delta);
      },
      onPanEnd: (details) {
        onResizeEnd?.call();
      },
      child: MouseRegion(
        cursor: sizer.cursor,
        child: Container(
          alignment: sizer.alignment,
          width: hasWidth ? strokeHandleSize : null,
          height: hasHeight ? strokeHandleSize : null,
          child: Container(
            width: hasWidth ? strokeSize : null,
            height: hasHeight ? strokeSize : null,
            color: Colors.purple,
          ),
        ),
      ),
    );
  }

  Widget _buildCornerResizeHandle(BuildContext context, Sizer sizer) {
    return GestureDetector(
      onPanStart: (details) {
        onResizeStart?.call(sizer);
      },
      onPanUpdate: (details) {
        onResize?.call(details.delta);
      },
      onPanEnd: (details) {
        onResizeEnd?.call();
      },
      child: MouseRegion(
        cursor: sizer.cursor,
        child: Container(
          alignment: Alignment.center,
          width: cornerSizerSize,
          height: cornerSizerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.purple,
          ),
        ),
      ),
    );
  }

  Widget _buildRotatorHandle() {
    return GestureDetector(
      onPanStart: (details) => onRotateStart?.call(details),
      onPanUpdate: (details) => onRotate?.call(details),
      onPanEnd: (details) => onRotateEnd?.call(),
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        hitTestBehavior: HitTestBehavior.translucent,
        child: Container(
          width: rotatorSize,
          height: rotatorSize,
          decoration: BoxDecoration(shape: BoxShape.circle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cornerHandleOffset = padding - rotatorSize / 2 - cornerSizerSize / 3;
    return Stack(
      children: [
        Positioned(
          top: padding,
          left: padding,
          bottom: padding,
          right: padding,
          child: _buildMoveHandle(context),
        ),
        Positioned(
          top: padding,
          left: padding,
          right: padding,
          height: strokeHandleSize,
          child: _buildEdgeResizeHandle(context, Sizer.top),
        ),
        Positioned(
          bottom: padding,
          left: padding,
          right: padding,
          height: strokeHandleSize,
          child: _buildEdgeResizeHandle(context, Sizer.bottom),
        ),
        Positioned(
          top: padding,
          bottom: padding,
          left: padding,
          width: strokeHandleSize,
          child: _buildEdgeResizeHandle(context, Sizer.left),
        ),
        Positioned(
          top: padding,
          bottom: padding,
          right: padding,
          width: strokeHandleSize,
          child: _buildEdgeResizeHandle(context, Sizer.right),
        ),
        Positioned(
          top: cornerHandleOffset,
          left: cornerHandleOffset,
          width: rotatorSize,
          height: rotatorSize,
          child: Stack(
            children: [
              _buildRotatorHandle(),
              Align(
                alignment: Alignment.bottomRight,
                child: _buildCornerResizeHandle(context, Sizer.topLeft),
              ),
            ],
          ),
        ),
        Positioned(
          top: cornerHandleOffset,
          right: cornerHandleOffset,
          width: rotatorSize,
          height: rotatorSize,
          child: Stack(
            children: [
              _buildRotatorHandle(),
              Align(
                alignment: Alignment.bottomLeft,
                child: _buildCornerResizeHandle(context, Sizer.topRight),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: cornerHandleOffset,
          left: cornerHandleOffset,
          width: rotatorSize,
          height: rotatorSize,
          child: Stack(
            children: [
              _buildRotatorHandle(),
              Align(
                alignment: Alignment.topRight,
                child: _buildCornerResizeHandle(context, Sizer.bottomLeft),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: cornerHandleOffset,
          right: cornerHandleOffset,
          width: rotatorSize,
          height: rotatorSize,
          child: Stack(
            children: [
              _buildRotatorHandle(),
              _buildCornerResizeHandle(context, Sizer.bottomRight),
            ],
          ),
        ),
      ],
    );
  }
}
