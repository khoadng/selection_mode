import 'package:flutter/widgets.dart';
import '../options/selection_constraints.dart';

/// Result of a rectangle selection operation
class RectangleSelectionResult {
  const RectangleSelectionResult({
    required this.newSelection,
    required this.addedItems,
    required this.removedItems,
    required this.hitLimit,
  });

  final Set<int> newSelection;
  final Set<int> addedItems;
  final Set<int> removedItems;
  final bool hitLimit;
}

/// Manages rectangle selection state and operations
class RectangleSelectionManager extends ChangeNotifier {
  bool _isSelectionInProgress = false;
  Offset? _startPosition;
  Offset? _currentPosition;
  Set<int> _preSelectionState = {};
  double _initialScrollOffset = 0;

  bool get isSelectionInProgress => _isSelectionInProgress;
  Offset? get startPosition => _startPosition;
  Offset? get currentPosition => _currentPosition;

  /// Current selection rectangle bounds (content coordinates)
  Rect? get selectionRect {
    if (_startPosition == null || _currentPosition == null) return null;

    final start = _startPosition!;
    final current = _currentPosition!;

    return Rect.fromPoints(start, current);
  }

  /// Get rectangle in viewport coordinates for painting
  Rect? getViewportRect(double currentScrollOffset) {
    if (_startPosition == null || _currentPosition == null) return null;

    final scrollDelta = currentScrollOffset - _initialScrollOffset;
    final adjustedStart = _startPosition! - Offset(0, scrollDelta);

    return Rect.fromPoints(adjustedStart, _currentPosition!);
  }

  /// Start rectangle selection
  void startSelection(
    Offset position,
    Set<int> currentSelection,
    double scrollOffset,
  ) {
    _isSelectionInProgress = true;
    _startPosition = position;
    _currentPosition = position;
    _preSelectionState = Set<int>.from(currentSelection);
    _initialScrollOffset = scrollOffset;
    notifyListeners();
  }

  /// Update current position during selection
  void updatePosition(Offset position) {
    if (!_isSelectionInProgress) return;
    _currentPosition = position;
    notifyListeners();
  }

  /// Calculate items that intersect with current rectangle
  RectangleSelectionResult calculateSelection(
    Map<int, Rect? Function()> positionCallbacks,
    bool Function(int) isSelectable,
    SelectionConstraints? constraints,
  ) {
    if (!_isSelectionInProgress || selectionRect == null) {
      return RectangleSelectionResult(
        newSelection: _preSelectionState,
        addedItems: {},
        removedItems: {},
        hitLimit: false,
      );
    }

    final rect = selectionRect!;
    final intersectingItems = <int>{};
    bool hitLimit = false;

    // Find all items that intersect with rectangle
    for (final entry in positionCallbacks.entries) {
      final index = entry.key;
      final getPosition = entry.value;

      if (!isSelectable(index)) continue;

      final itemRect = getPosition();
      if (itemRect != null && rect.overlaps(itemRect)) {
        intersectingItems.add(index);
      }
    }

    // Clean up pre-selection state
    final newSelection = <int>{};

    for (final item in intersectingItems) {
      if (!newSelection.contains(item)) {
        final canAdd = constraints?.canAddToSelection(newSelection) ?? true;
        if (canAdd) {
          newSelection.add(item);
        } else {
          hitLimit = true;
          break;
        }
      }
    }

    final addedItems = intersectingItems.difference(_preSelectionState);
    final removedItems = <int>{};

    return RectangleSelectionResult(
      newSelection: newSelection,
      addedItems: addedItems,
      removedItems: removedItems,
      hitLimit: hitLimit,
    );
  }

  /// End rectangle selection
  void endSelection() {
    _isSelectionInProgress = false;
    _startPosition = null;
    _currentPosition = null;
    _preSelectionState.clear();
    _initialScrollOffset = 0;
    notifyListeners();
  }

  /// Cancel rectangle selection and return to pre-selection state
  Set<int> cancelSelection() {
    final originalSelection = Set<int>.from(_preSelectionState);
    endSelection();
    return originalSelection;
  }

  /// Reset manager state
  void reset() {
    endSelection();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
