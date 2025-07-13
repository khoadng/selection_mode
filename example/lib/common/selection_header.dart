import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

class SelectionHeader extends StatelessWidget {
  const SelectionHeader({super.key, this.controller, this.child});

  final SelectionModeController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!ctrl.isActive) return const SizedBox.shrink();

        return SizedBox(height: kToolbarHeight, child: child);
      },
    );
  }
}
