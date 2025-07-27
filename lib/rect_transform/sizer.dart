import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

sealed class Sizer {
  final Alignment alignment;
  final EdgeInsets insets;
  final Offset growthDirection;
  final SystemMouseCursor cursor;

  const Sizer(this.alignment, this.insets, this.growthDirection, this.cursor);

  Sizer flipHorizontally();

  Sizer flipVertically();

  static const left = LeftSizer();
  static const right = RightSizer();
  static const top = TopSizer();
  static const bottom = BottomSizer();
  static const topLeft = TopLeftSizer();
  static const topRight = TopRightSizer();
  static const bottomLeft = BottomLeftSizer();
  static const bottomRight = BottomRightSizer();
}

class LeftSizer extends Sizer {
  const LeftSizer()
    : super(
        Alignment.centerLeft,
        const EdgeInsets.only(left: 1),
        const Offset(-1, 0),
        SystemMouseCursors.resizeLeftRight,
      );
  @override
  Sizer flipHorizontally() => Sizer.right;
  @override
  Sizer flipVertically() => this;
}

class RightSizer extends Sizer {
  const RightSizer()
    : super(
        Alignment.centerRight,
        const EdgeInsets.only(right: 1),
        const Offset(1, 0),
        SystemMouseCursors.resizeLeftRight,
      );
  @override
  Sizer flipHorizontally() => Sizer.left;
  @override
  Sizer flipVertically() => this;
}

class TopSizer extends Sizer {
  const TopSizer()
    : super(
        Alignment.topCenter,
        const EdgeInsets.only(top: 1),
        const Offset(0, -1),
        SystemMouseCursors.resizeUpDown,
      );
  @override
  Sizer flipHorizontally() => this;
  @override
  Sizer flipVertically() => Sizer.bottom;
}

class BottomSizer extends Sizer {
  const BottomSizer()
    : super(
        Alignment.bottomCenter,
        const EdgeInsets.only(bottom: 1),
        const Offset(0, 1),
        SystemMouseCursors.resizeUpDown,
      );
  @override
  Sizer flipHorizontally() => this;
  @override
  Sizer flipVertically() => Sizer.top;
}

class TopLeftSizer extends Sizer {
  const TopLeftSizer()
    : super(
        Alignment.topLeft,
        const EdgeInsets.only(top: 1, left: 1),
        const Offset(-1, -1),
        SystemMouseCursors.resizeUpLeftDownRight,
      );
  @override
  Sizer flipHorizontally() => Sizer.topRight;
  @override
  Sizer flipVertically() => Sizer.bottomLeft;
}

class TopRightSizer extends Sizer {
  const TopRightSizer()
    : super(
        Alignment.topRight,
        const EdgeInsets.only(top: 1, right: 1),
        const Offset(1, -1),
        SystemMouseCursors.resizeUpRightDownLeft,
      );
  @override
  Sizer flipHorizontally() => Sizer.topLeft;
  @override
  Sizer flipVertically() => Sizer.bottomRight;
}

class BottomLeftSizer extends Sizer {
  const BottomLeftSizer()
    : super(
        Alignment.bottomLeft,
        const EdgeInsets.only(bottom: 1, left: 1),
        const Offset(-1, 1),
        SystemMouseCursors.resizeUpRightDownLeft,
      );
  @override
  Sizer flipHorizontally() => Sizer.bottomRight;
  @override
  Sizer flipVertically() => Sizer.topLeft;
}

class BottomRightSizer extends Sizer {
  const BottomRightSizer()
    : super(
        Alignment.bottomRight,
        const EdgeInsets.only(bottom: 1, right: 1),
        const Offset(1, 1),
        SystemMouseCursors.resizeUpLeftDownRight,
      );
  @override
  Sizer flipHorizontally() => Sizer.bottomLeft;
  @override
  Sizer flipVertically() => Sizer.topRight;
}
