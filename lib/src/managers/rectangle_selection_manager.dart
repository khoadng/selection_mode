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
  // Canvas coordinates
  Offset? _startPosition;
  // Canvas coordinates for selection calculations
  Offset? _currentCanvasPosition;
  // Viewport coordinates for overlay drawing
  Offset? _currentViewportPosition;
  Set<int> _preSelectionState = {};
  double _initialScrollOffset = 0;

  bool get isSelectionInProgress => _isSelectionInProgress;
  Offset? get startPosition => _startPosition;
  Offset? get currentViewportPosition => _currentViewportPosition;

  /// Current selection rectangle bounds (canvas coordinates)
  Rect? get selectionRect {
    if (_startPosition == null || _currentCanvasPosition == null) return null;

    return Rect.fromPoints(_startPosition!, _currentCanvasPosition!);
  }

  /// Get rectangle in viewport coordinates for painting
  Rect? getViewportRect(double currentScrollOffset) {
    if (_startPosition == null || _currentViewportPosition == null) return null;

    final scrollDelta = currentScrollOffset - _initialScrollOffset;
    final adjustedStart = _startPosition! - Offset(0, scrollDelta);

    return Rect.fromPoints(adjustedStart, _currentViewportPosition!);
  }

  /// Start rectangle selection
  void startSelection(
    Offset position,
    Set<int> currentSelection,
    double scrollOffset,
  ) {
    _isSelectionInProgress = true;
    _startPosition = position;
    _currentCanvasPosition = position;
    _currentViewportPosition = position;
    _preSelectionState = Set<int>.from(currentSelection);
    _initialScrollOffset = scrollOffset;
    notifyListeners();
  }

  /// Update current position during selection
  void updatePosition(Offset viewportPosition, double currentScrollOffset) {
    if (!_isSelectionInProgress) return;

    _currentViewportPosition = viewportPosition;

    // Convert viewport position to canvas coordinates for selection calculations
    final scrollDelta = currentScrollOffset - _initialScrollOffset;
    _currentCanvasPosition = viewportPosition + Offset(0, scrollDelta);

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

      print(
          'Checking item $index: $itemRect against selection rect: $rect, overlaps: ${itemRect?.overlaps(rect)}');

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
    _currentCanvasPosition = null;
    _currentViewportPosition = null;
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
