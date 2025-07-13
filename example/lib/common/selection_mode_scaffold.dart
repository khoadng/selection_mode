import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';
import 'selection_footer.dart';
import 'selection_header.dart';

class SelectionModeScaffold extends StatelessWidget {
  const SelectionModeScaffold({
    super.key,
    this.controller,
    this.onEnabledChanged,
    this.header,
    this.footer,
    required this.child,
  });

  final SelectionModeController? controller;
  final void Function(bool enabled)? onEnabledChanged;
  final Widget? header;
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionMode(
      controller: controller,
      onModeChanged: onEnabledChanged,
      child: Stack(
        children: [
          Column(
            children: [
              if (header != null) SelectionHeader(child: header),
              Expanded(child: child),
            ],
          ),
          if (footer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SelectionFooter(child: footer!),
            ),
        ],
      ),
    );
  }
}
