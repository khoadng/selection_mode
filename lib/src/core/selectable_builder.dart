import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:selection_mode/selection_mode.dart';
import 'selection_item_info.dart';
import 'selectable_render_object.dart';

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

  void _registerWithController(SelectionModeController controller) {
    controller.register(SelectionItemInfo(
      index: widget.index,
      identifier: _getIdentifier(),
      isSelectable: widget.isSelectable,
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

  void _handleTap() {
    if (!widget.isSelectable) return;

    final controller = SelectionMode.of(context);
    final options = controller.options;
    final hasShortcuts = SelectionShortcuts.maybeOf(context) != null;

    // Handle keyboard shortcuts first
    if (hasShortcuts && _isCtrlPressed()) {
      Actions.invoke(context, ToggleSelectionIntent(widget.index));
      return;
    } else if (hasShortcuts && _isShiftPressed()) {
      Actions.invoke(context, ExtendSelectionIntent(widget.index));
      return;
    }

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

  Widget _buildGestureWrapper(
    Widget child,
    SelectionModeController controller,
  ) {
    final options = controller.options;
    final shouldHandleTap =
        _shouldHandleTap(options.tapBehavior, controller.isActive);

    // In manual mode when disabled, don't consume long press
    if (options.behavior == SelectionBehavior.manual && !controller.isActive) {
      final hasShortcuts = SelectionShortcuts.maybeOf(context) != null;
      if (hasShortcuts && shouldHandleTap) {
        return GestureDetector(
          onTap: _handleTap,
          child: child,
        );
      }
      return child;
    }

    final dragSelection = options.dragSelection;

    if (dragSelection == null) {
      final gestures = <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
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
            instance.onTap = _handleTap;
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
            onTap: _handleTap,
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

        return SelectableWidget(
          index: widget.index,
          controller: controller,
          isSelectable: widget.isSelectable,
          child: _buildGestureWrapper(child, controller),
        );
      },
    );
  }
}
