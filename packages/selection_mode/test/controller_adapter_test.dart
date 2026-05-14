import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';

void main() {
  test('controller is Listenable while delegating selection logic to model',
      () {
    final controller = SelectionModeController();
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.toggleItem(0);

    expect(controller.isSelected(0), isTrue);
    expect(controller.selection, {0});
    expect(notifications, 1);

    controller.dispose();
  });

  test('selection options keep Flutter interaction defaults', () {
    const options = SelectionOptions();

    expect(options.behavior, SelectionBehavior.autoEnable);
    expect(options.autoScroll, isNotNull);
    expect(options.haptics, isNotNull);
  });
}
