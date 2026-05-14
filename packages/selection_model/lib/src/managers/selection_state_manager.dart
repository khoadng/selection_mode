/// Manages selection state and item registration
class SelectionStateManager {
  SelectionStateManager([Set<int>? initialSelected])
      : _selectedIdentifiers = Set<Object>.from(initialSelected ?? <int>{});

  final Set<Object> _selectedIdentifiers;
  final Map<Object, int> _identifierToIndex = <Object, int>{};
  final Map<int, Object> _indexToIdentifier = <int, Object>{};
  bool _usesExplicitIdentifiers = false;

  /// Current selection as indices
  Set<int> get visibleSelection {
    final result = <int>{};
    for (final id in _selectedIdentifiers) {
      final index = _identifierToIndex[id];
      if (index != null) {
        result.add(index);
      }
    }
    return result;
  }

  Set<int> get selection {
    final result = <int>{};
    for (final identifier in _selectedIdentifiers) {
      final index = _identifierToIndex[identifier];
      if (index != null) {
        result.add(index);
      } else if (!_usesExplicitIdentifiers && identifier is int) {
        result.add(identifier);
      }
    }
    return result;
  }

  /// Check if an item is selected
  bool isSelected(int index) {
    final identifier = _indexToIdentifier[index];
    if (identifier == null) {
      return !_usesExplicitIdentifiers && _selectedIdentifiers.contains(index);
    }
    return _selectedIdentifiers.contains(identifier);
  }

  /// Get identifier for an index (fallback to index if not found)
  Object getIdentifier(int index) => _indexToIdentifier[index] ?? index;

  /// Register an item with its identifier
  void registerItem(int index, Object identifier) {
    if (identifier != index) {
      _usesExplicitIdentifiers = true;
    }
    _identifierToIndex[identifier] = index;
    _indexToIdentifier[index] = identifier;
  }

  /// Unregister an item and clean up its selection
  bool unregisterItem(
    int index, {
    bool removeSelection = false,
    Object? expectedIdentifier,
  }) {
    final currentIdentifier = _indexToIdentifier[index];
    if (currentIdentifier == null) {
      return false;
    }
    if (expectedIdentifier != null && currentIdentifier != expectedIdentifier) {
      return false;
    }
    if (removeSelection) {
      _identifierToIndex.remove(currentIdentifier);
      _indexToIdentifier.remove(index);
      _selectedIdentifiers.remove(currentIdentifier);
    }
    return true;
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

  bool retainSelectedIdentifiers(Iterable<Object> identifiers) {
    final allowedIdentifiers = identifiers.toSet();
    final oldLength = _selectedIdentifiers.length;
    _selectedIdentifiers.removeWhere(
      (identifier) => !allowedIdentifiers.contains(identifier),
    );
    return _selectedIdentifiers.length != oldLength;
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
    _usesExplicitIdentifiers = false;
  }
}
