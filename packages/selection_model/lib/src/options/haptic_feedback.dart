/// Events that can trigger feedback during selection operations.
enum HapticEvent {
  modeEnabled,
  modeDisabled,
  itemSelected,
  itemDeselected,
  itemSelectedInRange,
  itemDeselectedInRange,
  rangeSelection,
  dragStart,
  maxItemsReached,
}

typedef HapticResolver = void Function(HapticEvent event);
