import 'dart:math' as math;
import 'selection_constraints.dart';

/// Result of a drag update operation
class DragUpdateResult {
  const DragUpdateResult({
    required this.newSelection,
    required this.newlySelected,
    required this.newlyDeselected,
    required this.hitLimit,
  });

  final Set<int> newSelection;
  final Set<int> newlySelected;
  final Set<int> newlyDeselected;
  final bool hitLimit;
}

/// Manages drag selection state and operations
class DragSelectionManager {
  bool _isDragInProgress = false;
  Set<int> _preDragSelection = {};
  Set<int> _previousDragSelection = {};
  int? _dragAnchor;

  bool get isDragInProgress => _isDragInProgress;
  int? get dragAnchor => _dragAnchor;

  /// Start a drag selection operation
  void startDrag(int anchorIndex, Set<int> currentSelection) {
    _isDragInProgress = true;
    _dragAnchor = anchorIndex;
    _preDragSelection = Set<int>.from(currentSelection);
    _previousDragSelection = Set<int>.from(currentSelection);
  }

  /// Calculate new selection during drag over operation
  DragUpdateResult calculateDragUpdate(
    int targetIndex,
    bool Function(int) isSelectable,
    SelectionConstraints? constraints,
  ) {
    if (!_isDragInProgress || _dragAnchor == null) {
      return DragUpdateResult(
        newSelection: _preDragSelection,
        newlySelected: {},
        newlyDeselected: {},
        hitLimit: false,
      );
    }

    final newSelection = Set<int>.from(_preDragSelection);
    bool hitLimit = false;
    final anchor = _dragAnchor!;

    if (targetIndex == anchor) {
      final canAddToSelection =
          constraints?.canAddToSelection(newSelection) ?? true;

      if (canAddToSelection) {
        newSelection.add(anchor);
      } else {
        hitLimit = true;
      }
    } else {
      final start = math.min(anchor, targetIndex);
      final end = math.max(anchor, targetIndex);

      for (int i = start; i <= end; i++) {
        if (isSelectable(i)) {
          final canAddToSelection =
              constraints?.canAddToSelection(newSelection) ?? true;
          if (canAddToSelection) {
            newSelection.add(i);
          } else if (!hitLimit) {
            hitLimit = true;
            break;
          }
        }
      }
    }

    final newlySelected = newSelection.difference(_previousDragSelection);
    final newlyDeselected = _previousDragSelection.difference(newSelection);

    _previousDragSelection = Set<int>.from(newSelection);

    return DragUpdateResult(
      newSelection: newSelection,
      newlySelected: newlySelected,
      newlyDeselected: newlyDeselected,
      hitLimit: hitLimit,
    );
  }

  /// End the drag selection operation
  void endDrag() {
    _isDragInProgress = false;
    _dragAnchor = null;
    _preDragSelection.clear();
    _previousDragSelection.clear();
  }

  /// Cancel the drag and restore pre-drag state
  Set<int> cancelDrag() {
    final originalSelection = Set<int>.from(_preDragSelection);
    endDrag();
    return originalSelection;
  }

  /// Reset manager state
  void reset() {
    endDrag();
  }
}
