import 'package:flutter/widgets.dart';

/// Registration data for a selectable item
class SelectionItemInfo {
  const SelectionItemInfo({
    required this.index,
    required this.identifier,
    required this.isSelectable,
    this.positionCallback,
  });

  /// The index of this item
  final int index;

  /// Unique identifier for this item
  final Object identifier;

  /// Whether this item can be selected
  final bool isSelectable;

  /// Callback to get current bounds of the item
  final Rect? Function()? positionCallback;

  SelectionItemInfo copyWith({
    int? index,
    Object? identifier,
    bool? isSelectable,
    Rect? Function()? positionCallback,
  }) {
    return SelectionItemInfo(
      index: index ?? this.index,
      identifier: identifier ?? this.identifier,
      isSelectable: isSelectable ?? this.isSelectable,
      positionCallback: positionCallback ?? this.positionCallback,
    );
  }
}
