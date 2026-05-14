import 'dart:ui';

import 'package:selection_model/selection_model.dart' as model;

/// Registration data for a selectable item.
class SelectionItemInfo extends model.SelectionItemInfo {
  const SelectionItemInfo({
    required super.index,
    required super.identifier,
    required super.isSelectable,
    this.positionCallback,
  });

  /// Callback to get current bounds of the item.
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
