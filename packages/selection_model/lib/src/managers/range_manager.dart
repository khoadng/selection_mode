import 'dart:math' as math;

class RangeManager {
  RangeManager({
    required this.isSelectable,
  });

  final bool Function(int) isSelectable;

  int? _anchor;
  int? get anchor => _anchor;

  void setAnchor(int index) {
    if (!isSelectable(index)) return;
    _anchor = index;
  }

  void clearAnchor() {
    _anchor = null;
  }

  /// Calculate range selection changes
  RangeSelectionResult calculateRangeSelection(
    Set<int> currentSelection,
    int from,
    int to,
    int maxSelections,
  ) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    final newSelection = Set<int>.from(currentSelection);
    final added = <int>[];
    bool hitLimit = false;

    for (int i = start; i <= end; i++) {
      if (isSelectable(i) && !newSelection.contains(i)) {
        if (maxSelections == -1 || newSelection.length < maxSelections) {
          newSelection.add(i);
          added.add(i);
        } else {
          hitLimit = true;
          break;
        }
      }
    }

    return RangeSelectionResult(
      selection: newSelection,
      addedItems: added,
      hitLimit: hitLimit,
    );
  }

  /// Calculate range deselection
  Set<int> calculateRangeDeselection(
    Set<int> currentSelection,
    int from,
    int to,
  ) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    final newSelection = Set<int>.from(currentSelection);

    for (int i = start; i <= end; i++) {
      newSelection.remove(i);
    }

    return newSelection;
  }

  /// Calculate range toggle
  RangeSelectionResult calculateRangeToggle(
    Set<int> currentSelection,
    int from,
    int to,
    int maxSelections,
  ) {
    final start = math.min(from, to);
    final end = math.max(from, to);
    final newSelection = Set<int>.from(currentSelection);
    final added = <int>[];
    bool hitLimit = false;

    for (int i = start; i <= end; i++) {
      if (isSelectable(i)) {
        if (newSelection.contains(i)) {
          newSelection.remove(i);
        } else if (maxSelections == -1 || newSelection.length < maxSelections) {
          newSelection.add(i);
          added.add(i);
        } else {
          hitLimit = true;
          break;
        }
      }
    }

    return RangeSelectionResult(
      selection: newSelection,
      addedItems: added,
      hitLimit: hitLimit,
    );
  }

  /// Get shift selection target
  int? getShiftSelectionTarget(int index) {
    if (!isSelectable(index)) return null;
    return _anchor;
  }

  void dispose() {
    _anchor = null;
  }
}

class RangeSelectionResult {
  const RangeSelectionResult({
    required this.selection,
    required this.addedItems,
    required this.hitLimit,
  });

  final Set<int> selection;
  final List<int> addedItems;
  final bool hitLimit;
}
