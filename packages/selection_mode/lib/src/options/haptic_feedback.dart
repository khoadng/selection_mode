import 'package:flutter/services.dart';
import 'package:selection_model/selection_model.dart';

/// Flutter haptic feedback configuration using the resolver pattern.
class HapticFeedbackResolver {
  const HapticFeedbackResolver._();

  static void none(HapticEvent event) {
    // No haptic feedback.
  }

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
