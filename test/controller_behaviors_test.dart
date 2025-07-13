import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Selection Behaviors', () {
    group('Manual Behavior', () {
      test('blocks selection when disabled', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        controller.toggleItem(0);
        expect(controller.isActive, isFalse);
        expect(controller.isSelected(0), isFalse);

        controller.dispose();
      });

      test('allows selection when enabled', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        controller.enable();
        controller.toggleItem(0);
        expect(controller.isActive, isTrue);
        expect(controller.isSelected(0), isTrue);

        controller.dispose();
      });

      test('does not auto-disable when empty', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        controller.enable();
        controller.toggleItem(0);
        controller.toggleItem(0); // Deselect

        expect(controller.isActive, isTrue);
        expect(controller.hasSelection, isFalse);

        controller.dispose();
      });

      test('blocks range operations when disabled', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        controller.selectRange(0, 3);
        expect(controller.isActive, isFalse);
        expect(controller.selection, isEmpty);

        controller.dispose();
      });
    });

    group('AutoEnable Behavior', () {
      test('auto-enables on first selection', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoEnable,
          ),
        );

        controller.toggleItem(0);

        expect(controller.isActive, isTrue);
        expect(controller.isSelected(0), isTrue);

        controller.dispose();
      });

      test('does not auto-disable when empty', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoEnable,
          ),
        );

        controller.toggleItem(0); // Auto-enables
        controller.toggleItem(0); // Deselect

        expect(controller.isActive, isTrue);
        expect(controller.hasSelection, isFalse);

        controller.dispose();
      });

      test('allows range operations when disabled', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoEnable,
          ),
        );

        controller.selectRange(0, 2);

        expect(controller.isActive, isTrue);
        expect(controller.selection, equals({0, 1, 2}));

        controller.dispose();
      });
    });

    group('Implicit Behavior', () {
      test('auto-enables on first selection', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoToggle,
          ),
        );

        controller.toggleItem(0);

        expect(controller.isActive, isTrue);
        expect(controller.isSelected(0), isTrue);

        controller.dispose();
      });

      test('auto-disables when empty', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoToggle,
          ),
        );

        controller.toggleItem(0); // Auto-enables
        controller.toggleItem(0); // Deselect - should auto-disable

        expect(controller.isActive, isFalse);
        expect(controller.hasSelection, isFalse);

        controller.dispose();
      });

      test('auto-disables when cleared', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoToggle,
          ),
        );

        controller.toggleItem(0);
        controller.toggleItem(1);
        controller.deselectAll();

        expect(controller.isActive, isFalse);

        controller.dispose();
      });

      test('auto-disables when range deselected to empty', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoToggle,
          ),
        );

        controller.selectRange(0, 2); // Auto-enables
        controller.deselectRange(0, 2); // Should auto-disable

        expect(controller.isActive, isFalse);
        expect(controller.hasSelection, isFalse);

        controller.dispose();
      });

      test('allows operations when disabled', () {
        final controller = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoToggle,
          ),
        );

        controller.selectAll([0, 1, 2]);

        expect(controller.isActive, isTrue);
        expect(controller.selection, equals({0, 1, 2}));

        controller.dispose();
      });
    });

    group('Behavior Consistency', () {
      test('handleSelection respects behavior modes', () {
        final manualController = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        final autoController = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoEnable,
          ),
        );

        // Manual should not work when disabled
        manualController.handleSelection(0);
        expect(manualController.isActive, isFalse);
        expect(manualController.isSelected(0), isFalse);

        // AutoEnable should work when disabled
        autoController.handleSelection(0);
        expect(autoController.isActive, isTrue);
        expect(autoController.isSelected(0), isTrue);

        manualController.dispose();
        autoController.dispose();
      });

      test('invertSelection respects behavior modes', () {
        final manualController = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.manual,
          ),
        );

        final autoController = SelectionModeController(
          options: const SelectionOptions(
            behavior: SelectionBehavior.autoEnable,
          ),
        );

        // Manual should not work when disabled
        manualController.invertSelection([0, 1, 2]);
        expect(manualController.isActive, isFalse);
        expect(manualController.selection, isEmpty);

        // AutoEnable should work when disabled
        autoController.invertSelection([0, 1, 2]);
        expect(autoController.isActive, isTrue);
        expect(autoController.selection, equals({0, 1, 2}));

        manualController.dispose();
        autoController.dispose();
      });
    });
  });
}
