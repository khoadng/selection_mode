import 'package:selection_mode/selection_mode.dart';
import 'package:selection_mode/src/core/selection_item_info.dart';

extension TestHelpers on SelectionModeController {
  void registerTestItems(int count, {bool selectable = true}) {
    for (int i = 0; i < count; i++) {
      register(SelectionItemInfo(
        index: i,
        identifier: i,
        isSelectable: selectable,
      ));
    }
  }

  void registerTestRange(int start, int end, {bool selectable = true}) {
    for (int i = start; i <= end; i++) {
      register(SelectionItemInfo(
        index: i,
        identifier: i,
        isSelectable: selectable,
      ));
    }
  }
}
