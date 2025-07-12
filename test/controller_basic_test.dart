import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SelectionModeController - Basic Operations', () {
    late SelectionModeController controller;

    setUp(() {
      controller = SelectionModeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is correct', () {
      expect(controller.enabled, isFalse);
      expect(controller.selectedItems, isEmpty);
      expect(controller.selectedCount, equals(0));
      expect(controller.hasSelection, isFalse);
    });

    test('enable/disable controls state and selection', () {
      controller.enable();
      expect(controller.enabled, isTrue);

      controller.toggleSelection(0);
      controller.disable();

      expect(controller.enabled, isFalse);
      expect(controller.selectedItems, isEmpty);
    });

    test('toggleSelection adds and removes items', () {
      controller.enable();

      controller.toggleSelection(0);
      expect(controller.isSelected(0), isTrue);
      expect(controller.selectedCount, equals(1));

      controller.toggleSelection(0);
      expect(controller.isSelected(0), isFalse);
      expect(controller.selectedCount, equals(0));
    });

    test('notifies listeners on state changes', () {
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.enable();
      controller.toggleSelection(0);
      controller.disable();

      expect(notificationCount, equals(3));
    });
  });
}
