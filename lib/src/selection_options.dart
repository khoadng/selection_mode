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

/// Configuration for auto-scroll behavior during drag selection
class AutoScrollConfig {
  const AutoScrollConfig({
    this.edgeThreshold = 100,
    this.scrollSpeed = 960,
  });

  /// Distance from viewport edge to trigger auto-scroll
  final double edgeThreshold;

  /// Scroll speed in pixels per second
  final double scrollSpeed;

  AutoScrollConfig copyWith({
    double? edgeThreshold,
    double? scrollSpeed,
  }) {
    return AutoScrollConfig(
      edgeThreshold: edgeThreshold ?? this.edgeThreshold,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
    );
  }
}

/// Configuration options for SelectionMode behavior
class SelectionOptions {
  const SelectionOptions({
    this.haptics,
    this.behavior = SelectionBehavior.autoEnable,
    this.constraints = const SelectionConstraints.none(),
    this.autoScroll,
  });

  /// Haptic feedback resolver. If null, no haptic feedback is provided.
  final HapticResolver? haptics;

  /// Selection mode behavior pattern
  final SelectionBehavior behavior;

  /// Selection constraints
  final SelectionConstraints constraints;

  /// Auto-scroll configuration for drag selection (null = disabled)
  final AutoScrollConfig? autoScroll;

  /// Default configuration with haptic feedback for all events
  static const defaultOptions = SelectionOptions(
    haptics: HapticFeedbackResolver.all,
  );

  /// Manual selection mode - explicit enable/disable only
  static const manual = SelectionOptions(
    behavior: SelectionBehavior.manual,
    haptics: HapticFeedbackResolver.modeOnly,
  );

  /// Implicit selection mode - auto enable + auto exit when empty
  static const implicit = SelectionOptions(
    behavior: SelectionBehavior.autoToggle,
    haptics: HapticFeedbackResolver.all,
  );

  SelectionOptions copyWith({
    HapticResolver? haptics,
    SelectionBehavior? behavior,
    SelectionConstraints? constraints,
    AutoScrollConfig? autoScroll,
  }) {
    return SelectionOptions(
      haptics: haptics ?? this.haptics,
      behavior: behavior ?? this.behavior,
      constraints: constraints ?? this.constraints,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }
}
