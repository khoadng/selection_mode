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

/// Conditions when tap behavior should be active
enum TapCondition {
  /// Only when selection mode is active
  active,

  /// Only when selection mode is inactive
  inactive,

  /// Regardless of selection mode state
  both,
}

/// Actions to perform on tap
enum TapAction {
  /// Add/remove item from selection
  toggle,

  /// Replace entire selection with tapped item
  replace,
}

/// Tap behavior configuration for selectable items
class TapBehavior {
  const TapBehavior({
    required this.when,
    required this.action,
  });

  /// The condition when tap behavior should be active
  final TapCondition? when;

  /// The action to perform on tap
  final TapAction? action;

  /// Toggle items only when selection mode is active (default)
  static const toggleWhenSelecting = TapBehavior(
    when: TapCondition.active,
    action: TapAction.toggle,
  );

  /// Replace selection regardless of mode state
  static const alwaysReplace = TapBehavior(
    when: TapCondition.both,
    action: TapAction.replace,
  );

  /// Toggle items regardless of mode state
  static const alwaysToggle = TapBehavior(
    when: TapCondition.both,
    action: TapAction.toggle,
  );

  /// Replace selection only when inactive
  static const replaceWhenInactive = TapBehavior(
    when: TapCondition.inactive,
    action: TapAction.replace,
  );

  /// Disable tap handling completely
  static const disabled = TapBehavior(
    when: null,
    action: null,
  );
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
    this.tapBehavior,
    this.dragSelection,
    this.autoScroll = const SelectionAutoScrollOptions(),
    this.constraints,
  });

  /// Haptic feedback resolver. If null, no haptic feedback is provided.
  final HapticResolver? haptics;

  /// Selection mode behavior pattern
  final SelectionBehavior behavior;

  /// Tap behavior for selectable items. If null, defaults to toggleWhenSelecting.
  final TapBehavior? tapBehavior;

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
