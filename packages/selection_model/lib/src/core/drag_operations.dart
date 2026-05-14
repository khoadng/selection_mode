part of 'controller.dart';

class DragOperations {
  const DragOperations(this._controller);

  final SelectionModeController _controller;

  DragSelectionManager get dragManager => _controller._dragManager;
  SelectionStateManager get stateManager => _controller._stateManager;
  SelectabilityManager get selectabilityManager =>
      _controller._selectabilityManager;
  RangeManager get rangeManager => _controller._rangeManager;

  void startRangeSelection(int index) {
    if (!selectabilityManager.isSelectable(index)) return;

    if (_controller._shouldBlockManualSelection()) {
      return;
    }

    final events = <HapticEvent>[];

    if (!_controller._enabled && _controller._shouldAutoEnable()) {
      _controller._setEnabled(true);
      events.add(HapticEvent.modeEnabled);
    }

    dragManager.startDrag(index, _controller.visibleSelection);
    rangeManager.setAnchor(index);
    events.add(HapticEvent.dragStart);

    if (!_controller.isSelected(index)) {
      final canAddMore = _controller._options.constraints?.canAddMoreSelections(
            stateManager.length,
          ) ??
          true;

      if (canAddMore) {
        final identifier = stateManager.getIdentifier(index);
        stateManager.addIdentifier(identifier);
        events.add(HapticEvent.itemSelected);
        _controller._notify();
      } else {
        events.add(HapticEvent.maxItemsReached);
      }
    }

    _controller._hapticCoordinator.triggerSequence(events);
  }

  void handleDragOver(int index) {
    if (!dragManager.isDragInProgress ||
        rangeManager.anchor == null ||
        !selectabilityManager.isSelectable(index)) {
      return;
    }

    final result = dragManager.calculateDragUpdate(
      index,
      selectabilityManager.isSelectable,
      _controller._options.constraints,
    );

    final currentSelection = _controller.visibleSelection;
    if (result.newSelection.length == currentSelection.length &&
        result.newSelection.containsAll(currentSelection)) {
      return;
    }

    final events = <HapticEvent>[];

    if (result.newlySelected.isNotEmpty || result.newlyDeselected.isNotEmpty) {
      events.add(HapticEvent.rangeSelection);
    }

    if (result.hitLimit) {
      events.add(HapticEvent.maxItemsReached);
    }

    _controller._hapticCoordinator.triggerSequence(events);

    stateManager.clearIdentifiers();
    for (final index in result.newSelection) {
      final identifier = stateManager.getIdentifier(index);
      stateManager.addIdentifier(identifier);
    }

    _controller._notify();
  }

  void endRangeSelection() {
    dragManager.endDrag();
    _controller._checkAutoDisable();
  }
}
