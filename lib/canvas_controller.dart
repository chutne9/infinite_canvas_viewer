import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  static const double _minScale = 0.01;
  static const double _maxScale = 10.0;

  Matrix4 _transform = Matrix4.identity();

  Matrix4 get transform => _transform;

  set transform(Matrix4 newTransform) {
    if (_transform == newTransform) return;
    _transform = newTransform;
    notifyListeners();
  }

  /// Pans the canvas by a given delta.
  ///
  /// The [delta] is the amount to move the canvas in screen coordinates.
  void pan(Offset delta) {
    final translationMatrix = Matrix4.identity()..translate(delta.dx, delta.dy);
    transform = translationMatrix * _transform;
  }

  /// Zooms the canvas by a given scale delta, centered on a focal point.
  ///
  /// The [scaleDelta] is the multiplicative factor for the zoom.
  /// Values > 1.0 zoom in, values < 1.0 zoom out.
  ///
  /// The [focalPoint] is the point on the screen (e.g., cursor position)
  /// where the zoom should be centered.
  void zoom(double scaleDelta, Offset focalPoint) {
    final double currentScale = _transform.getMaxScaleOnAxis();
    double newScale = currentScale * scaleDelta;

    if (newScale < _minScale) {
      scaleDelta = _minScale / currentScale;
    } else if (newScale > _maxScale) {
      scaleDelta = _maxScale / currentScale;
    }

    if (scaleDelta == 1.0) return;

    final zoomMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scaleDelta, scaleDelta)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    transform = zoomMatrix * _transform;
  }
}
