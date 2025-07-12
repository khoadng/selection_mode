import 'haptic_feedback.dart';

/// Selection mode behavior patterns
enum SelectionBehavior {
  /// Manual enable/disable only - no automatic behavior
  manual,

  /// Auto enable on first selection + auto disable when empty
  implicit,

  /// Auto enable on first selection + manual disable (default)
  autoEnable,
}

/// Configuration for auto-scroll behavior during drag selection
class AutoScrollConfig {
  const AutoScrollConfig({
    this.edgeThreshold = 80.0,
    this.scrollSpeed = 20.0,
    this.scrollInterval = const Duration(milliseconds: 16),
  });

  /// Distance from viewport edge to trigger auto-scroll
  final double edgeThreshold;

  /// Base scroll speed in pixels per interval
  final double scrollSpeed;

  /// How often to perform scroll updates
  final Duration scrollInterval;

  AutoScrollConfig copyWith({
    double? edgeThreshold,
    double? scrollSpeed,
    Duration? scrollInterval,
  }) {
    return AutoScrollConfig(
      edgeThreshold: edgeThreshold ?? this.edgeThreshold,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      scrollInterval: scrollInterval ?? this.scrollInterval,
    );
  }
}

/// Configuration options for SelectionMode behavior
class SelectionModeOptions {
  const SelectionModeOptions({
    this.hapticResolver,
    this.enableLongPress = true,
    this.enableDragSelection = true,
    this.selectionBehavior = SelectionBehavior.autoEnable,
    this.maxSelections,
    this.autoScroll,
  });

  /// Haptic feedback resolver. If null, no haptic feedback is provided.
  final HapticResolver? hapticResolver;

  /// Enable long press to start selection mode
  final bool enableLongPress;

  /// Enable drag to select multiple items (mobile)
  final bool enableDragSelection;

  /// Selection mode behavior pattern
  final SelectionBehavior selectionBehavior;

  /// Maximum number of items that can be selected (null = unlimited)
  final int? maxSelections;

  /// Auto-scroll configuration for drag selection (null = disabled)
  final AutoScrollConfig? autoScroll;

  /// Default configuration with haptic feedback for all events
  static const defaultOptions = SelectionModeOptions(
    hapticResolver: HapticFeedbackResolver.all,
  );

  /// Manual selection mode - explicit enable/disable only
  static const manual = SelectionModeOptions(
    selectionBehavior: SelectionBehavior.manual,
    hapticResolver: HapticFeedbackResolver.modeOnly,
  );

  /// Implicit selection mode - auto enable + auto exit when empty
  static const implicit = SelectionModeOptions(
    selectionBehavior: SelectionBehavior.implicit,
    hapticResolver: HapticFeedbackResolver.all,
  );

  SelectionModeOptions copyWith({
    HapticResolver? hapticResolver,
    bool? enableLongPress,
    bool? enableDragSelection,
    SelectionBehavior? selectionBehavior,
    int? maxSelections,
    AutoScrollConfig? autoScroll,
  }) {
    return SelectionModeOptions(
      hapticResolver: hapticResolver ?? this.hapticResolver,
      enableLongPress: enableLongPress ?? this.enableLongPress,
      enableDragSelection: enableDragSelection ?? this.enableDragSelection,
      selectionBehavior: selectionBehavior ?? this.selectionBehavior,
      maxSelections: maxSelections ?? this.maxSelections,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }
}
