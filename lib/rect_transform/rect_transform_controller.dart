import 'dart:math';
import 'package:flutter/material.dart';
import 'package:infinite_canvas_viewer/rect_transform/sizer.dart';

class RectTransformController extends ChangeNotifier {
  Rect _bounds = Rect.zero;
  double _rotation = 0;
  Size _originalSize = Size.zero;
  Sizer? _activeSizer;

  Rect get bounds => _bounds;

  Offset get position => Offset(_bounds.left, _bounds.top);

  double get angle => _rotation;

  Offset get scale => Offset(
    _bounds.width / _originalSize.width,
    _bounds.height / _originalSize.height,
  );

  Size get size => Size(_bounds.width, bounds.height);

  void setTransform(Offset position, double angle, Offset scale, Size size) {
    _bounds = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    _rotation = angle;
    _originalSize = Size(_bounds.width / scale.dx, _bounds.height / scale.dy);
  }

  void move(Offset delta) {
    if (delta == Offset.zero) {
      return;
    }
    final rotatedDelta = _rotateVector(delta, _rotation);
    final currentBounds = _bounds;
    _bounds = Rect.fromLTWH(
      currentBounds.left + rotatedDelta.dx,
      currentBounds.top + rotatedDelta.dy,
      currentBounds.width,
      currentBounds.height,
    );
    notifyListeners();
  }

  void startResize(Sizer sizer) {
    _activeSizer = sizer;
  }

  void endResize() {
    _activeSizer = null;
  }

  void resize(Offset localDelta) {
    final sizer = _activeSizer;
    if (sizer == null) return;

    final oldBounds = _bounds;
    final growth = sizer.growthDirection;

    final dw = localDelta.dx * growth.dx;
    final dh = localDelta.dy * growth.dy;

    var newWidth = oldBounds.width + dw;
    var newHeight = oldBounds.height + dh;

    final localCenterShift = Offset(dw * growth.dx / 2, dh * growth.dy / 2);
    final rotatedCenterShift = _rotateVector(localCenterShift, _rotation);
    final newCenter = oldBounds.center + rotatedCenterShift;

    Sizer newSizer = sizer;
    if (newWidth < 0) {
      newWidth = -newWidth;
      newSizer = newSizer.flipHorizontally();
    }
    if (newHeight < 0) {
      newHeight = -newHeight;
      newSizer = newSizer.flipVertically();
    }
    _activeSizer = newSizer;

    _bounds = Rect.fromCenter(
      center: newCenter,
      width: newWidth,
      height: newHeight,
    );

    notifyListeners();
  }

  void rotate(double angleDelta) {
    _rotation += angleDelta;
    notifyListeners();
  }

  Offset _rotateVector(Offset vector, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    final x = vector.dx * cosA - vector.dy * sinA;
    final y = vector.dx * sinA + vector.dy * cosA;
    return Offset(x, y);
  }
}
