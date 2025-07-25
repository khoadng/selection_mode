import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../options/haptic_feedback.dart';
import '../options/selection_options.dart';
import '../managers/auto_scroll_manager.dart';
import '../managers/range_manager.dart';
import '../managers/selectability_manager.dart';
import '../managers/drag_selection_manager.dart';
import '../managers/selection_state_manager.dart';

part 'selection_operations.dart';
part 'drag_operations.dart';

class SelectionModeController extends ChangeNotifier {
  SelectionModeController({
    bool initialEnabled = false,
    Set<int>? initialSelected,
  })  : _enabled = initialEnabled,
        _stateManager = SelectionStateManager(initialSelected) {
    _rangeManager = RangeManager(
      isSelectable: _selectabilityManager.isSelectable,
    );

    _selectionOps = SelectionOperations(this);
    _dragOps = DragOperations(this);
  }

  late final SelectionOperations _selectionOps;
  late final DragOperations _dragOps;

  SelectionOptions _options = const SelectionOptions();
  SelectionOptions get options => _options;

  bool _enabled;

  late final SelectionStateManager _stateManager;
  final SelectabilityManager _selectabilityManager = SelectabilityManager();
  final DragSelectionManager _dragManager = DragSelectionManager();

  late final RangeManager _rangeManager;
  AutoScrollManager? _autoScrollManager;

  final Map<int, Rect? Function()> positionCallbacks = {};

  bool get isActive => _enabled;
  Set<int> get selection => _stateManager.selection;
  bool get isDragInProgress => _dragManager.isDragInProgress;
  bool get isAutoScrolling => _autoScrollManager?.isScrolling ?? false;

  void registerItem(int index, Object identifier, bool isSelectable) {
    _stateManager.registerItem(index, identifier);
    _selectabilityManager.setSelectable(index, isSelectable);

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
      manager.onScrollUpdate = _dragOps.onAutoScrollUpdate;
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
    _autoScrollManager?.stopDragAutoScroll();
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
      _autoScrollManager?.stopDragAutoScroll();
    }
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

  void toggleItem(int item) => _selectionOps.toggleItem(item);
  void selectRange(int from, int to) => _selectionOps.selectRange(from, to);
  void deselectRange(int from, int to) => _selectionOps.deselectRange(from, to);
  void toggleRange(int from, int to) => _selectionOps.toggleRange(from, to);
  void clearRange(int from, int to) => _selectionOps.deselectRange(from, to);
  void deselectAll() => _selectionOps.deselectAll();
  void selectAll(List<int> items) => _selectionOps.selectAll(items);
  void invertSelection(List<int> allItems) =>
      _selectionOps.invertSelection(allItems);

  void startRangeSelection(int index) => _dragOps.startRangeSelection(index);
  void handleDragUpdate(Offset globalPosition) =>
      _dragOps.handleDragUpdate(globalPosition);
  void handleDragOver(int index) => _dragOps.handleDragOver(index);
  void endRangeSelection() => _dragOps.endRangeSelection();

  bool isSelectable(int index) => _selectabilityManager.isSelectable(index);
  bool isSelected(int item) => _stateManager.isSelected(item);
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

  bool _shouldBlockManualSelection() {
    return !_enabled && _options.behavior == SelectionBehavior.manual;
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
      _autoScrollManager?.stopDragAutoScroll();
    }
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

  void _triggerHaptic(HapticEvent event) {
    final resolver = _options.haptics;
    if (resolver == null) return;
    resolver.call(event);
  }

  void _notify() => notifyListeners();

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
    _clearAllMappings();
    super.dispose();
  }
}
