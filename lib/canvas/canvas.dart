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
  });

  final List<Widget> children;
  final CanvasController controller;
  final GridType gridType;

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
    if (event is PointerScrollEvent) {
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
    widget.controller.pan(details.focalPointDelta);

    final double scaleDelta = details.scale / _previousScale;
    if (scaleDelta != 1.0) {
      widget.controller.zoom(scaleDelta, details.localFocalPoint);
    }

    _previousScale = details.scale;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        behavior: HitTestBehavior.opaque,
        child: ClipRect(
          child: CanvasLayoutWidget(
            controller: widget.controller,
            gridType: widget.gridType,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
