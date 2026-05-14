import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final canvasRenderBox = _getCanvasRenderBox();
    if (canvasRenderBox == null) return null;

    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final localOffset = canvasRenderBox.globalToLocal(globalOffset);

    return Rect.fromLTWH(
      localOffset.dx,
      localOffset.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  RenderBox? _getCanvasRenderBox() {
    RenderBox? canvasRenderBox;
    context.visitAncestorElements((element) {
      if (element.widget is SelectionCanvas) {
        canvasRenderBox = element.findRenderObject() as RenderBox?;
        return false;
      }
      return true;
    });

    return canvasRenderBox;
  }

  void _registerWithController(SelectionModeController controller) {
    controller.register(SelectionItemInfo(
      index: widget.index,
      identifier: _getIdentifier(),
      isSelectable: widget.isSelectable,
      positionCallback: _getCurrentBounds,
    ));
  }

  bool _isShiftPressed() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
  }

  bool _isCtrlPressed() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  void _handlePrimaryTap() {
    if (!widget.isSelectable) return;

    final controller = SelectionMode.of(context);

    if (_isCtrlPressed()) {
      controller.toggleItem(widget.index);
      return;
    }

    if (_isShiftPressed()) {
      _extendSelection(controller);
      return;
    }

    _handleConfiguredTap(controller);
  }

  void _handleSecondaryTap() {
    if (!widget.isSelectable) return;

    final controller = SelectionMode.of(context);

    if (controller.isSelected(widget.index)) return;

    if (_isCtrlPressed()) {
      controller.toggleItem(widget.index);
      return;
    }

    if (_isShiftPressed()) {
      _extendSelection(controller);
      return;
    }

    controller.replaceSelection(widget.index);
  }

  void _extendSelection(SelectionModeController controller) {
    final anchor = controller.getAnchor();
    if (anchor == null) {
      controller.replaceSelection(widget.index);
      return;
    }

    controller.selectRange(anchor, widget.index);
  }

  void _handleConfiguredTap(SelectionModeController controller) {
    final options = controller.options;
    final behavior = options.tapBehavior ?? TapBehavior.toggleWhenSelecting;

    if (behavior.when == null) return; // disabled

    final shouldHandle = switch (behavior.when!) {
      TapCondition.active => controller.isActive,
      TapCondition.inactive => !controller.isActive,
      TapCondition.both => true,
    };

    if (!shouldHandle) return;

    switch (behavior.action!) {
      case TapAction.toggle:
        controller.toggleItem(widget.index);
      case TapAction.replace:
        controller.replaceSelection(widget.index);
    }
  }

  bool _shouldHandleTap(TapBehavior? tapBehavior, bool isActive) {
    final behavior = tapBehavior ?? TapBehavior.toggleWhenSelecting;
    if (behavior.when == null) return false;

    return switch (behavior.when!) {
      TapCondition.active => isActive,
      TapCondition.inactive => !isActive,
      TapCondition.both => true,
    };
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
      _controller?.unregister(oldWidget.index, identifier: oldIdentifier);
      if (_controller != null) {
        _registerWithController(_controller!);
      }
    }
  }

  @override
  void dispose() {
    _controller?.unregister(widget.index, identifier: _getIdentifier());
    super.dispose();
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
        final shouldHandleTap =
            _shouldHandleTap(options.tapBehavior, controller.isActive);

        // In manual mode when disabled, don't consume long press
        if (options.behavior == SelectionBehavior.manual &&
            !controller.isActive) {
          final hasShortcuts = SelectionShortcuts.maybeOf(context) != null;
          if (hasShortcuts && shouldHandleTap) {
            return GestureDetector(
              onTap: _handlePrimaryTap,
              onSecondaryTap: _handleSecondaryTap,
              child: child,
            );
          }
          return child;
        }

        final dragSelection = options.dragSelection;

        if (dragSelection == null) {
          final gestures = <Type, GestureRecognizerFactory>{
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
              (LongPressGestureRecognizer instance) {
                instance.onLongPress = () {
                  controller.enable(initialSelected: [widget.index]);
                };
              },
            ),
          };

          if (shouldHandleTap) {
            gestures[TapGestureRecognizer] =
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onTap = _handlePrimaryTap;
                instance.onSecondaryTap = _handleSecondaryTap;
              },
            );
          } else {
            gestures[TapGestureRecognizer] =
                GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (TapGestureRecognizer instance) {
                instance.onSecondaryTap = _handleSecondaryTap;
              },
            );
          }

          return RawGestureDetector(
            gestures: gestures,
            child: child,
          );
        }

        return DragTarget(
          onWillAcceptWithDetails: (data) {
            controller.handleDragOver(widget.index);
            return true;
          },
          builder: (context, candidateData, rejectedData) {
            Widget dragChild = child;

            if (shouldHandleTap) {
              dragChild = GestureDetector(
                onTap: _handlePrimaryTap,
                onSecondaryTap: _handleSecondaryTap,
                child: child,
              );
            } else {
              dragChild = GestureDetector(
                onSecondaryTap: _handleSecondaryTap,
                child: child,
              );
            }

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
              child: dragChild,
            );
          },
        );
      },
    );
  }
}
