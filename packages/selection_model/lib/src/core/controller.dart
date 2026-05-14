import '../managers/drag_selection_manager.dart';
import '../managers/haptic_coordinator.dart';
import '../managers/range_manager.dart';
import '../managers/selectability_manager.dart';
import '../managers/selection_state_manager.dart';
import '../options/haptic_feedback.dart';
import '../options/selection_options.dart';
import 'selection_item_info.dart';

part 'drag_operations.dart';
part 'selection_operations.dart';

typedef SelectionModelListener = void Function();

class SelectionModeController {
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
    _hapticCoordinator = HapticCoordinator(_options.haptics);
  }

  late final SelectionOperations _selectionOps;
  late final DragOperations _dragOps;

  SelectionOptions _options = const SelectionOptions();
  bool _enabled;

  late final SelectionStateManager _stateManager;
  final SelectabilityManager _selectabilityManager = SelectabilityManager();
  final DragSelectionManager _dragManager = DragSelectionManager();

  late final RangeManager _rangeManager;
  late HapticCoordinator _hapticCoordinator;

  final List<SelectionModelListener> _listeners = [];
  bool _disposed = false;

  SelectionOptions get options => _options;
  bool get isActive => _enabled;
  Set<int> get visibleSelection => _stateManager.visibleSelection;
  Set<int> get selection => _stateManager.selection;
  bool get isDragInProgress => _dragManager.isDragInProgress;

  void addListener(SelectionModelListener listener) {
    if (_disposed) return;
    _listeners.add(listener);
  }

  void removeListener(SelectionModelListener listener) {
    _listeners.remove(listener);
  }

  void enable({List<int>? initialSelected}) {
    _setEnabled(true);
    _hapticCoordinator.trigger(HapticEvent.modeEnabled);
    if (initialSelected != null) {
      final selectableInitial =
          _selectabilityManager.filterSelectable(initialSelected);
      _addToSelectionByIndex(selectableInitial);
    }
    notifyListeners();
  }

  void disable({bool clearSelection = true}) {
    _setEnabled(false);
    _hapticCoordinator.trigger(HapticEvent.modeDisabled);
    if (clearSelection) {
      _stateManager.clearIdentifiers();
    }
    _rangeManager.clearAnchor();
    _dragManager.endDrag();

    notifyListeners();
  }

  void toggle() {
    _setEnabled(!_enabled);
    if (_enabled) {
      _hapticCoordinator.trigger(HapticEvent.modeEnabled);
    } else {
      _hapticCoordinator.trigger(HapticEvent.modeDisabled);
      _rangeManager.clearAnchor();
      _dragManager.endDrag();
    }
    notifyListeners();
  }

  void removeItem(int index) {
    unregister(index);
    notifyListeners();
  }

  void toggleItem(int item) => _selectionOps.toggleItem(item);
  void replaceSelection(int item) => _selectionOps.replaceSelection(item);
  void selectRange(int from, int to) => _selectionOps.selectRange(from, to);
  void deselectRange(int from, int to) => _selectionOps.deselectRange(from, to);
  void toggleRange(int from, int to) => _selectionOps.toggleRange(from, to);
  void deselectAll() => _selectionOps.deselectAll();
  void selectAll(List<int> items) => _selectionOps.selectAll(items);
  void invertSelection(List<int> allItems) =>
      _selectionOps.invertSelection(allItems);

  bool isSelected(int item) => _stateManager.isSelected(item);

  int? getAnchor() => _rangeManager.anchor;

  void register(SelectionItemInfo info) {
    _stateManager.registerItem(info.index, info.identifier);
    _selectabilityManager.setSelectable(info.index, info.isSelectable);

    if (!info.isSelectable && _stateManager.isSelected(info.index)) {
      _stateManager.removeIdentifier(info.identifier);
      if (_rangeManager.anchor == info.index) {
        _rangeManager.clearAnchor();
      }
      _checkAutoDisable();
      notifyListeners();
    }
  }

  void unregister(int index) {
    _stateManager.unregisterItem(index);
    _selectabilityManager.removeItem(index);

    if (_rangeManager.anchor == index) {
      _rangeManager.clearAnchor();
    }
    _checkAutoDisable();
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

  void startRangeSelection(int index) => _dragOps.startRangeSelection(index);
  void handleDragOver(int index) => _dragOps.handleDragOver(index);
  void endRangeSelection() => _dragOps.endRangeSelection();

  void _applyOptions(SelectionOptions options) {
    _options = options;
    _hapticCoordinator = HapticCoordinator(options.haptics);

    final maxSelections = options.constraints?.maxSelections;

    if (maxSelections != null && _stateManager.length > maxSelections) {
      final currentSelection = _stateManager.visibleSelection.toList();
      final toRemove = currentSelection.skip(maxSelections);

      for (final index in toRemove) {
        final identifier = _stateManager.getIdentifier(index);
        _stateManager.removeIdentifier(identifier);
      }
      _checkAutoDisable();
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
      _hapticCoordinator.trigger(HapticEvent.modeDisabled);
      _rangeManager.clearAnchor();
      _dragManager.endDrag();
    }
  }

  void _setEnabled(bool value) {
    _enabled = value;
  }

  void _addToSelectionByIndex(Iterable<int> items) {
    var hitLimit = false;
    for (final item in items) {
      final canAddMore =
          _options.constraints?.canAddMoreSelections(_stateManager.length) ??
              true;
      if (canAddMore) {
        final identifier = _stateManager.getIdentifier(item);
        _stateManager.addIdentifier(identifier);
      } else if (!hitLimit) {
        _hapticCoordinator.trigger(HapticEvent.maxItemsReached);
        hitLimit = true;
        break;
      }
    }
  }

  void _notify() => notifyListeners();

  void _clearAllMappings() {
    _stateManager.clear();
    _selectabilityManager.clear();
  }

  void notifyListeners() {
    if (_disposed) return;
    for (final listener in List<SelectionModelListener>.from(_listeners)) {
      listener();
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
    _rangeManager.dispose();
    _dragManager.reset();
    _clearAllMappings();
  }
}
