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
  }) : _enabled = initialEnabled {
    _rangeManager = RangeManager(
      isSelectable: _selectabilityManager.isSelectable,
    );
    _selectedIdentifiers = Set<Object>.from(initialSelected ?? <int>{});
  }

  SelectionOptions options;
  bool _enabled;

  late Set<Object> _selectedIdentifiers = <Object>{};
  final Map<Object, int> _identifierToIndex = <Object, int>{};
  final Map<int, Object> _indexToIdentifier = <int, Object>{};

  final SelectabilityManager _selectabilityManager = SelectabilityManager();
  final DragSelectionManager _dragManager = DragSelectionManager();

  late final RangeManager _rangeManager;
  AutoScrollManager? _autoScrollManager;

  bool get isActive => _enabled;

  Set<int> get selection {
    return _selectedIdentifiers
        .map((id) => _identifierToIndex[id])
        .where((index) => index != null)
        .cast<int>()
        .toSet();
  }

  Set<Object> get selectedIdentifiers => Set.unmodifiable(_selectedIdentifiers);

  int get selectedCount => _selectedIdentifiers.length;
  bool get hasSelection => _selectedIdentifiers.isNotEmpty;
  int? get rangeAnchor => _rangeManager.anchor;
  bool get isDragInProgress => _dragManager.isDragInProgress;

  void registerItem(int index, Object identifier, bool isSelectable) {
    _identifierToIndex[identifier] = index;
    _indexToIdentifier[index] = identifier;

    _selectabilityManager.setSelectable(index, isSelectable);

    // If identifier was selected but item became unselectable, remove selection
    if (!isSelectable && _selectedIdentifiers.contains(identifier)) {
      _selectedIdentifiers.remove(identifier);
      if (_rangeManager.anchor == index) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void unregisterItem(int index) {
    final identifier = _indexToIdentifier[index];
    if (identifier != null) {
      _identifierToIndex.remove(identifier);
      _indexToIdentifier.remove(index);
    }

    _selectabilityManager.removeItem(index);

    if (_rangeManager.anchor == index) {
      _rangeManager.clearAnchor();
    }
    _checkAutoDisable();
  }

  Object _getIdentifier(int index) {
    return _indexToIdentifier[index] ?? index;
  }

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
  }

  void updateOptions(SelectionOptions newOptions) {
    options = newOptions;

    if (options.constraints.maxSelections != null) {
      final maxCount = options.constraints.maxSelections!;
      if (_selectedIdentifiers.length > maxCount) {
        final identifiersToRemove =
            _selectedIdentifiers.skip(maxCount).toList();
        for (final id in identifiersToRemove) {
          _selectedIdentifiers.remove(id);
        }
        _checkAutoDisable();
        notifyListeners();
      }
    }
  }

  void setItemSelectable(int index, bool selectable) {
    _selectabilityManager.setSelectable(index, selectable);

    if (!selectable) {
      final identifier = _getIdentifier(index);
      if (_selectedIdentifiers.contains(identifier)) {
        _selectedIdentifiers.remove(identifier);
        if (_rangeManager.anchor == index) {
          _rangeManager.clearAnchor();
        }
        _checkAutoDisable();
        notifyListeners();
      }
    }
  }

  void removeItem(int index) {
    unregisterItem(index);
    notifyListeners();
  }

  bool isSelectable(int index) => _selectabilityManager.isSelectable(index);

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
      _selectedIdentifiers.clear();
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

    final identifier = _getIdentifier(item);

    if (_selectedIdentifiers.contains(identifier)) {
      _selectedIdentifiers.remove(identifier);
      _triggerHaptic(HapticEvent.itemDeselected);
      if (_rangeManager.anchor == item) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
    } else {
      if (options.constraints
          .canAddMoreSelections(_selectedIdentifiers.length)) {
        if (!_enabled && _shouldAutoEnable()) {
          _setEnabled(true);
          _triggerHaptic(HapticEvent.modeEnabled);
        }
        _selectedIdentifiers.add(identifier);
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
      options.constraints.maxSelections ?? -1,
    );

    if (result.addedItems.isNotEmpty) {
      for (final index in result.addedItems) {
        final identifier = _getIdentifier(index);
        _selectedIdentifiers.add(identifier);
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
        final identifier = _getIdentifier(index);
        _selectedIdentifiers.remove(identifier);
      }

      if (_selectedIdentifiers.isEmpty) {
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
      options.constraints.maxSelections ?? -1,
    );

    if (result.selection.length != currentIndexSelection.length) {
      final added = result.selection.difference(currentIndexSelection);
      final removed = currentIndexSelection.difference(result.selection);

      for (final index in removed) {
        final identifier = _getIdentifier(index);
        _selectedIdentifiers.remove(identifier);
      }

      for (final index in added) {
        final identifier = _getIdentifier(index);
        _selectedIdentifiers.add(identifier);
      }

      if (_selectedIdentifiers.isEmpty) {
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
    _triggerHaptic(HapticEvent.dragStart);

    if (!isSelected(index)) {
      if (options.constraints
          .canAddMoreSelections(_selectedIdentifiers.length)) {
        final identifier = _getIdentifier(index);
        _selectedIdentifiers.add(identifier);
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

    _selectedIdentifiers.clear();
    for (final index in result.newSelection) {
      final identifier = _getIdentifier(index);
      _selectedIdentifiers.add(identifier);
    }

    notifyListeners();
  }

  void endRangeSelection() {
    _dragManager.endDrag();
    _autoScrollManager?.stopAutoScroll();
    _checkAutoDisable();
  }

  void deselectAll() {
    if (_selectedIdentifiers.isEmpty) return;
    _selectedIdentifiers.clear();
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

    final oldLength = _selectedIdentifiers.length;
    final selectableItems = _selectabilityManager.filterSelectable(items);
    _addToSelectionByIndex(selectableItems);

    if (_selectedIdentifiers.length != oldLength) {
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

    _selectedIdentifiers.clear();
    _addToSelectionByIndex(newSelection);

    _checkAutoDisable();
    _triggerHaptic(HapticEvent.rangeSelection);
    notifyListeners();
  }

  bool isSelected(int item) {
    final identifier = _getIdentifier(item);
    return _selectedIdentifiers.contains(identifier);
  }

  void _setEnabled(bool value) {
    _enabled = value;
  }

  void _addToSelectionByIndex(Iterable<int> items) {
    bool hitLimit = false;
    for (final item in items) {
      if (options.constraints
          .canAddMoreSelections(_selectedIdentifiers.length)) {
        final identifier = _getIdentifier(item);
        _selectedIdentifiers.add(identifier);
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
        _selectedIdentifiers.isEmpty &&
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

  void _clearAllMappings() {
    _identifierToIndex.clear();
    _indexToIdentifier.clear();
    _selectabilityManager.clear();
    _selectedIdentifiers.clear();
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
