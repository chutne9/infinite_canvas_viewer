import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  static const double minScale = 0.1;
  static const double maxScale = 4.0;

  Matrix4 _transform = Matrix4.identity();
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;
  final TickerProvider? vsync;

  CanvasController({this.vsync});

  Matrix4 get transform => _transform;

  set transform(Matrix4 newTransform) {
    if (_animationController?.isAnimating ?? false) {
      _animationController!.stop();
    }
    _setTransform(newTransform);
  }

  void _setTransform(Matrix4 newTransform) {
    if (_transform == newTransform) return;
    _transform = newTransform;
    notifyListeners();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void pan(Offset delta) {
    final translationMatrix = Matrix4.identity()..translate(delta.dx, delta.dy);
    transform = translationMatrix * _transform;
  }

  void zoom(double scaleDelta, Offset focalPoint) {
    final double currentScale = _transform.getMaxScaleOnAxis();
    double newScale = currentScale * scaleDelta;

    if (newScale < minScale) {
      scaleDelta = minScale / currentScale;
    } else if (newScale > maxScale) {
      scaleDelta = maxScale / currentScale;
    }

    if (scaleDelta == 1.0) return;

    final zoomMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scaleDelta, scaleDelta)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    transform = zoomMatrix * _transform;
  }

  void animateTo(
    Matrix4 target, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    if (vsync case final vsync?) {
      _animationController?.stop();
      _animationController ??= AnimationController(vsync: vsync)
        ..addListener(_onAnimate);
      _animationController!.duration = duration;

      _animation = Matrix4Tween(
        begin: _transform,
        end: target,
      ).animate(CurvedAnimation(parent: _animationController!, curve: curve));

      _animationController!
        ..reset()
        ..forward();
    }
  }

  void _onAnimate() {
    if (_animation case final animation?) {
      _setTransform(animation.value);
    }
  }
}
