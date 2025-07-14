import 'package:flutter/material.dart';
import 'controller.dart';
import 'selection_mode.dart';

class SelectionStatusBar extends StatelessWidget {
  const SelectionStatusBar({
    super.key,
    this.leftActions = const [],
    this.rightActions = const [],
    this.statusBuilder,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.height,
    this.animated = true,
  });

  final List<Widget> leftActions;
  final List<Widget> rightActions;
  final Widget Function(BuildContext context, int selectedCount)? statusBuilder;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double? height;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final ctrl = SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!ctrl.isActive) {
          return const SizedBox.shrink();
        }

        final content = _buildContent(context, ctrl);

        if (!animated) return content;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: Offset.zero,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, SelectionModeController controller) {
    final theme = Theme.of(context);

    final status = statusBuilder?.call(context, controller.selection.length) ??
        Text(
          controller.selection.length == 1
              ? '1 Selected'
              : '${controller.selection.length} Selected',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        );

    Widget content = Row(
      children: [
        // Left actions
        ...leftActions,

        // Status in center
        Expanded(child: Center(child: status)),

        // Right actions
        ...rightActions,
      ],
    );

    if (height != null) {
      content = SizedBox(height: height, child: content);
    }

    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: padding,
        color: backgroundColor ?? theme.colorScheme.surface,
        child: content,
      ),
    );
  }
}
