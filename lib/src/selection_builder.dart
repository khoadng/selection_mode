import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

/// A builder widget that provides selection state and gestures for an indexed item.
///
/// Combines selection state management with gesture handling in a single widget.
class SelectionBuilder extends StatefulWidget {
  const SelectionBuilder({
    super.key,
    this.controller,
    required this.index,
    required this.builder,
    this.enableRangeSelection = true,
    this.isSelectable = true,
  });

  /// The selection controller. If null, uses [SelectionMode.of(context)]
  final SelectionModeController? controller;

  /// The index of this item
  final int index;

  /// Builder that receives the current selection state
  final Widget Function(
    BuildContext context,
    bool isSelected,
  ) builder;

  /// Whether range selection is enabled for this item
  final bool enableRangeSelection;

  /// Whether this item can be selected
  final bool isSelectable;

  @override
  State<SelectionBuilder> createState() => _SelectionBuilderState();
}

class _SelectionBuilderState extends State<SelectionBuilder> {
  SelectionModeController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = SelectionMode.of(context);
    if (_controller != controller) {
      _controller?.removeItem(widget.index);
      _controller = controller;
      controller.setItemSelectable(widget.index, widget.isSelectable);
    }
  }

  @override
  void didUpdateWidget(SelectionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelectable != widget.isSelectable) {
      _controller?.setItemSelectable(widget.index, widget.isSelectable);
    }
  }

  Offset? _getGlobalPosition(BuildContext context) {
    // Get the center of the widget instead of top-left corner
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final size = renderBox.size;
    return renderBox.localToGlobal(Offset(size.width / 2, size.height / 2));
  }

  Size? _getViewportSize(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return null;

    final RenderBox? renderBox =
        scrollable.context.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final child = widget.builder(context, ctrl.isSelected(widget.index));

        if (!widget.isSelectable) {
          return child;
        }

        // In manual mode when disabled, don't consume long press
        if (ctrl.options.selectionBehavior == SelectionBehavior.manual &&
            !ctrl.enabled) {
          return child;
        }

        return DragTarget<int>(
          onWillAcceptWithDetails: (data) {
            final controller = SelectionMode.of(context);
            final globalPosition = _getGlobalPosition(context);
            final viewportSize = _getViewportSize(context);

            controller.handleDragOver(
              widget.index,
              globalPosition,
              viewportSize,
            );
            return true;
          },
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: widget.index,
              onDragStarted: () {
                final controller = SelectionMode.of(context);
                controller.startRangeSelection(widget.index);
              },
              onDragEnd: (_) {
                final controller = SelectionMode.of(context);
                controller.endRangeSelection();
              },
              feedback: const SizedBox.shrink(),
              childWhenDragging: child,
              child: child,
            );
          },
        );
      },
    );
  }
}
