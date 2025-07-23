import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../options/haptic_feedback.dart';
import '../options/selection_options.dart';
import '../managers/auto_scroll_manager.dart';
import '../managers/range_manager.dart';
import '../managers/selectability_manager.dart';
import '../managers/drag_selection_manager.dart';
import '../managers/rectangle_selection_manager.dart';
import '../managers/selection_state_manager.dart';

class SelectionModeController extends ChangeNotifier {
  SelectionModeController({
    bool initialEnabled = false,
    Set<int>? initialSelected,
  })  : _enabled = initialEnabled,
        _stateManager = SelectionStateManager(initialSelected) {
    _rangeManager = RangeManager(
      isSelectable: _selectabilityManager.isSelectable,
    );
  }

  SelectionOptions _options = const SelectionOptions();
  SelectionOptions get options => _options;

  bool _enabled;

  late final SelectionStateManager _stateManager;
  final SelectabilityManager _selectabilityManager = SelectabilityManager();
  final DragSelectionManager _dragManager = DragSelectionManager();
  final RectangleSelectionManager _rectangleManager =
      RectangleSelectionManager();

  late final RangeManager _rangeManager;
  AutoScrollManager? _autoScrollManager;

  Offset? _currentDragPosition;
  final Map<int, Rect? Function()> positionCallbacks = {};

  bool get isActive => _enabled;

  Set<int> get selection => _stateManager.selection;

  bool get isDragInProgress => _dragManager.isDragInProgress;
  bool get isRectangleSelectionInProgress =>
      _rectangleManager.isSelectionInProgress;
  Rect? get selectionRect => _rectangleManager.selectionRect;

  AutoScrollManager? get autoScrollManager => _autoScrollManager;

  void registerItem(int index, Object identifier, bool isSelectable) {
    _stateManager.registerItem(index, identifier);
    _selectabilityManager.setSelectable(index, isSelectable);

    // If identifier was selected but item became unselectable, remove selection
    if (!isSelectable && _stateManager.isSelected(index)) {
      _stateManager.removeIdentifier(identifier);
      if (_rangeManager.anchor == index) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void unregisterItem(int index, {bool? trackId}) {
    _stateManager.unregisterItem(index);
    _selectabilityManager.removeItem(index);

    if (_rangeManager.anchor == index) {
      _rangeManager.clearAnchor();
    }
    _checkAutoDisable();
  }

  void registerPositionCallback(int index, Rect? Function() callback) {
    positionCallbacks[index] = callback;
  }

  void unregisterPositionCallback(int index) {
    positionCallbacks.remove(index);
  }

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
    if (manager != null) {
      manager.onScrollUpdate = _onAutoScrollUpdate;
    }
  }

  void _applyOptions(SelectionOptions options) {
    _options = options;
    final maxSelections = options.constraints?.maxSelections;

    if (maxSelections != null && _stateManager.length > maxSelections) {
      final currentSelection = _stateManager.selection.toList();
      final toRemove = currentSelection.skip(maxSelections);

      for (final index in toRemove) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.removeIdentifier(identifier);
      }
      _checkAutoDisable();
    }
  }

  void initializeOptions(SelectionOptions options) {
    _applyOptions(options);
  }

  void updateOptions(SelectionOptions options) {
    _applyOptions(options);
    notifyListeners();
  }

