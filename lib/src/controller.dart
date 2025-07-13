import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'haptic_feedback.dart';
import 'selection_options.dart';
import 'auto_scroll_manager.dart';
import 'range_manager.dart';
import 'selectability_manager.dart';
import 'drag_selection_manager.dart';

class SelectionModeController extends ChangeNotifier {
  SelectionModeController({
    bool initialEnabled = false,
    Set<int>? initialSelected,
    this.options = SelectionOptions.defaultOptions,
  })  : _enabled = initialEnabled,
        _selectedItems = Set<int>.from(initialSelected ?? <int>{}) {
    _rangeManager = RangeManager(
      isSelectable: _selectabilityManager.isSelectable,
    );
  }

  SelectionOptions options;
  bool _enabled;
  final Set<int> _selectedItems;

  final SelectabilityManager _selectabilityManager = SelectabilityManager();
  final DragSelectionManager _dragManager = DragSelectionManager();

  late final RangeManager _rangeManager;
  AutoScrollManager? _autoScrollManager;

  bool get isActive => _enabled;
  Set<int> get selection => Set.unmodifiable(_selectedItems);
  int get selectedCount => _selectedItems.length;
  bool get hasSelection => _selectedItems.isNotEmpty;
  int? get rangeAnchor => _rangeManager.anchor;
  bool get isDragInProgress => _dragManager.isDragInProgress;

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
  }

  void updateOptions(SelectionOptions newOptions) {
    options = newOptions;

    final constrainedSelection =
        options.constraints.enforceConstraints(_selectedItems);
    if (constrainedSelection.length != _selectedItems.length) {
      _selectedItems.clear();
      _selectedItems.addAll(constrainedSelection);
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void setItemSelectable(int index, bool selectable) {
    _selectabilityManager.setSelectable(index, selectable);

    if (!selectable && _selectedItems.contains(index)) {
      _selectedItems.remove(index);
      if (_rangeManager.anchor == index) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _selectabilityManager.removeItem(index);
    _selectedItems.remove(index);
    if (_rangeManager.anchor == index) {
      _rangeManager.clearAnchor();
    }
    _checkAutoDisable();
  }

  bool isSelectable(int index) => _selectabilityManager.isSelectable(index);

  void enable({List<int>? initialSelected}) {
    _setEnabled(true);
    _triggerHaptic(HapticEvent.modeEnabled);
    if (initialSelected != null) {
      final selectableInitial =
          _selectabilityManager.filterSelectable(initialSelected);
      _addToSelection(selectableInitial);
    }
    notifyListeners();
  }

  void disable({bool clearSelection = true}) {
    _setEnabled(false);
    _triggerHaptic(HapticEvent.modeDisabled);
    if (clearSelection) {
      _selectedItems.clear();
    }
    _rangeManager.clearAnchor();
    _dragManager.endDrag();
    _autoScrollManager?.stopAutoScroll();
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
      _autoScrollManager?.stopAutoScroll();
    }
    notifyListeners();
  }

  bool _shouldBlockManualSelection() {
    return !_enabled && options.behavior == SelectionBehavior.manual;
  }

  void toggleItem(int item) {
    if (!isSelectable(item)) return;

    if (_shouldBlockManualSelection()) {
      return;
    }

    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
      _triggerHaptic(HapticEvent.itemDeselected);
      if (_rangeManager.anchor == item) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
    } else {
      if (options.constraints.canAddMoreSelections(_selectedItems.length)) {
        if (!_enabled && _shouldAutoEnable()) {
          _setEnabled(true);
          _triggerHaptic(HapticEvent.modeEnabled);
        }
        _selectedItems.add(item);
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
      _selectedItems,
      from,
      to,
      options.constraints.maxSelections ?? -1,
    );

    if (result.addedItems.isNotEmpty) {
      _selectedItems.clear();
      _selectedItems.addAll(result.selection);

      if (result.hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void deselectRange(int from, int to) {
    final newSelection =
        _rangeManager.calculateRangeDeselection(_selectedItems, from, to);

    if (newSelection.length != _selectedItems.length) {
      _selectedItems.clear();
      _selectedItems.addAll(newSelection);

      if (_selectedItems.isEmpty) {
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

    final result = _rangeManager.calculateRangeToggle(
      _selectedItems,
      from,
      to,
      options.constraints.maxSelections ?? -1,
    );

    if (result.selection.length != _selectedItems.length) {
      _selectedItems.clear();
      _selectedItems.addAll(result.selection);

      if (_selectedItems.isEmpty) {
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
      _rangeManager.getSelectedInRange(_selectedItems, from, to);

  List<int> getSelectableInRange(int from, int to) =>
      _rangeManager.getSelectableInRange(from, to);

  int getSelectedCountInRange(int from, int to) =>
      _rangeManager.getSelectedCountInRange(_selectedItems, from, to);

  bool hasSelectionInRange(int from, int to) =>
      _rangeManager.hasSelectionInRange(_selectedItems, from, to);

  bool isRangeFullySelected(int from, int to) =>
      _rangeManager.isRangeFullySelected(_selectedItems, from, to);

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
    if (!_selectedItems.contains(index)) {
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

    _dragManager.startDrag(index, _selectedItems);
    _rangeManager.setAnchor(index);
    _triggerHaptic(HapticEvent.dragStart);

    if (!_selectedItems.contains(index)) {
      if (options.constraints.canAddMoreSelections(_selectedItems.length)) {
        _selectedItems.add(index);
        _triggerHaptic(HapticEvent.itemSelected);
        notifyListeners();
      } else {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
    }
  }

  void handleDragOver(int index, [Offset? globalPosition, Size? viewportSize]) {
    if (!_dragManager.isDragInProgress ||
        _rangeManager.anchor == null ||
        !isSelectable(index)) {
      return;
    }

    // Handle auto-scroll if enabled and position/viewport provided
    if (_autoScrollManager != null &&
        globalPosition != null &&
        viewportSize != null) {
      _autoScrollManager!.handleDragUpdate(globalPosition, viewportSize);
    }

    final result = _dragManager.calculateDragUpdate(
      index,
      _selectabilityManager.isSelectable,
      options.constraints,
    );

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

    _selectedItems.clear();
    _selectedItems.addAll(result.newSelection);
    notifyListeners();
  }

  void endRangeSelection() {
    _dragManager.endDrag();
    _autoScrollManager?.stopAutoScroll();
    _checkAutoDisable();
  }

  void deselectAll() {
    if (_selectedItems.isEmpty) return;
    _selectedItems.clear();
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

    final oldLength = _selectedItems.length;
    final selectableItems = _selectabilityManager.filterSelectable(items);
    _addToSelection(selectableItems);

    if (_selectedItems.length != oldLength) {
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
    final newSelection = selectableItems..removeAll(_selectedItems);

    _selectedItems.clear();
    _addToSelection(newSelection);

    _checkAutoDisable();
    _triggerHaptic(HapticEvent.rangeSelection);
    notifyListeners();
  }

  bool isSelected(int item) => _selectedItems.contains(item);

  void _setEnabled(bool value) {
    _enabled = value;
  }

  void _addToSelection(Iterable<int> items) {
    bool hitLimit = false;
    for (final item in items) {
      if (options.constraints.canAddMoreSelections(_selectedItems.length)) {
        _selectedItems.add(item);
      } else if (!hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
        hitLimit = true;
        break;
      }
    }
  }

  bool _shouldAutoEnable() {
    return options.behavior == SelectionBehavior.autoEnable ||
        options.behavior == SelectionBehavior.autoToggle;
  }

  void _checkAutoDisable() {
    if (_enabled &&
        _selectedItems.isEmpty &&
        options.behavior == SelectionBehavior.autoToggle) {
      _setEnabled(false);
      _triggerHaptic(HapticEvent.modeDisabled);
      _rangeManager.clearAnchor();
      _dragManager.endDrag();
      _autoScrollManager?.stopAutoScroll();
    }
  }

  void _triggerHaptic(HapticEvent event) {
    final resolver = options.haptics ?? HapticFeedbackResolver.all;
    resolver.call(event);
  }

  @override
  void dispose() {
    _autoScrollManager?.dispose();
    _rangeManager.dispose();
    _dragManager.reset();
    _selectabilityManager.clear();
    super.dispose();
  }
}
