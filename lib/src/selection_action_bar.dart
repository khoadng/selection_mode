import 'package:flutter/material.dart';
import 'selection_mode.dart';

class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0,
    this.height,
    this.maxWidth,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8,
    this.animated = true,
  });

  final List<Widget> children;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final double? height;
  final double? maxWidth;

  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  final bool animated;

  @override
  Widget build(BuildContext context) {
    final controller = SelectionMode.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive || children.isEmpty) {
          return const SizedBox.shrink();
        }

        final content = _buildContent(context);

        if (!animated) return content;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1.0,
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = _buildRow();

    if (height != null) {
      content = SizedBox(height: height, child: content);
    }

    Widget actionBar = Material(
      color: backgroundColor ?? theme.colorScheme.surface,
      borderRadius: borderRadius,
      elevation: elevation,
      child: Container(
        width: double.infinity,
        constraints:
            maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
        margin: margin,
        padding: padding,
        child: content,
      ),
    );

    return actionBar;
  }

  Widget _buildRow() {
    if (children.length == 1) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [Expanded(child: children.first)],
      );
    }

    final widgets = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        widgets.add(SizedBox(width: spacing));
      }
      widgets.add(Expanded(child: children[i]));
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: widgets,
    );
  }
}
