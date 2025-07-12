import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

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
        controller.enable();

        controller.selectRange(2, 5);

        expect(controller.selectedItems, equals({2, 3, 4, 5}));
      });

      test('deselectRange removes items in range', () {
        controller.enable();
        controller.selectRange(0, 10);

        controller.deselectRange(3, 7);

        expect(controller.selectedItems, equals({0, 1, 2, 8, 9, 10}));
      });

      test('toggleRange toggles items in range', () {
        controller.enable();
        controller.toggleSelection(1);
        controller.toggleSelection(3);

        controller.toggleRange(0, 4);

        expect(controller.selectedItems, equals({0, 2, 4}));
      });

      test('range queries work correctly', () {
        controller.enable();
        controller.selectRange(2, 8);

        expect(controller.getSelectedCountInRange(4, 6), equals(3));
        expect(controller.hasSelectionInRange(1, 3), isTrue);
        expect(controller.hasSelectionInRange(9, 10), isFalse);
        expect(controller.isRangeFullySelected(3, 5), isTrue);
      });
    });

    group('Shift Selection', () {
      test('handleSelection with shift creates range', () {
        controller.enable();
        controller.handleSelection(2);

        controller.handleSelection(5, isShiftPressed: true);

        expect(controller.selectedItems, equals({2, 3, 4, 5}));
      });

      test('setRangeAnchor sets anchor and selects item', () {
        controller.enable();

        controller.setRangeAnchor(3);

        expect(controller.rangeAnchor, equals(3));
        expect(controller.isSelected(3), isTrue);
      });
    });
  });
}
