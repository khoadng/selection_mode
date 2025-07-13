import 'package:flutter/material.dart';
import 'controller.dart';
import 'selection_mode.dart';

/// Generic builder for app bars that respond to selection mode state.
///
/// Provides maximum flexibility by allowing any PreferredSizeWidget to be returned
/// for both normal and selection modes.
class SelectionAppBarBuilder extends StatelessWidget
    implements PreferredSizeWidget {
  const SelectionAppBarBuilder({
    super.key,
    this.controller,
    required this.builder,
    this.preferredSize = const Size.fromHeight(kToolbarHeight),
  });

  /// The selection controller. If null, uses [SelectionMode.of(context)]
  final SelectionModeController? controller;

  /// Builder that receives selection state and should return a PreferredSizeWidget
  final PreferredSizeWidget Function(
    BuildContext context,
    SelectionModeController controller,
    bool isSelectionMode,
  ) builder;

  /// The preferred size for this app bar
  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) => builder(context, ctrl, ctrl.isActive),
    );
  }
}

/// Material Design app bar that adapts to selection mode.
///
/// Follows Material Design guidelines for selection mode with sensible defaults
/// while allowing customization of common elements.
class MaterialSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MaterialSelectionAppBar({
    super.key,
    this.controller,
    required this.child,
    this.selectionTitle,
    this.actions,
    this.onCancel,
    this.selectionBackgroundColor,
    this.selectionForegroundColor,
    this.selectionElevation,
    this.centerTitle,
  });

  /// The selection controller. If null, uses [SelectionMode.of(context)]
  final SelectionModeController? controller;

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
    final ctrl = controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) =>
          ctrl.isActive ? _buildSelectionAppBar(context, ctrl) : child,
    );
  }

  Widget _buildSelectionAppBar(
    BuildContext context,
    SelectionModeController ctrl,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: selectionTitle?.call(context, ctrl.selectedCount) ??
          Text('${ctrl.selectedCount} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onCancel ?? ctrl.disable,
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
