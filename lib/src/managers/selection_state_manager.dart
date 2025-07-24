/// Manages selection state and item registration
class SelectionStateManager {
  SelectionStateManager([Set<int>? initialSelected])
      : _selectedIdentifiers = Set<Object>.from(initialSelected ?? <int>{});

  final Set<Object> _selectedIdentifiers;
  final Map<Object, int> _identifierToIndex = <Object, int>{};
  final Map<int, Object> _indexToIdentifier = <int, Object>{};

  /// Current selection as indices
  Set<int> get selection {
    return _selectedIdentifiers
        .map((id) => _identifierToIndex[id])
        .where((index) => index != null)
        .cast<int>()
        .toSet();
  }

  /// Check if an item is selected
  bool isSelected(int index) {
    final identifier = getIdentifier(index);
    return _selectedIdentifiers.contains(identifier);
  }

  /// Get identifier for an index (fallback to index if not found)
  Object getIdentifier(int index) => _indexToIdentifier[index] ?? index;

  /// Register an item with its identifier
  void registerItem(int index, Object identifier) {
    _identifierToIndex[identifier] = index;
    _indexToIdentifier[index] = identifier;
  }

  /// Unregister an item and clean up its selection
  void unregisterItem(int index) {
    final identifier = _indexToIdentifier[index];
    if (identifier != null) {
      _identifierToIndex.remove(identifier);
      _indexToIdentifier.remove(index);
      _selectedIdentifiers.remove(identifier);
    }
  }

  /// Add identifier to selection
  void addIdentifier(Object identifier) {
    _selectedIdentifiers.add(identifier);
  }

  /// Remove identifier from selection
  void removeIdentifier(Object identifier) {
    _selectedIdentifiers.remove(identifier);
  }

  /// Clear all selections
  void clearIdentifiers() {
    _selectedIdentifiers.clear();
  }

  /// Check if selection is empty
  bool get isEmpty => _selectedIdentifiers.isEmpty;

  /// Get selection count
  int get length => _selectedIdentifiers.length;

  /// Clear all state
  void clear() {
    _selectedIdentifiers.clear();
    _identifierToIndex.clear();
    _indexToIdentifier.clear();
  }
}
