import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/selection_consumer.dart';
import 'controller.dart';
import 'selection_mode.dart';

/// A widget that provides gesture handling for selection mode interactions.
///
/// [SelectionCanvas] acts as an interactive overlay that captures gestures
/// for selection operations while allowing child widgets to receive their
/// normal gesture events. It must be used within a [SelectionMode] widget
/// to function properly.
///
/// ## Usage
///
/// Wrap your scrollable widget or list with [SelectionCanvas]:
///
/// ```dart
/// SelectionCanvas(
///   child: ListView.builder(
///     itemBuilder: (context, index) => SelectableBuilder(
///       index: index,
///       builder: (context, isSelected) => ListTile(...),
///     ),
///   ),
/// )
/// ```
///
/// See also:
///
/// * [SelectionMode], which provides the selection controller and options
/// * [SelectableBuilder], for making individual items selectable
class SelectionCanvas extends StatefulWidget {
  const SelectionCanvas({
    super.key,
    required this.child,
    this.onBackgroundTap,
    this.hitTestBehavior = HitTestBehavior.translucent,
  });

  final Widget child;

  /// Called when canvas is tapped while selection mode is active.
  /// If null, defaults to disabling selection mode.
  final VoidCallback? onBackgroundTap;

  /// How to behave during hit testing
  final HitTestBehavior hitTestBehavior;

  @override
  State<SelectionCanvas> createState() => _SelectionCanvasState();
}

class _SelectionCanvasState extends State<SelectionCanvas> {
  SelectionModeController? _controller;
  int? _marqueePointer;
  Offset? _marqueeStart;
  bool _marqueeStarted = false;
  bool _marqueeAdditive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = SelectionMode.of(context);
  }

  @override
  void dispose() {
    if (_marqueeStarted) {
      _controller?.endMarqueeSelection();
    }
    _clearMarquee();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) {
        final marqueeRect = controller.currentMarqueeCanvasRect;
        return Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: GestureDetector(
            onTap: controller.isActive ? widget.onBackgroundTap : null,
            behavior: widget.hitTestBehavior,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                widget.child,
                if (marqueeRect != null)
                  Positioned.fromRect(
                    rect: marqueeRect,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isDesktopPointerKind(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.mouse ||
        kind == PointerDeviceKind.trackpad;
  }

  bool _hasPrimaryButton(int buttons) {
    return (buttons & kPrimaryButton) != 0;
  }

  bool _isAdditiveModifierPressed() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final commandPressed = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight) ||
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final shiftPressed = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    return commandPressed || shiftPressed;
  }

  void _handlePointerDown(PointerDownEvent event) {
    final controller = _controller;
    if (controller == null || controller.options.dragSelection == null) return;
    if (!_isDesktopPointerKind(event.kind) ||
        !_hasPrimaryButton(event.buttons)) {
      return;
    }

    _marqueePointer = event.pointer;
    _marqueeStart = event.localPosition;
    _marqueeStarted = false;
    _marqueeAdditive = _isAdditiveModifierPressed();
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final controller = _controller;
    if (controller == null) return;

    if (event.pointer == _marqueePointer && _hasPrimaryButton(event.buttons)) {
      _handleMarqueePointerMove(controller, event);
      return;
    }

    // Handle regular drag selection (item-to-item)
    if (controller.isDragInProgress) {
      controller.handleDragUpdate(
        event.localPosition,
        globalPosition: event.position,
      );
      return;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final controller = _controller;
    if (controller == null) return;

    if (event.pointer == _marqueePointer) {
      _finishMarqueeSelection();
      return;
    }

    // Handle regular drag selection end
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final controller = _controller;
    if (controller == null) return;

    if (event.pointer == _marqueePointer) {
      _finishMarqueeSelection();
      return;
    }

    // Handle regular drag selection cancel
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }
  }

  void _handleMarqueePointerMove(
    SelectionModeController controller,
    PointerMoveEvent event,
  ) {
    final start = _marqueeStart;
    if (start == null) return;

    if (!_marqueeStarted) {
      if ((event.localPosition - start).distance < kTouchSlop) {
        return;
      }

      controller.startMarqueeSelection(start, additive: _marqueeAdditive);
      if (!controller.isMarqueeSelectionInProgress) {
        _clearMarquee();
        return;
      }
      _marqueeStarted = true;
    }

    controller.updateMarqueeSelection(
      event.localPosition,
      globalPosition: event.position,
    );
  }

  void _finishMarqueeSelection() {
    if (_marqueeStarted) {
      _controller?.endMarqueeSelection();
    }
    _clearMarquee();
  }

  void _clearMarquee() {
    _marqueePointer = null;
    _marqueeStart = null;
    _marqueeStarted = false;
    _marqueeAdditive = false;
  }
}
