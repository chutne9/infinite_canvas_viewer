A Flutter widget for creating an infinite, zoomable, and pannable canvas.

## Features

- **Infinite Canvas:** Pan and zoom infinitely in a 2D space.
- **Supported Gestures:** Supports pinch-to-zoom, two-finger pan for touch devices, and mouse scroll-wheel zoom/drag-to-pan for desktop.
- **Transform Widget:** Includes `RectTransform`, a wrapper that adds handles to any widget for moving, resizing, and rotating.

## Getting started

1.  Add the package to your `pubspec.yaml`:

    ```yaml
    dependencies:
      infinite_canvas_viewer: ^latest_version
    ```

2.  Install the package from your terminal:

    ```sh
    flutter pub get
    ```

3.  Import the package into your Dart file:

    ```dart
    import 'package:infinite_canvas_viewer/infinite_canvas_viewer.dart';
    ```

## Usage

The core of the package is the `InfiniteCanvasViewer` widget. You provide it with a `CanvasController` and a list of children. For interactive items that can be moved, resized, and rotated, wrap them in a `RectTransform` widget.

Here is a complete example of a simple editor with three colored blocks that can be manipulated on the canvas.

```dart
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:infinite_canvas_viewer/infinite_canvas_viewer.dart';

class Item extends Equatable {
  const Item({required this.bounds, required this.angle, required this.color});

  final Rect bounds;
  final double angle;
  final Color color;

  @override
  List<Object?> get props => [bounds, angle, color];

  Item copyWith({Rect? bounds, double? angle, Color? color}) {
    return Item(
      bounds: bounds ?? this.bounds,
      angle: angle ?? this.angle,
      color: color ?? this.color,
    );
  }
}

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final _controller = CanvasController();
  List<Item> items = [
    Item(bounds: Rect.fromLTWH(0, 0, 200, 100), angle: 0, color: Colors.red),
    Item(
      bounds: Rect.fromLTWH(100, 300, 150, 200),
      angle: 90,
      color: Colors.green,
    ),
    Item(
      bounds: Rect.fromLTWH(200, 400, 300, 200),
      angle: 45,
      color: Colors.blue,
    ),
  ];

  void _handleNewBounds(int index, Rect bounds, double angle) {
    final item = items[index].copyWith(bounds: bounds, angle: angle);
    setState(() {
      items = List.from(items);
      items[index] = item;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InfiniteCanvasViewer(
      controller: _controller,
      children: items
          .mapIndexed(
            (index, item) => RectTransform(
              bounds: item.bounds,
              angle: item.angle,
              onNewBounds: (bounds, angle) =>
                  _handleNewBounds(index, bounds, angle),
              child: Container(color: item.color),
            ),
          )
          .toList(),
    );
  }
}
```

## Additional information

This package is still in development. All feedback and contributions are welcomed!

-   **File an issue:** If you encounter a bug or have a feature request, please file an issue on our [GitHub repository](https://github.com/your-repo/infinite_canvas_viewer/issues).
-   **Contribute:** I am happy to accept pull requests. Please feel free to fork the repository and submit your changes.
-   **Learn more:** For more detailed examples, check out the `/example` directory in the package repository.