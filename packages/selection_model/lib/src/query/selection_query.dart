import '../core/controller.dart';

/// A fluent query builder for working with selected items in a clean, composable way.
///
/// Example usage:
/// ```dart
/// // Get selected items
/// final selectedPhotos = controller.selectedFrom(photos).toList();
///
/// // Transform selected items
/// final titles = controller.selectedFrom(photos).map((p) => p.title).toList();
///
/// // Filter and transform
/// final activeTitles = controller
///     .selectedFrom(contacts)
///     .where((c) => c.isActive)
///     .map((c) => c.name)
///     .toList();
/// ```
class SelectionQuery<T> {
  const SelectionQuery._(this._controller, this._items);

  final SelectionModeController _controller;
  final List<T> _items;

  /// Returns the currently selected items as a list
  List<T> toList() => _getSelectedItems();

  /// Transforms each selected item using the provided function
  SelectionQuery<R> map<R>(R Function(T item) transform) {
    final mapped = <R>[];
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) {
        mapped.add(transform(_items[i]));
      }
    }
    return SelectionQuery._(
      _controller,
      mapped,
    );
  }

  /// Filters selected items using the provided test function
  SelectionQuery<T> where(bool Function(T item) test) {
    final filtered = <T>[];
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) {
        final item = _items[i];
        if (test(item)) {
          filtered.add(item);
        }
      }
    }
    return SelectionQuery._(
      _controller,
      filtered,
    );
  }

  /// Returns selected items with their original indices
  List<(int index, T item)> get withIndices {
    final result = <(int, T)>[];
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) {
        result.add((i, _items[i]));
      }
    }
    return result;
  }

  /// Returns true if any items are selected
  bool get hasAny {
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) return true;
    }
    return false;
  }

  /// Returns the number of selected items
  int get length {
    int count = 0;
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) count++;
    }
    return count;
  }

  List<T> _getSelectedItems() {
    final selected = <T>[];
    for (int i = 0; i < _items.length; i++) {
      if (_controller.isSelected(i)) {
        selected.add(_items[i]);
      }
    }
    return selected;
  }
}

extension SelectionQueryExtension on SelectionModeController {
  SelectionQuery<T> selectedFrom<T>(List<T> items) {
    return SelectionQuery._(this, items);
  }
}
