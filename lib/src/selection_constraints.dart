/// Constraints for selection behavior
class SelectionConstraints {
  const SelectionConstraints({
    this.maxSelections,
  });

  const SelectionConstraints.none() : maxSelections = null;

  /// Maximum number of items that can be selected (null = unlimited)
  final int? maxSelections;

  bool canAddMoreSelections(int currentCount) {
    if (maxSelections == null) return true;

    return currentCount < maxSelections!;
  }

  bool canAddToSelection(Set<int> selection) {
    final limit = maxSelections;
    if (limit == null) return true;

    return selection.length < limit;
  }

  Set<int> enforceConstraints(Set<int> selection) {
    final limit = maxSelections;
    if (limit == null) return selection;

    return selection.take(limit).toSet();
  }

  SelectionConstraints copyWith({int? maxSelections}) {
    return SelectionConstraints(
      maxSelections: maxSelections ?? this.maxSelections,
    );
  }
}
