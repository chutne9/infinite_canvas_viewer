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
    this.onTapOutside,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<Widget> children;
  final CanvasController controller;
  final GridType gridType;
  final Color? backgroundColor;
  final bool canZoom;
  final bool canPan;
  final CustomPainter? foregroundPainter;
  final VoidCallback? onTapOutside;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  @override
  State<InfiniteCanvasViewer> createState() => _InfiniteCanvasViewerState();
}

class _InfiniteCanvasViewerState extends State<InfiniteCanvasViewer>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();

  bool _isSpacePressed = false;
  bool _isLeftMouseDragging = false;
  bool _isMiddleMousePanning = false;
  bool _isTouchDevice = false;
  double _previousScale = 1.0;

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
      return KeyEventResult.ignored;
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
            onScaleStart: (details) {
              if (_isMiddleMousePanning) return;
              if (!_isSpacePressed &&
                  details.pointerCount == 1 &&
                  details.kind != PointerDeviceKind.trackpad &&
                  details.kind != PointerDeviceKind.touch) {
                return;
              }
              if (!_focusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_focusNode);
              }
              widget.controller.stopAnimation();
              setState(() {
                _isLeftMouseDragging = true;
                _isTouchDevice = details.kind == PointerDeviceKind.touch;
                _previousScale = 1.0;
                _gestureStartMat = widget.controller.transform.clone();
                _gestureStartPosition = details.localFocalPoint;
                _gestureStartLocalPosition = details.localFocalPoint;
              });
            },
            onScaleUpdate: (details) {
              if (!_isLeftMouseDragging) return;

              // Handle panning (single finger or space + mouse)
              if (widget.canPan) {
                // For touch devices, always pan with single finger
                // For desktop, only pan when space is pressed
                final bool shouldPan = _isSpacePressed || _isTouchDevice;
                if (shouldPan && details.pointerCount == 1) {
                  widget.controller.pan(details.focalPointDelta);
                }
              }

              // Handle zooming (pinch-to-zoom on mobile, scroll on desktop)
              if (widget.canZoom) {
                // Pinch-to-zoom for multi-touch on mobile devices
                if (details.pointerCount >= 2 && _isTouchDevice) {
                  final double scaleDelta = details.scale / _previousScale;
                  if (scaleDelta != 1.0) {
                    widget.controller.zoom(scaleDelta, details.localFocalPoint);
                  }
                  _previousScale = details.scale;
                }
                // Desktop zoom with mouse drag (when not pressing space)
                else if (details.pointerCount == 1 &&
                    !_isTouchDevice &&
                    !_isSpacePressed) {
                  final double dy = details.focalPointDelta.dy;
                  double scaleFactor = 1 + dy * _dragZoomSensitivity;
                  scaleFactor = max(0.01, scaleFactor);

                  final double startScale = _gestureStartMat
                      .getMaxScaleOnAxis();
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
              }
            },
            onScaleEnd: (details) {
              if (!_isLeftMouseDragging) return;

              final bool wasPanning = _isSpacePressed || _isTouchDevice;
              setState(() {
                _isLeftMouseDragging = false;
                _previousScale = 1.0;
              });

              // Handle fling for zoom on desktop
              if (!wasPanning && !_isTouchDevice && widget.canZoom) {
                final Offset pixelsPerSecond = details.velocity.pixelsPerSecond;
                const double flingThreshold = 200.0;
                if (pixelsPerSecond.distance < flingThreshold) return;

                widget.controller.flingZoom(
                  pixelsPerSecond.dy,
                  _gestureStartLocalPosition,
                );
              }
            },

            child: Container(
              color: widget.backgroundColor,
              child: ClipRect(
                child: Stack(
                  children: [
                    // Transparent gesture detector for canvas taps
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: widget.onTapOutside,
                        onDoubleTap: widget.onDoubleTap,
                        onLongPress: widget.onLongPress,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Canvas content
                    CanvasLayoutWidget(
                      controller: widget.controller,
                      gridType: widget.gridType,
                      foregroundPainter: widget.foregroundPainter,
                      children: widget.children,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
