import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

/// A builder widget that provides selection state and gestures for an indexed item.
///
/// Combines selection state management with gesture handling in a single widget.
class SelectionBuilder extends StatefulWidget {
  const SelectionBuilder({
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
  State<SelectionBuilder> createState() => _SelectionBuilderState();
}

class _SelectionBuilderState extends State<SelectionBuilder> {
  SelectionModeController? _controller;

  /// Extract identifier from key, fallback to index
  Object _getIdentifier() {
    final key = widget.key;
    if (key is ValueKey) return key.value;
    if (key != null) return key;
    return widget.index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = SelectionMode.of(context);
    if (_controller != controller) {
      _controller?.unregisterItem(widget.index);
      _controller = controller;
      controller.registerItem(
        widget.index,
        _getIdentifier(),
        widget.isSelectable,
      );
    }
  }

  @override
  void didUpdateWidget(SelectionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIdentifier = oldWidget.key is ValueKey
        ? (oldWidget.key as ValueKey).value
        : oldWidget.key ?? oldWidget.index;
    final newIdentifier = _getIdentifier();

    if (oldIdentifier != newIdentifier ||
        oldWidget.index != widget.index ||
        oldWidget.isSelectable != widget.isSelectable) {
      _controller?.unregisterItem(oldWidget.index);
      _controller?.registerItem(
        widget.index,
        newIdentifier,
        widget.isSelectable,
      );
    }
  }

  Size? _getViewportSize(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return null;

    final renderBox = scrollable.context.findRenderObject() as RenderBox?;
    return renderBox?.size;
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
              onDragUpdate: (details) {
                final viewportSize = _getViewportSize(context);
                if (viewportSize != null) {
                  controller.handleDragUpdate(
                      details.globalPosition, viewportSize);
                }
              },
              onDragEnd: (_) {
                controller.endRangeSelection();
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
