class SelectionItemInfo {
  const SelectionItemInfo({
    required this.index,
    Object? identifier,
    this.isSelectable = true,
  }) : identifier = identifier ?? index;

  final int index;
  final Object identifier;
  final bool isSelectable;
}
