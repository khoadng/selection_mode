import 'package:flutter/material.dart';

import 'selection_consumer.dart';

class DragSelectionIgnore extends StatefulWidget {
  const DragSelectionIgnore({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<DragSelectionIgnore> createState() => _DragSelectionIgnoreState();
}

class _DragSelectionIgnoreState extends State<DragSelectionIgnore> {
  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) => IgnorePointer(
        ignoring: controller.isDragInProgress,
        child: widget.child,
      ),
    );
  }
}
