import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Integration Scenarios', () {
    test('complex selection workflow', () {
      final controller = SelectionModeController(
        options: const SelectionModeOptions(
          selectionBehavior: SelectionBehavior.implicit,
          maxSelections: 10,
        ),
      );

      // Auto-enable on first selection
      controller.toggleSelection(0);
      expect(controller.enabled, isTrue);

      // Range select
      controller.setRangeAnchor(0);
      controller.handleSelection(4, isShiftPressed: true);
      expect(controller.selectedItems, equals({0, 1, 2, 3, 4}));

      // Drag selection
      controller.startRangeSelection(6);
      controller.handleDragOver(8);
      expect(controller.selectedItems, equals({0, 1, 2, 3, 4, 6, 7, 8}));
      controller.endRangeSelection();

      // Auto-disable when cleared
      controller.clearSelected();
      expect(controller.enabled, isFalse);

      controller.dispose();
    });

    test('max selection limits during drag', () {
      final controller = SelectionModeController(
        options: const SelectionModeOptions(maxSelections: 3),
      );
      controller.enable();

      controller.toggleSelection(0);
      controller.toggleSelection(1);

      controller.startRangeSelection(5);
      controller.handleDragOver(8);

      expect(controller.selectedCount, equals(3));
      expect(controller.selectedItems, contains(0));
      expect(controller.selectedItems, contains(1));

      controller.dispose();
    });
  });
}
