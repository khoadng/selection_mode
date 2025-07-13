/// Manages which items can be selected
class SelectabilityManager {
  final Map<int, bool> _selectableItems = {};

  /// Check if an item can be selected
  bool isSelectable(int index) => _selectableItems[index] ?? true;

  /// Set whether an item can be selected
  void setSelectable(int index, bool selectable) {
    _selectableItems[index] = selectable;
  }

  /// Remove item from selectability tracking
  void removeItem(int index) {
    _selectableItems.remove(index);
  }

  /// Filter a collection to only selectable items
  Iterable<int> filterSelectable(Iterable<int> items) {
    return items.where(isSelectable);
  }

  /// Get all items that are explicitly marked as unselectable
  Set<int> getUnselectableItems() {
    return _selectableItems.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Clear all selectability overrides
  void clear() {
    _selectableItems.clear();
  }
}
