import 'package:selection_mode/selection_mode.dart';

extension TestHelpers on SelectionModeController {
  void registerTestItems(int count, {bool selectable = true}) {
    for (int i = 0; i < count; i++) {
      registerItem(i, i, selectable);
    }
  }

  void registerTestRange(int start, int end, {bool selectable = true}) {
    for (int i = start; i <= end; i++) {
      registerItem(i, i, selectable);
    }
  }
}
