import 'package:flutter/services.dart';

/// Events that can trigger haptic feedback during selection operations
enum HapticEvent {
  /// Selection mode was enabled
  modeEnabled,

  /// Selection mode was disabled
  modeDisabled,

  /// An item was selected
  itemSelected,

  /// An item was deselected
  itemDeselected,

  /// An item was selected during drag/range selection
  itemSelectedInRange,

  /// An item was deselected during drag/range selection
  itemDeselectedInRange,

  /// Multiple items selected via range selection (shift+click, select all)
  rangeSelection,

  /// Drag selection started
  dragStart,

  /// Maximum selection limit reached
  maxItemsReached,
}

/// Signature for haptic feedback resolvers
typedef HapticResolver = void Function(HapticEvent event);

/// Haptic feedback configuration using Flutter's resolver pattern
class HapticFeedbackResolver {
  const HapticFeedbackResolver._();

  /// No haptic feedback
  static void none(HapticEvent event) {
    // No haptic feedback
  }

  /// Haptic feedback for all events (default behavior)
  static void all(HapticEvent event) {
    switch (event) {
      case HapticEvent.modeEnabled:
      case HapticEvent.modeDisabled:
        HapticFeedback.lightImpact();
      case HapticEvent.itemSelected:
      case HapticEvent.itemDeselected:
      case HapticEvent.itemSelectedInRange:
      case HapticEvent.itemDeselectedInRange:
      case HapticEvent.rangeSelection:
        HapticFeedback.selectionClick();
      case HapticEvent.dragStart:
        HapticFeedback.mediumImpact();
      case HapticEvent.maxItemsReached:
        HapticFeedback.heavyImpact();
    }
  }

  /// Haptic feedback only for mode changes (enter/exit selection)
  static void modeOnly(HapticEvent event) {
    switch (event) {
      case HapticEvent.modeEnabled:
      case HapticEvent.modeDisabled:
        HapticFeedback.lightImpact();
      case HapticEvent.maxItemsReached:
        HapticFeedback.heavyImpact();
      default:
        break;
    }
  }
}
