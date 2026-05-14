import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  group('desktop item gestures', () {
    late SelectionModeController controller;

    setUp(() {
      controller = SelectionModeController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('modifier click toggles selection without SelectionShortcuts',
        (tester) async {
      await tester.pumpWidget(_SelectionHarness(controller: controller));

      await tester.tap(find.byKey(const ValueKey('item-1')));
      await tester.pump();

      expect(controller.selection, {1});

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byKey(const ValueKey('item-2')));
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(controller.selection, {1, 2});
    });

    testWidgets('shift click extends selection from the anchor',
        (tester) async {
      await tester.pumpWidget(_SelectionHarness(controller: controller));

      await tester.tap(find.byKey(const ValueKey('item-1')));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.byKey(const ValueKey('item-3')));
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(controller.selection, {1, 2, 3});
    });

    testWidgets('secondary click selects only unselected items',
        (tester) async {
      await tester.pumpWidget(_SelectionHarness(controller: controller));

      await tester.tap(find.byKey(const ValueKey('item-1')));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('item-1')),
        buttons: kSecondaryButton,
      );
      await tester.pump();

      expect(controller.selection, {1});

      await tester.tap(
        find.byKey(const ValueKey('item-3')),
        buttons: kSecondaryButton,
      );
      await tester.pump();

      expect(controller.selection, {3});
    });

    testWidgets('mouse marquee selects intersecting items', (tester) async {
      await tester.pumpWidget(_SelectionHarness(
        controller: controller,
        options: const SelectionOptions(
          tapBehavior: TapBehavior.alwaysReplace,
          dragSelection: DragSelectionOptions(),
        ),
      ));

      final start = tester.getTopLeft(find.byKey(const ValueKey('item-1'))) +
          const Offset(4, 4);
      final end = tester.getBottomRight(find.byKey(const ValueKey('item-4'))) -
          const Offset(4, 4);
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryButton,
      );

      await gesture.moveTo(end);
      await tester.pump();

      expect(controller.selection, {1, 2, 3, 4});

      await gesture.up();
      await tester.pump();
      expect(controller.isMarqueeSelectionInProgress, isFalse);
    });

    testWidgets('mouse drag auto-scrolls near the viewport edge',
        (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(_ScrollableSelectionHarness(
        controller: controller,
        scrollController: scrollController,
      ));

      final start = tester.getTopLeft(find.byKey(const ValueKey('row-1'))) +
          const Offset(4, 4);
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryButton,
      );

      final listBottom = tester.getBottomLeft(find.byType(ListView)).dy;
      await gesture.moveTo(Offset(220, listBottom - 4));
      await tester.pump(const Duration(milliseconds: 500));

      expect(scrollController.offset, greaterThan(0));
      expect(controller.currentMarqueeCanvasRect?.top, lessThan(start.dy));
      expect(controller.selection, contains(1));

      await gesture.up();
      await tester.pump();
    });

    testWidgets('grid marquee auto-scroll keeps recycled selections',
        (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(_VirtualGridSelectionHarness(
        controller: controller,
        scrollController: scrollController,
      ));

      final start = tester.getTopLeft(find.byKey(const ValueKey('cell-0'))) +
          const Offset(4, 4);
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryButton,
      );

      final gridBottom = tester.getBottomLeft(find.byType(GridView)).dy;
      await gesture.moveTo(Offset(500, gridBottom + 80));

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 16));

      expect(scrollController.offset, greaterThan(1400));
      expect(controller.selection.length, greaterThan(40));
      expect(controller.isSelected(0), isTrue);
      expect(controller.isSelected(100), isFalse);

      await gesture.up();
      await tester.pump();

      scrollController.jumpTo(0);
      await tester.pump();

      expect(find.text('Cell 0 selected=true'), findsOneWidget);
    });

    testWidgets('filtered grid can marquee again after visibility toggles',
        (tester) async {
      final scrollController = ScrollController();
      final showHidden = ValueNotifier<bool>(false);
      final photos = List.generate(
        120,
        (index) => _TestPhoto(
          id: index + 100,
          hidden: index % 5 == 0,
        ),
      );
      List<_TestPhoto> visiblePhotos() =>
          photos.where((photo) => showHidden.value || !photo.hidden).toList();

      addTearDown(scrollController.dispose);
      addTearDown(showHidden.dispose);

      await tester.pumpWidget(_FilteredGridSelectionHarness(
        controller: controller,
        scrollController: scrollController,
        showHidden: showHidden,
        photos: photos,
      ));

      await _dragGridMarquee(tester);
      final firstVisibleSelection =
          controller.selectedFrom(visiblePhotos()).toList();
      expect(firstVisibleSelection.length, controller.selection.length);
      expect(firstVisibleSelection, isNotEmpty);

      showHidden.value = true;
      await tester.pump();
      showHidden.value = false;
      await tester.pump();

      await _dragGridMarquee(tester);
      final secondVisibleSelection =
          controller.selectedFrom(visiblePhotos()).toList();

      expect(secondVisibleSelection.length, controller.selection.length);
      expect(secondVisibleSelection, isNotEmpty);
      expect(
        find.text(
          'Photo ${secondVisibleSelection.first.id} selected=true',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('filtered grid prunes hidden selected items', (tester) async {
      final scrollController = ScrollController();
      final showHidden = ValueNotifier<bool>(true);
      final photos = List.generate(
        12,
        (index) => _TestPhoto(
          id: index + 100,
          hidden: index == 0,
        ),
      );
      List<_TestPhoto> visiblePhotos() =>
          photos.where((photo) => showHidden.value || !photo.hidden).toList();

      addTearDown(scrollController.dispose);
      addTearDown(showHidden.dispose);

      await tester.pumpWidget(_FilteredGridSelectionHarness(
        controller: controller,
        scrollController: scrollController,
        showHidden: showHidden,
        photos: photos,
      ));

      controller.selectRange(0, 2);
      await tester.pump();
      expect(controller.selectedFrom(visiblePhotos()).toList().length, 3);

      showHidden.value = false;
      controller.retainSelectionIdentifiers(
        visiblePhotos().map((photo) => photo.id),
      );
      await tester.pump();

      final selectedVisiblePhotos = controller.selectedFrom(visiblePhotos());
      expect(controller.selection.length, 2);
      expect(selectedVisiblePhotos.toList().map((photo) => photo.id), [
        101,
        102,
      ]);
      expect(find.text('Photo 101 selected=true'), findsOneWidget);
      expect(find.text('Photo 102 selected=true'), findsOneWidget);
    });
  });
}

Future<void> _dragGridMarquee(WidgetTester tester) async {
  final grid = find.byType(GridView);
  final start = tester.getTopLeft(grid) + const Offset(12, 12);
  final end = tester.getBottomRight(grid) - const Offset(12, 12);
  final gesture = await tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
    buttons: kPrimaryButton,
  );

  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

class _SelectionHarness extends StatelessWidget {
  const _SelectionHarness({
    required this.controller,
    this.options = const SelectionOptions(
      tapBehavior: TapBehavior.alwaysReplace,
    ),
  });

  final SelectionModeController controller;
  final SelectionOptions options;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SelectionMode(
        controller: controller,
        options: options,
        child: SelectionCanvas(
          child: Column(
            children: List.generate(
              5,
              (index) => SelectableBuilder(
                index: index,
                builder: (context, isSelected) => SizedBox(
                  key: ValueKey('item-$index'),
                  width: 200,
                  height: 40,
                  child: Text('Item $index selected=$isSelected'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollableSelectionHarness extends StatelessWidget {
  const _ScrollableSelectionHarness({
    required this.controller,
    required this.scrollController,
  });

  final SelectionModeController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SizedBox(
        width: 240,
        height: 120,
        child: SelectionMode(
          controller: controller,
          scrollController: scrollController,
          options: const SelectionOptions(
            tapBehavior: TapBehavior.alwaysReplace,
            dragSelection: DragSelectionOptions(),
            autoScroll: SelectionAutoScrollOptions(
              edgeThreshold: 40,
              scrollSpeed: 900,
            ),
          ),
          child: SelectionCanvas(
            child: ListView.builder(
              controller: scrollController,
              itemExtent: 40,
              itemCount: 30,
              itemBuilder: (context, index) => SelectableBuilder(
                index: index,
                builder: (context, isSelected) => SizedBox(
                  key: ValueKey('row-$index'),
                  width: 240,
                  height: 40,
                  child: Text('Row $index selected=$isSelected'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VirtualGridSelectionHarness extends StatelessWidget {
  const _VirtualGridSelectionHarness({
    required this.controller,
    required this.scrollController,
  });

  final SelectionModeController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SizedBox(
        width: 360,
        height: 240,
        child: SelectionMode(
          controller: controller,
          scrollController: scrollController,
          options: const SelectionOptions(
            tapBehavior: TapBehavior.alwaysReplace,
            dragSelection: DragSelectionOptions(),
            autoScroll: SelectionAutoScrollOptions(
              edgeThreshold: 64,
              scrollSpeed: 1000,
            ),
          ),
          child: SelectionCanvas(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: 300,
              itemBuilder: (context, index) => SelectableBuilder(
                key: ValueKey('photo-$index'),
                index: index,
                builder: (context, isSelected) => SizedBox(
                  key: ValueKey('cell-$index'),
                  width: 64,
                  height: 64,
                  child: Text('Cell $index selected=$isSelected'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestPhoto {
  const _TestPhoto({
    required this.id,
    required this.hidden,
  });

  final int id;
  final bool hidden;
}

class _FilteredGridSelectionHarness extends StatelessWidget {
  const _FilteredGridSelectionHarness({
    required this.controller,
    required this.scrollController,
    required this.showHidden,
    required this.photos,
  });

  final SelectionModeController controller;
  final ScrollController scrollController;
  final ValueNotifier<bool> showHidden;
  final List<_TestPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: showHidden,
        builder: (context, showHiddenValue, _) {
          final visiblePhotos = photos
              .where((photo) => showHiddenValue || !photo.hidden)
              .toList();

          return SizedBox(
            width: 360,
            height: 260,
            child: SelectionMode(
              controller: controller,
              scrollController: scrollController,
              options: const SelectionOptions(
                tapBehavior: TapBehavior.alwaysReplace,
                dragSelection: DragSelectionOptions(),
                autoScroll: SelectionAutoScrollOptions(
                  edgeThreshold: 64,
                  scrollSpeed: 1000,
                ),
              ),
              child: Column(
                children: [
                  TextButton(
                    key: const ValueKey('toggle-hidden'),
                    onPressed: () => showHidden.value = !showHidden.value,
                    child: Text(showHiddenValue ? 'Hide hidden' : 'Show all'),
                  ),
                  Expanded(
                    child: SelectionCanvas(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: visiblePhotos.length,
                        itemBuilder: (context, index) {
                          final photo = visiblePhotos[index];
                          return SelectableBuilder(
                            key: ValueKey(photo.id),
                            index: index,
                            builder: (context, isSelected) => SizedBox(
                              key: ValueKey('filtered-cell-${photo.id}'),
                              width: 64,
                              height: 64,
                              child: Text(
                                'Photo ${photo.id} selected=$isSelected',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
