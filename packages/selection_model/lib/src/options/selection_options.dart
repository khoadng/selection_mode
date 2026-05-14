import 'haptic_feedback.dart';
import 'selection_constraints.dart';

/// Selection mode behavior patterns.
enum SelectionBehavior {
  /// Manual enable/disable only.
  manual,

  /// Auto enable on first selection and auto disable when empty.
  autoToggle,

  /// Auto enable on first selection and manual disable.
  autoEnable,
}

/// Conditions when tap behavior should be active.
enum TapCondition {
  active,
  inactive,
  both,
}

/// Actions to perform on tap.
enum TapAction {
  toggle,
  replace,
}

/// Tap behavior configuration for selectable items.
class TapBehavior {
  const TapBehavior({
    required this.when,
    required this.action,
  });

  final TapCondition? when;
  final TapAction? action;

  static const toggleWhenSelecting = TapBehavior(
    when: TapCondition.active,
    action: TapAction.toggle,
  );

  static const alwaysReplace = TapBehavior(
    when: TapCondition.both,
    action: TapAction.replace,
  );

  static const alwaysToggle = TapBehavior(
    when: TapCondition.both,
    action: TapAction.toggle,
  );

  static const replaceWhenInactive = TapBehavior(
    when: TapCondition.inactive,
    action: TapAction.replace,
  );

  static const disabled = TapBehavior(
    when: null,
    action: null,
  );
}

/// Pure selection behavior options.
class SelectionOptions {
  const SelectionOptions({
    this.haptics,
    this.behavior = SelectionBehavior.autoEnable,
    this.tapBehavior,
    this.constraints,
  });

  final HapticResolver? haptics;
  final SelectionBehavior behavior;
  final TapBehavior? tapBehavior;
  final SelectionConstraints? constraints;

  SelectionOptions copyWith({
    HapticResolver? haptics,
    SelectionBehavior? behavior,
    TapBehavior? tapBehavior,
    SelectionConstraints? constraints,
  }) {
    return SelectionOptions(
      haptics: haptics ?? this.haptics,
      behavior: behavior ?? this.behavior,
      tapBehavior: tapBehavior ?? this.tapBehavior,
      constraints: constraints ?? this.constraints,
    );
  }
}
