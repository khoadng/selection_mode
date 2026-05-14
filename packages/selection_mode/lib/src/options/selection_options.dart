import 'package:flutter/widgets.dart';
import 'package:selection_model/selection_model.dart' as model;

import 'auto_scroll_options.dart';
import 'haptic_feedback.dart';

export 'package:selection_model/selection_model.dart'
    show
        HapticEvent,
        HapticResolver,
        SelectionBehavior,
        SelectionConstraints,
        TapAction,
        TapBehavior,
        TapCondition;

/// Configuration for drag selection behavior.
class DragSelectionOptions {
  const DragSelectionOptions({
    this.axis,
    this.delay,
  });

  /// Axis to constrain drag selection. If null, allows free dragging.
  final Axis? axis;

  /// Delay before starting drag selection, useful for preventing accidental drags.
  final Duration? delay;
}

/// Flutter selection behavior options.
class SelectionOptions extends model.SelectionOptions {
  const SelectionOptions({
    super.haptics = HapticFeedbackResolver.modeOnly,
    super.behavior = model.SelectionBehavior.autoEnable,
    super.tapBehavior,
    this.dragSelection,
    this.autoScroll = const SelectionAutoScrollOptions(),
    super.constraints,
  });

  /// Auto-scroll configuration for drag selection. If null, no auto-scroll is applied.
  final SelectionAutoScrollOptions? autoScroll;

  /// Drag selection options. If null, drag selection is disabled.
  final DragSelectionOptions? dragSelection;

  @override
  SelectionOptions copyWith({
    model.HapticResolver? haptics,
    model.SelectionBehavior? behavior,
    model.TapBehavior? tapBehavior,
    model.SelectionConstraints? constraints,
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