  void setItemSelectable(int index, bool selectable) {
    _selectabilityManager.setSelectable(index, selectable);

    if (!selectable && _stateManager.isSelected(index)) {
      final identifier = _stateManager.getIdentifier(index);
      _stateManager.removeIdentifier(identifier);
      if (_rangeManager.anchor == index) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void removeItem(int index) {
    unregisterItem(index);
    notifyListeners();
  }

  bool isSelectable(int index) => _selectabilityManager.isSelectable(index);

  // Delegate to state manager
  bool isSelected(int item) => _stateManager.isSelected(item);

  void enable({List<int>? initialSelected}) {
    _setEnabled(true);
    _triggerHaptic(HapticEvent.modeEnabled);
    if (initialSelected != null) {
      final selectableInitial =
          _selectabilityManager.filterSelectable(initialSelected);
      _addToSelectionByIndex(selectableInitial);
    }
    notifyListeners();
  }

  void disable({bool clearSelection = true}) {
    _setEnabled(false);
    _triggerHaptic(HapticEvent.modeDisabled);
    if (clearSelection) {
      _stateManager.clearIdentifiers();
    }
    _rangeManager.clearAnchor();
    _dragManager.endDrag();
    _rectangleManager.endSelection();
    _autoScrollManager?.stopDragAutoScroll();
    _currentDragPosition = null;
    notifyListeners();
  }

  void toggle() {
    _setEnabled(!_enabled);
    if (_enabled) {
      _triggerHaptic(HapticEvent.modeEnabled);
    } else {
      _triggerHaptic(HapticEvent.modeDisabled);
      _rangeManager.clearAnchor();
      _dragManager.endDrag();
      _rectangleManager.endSelection();
      _autoScrollManager?.stopDragAutoScroll();
      _currentDragPosition = null;
    }
    notifyListeners();
  }

  bool _shouldBlockManualSelection() {
    return !_enabled && _options.behavior == SelectionBehavior.manual;
  }

  void toggleItem(int item) {
    if (!isSelectable(item)) return;

    if (_shouldBlockManualSelection()) {
      return;
    }

    final identifier = _stateManager.getIdentifier(item);

    if (_stateManager.isSelected(item)) {
      _stateManager.removeIdentifier(identifier);
      _triggerHaptic(HapticEvent.itemDeselected);
      if (_rangeManager.anchor == item) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
    } else {
      final canAddMore =
          _options.constraints?.canAddMoreSelections(_stateManager.length) ??
              true;

      if (canAddMore) {
        if (!_enabled && _shouldAutoEnable()) {
          _setEnabled(true);
          _triggerHaptic(HapticEvent.modeEnabled);
        }
        _stateManager.addIdentifier(identifier);
        _triggerHaptic(HapticEvent.itemSelected);
        if (_rangeManager.anchor == null) {
          _rangeManager.setAnchor(item);
        }
      } else {
        _triggerHaptic(HapticEvent.maxItemsReached);
        return;
      }
    }
    notifyListeners();
  }

  void selectRange(int from, int to) {
    if (_shouldBlockManualSelection()) return;

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final result = _rangeManager.calculateRangeSelection(
      selection,
      from,
      to,
      _options.constraints?.maxSelections ?? -1,
    );

    if (result.addedItems.isNotEmpty) {
      for (final index in result.addedItems) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.addIdentifier(identifier);
      }

      if (result.hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void deselectRange(int from, int to) {
    final currentIndexSelection = selection;
    final newSelection = _rangeManager.calculateRangeDeselection(
        currentIndexSelection, from, to);

    if (newSelection.length != currentIndexSelection.length) {
      final deselectedIndices = currentIndexSelection.difference(newSelection);
      for (final index in deselectedIndices) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.removeIdentifier(identifier);
      }

      if (_stateManager.isEmpty) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void toggleRange(int from, int to) {
    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final currentIndexSelection = selection;
    final result = _rangeManager.calculateRangeToggle(
      currentIndexSelection,
      from,
      to,
      _options.constraints?.maxSelections ?? -1,
    );

    if (result.selection.length != currentIndexSelection.length) {
      final added = result.selection.difference(currentIndexSelection);
      final removed = currentIndexSelection.difference(result.selection);

      for (final index in removed) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.removeIdentifier(identifier);
      }

      for (final index in added) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.addIdentifier(identifier);
      }

      if (_stateManager.isEmpty) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();

      if (result.hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void clearRange(int from, int to) => deselectRange(from, to);

  List<int> getSelectedInRange(int from, int to) =>
      _rangeManager.getSelectedInRange(selection, from, to);

  List<int> getSelectableInRange(int from, int to) =>
      _rangeManager.getSelectableInRange(from, to);

  int getSelectedCountInRange(int from, int to) =>
      _rangeManager.getSelectedCountInRange(selection, from, to);

  bool hasSelectionInRange(int from, int to) =>
      _rangeManager.hasSelectionInRange(selection, from, to);

  bool isRangeFullySelected(int from, int to) =>
      _rangeManager.isRangeFullySelected(selection, from, to);

  void handleSelection(
    int index, {
    bool isShiftPressed = false,
    bool isRangeMode = false,
  }) {
    if (!isSelectable(index)) return;

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    if ((isShiftPressed || isRangeMode)) {
      final anchor = _rangeManager.getShiftSelectionTarget(index);
      if (anchor != null) {
        selectRange(anchor, index);
        return;
      }
    }

    toggleItem(index);
    _rangeManager.setAnchor(index);
  }

  void setRangeAnchor(int index) {
    if (!isSelectable(index)) return;
    _rangeManager.setAnchor(index);
    if (!isSelected(index)) {
      toggleItem(index);
    }
  }

  void startRangeSelection(int index) {
    if (!isSelectable(index)) return;

    if (_shouldBlockManualSelection()) {
      return;
    }

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    _dragManager.startDrag(index, selection);
    _rangeManager.setAnchor(index);
    _autoScrollManager?.startDragAutoScroll();
    _triggerHaptic(HapticEvent.dragStart);

    if (!isSelected(index)) {
      final canAddMore =
          _options.constraints?.canAddMoreSelections(_stateManager.length) ??
              true;

      if (canAddMore) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.addIdentifier(identifier);
        _triggerHaptic(HapticEvent.itemSelected);
        notifyListeners();
      } else {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
    }
  }

  void handleDragUpdate(Offset globalPosition) {
    if (!_dragManager.isDragInProgress) return;

    _currentDragPosition = globalPosition;
    final autoScrollManager = _autoScrollManager;

    if (autoScrollManager != null) {
      final viewportSize = autoScrollManager.getViewportSize();
      if (viewportSize != null) {
        autoScrollManager.handleDragUpdate(globalPosition, viewportSize);
      }
    }
  }

  void handleDragOver(int index) {
    if (!_dragManager.isDragInProgress ||
        _rangeManager.anchor == null ||
        !isSelectable(index)) {
      return;
    }

    final result = _dragManager.calculateDragUpdate(
      index,
      _selectabilityManager.isSelectable,
      _options.constraints,
    );

    // Early return if selection hasn't changed
    final currentSelection = selection;
    if (result.newSelection.length == currentSelection.length &&
        result.newSelection.containsAll(currentSelection)) {
      return;
    }

    // Trigger haptic for newly selected/deselected items during drag
    if (result.newlySelected.isNotEmpty) {
      for (final _ in result.newlySelected) {
        _triggerHaptic(HapticEvent.itemSelectedInRange);
      }
    }

    if (result.newlyDeselected.isNotEmpty) {
      for (final _ in result.newlyDeselected) {
        _triggerHaptic(HapticEvent.itemDeselectedInRange);
      }
    }

    if (result.hitLimit) {
      _triggerHaptic(HapticEvent.maxItemsReached);
    }

    _stateManager.clearIdentifiers();
    for (final index in result.newSelection) {
      final identifier = _stateManager.getIdentifier(index);
      _stateManager.addIdentifier(identifier);
    }

    notifyListeners();
  }

  void endRangeSelection() {
    _dragManager.endDrag();
    _autoScrollManager?.stopDragAutoScroll();
    _currentDragPosition = null;
    _checkAutoDisable();
  }

  void startRectangleSelection(Offset position) {
    if (_shouldBlockManualSelection()) return;

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    _rectangleManager.startSelection(position, selection);
    _autoScrollManager?.startDragAutoScroll();
    _triggerHaptic(HapticEvent.dragStart);
    notifyListeners();
  }

  void updateRectangleSelection(Offset position) {
    if (!_rectangleManager.isSelectionInProgress) return;

    _currentDragPosition = position;
    _rectangleManager.updateSelection(position);

    final result = _rectangleManager.calculateSelection(
      positionCallbacks,
      _selectabilityManager.isSelectable,
      _options.constraints,
    );

    // Update selection
    _stateManager.clearIdentifiers();
    for (final index in result.newSelection) {
      final identifier = _stateManager.getIdentifier(index);
      _stateManager.addIdentifier(identifier);
    }

    // Trigger haptics for changes
    if (result.addedItems.isNotEmpty) {
      _triggerHaptic(HapticEvent.itemSelectedInRange);
    }
    if (result.removedItems.isNotEmpty) {
      _triggerHaptic(HapticEvent.itemDeselectedInRange);
    }
    if (result.hitLimit) {
      _triggerHaptic(HapticEvent.maxItemsReached);
    }

    notifyListeners();
  }

  void endRectangleSelection() {
    if (_rectangleManager.isSelectionInProgress) {
      _rectangleManager.endSelection();
      _autoScrollManager?.stopDragAutoScroll();
      _currentDragPosition = null;
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void cancelRectangleSelection() {
    if (_rectangleManager.isSelectionInProgress) {
      final originalSelection = _rectangleManager.cancelSelection();

      _stateManager.clearIdentifiers();
      for (final index in originalSelection) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.addIdentifier(identifier);
      }

      _autoScrollManager?.stopDragAutoScroll();
      _currentDragPosition = null;
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void _onAutoScrollUpdate() {
    if (_dragManager.isDragInProgress) {
      if (_currentDragPosition case final Offset position) {
        _checkItemUnderPointer(position);
      }
    }
  }

  void _checkItemUnderPointer(Offset position) {
    for (final entry in positionCallbacks.entries) {
      final rect = entry.value();
      if (rect != null && rect.contains(position)) {
        handleDragOver(entry.key);
        return;
      }
    }
  }

  void deselectAll() {
    if (_stateManager.isEmpty) return;
    _stateManager.clearIdentifiers();
    _rangeManager.clearAnchor();
    _checkAutoDisable();
    notifyListeners();
  }

  void selectAll(List<int> items) {
    if (_shouldBlockManualSelection()) {
      return;
    }
    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final oldLength = _stateManager.length;
    final selectableItems = _selectabilityManager.filterSelectable(items);
    _addToSelectionByIndex(selectableItems);

    if (_stateManager.length != oldLength) {
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void invertSelection(List<int> allItems) {
    if (_shouldBlockManualSelection()) {
      return;
    }

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final selectableItems =
        _selectabilityManager.filterSelectable(allItems).toSet();
    final currentSelection = selection;
    final newSelection = selectableItems..removeAll(currentSelection);

    _stateManager.clearIdentifiers();
    _addToSelectionByIndex(newSelection);

    _checkAutoDisable();
    _triggerHaptic(HapticEvent.rangeSelection);
    notifyListeners();
  }

  void _setEnabled(bool value) {
    _enabled = value;
  }

  void _addToSelectionByIndex(Iterable<int> items) {
    bool hitLimit = false;
    for (final item in items) {
      final canAddMore =
          _options.constraints?.canAddMoreSelections(_stateManager.length) ??
              true;
      if (canAddMore) {
        final identifier = _stateManager.getIdentifier(item);
        _stateManager.addIdentifier(identifier);
      } else if (!hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
        hitLimit = true;
        break;
      }
    }
  }

  bool _shouldAutoEnable() {
    return _options.behavior == SelectionBehavior.autoEnable ||
        _options.behavior == SelectionBehavior.autoToggle;
  }

  void _checkAutoDisable() {
    if (_enabled &&
        _stateManager.isEmpty &&
        _options.behavior == SelectionBehavior.autoToggle) {
      _setEnabled(false);
      _triggerHaptic(HapticEvent.modeDisabled);
      _rangeManager.clearAnchor();
      _dragManager.endDrag();
      _rectangleManager.endSelection();
      _autoScrollManager?.stopDragAutoScroll();
      _currentDragPosition = null;
    }
  }

  void _triggerHaptic(HapticEvent event) {
    final resolver = _options.haptics;
    if (resolver == null) return;
    resolver.call(event);
  }

  void _clearAllMappings() {
    _stateManager.clear();
    _selectabilityManager.clear();
    positionCallbacks.clear();
  }

  @override
  void dispose() {
    _autoScrollManager?.dispose();
    _rangeManager.dispose();
    _dragManager.reset();
    _rectangleManager.reset();
    _clearAllMappings();
    super.dispose();
  }
}
