import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_controller.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_grid_painter.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_layout.dart';

class InfiniteCanvasViewer extends StatefulWidget {
  const InfiniteCanvasViewer({
    super.key,
    required this.controller,
    required this.children,
    this.gridType = GridType.none,
    this.backgroundColor,
    this.canZoom = true,
    this.canPan = true,
    this.foregroundPainter,
  });

  final List<Widget> children;
  final CanvasController controller;
  final GridType gridType;
  final Color? backgroundColor;
  final bool canZoom;
  final bool canPan;
  final CustomPainter? foregroundPainter;

  @override
  State<InfiniteCanvasViewer> createState() => _InfiniteCanvasViewerState();
}

class _InfiniteCanvasViewerState extends State<InfiniteCanvasViewer>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();

  bool _isSpacePressed = false;
  bool _isLeftMouseDragging = false;
  bool _isMiddleMousePanning = false;

  Matrix4 _gestureStartMat = Matrix4.identity();
  Offset _gestureStartPosition = Offset.zero;
  Offset _gestureStartLocalPosition = Offset.zero;

  final double _dragZoomSensitivity = 0.002;
  final double _scrollZoomSensitivity = 0.001;

  @override
  void initState() {
    super.initState();
    widget.controller.setVsync(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (!widget.canPan) {
      return KeyEventResult.ignored;
    }

    final bool spacePressedCurrently = HardwareKeyboard.instance
        .isLogicalKeyPressed(LogicalKeyboardKey.space);

    if (_isSpacePressed != spacePressedCurrently) {
      widget.controller.stopAnimation();
      setState(() {
        _isSpacePressed = spacePressedCurrently;
      });
    }

    return _isSpacePressed ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  MouseCursor get _cursor {
    if (_isMiddleMousePanning) {
      return SystemMouseCursors.grabbing;
    }
    if (_isLeftMouseDragging) {
      return _isSpacePressed
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.zoomIn;
    }
    if (_isSpacePressed) {
      return SystemMouseCursors.grab;
    }
    return MouseCursor.defer;
  }

  void _handleMouseScroll(PointerScrollEvent event) {
    if (!widget.canZoom) return;

    widget.controller.stopAnimation();
    final double scaleDelta =
        1.0 - event.scrollDelta.dy * _scrollZoomSensitivity;
    widget.controller.zoom(scaleDelta, event.localPosition);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    if (event.buttons == kMiddleMouseButton && widget.canPan) {
      if (_isLeftMouseDragging) return;
      widget.controller.stopAnimation();
      setState(() {
        _isMiddleMousePanning = true;
        _gestureStartMat = widget.controller.transform.clone();
        _gestureStartPosition = event.position;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isMiddleMousePanning) {
      if (event.buttons & kMiddleMouseButton == 0) {
        setState(() => _isMiddleMousePanning = false);
        return;
      }
      final Offset delta = event.position - _gestureStartPosition;
      final panMatrix = Matrix4.identity()..translate(delta.dx, delta.dy);
      widget.controller.transform = panMatrix * _gestureStartMat;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isMiddleMousePanning && (event.buttons & kMiddleMouseButton) == 0) {
      setState(() => _isMiddleMousePanning = false);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_isMiddleMousePanning) {
      setState(() => _isMiddleMousePanning = false);
    }
    if (_isLeftMouseDragging) {
      setState(() => _isLeftMouseDragging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      autofocus: true,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            _handleMouseScroll(pointerSignal);
          }
        },
        child: MouseRegion(
          cursor: _cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              if (_isMiddleMousePanning) return;
              if (!_isSpacePressed &&
                  details.kind != PointerDeviceKind.trackpad) {
                return;
              }
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }
              widget.controller.stopAnimation();
              setState(() {
                _isLeftMouseDragging = true;
                _gestureStartMat = widget.controller.transform.clone();
                _gestureStartPosition = details.globalPosition;
                _gestureStartLocalPosition = details.localPosition;
              });
            },
            onPanUpdate: (details) {
              if (!_isLeftMouseDragging) return;

              if (_isSpacePressed) {
                if (!widget.canPan) return;
                final Offset delta =
                    details.globalPosition - _gestureStartPosition;
                final panMatrix = Matrix4.identity()
                  ..translate(delta.dx, delta.dy);
                widget.controller.transform = panMatrix * _gestureStartMat;
              } else {
                if (!widget.canZoom) return;
                final double dy =
                    details.globalPosition.dy - _gestureStartPosition.dy;
                double scaleFactor = 1 + dy * _dragZoomSensitivity;
                scaleFactor = max(0.01, scaleFactor);

                final double startScale = _gestureStartMat.getMaxScaleOnAxis();
                final double targetScale = startScale * scaleFactor;

                if (targetScale < CanvasController.minScale) {
                  scaleFactor = CanvasController.minScale / startScale;
                } else if (targetScale > CanvasController.maxScale) {
                  scaleFactor = CanvasController.maxScale / startScale;
                }

                final zoomMat = Matrix4.identity()
                  ..translate(
                    _gestureStartLocalPosition.dx,
                    _gestureStartLocalPosition.dy,
                  )
                  ..scale(scaleFactor)
                  ..translate(
                    -_gestureStartLocalPosition.dx,
                    -_gestureStartLocalPosition.dy,
                  );
                widget.controller.transform = zoomMat * _gestureStartMat;
              }
            },
            onPanEnd: (details) {
              if (!_isLeftMouseDragging) return;

              final bool wasPanning = _isSpacePressed;
              setState(() {
                _isLeftMouseDragging = false;
              });

              final Offset pixelsPerSecond = details.velocity.pixelsPerSecond;
              const double flingThreshold = 200.0;
              if (pixelsPerSecond.distance < flingThreshold) return;

              if (!wasPanning && widget.canZoom) {
                widget.controller.flingZoom(
                  pixelsPerSecond.dy,
                  _gestureStartLocalPosition,
                );
              }
            },
            onPanCancel: () {
              if (_isLeftMouseDragging) {
                setState(() => _isLeftMouseDragging = false);
              }
            },
            child: Container(
              color: widget.backgroundColor,
              child: ClipRect(
                child: CanvasControllerProvider(
                  controller: widget.controller,
                  child: CanvasLayoutWidget(
                    controller: widget.controller,
                    gridType: widget.gridType,
                    foregroundPainter: widget.foregroundPainter,
                    children: widget.children,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
