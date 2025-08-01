import 'package:flutter/widgets.dart';

import 'auto_scroll_options.dart';
import 'haptic_feedback.dart';
import 'selection_constraints.dart';

/// Selection mode behavior patterns
enum SelectionBehavior {
  /// Manual enable/disable only - no automatic behavior
  manual,

  /// Auto enable on first selection + auto disable when empty
  autoToggle,

  /// Auto enable on first selection + manual disable (default)
  autoEnable,
}

/// Tap behavior for selectable items
enum TapBehavior {
  /// Add/remove item from selection (default)
  toggle,

  /// Replace entire selection with tapped item
  replace,

  /// Disable tap handling
  none,
}

/// Configuration for drag selection behavior
class DragSelectionOptions {
  const DragSelectionOptions({
    this.axis,
    this.delay,
  });

  /// Axis to constrain drag selection. If null, allows free dragging.
  final Axis? axis;

  /// Delay before starting drag selection, useful for preventing accidental drags
  final Duration? delay;
}

/// Configuration options for SelectionMode behavior
class SelectionOptions {
  const SelectionOptions({
    this.haptics = HapticFeedbackResolver.modeOnly,
    this.behavior = SelectionBehavior.autoEnable,
    this.tapBehavior = TapBehavior.toggle,
    this.dragSelection,
    this.autoScroll = const SelectionAutoScrollOptions(),
    this.constraints,
  });

  /// Haptic feedback resolver. If null, no haptic feedback is provided.
  final HapticResolver? haptics;

  /// Selection mode behavior pattern
  final SelectionBehavior behavior;

  /// Tap behavior for selectable items
  final TapBehavior tapBehavior;

  /// Selection constraints. If null, no constraints are applied.
  final SelectionConstraints? constraints;

  /// Auto-scroll configuration for drag selection. If null, no auto-scroll is applied.
  final SelectionAutoScrollOptions? autoScroll;

  /// Drag selection options. If null, drag selection is disabled.
  final DragSelectionOptions? dragSelection;

  SelectionOptions copyWith({
    HapticResolver? haptics,
    SelectionBehavior? behavior,
    TapBehavior? tapBehavior,
    SelectionConstraints? constraints,
    SelectionAutoScrollOptions? autoScroll,
    DragSelectionOptions? dragSelection,
  }) {
    return SelectionOptions(
      haptics: haptics ?? this.haptics,
      behavior: behavior ?? this.behavior,
      tapBehavior: tapBehavior ?? this.tapBehavior,
      constraints: constraints ?? this.constraints,
      autoScroll: autoScroll ?? this.autoScroll,
      dragSelection: dragSelection ?? this.dragSelection,
    );
  }
}
