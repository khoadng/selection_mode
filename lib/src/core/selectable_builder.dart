import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';
import 'selection_item_info.dart';

/// A builder widget that provides selection state and gestures for an indexed item.
///
/// Combines selection state management with gesture handling in a single widget.
class SelectableBuilder extends StatefulWidget {
  const SelectableBuilder({
    super.key,
    required this.index,
    required this.builder,
    this.isSelectable = true,
  });

  /// The index of this item
  final int index;

  /// Builder that receives the current selection state
  final Widget Function(
    BuildContext context,
    bool isSelected,
  ) builder;

  /// Whether this item can be selected
  final bool isSelectable;

  @override
  State<SelectableBuilder> createState() => _SelectableBuilderState();
}

class _SelectableBuilderState extends State<SelectableBuilder> {
  SelectionModeController? _controller;

  /// Extract identifier from key, fallback to index
  Object _getIdentifier() {
    final key = widget.key;
    if (key is ValueKey) return key.value;
    if (key != null) return key;
    return widget.index;
  }

  Rect? _getCurrentBounds() {
    if (!mounted) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;

    RenderBox? canvasRenderBox;
    context.visitAncestorElements((element) {
      if (element.widget is SelectionCanvas) {
        canvasRenderBox = element.findRenderObject() as RenderBox?;
        return false;
      }
      return true;
    });

    if (canvasRenderBox == null) return null;

    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final localOffset = canvasRenderBox!.globalToLocal(globalOffset);

    return Rect.fromLTWH(
      localOffset.dx,
      localOffset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  void _registerWithController(SelectionModeController controller) {
    controller.register(SelectionItemInfo(
      index: widget.index,
      identifier: _getIdentifier(),
      isSelectable: widget.isSelectable,
      positionCallback: _getCurrentBounds,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = SelectionMode.of(context);
    if (_controller != controller) {
      _controller?.unregister(widget.index);
      _controller = controller;
      _registerWithController(controller);
    }
  }

  @override
  void didUpdateWidget(SelectableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIdentifier = oldWidget.key is ValueKey
        ? (oldWidget.key as ValueKey).value
        : oldWidget.key ?? oldWidget.index;
    final newIdentifier = _getIdentifier();

    if (oldIdentifier != newIdentifier ||
        oldWidget.index != widget.index ||
        oldWidget.isSelectable != widget.isSelectable) {
      _controller?.unregister(oldWidget.index);
      if (_controller != null) {
        _registerWithController(_controller!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = SelectionMode.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final child =
            widget.builder(context, controller.isSelected(widget.index));

        if (!widget.isSelectable) {
          return child;
        }

        final options = controller.options;

        // In manual mode when disabled, don't consume long press
        if (options.behavior == SelectionBehavior.manual &&
            !controller.isActive) {
          return child;
        }

        final dragSelection = options.dragSelection;

        if (dragSelection == null) {
          return RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(),
                (LongPressGestureRecognizer instance) {
                  instance.onLongPress = () {
                    controller.enable(initialSelected: [widget.index]);
                  };
                },
              ),
            },
            child: child,
          );
        }

        return DragTarget(
          onWillAcceptWithDetails: (data) {
            controller.handleDragOver(widget.index);
            return true;
          },
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable(
              data: widget.index,
              onDragStarted: () {
                controller.startRangeSelection(widget.index);
              },
              feedback: const SizedBox.shrink(),
              hapticFeedbackOnStart: false,
              childWhenDragging: child,
              delay: dragSelection.delay ?? kLongPressTimeout,
              axis: dragSelection.axis,
              child: child,
            );
          },
        );
      },
    );
  }
}
