import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/controller.dart';
import '../core/selection_mode.dart';
import '../options/selection_options.dart';

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class ExitSelectionModeIntent extends Intent {
  const ExitSelectionModeIntent();
}

class ToggleSelectionIntent extends Intent {
  const ToggleSelectionIntent(this.index);
  final int index;
}

class ExtendSelectionIntent extends Intent {
  const ExtendSelectionIntent(this.index);
  final int index;
}

class SelectAllAction extends Action<SelectAllIntent> {
  SelectAllAction(this.controller, this.totalItems);

  final SelectionModeController controller;
  final int? totalItems;

  @override
  bool isEnabled(SelectAllIntent intent) {
    if (totalItems == null) return false;

    // Manual mode requires active state
    if (controller.options.behavior == SelectionBehavior.manual) {
      return controller.isActive;
    }

    // Auto modes work regardless of current state
    return true;
  }

  @override
  Object? invoke(SelectAllIntent intent) {
    if (!isEnabled(intent)) return null;

    final items = List.generate(totalItems!, (i) => i);
    controller.selectAll(items);
    return null;
  }
}

class ExitSelectionModeAction extends Action<ExitSelectionModeIntent> {
  ExitSelectionModeAction(this.controller);

  final SelectionModeController controller;

  @override
  bool isEnabled(ExitSelectionModeIntent intent) {
    return controller.isActive;
  }

  @override
  Object? invoke(ExitSelectionModeIntent intent) {
    if (!isEnabled(intent)) return null;

    controller.disable();
    return null;
  }
}

class ToggleSelectionAction extends Action<ToggleSelectionIntent> {
  ToggleSelectionAction(this.controller);

  final SelectionModeController controller;

  @override
  Object? invoke(ToggleSelectionIntent intent) {
    controller.toggleItem(intent.index);
    return null;
  }
}

class ExtendSelectionAction extends Action<ExtendSelectionIntent> {
  ExtendSelectionAction(this.controller);

  final SelectionModeController controller;

  @override
  Object? invoke(ExtendSelectionIntent intent) {
    final anchor = controller.getAnchor() ?? 0;
    controller.selectRange(anchor, intent.index);
    return null;
  }
}

// Configuration for keyboard shortcuts
class SelectionShortcutPreset {
  const SelectionShortcutPreset._(this.shortcuts);

  SelectionShortcutPreset.standard() : this._(_standardShortcuts);

  const SelectionShortcutPreset.none()
      : this._(const <LogicalKeySet, Intent>{});

  const SelectionShortcutPreset.custom(Map<LogicalKeySet, Intent> shortcuts)
      : this._(shortcuts);

  final Map<LogicalKeySet, Intent> shortcuts;

  static final Map<LogicalKeySet, Intent> _standardShortcuts = {
    // Select all
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),
    LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
        const SelectAllIntent(),

    // Exit selection mode
    LogicalKeySet(LogicalKeyboardKey.escape): const ExitSelectionModeIntent(),
  };
}

// Main shortcuts widget
class SelectionShortcuts extends StatefulWidget {
  const SelectionShortcuts({
    super.key,
    required this.child,
    this.config,
    this.totalItems,
  });

  /// Child widget
  final Widget child;

  /// Total number of items for "select all" operation
  final int? totalItems;

  /// Keyboard shortcut configuration.
  final SelectionShortcutPreset? config;

  /// Access SelectionShortcuts from the widget tree (nullable)
  static SelectionShortcuts? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<SelectionShortcuts>();
  }

  @override
  State<SelectionShortcuts> createState() => _SelectionShortcutsState();
}

class _SelectionShortcutsState extends State<SelectionShortcuts> {
  Map<Type, Action<Intent>> _buildActions(SelectionModeController controller) {
    return {
      SelectAllIntent: SelectAllAction(controller, widget.totalItems),
      ExitSelectionModeIntent: ExitSelectionModeAction(controller),
      ToggleSelectionIntent: ToggleSelectionAction(controller),
      ExtendSelectionIntent: ExtendSelectionAction(controller),
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config ?? SelectionShortcutPreset.standard();
    final shortcuts = config.shortcuts;

    if (shortcuts.isEmpty) {
      return widget.child;
    }

    final controller = SelectionMode.of(context);

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: _buildActions(controller),
        child: widget.child,
      ),
    );
  }
}
