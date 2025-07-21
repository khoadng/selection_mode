import 'package:flutter/material.dart';

import 'controller.dart';
import 'selection_mode.dart';

/// A widget that provides selection state
class SelectionConsumer extends StatelessWidget {
  const SelectionConsumer({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget Function(
    BuildContext context,
    SelectionModeController controller,
    Widget? child,
  ) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = SelectionMode.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => builder(
        context,
        controller,
        child,
      ),
      child: child,
    );
  }
}
