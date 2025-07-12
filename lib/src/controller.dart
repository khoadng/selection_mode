import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'haptic_feedback.dart';
import 'selection_mode_options.dart';
import 'auto_scroll_manager.dart';

class SelectionModeController extends ChangeNotifier {
  SelectionModeController({
    bool initialEnabled = false,
    Set<int>? initialSelected,
    this.options = SelectionModeOptions.defaultOptions,
  })  : _enabled = initialEnabled,
        _selectedItems = Set<int>.from(initialSelected ?? <int>{});

  SelectionModeOptions options;
  bool _enabled;
  final Set<int> _selectedItems;
  final Map<int, bool> _selectableItems = {};
  int? _rangeAnchor;
  bool _isDragInProgress = false;
  Set<int> _preDragSelection = {};
  Set<int> _previousDragSelection = {};

  AutoScrollManager? _autoScrollManager;

  bool get enabled => _enabled;
  Set<int> get selectedItems => Set.unmodifiable(_selectedItems);
  List<int> get selectedItemsList => _selectedItems.toList();
  int get selectedCount => _selectedItems.length;
  bool get hasSelection => _selectedItems.isNotEmpty;
  int? get rangeAnchor => _rangeAnchor;
  bool get isDragInProgress => _isDragInProgress;

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
  }

  /// Update options and apply changes
  void updateOptions(SelectionModeOptions newOptions) {
    options = newOptions;

    // Apply maxSelections if changed
    if (options.maxSelections != null &&
        _selectedItems.length > options.maxSelections!) {
      final excess = _selectedItems.length - options.maxSelections!;
      final toRemove = _selectedItems.take(excess).toList();
      _selectedItems.removeAll(toRemove);
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void setItemSelectable(int index, bool selectable) {
    _selectableItems[index] = selectable;

    if (!selectable && _selectedItems.contains(index)) {
      _selectedItems.remove(index);
      if (_rangeAnchor == index) {
        _rangeAnchor = null;
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _selectableItems.remove(index);
    _selectedItems.remove(index);
    if (_rangeAnchor == index) {
      _rangeAnchor = null;
    }
    _checkAutoDisable();
  }

  bool isSelectable(int index) => _selectableItems[index] ?? true;

  void enable({List<int>? initialSelected}) {
    _setEnabled(true);
    _triggerHaptic(HapticEvent.modeEnabled);
    if (initialSelected != null) {
      final selectableInitial = initialSelected.where(isSelectable);
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
    _rangeAnchor = null;
    _isDragInProgress = false;
    _autoScrollManager?.stopAutoScroll();
    notifyListeners();
  }

  void toggle() {
    _setEnabled(!_enabled);
    if (_enabled) {
      _triggerHaptic(HapticEvent.modeEnabled);
    } else {
      _triggerHaptic(HapticEvent.modeDisabled);
      _rangeAnchor = null;
      _isDragInProgress = false;
      _autoScrollManager?.stopAutoScroll();
    }
    notifyListeners();
  }

  bool _shouldBlockManualSelection() {
    return !_enabled && options.selectionBehavior == SelectionBehavior.manual;
  }

  void toggleSelection(int item) {
    if (!isSelectable(item)) return;

    if (_shouldBlockManualSelection()) {
      return;
    }

    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
      _triggerHaptic(HapticEvent.itemDeselected);
      if (_rangeAnchor == item) {
        _rangeAnchor = null;
      }
      _checkAutoDisable();
    } else {
      if (_canAddMoreSelections()) {
        if (!_enabled && _shouldAutoEnable()) {
          _setEnabled(true);
          _triggerHaptic(HapticEvent.modeEnabled);
        }
        _selectedItems.add(item);
        _triggerHaptic(HapticEvent.itemSelected);
        _rangeAnchor ??= item;
      } else {
        _triggerHaptic(HapticEvent.maxItemsReached);
        return;
      }
    }
    notifyListeners();
  }

  void selectRange(int from, int to) {
    if (_shouldBlockManualSelection()) {
      return;
    }
    if (!_enabled && options.selectionBehavior == SelectionBehavior.manual) {
      return;
    }
    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final start = math.min(from, to);
    final end = math.max(from, to);
    final oldLength = _selectedItems.length;
    bool hitLimit = false;

    for (int i = start; i <= end; i++) {
      if (isSelectable(i)) {
        if (_canAddMoreSelections()) {
          _selectedItems.add(i);
        } else if (!hitLimit) {
          _triggerHaptic(HapticEvent.maxItemsReached);
          hitLimit = true;
          break;
        }
      }
    }

    if (_selectedItems.length != oldLength) {
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void deselectRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    final oldLength = _selectedItems.length;

    for (int i = start; i <= end; i++) {
      _selectedItems.remove(i);
    }

    if (_selectedItems.length != oldLength) {
      if (_selectedItems.isEmpty) {
        _rangeAnchor = null;
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void toggleRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);

    if (!_enabled && _shouldAutoEnable()) {
      _setEnabled(true);
      _triggerHaptic(HapticEvent.modeEnabled);
    }

    final oldLength = _selectedItems.length;
    bool hitLimit = false;

    for (int i = start; i <= end; i++) {
      if (isSelectable(i)) {
        if (_selectedItems.contains(i)) {
          _selectedItems.remove(i);
        } else if (_canAddMoreSelections()) {
          _selectedItems.add(i);
        } else if (!hitLimit) {
          _triggerHaptic(HapticEvent.maxItemsReached);
          hitLimit = true;
          break;
        }
      }
    }

    if (_selectedItems.length != oldLength) {
      if (_selectedItems.isEmpty) {
        _rangeAnchor = null;
      }
      _checkAutoDisable();
      _triggerHaptic(HapticEvent.rangeSelection);
      notifyListeners();
    }
  }

  void clearRange(int from, int to) => deselectRange(from, to);

  List<int> getSelectedInRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    return _selectedItems.where((item) => item >= start && item <= end).toList()
      ..sort();
  }

  List<int> getSelectableInRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    final selectableInRange = <int>[];
    for (int i = start; i <= end; i++) {
      if (isSelectable(i)) {
        selectableInRange.add(i);
      }
    }
    return selectableInRange;
  }

  int getSelectedCountInRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    return _selectedItems.where((item) => item >= start && item <= end).length;
  }

  bool hasSelectionInRange(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    return _selectedItems.any((item) => item >= start && item <= end);
  }

  bool isRangeFullySelected(int from, int to) {
    final start = math.min(from, to);
    final end = math.max(from, to);

    for (int i = start; i <= end; i++) {
      if (isSelectable(i) && !_selectedItems.contains(i)) {
        return false;
      }
    }
    return getSelectableInRange(from, to).isNotEmpty;
  }

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

    if ((isShiftPressed || isRangeMode) && _rangeAnchor != null) {
      selectRange(_rangeAnchor!, index);
    } else {
      toggleSelection(index);
      _rangeAnchor = index;
    }
  }

  void setRangeAnchor(int index) {
    if (!isSelectable(index)) return;
    _rangeAnchor = index;
    if (!_selectedItems.contains(index)) {
      toggleSelection(index);
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

    _preDragSelection = Set<int>.from(_selectedItems);
    _previousDragSelection = Set<int>.from(_selectedItems);
    _rangeAnchor = index;
    _isDragInProgress = true;
    _triggerHaptic(HapticEvent.dragStart);

    if (!_selectedItems.contains(index)) {
      if (_canAddMoreSelections()) {
        _selectedItems.add(index);
        _triggerHaptic(HapticEvent.itemSelected);
        notifyListeners();
      } else {
        _triggerHaptic(HapticEvent.maxItemsReached);
      }
    }
  }

  void handleDragOver(int index, [Offset? globalPosition, Size? viewportSize]) {
    if (!_isDragInProgress || _rangeAnchor == null || !isSelectable(index)) {
      return;
    }

    // Handle auto-scroll if enabled and position/viewport provided
    if (_autoScrollManager != null &&
        globalPosition != null &&
        viewportSize != null) {
      _autoScrollManager!.handleDragUpdate(globalPosition, viewportSize);
    }

    // Calculate new selection range
    final newSelection = Set<int>.from(_preDragSelection);
    bool hitLimit = false;

    if (index == _rangeAnchor) {
      if (_canAddMoreItems(newSelection)) {
        newSelection.add(_rangeAnchor!);
      } else {
        hitLimit = true;
      }
    } else {
      final start = math.min(_rangeAnchor!, index);
      final end = math.max(_rangeAnchor!, index);

      for (int i = start; i <= end; i++) {
        if (isSelectable(i)) {
          if (_canAddMoreItems(newSelection)) {
            newSelection.add(i);
          } else if (!hitLimit) {
            _triggerHaptic(HapticEvent.maxItemsReached);
            hitLimit = true;
            break;
          }
        }
      }
    }

    // Trigger haptic for newly selected/deselected items during drag
    final newlySelected = newSelection.difference(_previousDragSelection);
    final newlyDeselected = _previousDragSelection.difference(newSelection);

    if (newlySelected.isNotEmpty) {
      for (final _ in newlySelected) {
        _triggerHaptic(HapticEvent.itemSelectedInRange);
      }
    }

    if (newlyDeselected.isNotEmpty) {
      for (final _ in newlyDeselected) {
        _triggerHaptic(HapticEvent.itemDeselectedInRange);
      }
    }

    _selectedItems.clear();
    _selectedItems.addAll(newSelection);
    _previousDragSelection = Set<int>.from(newSelection);

    notifyListeners();
  }

  void endRangeSelection() {
    _isDragInProgress = false;
    _preDragSelection.clear();
    _previousDragSelection.clear();
    _autoScrollManager?.stopAutoScroll();
    _checkAutoDisable();
  }

  void clearSelected() {
    if (_selectedItems.isEmpty) return;
    _selectedItems.clear();
    _rangeAnchor = null;
    _checkAutoDisable();
    notifyListeners();
  }

  void deselectAll() {
    if (_selectedItems.isEmpty) return;
    _selectedItems.clear();
    _rangeAnchor = null;
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
    final selectableItems = items.where(isSelectable);
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

    final selectableItems = allItems.where(isSelectable).toSet();
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
      if (_canAddMoreSelections()) {
        _selectedItems.add(item);
      } else if (!hitLimit) {
        _triggerHaptic(HapticEvent.maxItemsReached);
        hitLimit = true;
        break;
      }
    }
  }

  bool _canAddMoreSelections() {
    final maxSelections = options.maxSelections;
    return maxSelections == null || _selectedItems.length < maxSelections;
  }

  bool _canAddMoreItems(Set<int> selection) {
    final maxSelections = options.maxSelections;
    return maxSelections == null || selection.length < maxSelections;
  }

  /// Check if selection mode should auto-enable based on behavior
  bool _shouldAutoEnable() {
    return options.selectionBehavior == SelectionBehavior.autoEnable ||
        options.selectionBehavior == SelectionBehavior.implicit;
  }

  /// Check if selection mode should auto-disable when empty
  void _checkAutoDisable() {
    if (_enabled &&
        _selectedItems.isEmpty &&
        options.selectionBehavior == SelectionBehavior.implicit) {
      _setEnabled(false);
      _triggerHaptic(HapticEvent.modeDisabled);
      _rangeAnchor = null;
      _isDragInProgress = false;
      _autoScrollManager?.stopAutoScroll();
    }
  }

  void _triggerHaptic(HapticEvent event) {
    final resolver = options.hapticResolver ?? HapticFeedbackResolver.all;
    resolver.call(event);
  }

  @override
  void dispose() {
    _autoScrollManager?.dispose();
    super.dispose();
  }
}
