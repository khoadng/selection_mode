part of 'controller.dart';

/// Handles selection state changes and operations
class SelectionOperations {
  const SelectionOperations(this._controller);

  final SelectionModeController _controller;

  SelectionStateManager get stateManager => _controller._stateManager;
  SelectabilityManager get selectabilityManager =>
      _controller._selectabilityManager;
  RangeManager get rangeManager => _controller._rangeManager;

  void toggleItem(int item) {
    if (!selectabilityManager.isSelectable(item)) return;

    if (_controller._shouldBlockManualSelection()) {
      return;
    }

    final identifier = stateManager.getIdentifier(item);

    if (stateManager.isSelected(item)) {
      stateManager.removeIdentifier(identifier);
      _controller._hapticCoordinator.trigger(HapticEvent.itemDeselected);
      if (rangeManager.anchor == item) {
        rangeManager.clearAnchor();
      }
      _controller._checkAutoDisable();
    } else {
      final canAddMore = _controller._options.constraints
              ?.canAddMoreSelections(stateManager.length) ??
          true;

      if (canAddMore) {
        final events = <HapticEvent>[];

        if (!_controller._enabled && _controller._shouldAutoEnable()) {
          _controller._setEnabled(true);
          events.add(HapticEvent.modeEnabled);
        }

        stateManager.addIdentifier(identifier);
        events.add(HapticEvent.itemSelected);

        _controller._hapticCoordinator.triggerSequence(events);

        if (rangeManager.anchor == null) {
          rangeManager.setAnchor(item);
        }
      } else {
        _controller._hapticCoordinator.trigger(HapticEvent.maxItemsReached);
        return;
      }
    }
    _controller._notify();
  }

  void selectRange(int from, int to) {
    if (_controller._shouldBlockManualSelection()) return;

    final events = <HapticEvent>[];

    if (!_controller._enabled && _controller._shouldAutoEnable()) {
      _controller._setEnabled(true);
      events.add(HapticEvent.modeEnabled);
    }

    final result = rangeManager.calculateRangeSelection(
      _controller.visibleSelection,
      from,
      to,
      _controller._options.constraints?.maxSelections ?? -1,
    );

    if (result.addedItems.isNotEmpty) {
      for (final index in result.addedItems) {
        final identifier = stateManager.getIdentifier(index);
        stateManager.addIdentifier(identifier);
      }

      events.add(HapticEvent.rangeSelection);

      if (result.hitLimit) {
        events.add(HapticEvent.maxItemsReached);
      }

      _controller._hapticCoordinator.triggerSequence(events);
      _controller._notify();
    }
  }

  void deselectRange(int from, int to) {
    final currentIndexSelection = _controller.visibleSelection;
    final newSelection =
        rangeManager.calculateRangeDeselection(currentIndexSelection, from, to);

    if (newSelection.length != currentIndexSelection.length) {
      final deselectedIndices = currentIndexSelection.difference(newSelection);
      for (final index in deselectedIndices) {
        final identifier = stateManager.getIdentifier(index);
        stateManager.removeIdentifier(identifier);
      }

      if (stateManager.isEmpty) {
        rangeManager.clearAnchor();
      }
      _controller._checkAutoDisable();
      _controller._notify();
    }
  }

  void toggleRange(int from, int to) {
    final events = <HapticEvent>[];

    if (!_controller._enabled && _controller._shouldAutoEnable()) {
      _controller._setEnabled(true);
      events.add(HapticEvent.modeEnabled);
    }

    final currentIndexSelection = _controller.visibleSelection;
    final result = rangeManager.calculateRangeToggle(
      currentIndexSelection,
      from,
      to,
      _controller._options.constraints?.maxSelections ?? -1,
    );

    if (result.selection.length != currentIndexSelection.length) {
      final added = result.selection.difference(currentIndexSelection);
      final removed = currentIndexSelection.difference(result.selection);

      for (final index in removed) {
        final identifier = stateManager.getIdentifier(index);
        stateManager.removeIdentifier(identifier);
      }

      for (final index in added) {
        final identifier = stateManager.getIdentifier(index);
        stateManager.addIdentifier(identifier);
      }

      if (stateManager.isEmpty) {
        rangeManager.clearAnchor();
      }
      _controller._checkAutoDisable();

      events.add(HapticEvent.rangeSelection);

      if (result.hitLimit) {
        events.add(HapticEvent.maxItemsReached);
      }

      _controller._hapticCoordinator.triggerSequence(events);
      _controller._notify();
    }
  }

  void deselectAll() {
    if (stateManager.isEmpty) return;
    stateManager.clearIdentifiers();
    rangeManager.clearAnchor();
    _controller._checkAutoDisable();
    _controller._notify();
  }

  void selectAll(List<int> items) {
    if (_controller._shouldBlockManualSelection()) {
      return;
    }

    final events = <HapticEvent>[];

    if (!_controller._enabled && _controller._shouldAutoEnable()) {
      _controller._setEnabled(true);
      events.add(HapticEvent.modeEnabled);
    }

    final oldLength = stateManager.length;
    final selectableItems = selectabilityManager.filterSelectable(items);
    _controller._addToSelectionByIndex(selectableItems);

    if (stateManager.length != oldLength) {
      events.add(HapticEvent.rangeSelection);
      _controller._hapticCoordinator.triggerSequence(events);
      _controller._notify();
    }
  }

  void invertSelection(List<int> allItems) {
    if (_controller._shouldBlockManualSelection()) {
      return;
    }

    final events = <HapticEvent>[];

    if (!_controller._enabled && _controller._shouldAutoEnable()) {
      _controller._setEnabled(true);
      events.add(HapticEvent.modeEnabled);
    }

    final selectableItems =
        selectabilityManager.filterSelectable(allItems).toSet();
    final currentSelection = _controller.visibleSelection;
    final newSelection = selectableItems..removeAll(currentSelection);

    stateManager.clearIdentifiers();
    _controller._addToSelectionByIndex(newSelection);

    _controller._checkAutoDisable();
    events.add(HapticEvent.rangeSelection);
    _controller._hapticCoordinator.triggerSequence(events);
    _controller._notify();
  }
}
