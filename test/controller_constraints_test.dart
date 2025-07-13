import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Constraints', () {
    group('Max Selections', () {
      test('respects max selections limit', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            constraints: SelectionConstraints(maxSelections: 2),
          ),
        );
        controller.enable();

        controller.toggleItem(0);
        controller.toggleItem(1);
        controller.toggleItem(2);

        expect(controller.selection, equals({0, 1}));
        expect(controller.selectedCount, equals(2));

        controller.dispose();
      });

      test('updating options enforces new max selections', () {
        final controller = SelectionModeController();
        controller.enable();
        controller.toggleItem(0);
        controller.toggleItem(1);
        controller.toggleItem(2);

        controller.updateOptions(
          const SelectionOptions(
            constraints: SelectionConstraints(maxSelections: 2),
          ),
        );

        expect(controller.selectedCount, equals(2));

        controller.dispose();
      });
    });

    group('Item Selectability', () {
      test('unselectable items cannot be selected', () {
        final controller = SelectionModeController();
        controller.enable();
        controller.setItemSelectable(0, false);

        controller.toggleItem(0);

        expect(controller.isSelected(0), isFalse);

        controller.dispose();
      });

      test('making selected item unselectable removes it', () {
        final controller = SelectionModeController();
        controller.enable();
        controller.toggleItem(0);

        controller.setItemSelectable(0, false);

        expect(controller.isSelected(0), isFalse);

        controller.dispose();
      });

      test('range operations respect selectability', () {
        final controller = SelectionModeController();
        controller.enable();
        controller.setItemSelectable(2, false);
        controller.setItemSelectable(4, false);

        controller.selectRange(1, 5);

        expect(controller.selection, equals({1, 3, 5}));

        controller.dispose();
      });
    });
  });
}
