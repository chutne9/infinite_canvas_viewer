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
  State<Editor> createState() => _CanvasState();
}

class _CanvasState extends State<Editor> {
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
      angle: 127,
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
