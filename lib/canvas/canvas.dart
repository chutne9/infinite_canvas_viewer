import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_controller.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_grid_painter.dart';
import 'package:infinite_canvas_viewer/canvas/canvas_layout.dart';

class InfiniteCanvasViewer extends StatefulWidget {
  const InfiniteCanvasViewer({
    super.key,
    required this.controller,
    required this.children,
    this.gridType = GridType.none,
    this.backgroundColor = const Color(0xFFFDFDFD),
    this.canZoom = true,
    this.canPan = true,
    this.foregroundPainter,
  });

  final List<Widget> children;
  final CanvasController controller;
  final GridType gridType;
  final Color backgroundColor;
  final bool canZoom;
  final bool canPan;
  final CustomPainter? foregroundPainter;

  @override
  State<InfiniteCanvasViewer> createState() => _InfiniteCanvasViewerState();
}

class _InfiniteCanvasViewerState extends State<InfiniteCanvasViewer> {
  double _previousScale = 1.0;

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && widget.canZoom) {
      const double zoomSensitivity = 200.0;
      final double scaleDelta = 1.0 - event.scrollDelta.dy / zoomSensitivity;
      final Offset focalPoint = event.localPosition;
      widget.controller.zoom(scaleDelta, focalPoint);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.canPan) {
      widget.controller.pan(details.focalPointDelta);
    }

    if (widget.canZoom) {
      final double scaleDelta = details.scale / _previousScale;
      if (scaleDelta != 1.0) {
        widget.controller.zoom(scaleDelta, details.localFocalPoint);
      }
      _previousScale = details.scale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          behavior: HitTestBehavior.opaque,
          child: ClipRect(
            child: CanvasLayoutWidget(
              controller: widget.controller,
              gridType: widget.gridType,
              foregroundPainter: widget.foregroundPainter,
              children: widget.children,
            ),
          ),
        ),
      ),
    );
  }
}
