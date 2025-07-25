import '../options/haptic_feedback.dart';

/// Coordinates haptic feedback to prevent redundant triggers and manage event priorities
class HapticCoordinator {
  final HapticResolver? _resolver;
  final Map<HapticEvent, DateTime> _lastTriggered = {};

  HapticCoordinator(this._resolver);

  /// Trigger a single haptic event with debouncing
  void trigger(
    HapticEvent event, {
    Duration debounce = const Duration(milliseconds: 100),
  }) {
    if (_resolver == null) return;

    final now = DateTime.now();
    final lastTime = _lastTriggered[event];

    if (lastTime != null && now.difference(lastTime) < debounce) return;

    _lastTriggered[event] = now;
    _resolver!(event);
  }

  /// Trigger the highest priority event from a sequence
  void triggerSequence(List<HapticEvent> events) {
    if (events.isEmpty) return;

    final highest =
        events.reduce((a, b) => _getPriority(a) > _getPriority(b) ? a : b);

    trigger(highest);
  }

  /// Get priority value for haptic events
  int _getPriority(HapticEvent event) => switch (event) {
        HapticEvent.maxItemsReached => 5,
        HapticEvent.modeEnabled || HapticEvent.modeDisabled => 4,
        HapticEvent.dragStart => 3,
        HapticEvent.rangeSelection => 2,
        HapticEvent.itemSelected ||
        HapticEvent.itemDeselected ||
        HapticEvent.itemSelectedInRange ||
        HapticEvent.itemDeselectedInRange =>
          1,
      };

  void clearHistory() {
    _lastTriggered.clear();
  }
}
