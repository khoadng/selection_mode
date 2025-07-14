import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'test_helpers.dart';

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

    test('deselectAll removes all selections', () {
      controller.registerTestItems(10);
      controller.enable();
      controller.selectRange(0, 5);

      controller.deselectAll();

      expect(controller.selection, isEmpty);
    });

    test('selectAll selects provided items', () {
      controller.registerTestItems(10);
      controller.enable();

      controller.selectAll([1, 3, 5, 7]);

      expect(controller.selection, equals({1, 3, 5, 7}));
    });

    test('invertSelection inverts selection', () {
      controller.registerTestItems(10);
      controller.enable();
      controller.toggleItem(1);
      controller.toggleItem(3);

      controller.invertSelection([0, 1, 2, 3, 4]);

      expect(controller.selection, equals({0, 2, 4}));
    });
  });
}
