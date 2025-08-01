/// Registration data for a selectable item
class SelectionItemInfo {
  const SelectionItemInfo({
    required this.index,
    required this.identifier,
    required this.isSelectable,
  });

  /// The index of this item
  final int index;

  /// Unique identifier for this item
  final Object identifier;

  /// Whether this item can be selected
  final bool isSelectable;

  SelectionItemInfo copyWith({
    int? index,
    Object? identifier,
    bool? isSelectable,
  }) {
    return SelectionItemInfo(
      index: index ?? this.index,
      identifier: identifier ?? this.identifier,
      isSelectable: isSelectable ?? this.isSelectable,
    );
  }
}
