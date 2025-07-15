import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Range Operations', () {
    late SelectionModeController controller;

    setUp(() {
      controller = SelectionModeController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('Range Selection', () {
      test('selectRange selects items in range', () {
        controller.registerTestItems(10);
        controller.enable();

        controller.selectRange(2, 5);

        expect(controller.selection, equals({2, 3, 4, 5}));
      });

      test('deselectRange removes items in range', () {
        controller.registerTestItems(15);
        controller.enable();
        controller.selectRange(0, 10);

        controller.deselectRange(3, 7);

        expect(controller.selection, equals({0, 1, 2, 8, 9, 10}));
      });

      test('toggleRange toggles items in range', () {
        controller.registerTestItems(10);
        controller.enable();
        controller.toggleItem(1);
        controller.toggleItem(3);

        controller.toggleRange(0, 4);

        expect(controller.selection, equals({0, 2, 4}));
      });

      test('range queries work correctly', () {
        controller.registerTestItems(15);
        controller.enable();
        controller.selectRange(2, 8);

        expect(controller.getSelectedCountInRange(4, 6), equals(3));
        expect(controller.hasSelectionInRange(1, 3), isTrue);
        expect(controller.hasSelectionInRange(9, 10), isFalse);
        expect(controller.isRangeFullySelected(3, 5), isTrue);
      });
    });
  });
}
