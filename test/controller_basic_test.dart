import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'test_helpers.dart';

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
      expect(controller.isActive, isFalse);
      expect(controller.selection, isEmpty);
      expect(controller.selectedCount, equals(0));
      expect(controller.hasSelection, isFalse);
    });

    test('enable/disable controls state and selection', () {
      controller.registerTestItems(5);
      controller.enable();
      expect(controller.isActive, isTrue);

      controller.toggleItem(0);
      controller.disable();

      expect(controller.isActive, isFalse);
      expect(controller.selection, isEmpty);
    });

    test('toggleSelection adds and removes items', () {
      controller.registerTestItems(5);
      controller.enable();

      controller.toggleItem(0);
      expect(controller.isSelected(0), isTrue);
      expect(controller.selectedCount, equals(1));

      controller.toggleItem(0);
      expect(controller.isSelected(0), isFalse);
      expect(controller.selectedCount, equals(0));
    });

    test('notifies listeners on state changes', () {
      controller.registerTestItems(5);
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.enable();
      controller.toggleItem(0);
      controller.disable();

      expect(notificationCount, equals(3));
    });
  });
}
