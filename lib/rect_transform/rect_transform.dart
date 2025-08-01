import 'package:flutter/material.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_item.dart';
import 'package:infinite_canvas_viewer/rect_transform/rect_transform_controller.dart';
import 'package:infinite_canvas_viewer/rect_transform/rect_transform_handles.dart';

class RectTransform extends StatefulWidget {
  const RectTransform({
    super.key,
    required this.child,
    this.bounds,
    this.position,
    this.angle = 0,
    this.scale,
    this.worldScale = 1,
    this.baseSize,
    this.strokeSize = 0.8,
    this.strokeHandleSize = 4,
    this.cornerSizerSize = 8,
    this.rotatorSize = 16,
    this.handleColor = Colors.blue,
    this.canMove = true,
    this.canRotate = true,
    this.canResize = true,
    this.onNewTransform,
    this.onNewBounds,
    this.onTransformEnd,
    this.onTapInside,
    this.onTapOutside,
  }) : assert(
         (bounds != null) ||
             (position != null && scale != null && baseSize != null),
         "You must provide either 'bounds' or the complete set of 'position', 'scale', and 'baseSize'.",
       ),
       assert(
         bounds == null ||
             (position == null && scale == null && baseSize == null),
         "You cannot provide 'bounds' and the set of ('position', 'scale', 'baseSize') simultaneously. 'bounds' is the preferred input.",
       );

  final Widget child;

  /// Define the transform by a bounding box.
  /// This is the preferred way if provided.
  final Rect? bounds;

  /// Define the transform by individual components.
  /// All three must be provided if `bounds` is null.
  final Offset? position;
  final Offset? scale;
  final Size? baseSize;

  /// The rotation angle in radians. Common to both input methods.
  final double angle;

  // Other properties
  final double worldScale;
  final double strokeSize;
  final double strokeHandleSize;
  final double cornerSizerSize;
  final double rotatorSize;
  final Color handleColor;
  final bool canMove;
  final bool canRotate;
  final bool canResize;
  final Function(Offset, double, Offset)? onNewTransform;
  final Function(Rect, double)? onNewBounds;
  final VoidCallback? onTransformEnd;
  final Function(PointerDownEvent)? onTapInside;
  final Function(PointerDownEvent)? onTapOutside;

  @override
  State<RectTransform> createState() => _RectTransformState();
}

class _RectTransformState extends State<RectTransform> {
  static const double kPadding = 120;

  final _controller = RectTransformController();
  final stackKey = GlobalKey();

  Offset? _center;
  Offset? _lastDragVector;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleRectTransformChanged);
    _updateControllerFromWidget();
  }

  @override
  void didUpdateWidget(RectTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bounds != oldWidget.bounds ||
        widget.position != oldWidget.position ||
        widget.scale != oldWidget.scale ||
        widget.baseSize != oldWidget.baseSize ||
        widget.angle != oldWidget.angle) {
      _updateControllerFromWidget();
    }
  }

  void _updateControllerFromWidget() {
    if (widget.bounds case final bounds?) {
      _controller.setTransform(
        bounds.topLeft,
        widget.angle,
        const Offset(1, 1),
        bounds.size,
      );
    } else {
      final width = widget.baseSize!.width * widget.scale!.dx;
      final height = widget.baseSize!.height * widget.scale!.dy;
      _controller.setTransform(
        widget.position!,
        widget.angle,
        widget.scale!,
        Size(width, height),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleRectTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleRectTransformChanged() {
    widget.onNewTransform?.call(
      _controller.position,
      _controller.angle,
      _controller.scale,
    );
    widget.onNewBounds?.call(_controller.bounds, _controller.angle);
  }

  Offset _getCenter() {
    final renderBox = stackKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localCenter = Offset(size.width / 2, size.height / 2);
    return renderBox.localToGlobal(localCenter);
  }

  void _move(Offset delta) {
    _controller.move(delta / widget.worldScale);
  }

  void _handleMoveEnd() {
    widget.onTransformEnd?.call();
  }

  void _onRotateStart(DragStartDetails details) {
    _center = _getCenter();
    _lastDragVector = details.globalPosition - _center!;
  }

  void _onRotateUpdate(DragUpdateDetails details) {
    if (_center == null || _lastDragVector == null) return;
    final currentDragVector = details.globalPosition - _center!;
    final angleDelta = currentDragVector.direction - _lastDragVector!.direction;
    if (angleDelta.abs() > 0.001) {
      _controller.rotate(angleDelta);
    }
    _lastDragVector = currentDragVector;
  }

  void _handleRotateEnd() {
    _center = null;
    _lastDragVector = null;
    widget.onTransformEnd?.call();
  }

  void _resize(Offset delta) {
    _controller.resize(delta / widget.worldScale);
  }

  void _handleResizeEnd() {
    _controller.endResize();
    widget.onTransformEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    final position = _controller.position;
    final angle = _controller.angle;
    final width = _controller.size.width;
    final height = _controller.size.height;

    final screenWidth = width * widget.worldScale + kPadding * 2;
    final screenHeight = height * widget.worldScale + kPadding * 2;

    return CanvasItem(
      position: Offset(
        position.dx * widget.worldScale - kPadding,
        position.dy * widget.worldScale - kPadding,
      ),
      child: TapRegion(
        onTapInside: (event) => widget.onTapInside?.call(event),
        onTapOutside: (event) => widget.onTapOutside?.call(event),
        child: Transform.rotate(
          angle: angle,
          child: SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Stack(
              clipBehavior: Clip.none,
              key: stackKey,
              children: [
                Positioned(
                  left: kPadding,
                  top: kPadding,
                  right: kPadding,
                  bottom: kPadding,
                  child: widget.child,
                ),
                if (widget.canMove || widget.canResize || widget.canRotate)
                  Positioned.fill(
                    child: RectTransformHandles(
                      canMove: widget.canMove,
                      canRotate: widget.canRotate,
                      canResize: widget.canResize,
                      rotatorSize: widget.rotatorSize,
                      cornerSizerSize: widget.cornerSizerSize,
                      strokeHandleSize: widget.strokeHandleSize,
                      strokeSize: widget.strokeSize,
                      padding: kPadding,
                      color: widget.handleColor,
                      onMove: _move,
                      onMoveEnd: _handleMoveEnd,
                      onResizeStart: _controller.startResize,
                      onResize: _resize,
                      onResizeEnd: _handleResizeEnd,
                      onRotateStart: _onRotateStart,
                      onRotate: _onRotateUpdate,
                      onRotateEnd: _handleRotateEnd,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
