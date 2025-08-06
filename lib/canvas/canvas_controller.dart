import 'dart:math';
import 'package:flutter/material.dart';

class CanvasController extends ChangeNotifier {
  static const double minScale = 0.1;
  static const double maxScale = 50.0;

  Matrix4 _transform = Matrix4.identity();
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;
  TickerProvider? _vsync;

  CanvasController();

  void setVsync(TickerProvider vsync) {
    _vsync = vsync;
  }

  Matrix4 get transform => _transform;

  set transform(Matrix4 newTransform) {
    stopAnimation();
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

  void stopAnimation() {
    if (_animationController?.isAnimating ?? false) {
      _animationController!.stop();
    }
  }

  void pan(Offset delta) {
    if (delta == Offset.zero) return;
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

  void flingZoom(double velocity, Offset focalPoint) {
    if (_vsync == null || velocity.abs() < 1.0) return;

    const double flingZoomSensitivity = 0.0005;
    double targetScaleFactor = 1.0 + velocity * flingZoomSensitivity;
    targetScaleFactor = max(0.01, targetScaleFactor);

    final double currentScale = _transform.getMaxScaleOnAxis();
    final double targetScale = currentScale * targetScaleFactor;

    if (targetScale < minScale) {
      targetScaleFactor = minScale / currentScale;
    } else if (targetScale > maxScale) {
      targetScaleFactor = maxScale / currentScale;
    }

    final targetZoomMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(targetScaleFactor, targetScaleFactor)
      ..translate(-focalPoint.dx, -focalPoint.dy);

    final Matrix4 targetMatrix = targetZoomMatrix * _transform;

    animateTo(
      targetMatrix,
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
    );
  }

  void animateTo(
    Matrix4 target, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    if (_vsync == null) {
      transform = target;
      return;
    }

    _animationController?.stop();
    _animationController ??= AnimationController(vsync: _vsync!)
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

  void _onAnimate() {
    if (_animation != null) {
      _setTransform(_animation!.value);
    }
  }
}
