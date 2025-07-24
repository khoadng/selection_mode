import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selection_mode/selection_mode.dart';
import 'package:selection_mode/src/managers/auto_scroll_manager.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectionModeController - Rectangle Selection with Auto-scroll', () {
    late SelectionModeController controller;
    late ScrollController scrollController;
    late AutoScrollManager autoScrollManager;

    setUp(() {
      controller = SelectionModeController();
      scrollController = ScrollController();
      autoScrollManager = AutoScrollManager(
        scrollController: scrollController,
        config: const SelectionAutoScrollOptions(
          edgeThreshold: 80,
          scrollSpeed: 300,
        ),
      );
      controller.setAutoScrollManager(autoScrollManager);
    });

    tearDown(() async {
      // Ensure rectangle selection is ended to stop auto-scroll
      if (controller.isRectangleSelectionInProgress) {
        controller.endRectangleSelection();
      }
      // Wait for ticker to complete disposal
      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
      scrollController.dispose();
      autoScrollManager.dispose();
    });

    testWidgets('rectangle selection coordinates adjust for scroll offset',
        (tester) async {
      controller.registerTestItems(10);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      // Create a scrollable widget to establish scroll context
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      // Start rectangle selection
      controller.startRectangleSelection(const Offset(50, 50));
      controller.updateRectangleSelection(const Offset(150, 150));

      // Initial viewport rect should match content rect
      var viewportRect = controller.getViewportSelectionRect();
      expect(viewportRect, equals(const Rect.fromLTRB(50, 50, 150, 150)));

      // Scroll down
      scrollController.jumpTo(100);
      await tester.pump();
      controller.updateRectangleSelection(const Offset(150, 150));

      // Viewport rect should adjust for scroll offset
      viewportRect = controller.getViewportSelectionRect();
      expect(viewportRect, equals(const Rect.fromLTRB(50, -50, 150, 150)));

      // Clean up
      controller.endRectangleSelection();
      await tester.pump();
    });

    testWidgets('auto-scroll triggers when dragging near viewport edges',
        (tester) async {
      controller.registerTestItems(20);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      controller.startRectangleSelection(const Offset(50, 50));
      expect(autoScrollManager.isScrolling, isFalse);

      // Drag near bottom edge to trigger auto-scroll
      final viewportSize = autoScrollManager.getViewportSize()!;
      final nearBottomEdge = Offset(100, viewportSize.height - 50);

      autoScrollManager.handleDragUpdate(nearBottomEdge, viewportSize);
      expect(autoScrollManager.isScrolling, isTrue);

      controller.endRectangleSelection();
      await tester.pump();
    });

    testWidgets('items selected during rectangle selection with scroll',
        (tester) async {
      controller.registerTestItems(20);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      // Register position callbacks for items arranged vertically
      for (int i = 0; i < 20; i++) {
        controller.registerPositionCallback(i, () {
          return Rect.fromLTWH(0, i * 50.0, 100, 50);
        });
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 1000, width: 300),
          ),
        ),
      );

      // Start rectangle covering items 0-2 (0,0 to 100,149 to avoid edge case)
      controller.startRectangleSelection(const Offset(0, 0));
      controller.updateRectangleSelection(const Offset(100, 149));
      await tester.pump();

      expect(controller.selection, equals({0, 1, 2}));

      // Scroll down - rectangle coordinates remain in content space
      scrollController.jumpTo(100);
      await tester.pump();

      // Rectangle still covers same content area (items 0-2)
      expect(controller.selection, equals({0, 1, 2}));

      // Expand rectangle to cover more items after scroll (avoid exact edge at 250)
      controller.updateRectangleSelection(const Offset(100, 249));

      // Should now include items 0-4 (avoiding edge case at y=250)
      expect(controller.selection, equals({0, 1, 2, 3, 4}));

      // End rectangle selection to stop auto-scroll
      controller.endRectangleSelection();
      await tester.pump();
    });

    testWidgets('auto-scroll stops when rectangle selection ends',
        (tester) async {
      controller.registerTestItems(10);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      controller.startRectangleSelection(const Offset(50, 50));

      // Trigger auto-scroll
      final viewportSize = autoScrollManager.getViewportSize()!;
      autoScrollManager.handleDragUpdate(
        Offset(50, viewportSize.height - 50),
        viewportSize,
      );

      controller.endRectangleSelection();
      await tester.pump();
      expect(autoScrollManager.isScrolling, isFalse);
    });

    testWidgets('rectangle selection respects max constraints during scroll',
        (tester) async {
      controller.registerTestItems(20);
      controller.updateOptions(const SelectionOptions(
        constraints: SelectionConstraints(maxSelections: 3),
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      // Register overlapping item positions
      for (int i = 0; i < 20; i++) {
        controller.registerPositionCallback(i, () {
          return Rect.fromLTWH(0, i * 20.0, 100, 25);
        });
      }

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      // Large rectangle that would select many items
      controller.startRectangleSelection(const Offset(0, 0));
      controller.updateRectangleSelection(const Offset(100, 500));
      await tester.pump();

      expect(controller.selection.length, lessThanOrEqualTo(3));

      // Scroll and verify constraint still respected
      scrollController.jumpTo(200);
      await tester.pump();
      controller.updateRectangleSelection(const Offset(100, 500));

      expect(controller.selection.length, lessThanOrEqualTo(3));

      controller.endRectangleSelection();
      await tester.pump();
    });

    testWidgets('scroll speed calculation works with edge proximity',
        (tester) async {
      controller.registerTestItems(10);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      final viewportSize = autoScrollManager.getViewportSize()!;

      // Test positions at different distances from edge
      final positions = [
        Offset(50, 70), // Close to top edge
        Offset(50, 40), // Closer to top edge
        Offset(50, 10), // Very close to top edge
        Offset(50, viewportSize.height - 70), // Close to bottom edge
        Offset(50, viewportSize.height - 10), // Very close to bottom edge
      ];

      controller.startRectangleSelection(const Offset(50, 100));

      for (final position in positions) {
        autoScrollManager.handleDragUpdate(position, viewportSize);
        // Auto-scroll should activate for edge positions
        final shouldScroll =
            position.dy <= 80 || position.dy >= viewportSize.height - 80;
        expect(autoScrollManager.isScrolling, equals(shouldScroll));
      }

      controller.endRectangleSelection();
      await tester.pump();
    });

    testWidgets('rectangle cancel restores pre-selection and stops auto-scroll',
        (tester) async {
      controller.registerTestItems(10);
      controller.updateOptions(const SelectionOptions(
        rectangleSelection: RectangleSelectionOptions(),
      ));
      controller.enable();

      // Pre-select some items
      controller.toggleItem(1);
      controller.toggleItem(3);
      final preSelection = Set.from(controller.selection);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(height: 2000, width: 300),
          ),
        ),
      );

      controller.startRectangleSelection(const Offset(50, 50));

      // Trigger auto-scroll
      final viewportSize = autoScrollManager.getViewportSize()!;
      autoScrollManager.handleDragUpdate(
        Offset(50, viewportSize.height - 50),
        viewportSize,
      );

      controller.cancelRectangleSelection();
      await tester.pump();

      expect(autoScrollManager.isScrolling, isFalse);
      expect(controller.selection, equals(preSelection));
    });
  });
}
