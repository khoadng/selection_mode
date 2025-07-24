import 'package:flutter/material.dart';
import '../core/controller.dart';
import 'selection_consumer.dart';

/// Material Design app bar that adapts to selection mode.
class MaterialSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MaterialSelectionAppBar({
    super.key,
    required this.child,
    this.selectionTitle,
    this.actions,
    this.onCancel,
    this.selectionBackgroundColor,
    this.selectionForegroundColor,
    this.selectionElevation,
    this.centerTitle,
  });

  /// The app bar to show when not in selection mode
  final AppBar child;

  /// Custom title builder for selection mode. Defaults to "${count} selected"
  final Widget Function(BuildContext context, int selectedCount)?
      selectionTitle;

  /// Actions to show in selection mode
  final List<Widget>? actions;

  /// Callback when cancel/close is pressed. Defaults to disabling selection mode
  final VoidCallback? onCancel;

  /// Background color for selection mode. Defaults to theme's surface variant
  final Color? selectionBackgroundColor;

  /// Foreground color for selection mode. Defaults to theme's on-surface variant
  final Color? selectionForegroundColor;

  /// Elevation for selection mode app bar
  final double? selectionElevation;

  /// Whether to center the title in selection mode
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) => controller.isActive
          ? _buildSelectionAppBar(context, controller)
          : child,
    );
  }

  Widget _buildSelectionAppBar(
    BuildContext context,
    SelectionModeController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: selectionTitle?.call(context, controller.selection.length) ??
          Text('${controller.selection.length} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onCancel ?? controller.disable,
      ),
      actions: actions,
      backgroundColor:
          selectionBackgroundColor ?? colorScheme.surfaceContainerHigh,
      foregroundColor: selectionForegroundColor ?? colorScheme.onSurface,
      elevation: selectionElevation,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => child.preferredSize;
}
