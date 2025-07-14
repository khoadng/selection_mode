import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Integration Scenarios', () {
    test('complex selection workflow', () {
      final controller = SelectionModeController(
        options: const SelectionOptions(
          behavior: SelectionBehavior.autoToggle,
          constraints: SelectionConstraints(maxSelections: 10),
        ),
      );
      controller.registerTestItems(15);

      // Auto-enable on first selection
      controller.toggleItem(0);
      expect(controller.isActive, isTrue);

      // Range select
      controller.setRangeAnchor(0);
      controller.handleSelection(4, isShiftPressed: true);
      expect(controller.selection, equals({0, 1, 2, 3, 4}));

      // Drag selection
      controller.startRangeSelection(6);
      controller.handleDragOver(8);
      expect(controller.selection, equals({0, 1, 2, 3, 4, 6, 7, 8}));
      controller.endRangeSelection();

      // Auto-disable when cleared
      controller.deselectAll();
      expect(controller.isActive, isFalse);

      controller.dispose();
    });

    test('max selection limits during drag', () {
      final controller = SelectionModeController(
        options: const SelectionOptions(
          constraints: SelectionConstraints(maxSelections: 3),
        ),
      );
      controller.registerTestItems(15);
      controller.enable();

      controller.toggleItem(0);
      controller.toggleItem(1);

      controller.startRangeSelection(5);
      controller.handleDragOver(8);

      expect(controller.selection.length, equals(3));
      expect(controller.selection, contains(0));
      expect(controller.selection, contains(1));

      controller.dispose();
    });
  });
}
