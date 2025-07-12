import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Bulk Operations', () {
    late SelectionModeController controller;

    setUp(() {
      controller = SelectionModeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('clearSelected removes all selections', () {
      controller.enable();
      controller.selectRange(0, 5);

      controller.clearSelected();

      expect(controller.selectedItems, isEmpty);
    });

    test('selectAll selects provided items', () {
      controller.enable();

      controller.selectAll([1, 3, 5, 7]);

      expect(controller.selectedItems, equals({1, 3, 5, 7}));
    });

    test('invertSelection inverts selection', () {
      controller.enable();
      controller.toggleSelection(1);
      controller.toggleSelection(3);

      controller.invertSelection([0, 1, 2, 3, 4]);

      expect(controller.selectedItems, equals({0, 2, 4}));
    });
  });
}
