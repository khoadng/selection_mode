import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Drag Selection', () {
    late SelectionModeController controller;

    setUp(() {
      controller = SelectionModeController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('drag selection workflow', () {
      controller.registerTestItems(10);
      controller.enable();

      controller.startRangeSelection(0);
      expect(controller.isDragInProgress, isTrue);

      controller.handleDragOver(3);
      expect(controller.selection, equals({0, 1, 2, 3}));

      controller.endRangeSelection();
      expect(controller.isDragInProgress, isFalse);
    });

    test('drag preserves pre-drag selections', () {
      controller.registerTestItems(10);
      controller.enable();
      controller.toggleItem(5);

      controller.startRangeSelection(0);
      controller.handleDragOver(2);

      expect(controller.selection, equals({0, 1, 2, 5}));
    });
  });
}
