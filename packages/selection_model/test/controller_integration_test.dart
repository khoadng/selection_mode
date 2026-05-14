import 'package:test/test.dart';
import 'package:selection_model/selection_model.dart';
import 'test_helpers.dart';

void main() {
  group('SelectionModeController - Integration Scenarios', () {
    test('complex selection workflow', () {
      final controller = SelectionModeController();
      controller.updateOptions(
        const SelectionOptions(
          behavior: SelectionBehavior.autoToggle,
          constraints: SelectionConstraints(maxSelections: 10),
        ),
      );
      controller.registerTestItems(15);

      // Auto-enable on first selection
      controller.toggleItem(0);
      expect(controller.isActive, isTrue);

      // Drag selection
      controller.startRangeSelection(6);
      controller.handleDragOver(8);
      expect(controller.selection, equals({0, 6, 7, 8}));
      controller.endRangeSelection();

      // Auto-disable when cleared
      controller.deselectAll();
      expect(controller.isActive, isFalse);

      controller.dispose();
    });

    test('max selection limits during drag', () {
      final controller = SelectionModeController();
      controller.updateOptions(
        const SelectionOptions(
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

    test('unregister preserves selection while removeItem clears selection',
        () {
      final controller = SelectionModeController();
      controller.registerTestItems(3);
      controller.enable();

      controller.toggleItem(1);
      expect(controller.isSelected(1), isTrue);

      controller.unregister(1);
      expect(controller.isSelected(1), isTrue);
      expect(controller.selection, contains(1));

      controller.register(const SelectionItemInfo(
        index: 1,
        identifier: 1,
        isSelectable: true,
      ));
      expect(controller.isSelected(1), isTrue);

      controller.removeItem(1);
      expect(controller.isSelected(1), isFalse);
      expect(controller.selection, isNot(contains(1)));

      controller.dispose();
    });

    test('integer stable identifiers do not collide with row indices', () {
      final controller = SelectionModeController();
      controller.register(const SelectionItemInfo(
        index: 1,
        identifier: 101,
        isSelectable: true,
      ));
      controller.enable();

      controller.toggleItem(1);
      expect(controller.isSelected(1), isTrue);

      controller.unregister(1);
      expect(controller.isSelected(1), isTrue);
      expect(controller.isSelected(101), isFalse);

      controller.dispose();
    });

    test('retainSelectionIdentifiers prunes filtered out items', () {
      final controller = SelectionModeController();
      controller.register(const SelectionItemInfo(
        index: 0,
        identifier: 100,
        isSelectable: true,
      ));
      controller.register(const SelectionItemInfo(
        index: 1,
        identifier: 101,
        isSelectable: true,
      ));
      controller.register(const SelectionItemInfo(
        index: 2,
        identifier: 102,
        isSelectable: true,
      ));
      controller.enable();

      controller.selectRange(0, 2);
      controller.retainSelectionIdentifiers([101, 102]);

      expect(controller.selection.length, 2);
      expect(controller.isSelected(0), isFalse);
      expect(controller.isSelected(1), isTrue);
      expect(controller.isSelected(2), isTrue);

      controller.dispose();
    });
  });
}
