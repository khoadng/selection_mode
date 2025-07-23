import 'package:flutter/material.dart';
import 'controller.dart';
import 'selection_consumer.dart';
import 'selection_mode.dart';
import 'selection_options.dart';

/// A widget that provides gesture handling for selection mode interactions.
///
/// [SelectionCanvas] acts as an interactive overlay that captures gestures
/// for selection operations while allowing child widgets to receive their
/// normal gesture events. It must be used within a [SelectionMode] widget
/// to function properly.
///
/// ## Gesture Handling
///
/// The canvas handles the following gestures when selection mode is active:
///
/// * **Tap on empty area**: Exits selection mode (calls [onBackgroundTap] or
///   [SelectionModeController.disable] by default)
/// * **Drag on empty area**: Initiates rectangle selection if enabled via
///   [SelectionOptions.rectangleSelection]
/// * **Gestures on selectable items**: Passed through to child widgets for
///   normal item-to-item drag selection
///
/// Rectangle selection is only available when [SelectionOptions.rectangleSelection]
/// is configured in the parent [SelectionMode] widget.
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
/// * [SelectionRectangleOverlay], for displaying rectangle selection feedback
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
  bool _isDragging = false;
  Offset? _startPosition;

  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) => Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: controller.isActive ? _handlePointerMove : null,
        onPointerUp: controller.isActive ? _handlePointerUp : null,
        onPointerCancel: controller.isActive ? _handlePointerCancel : null,
        child: GestureDetector(
          onTap: controller.isActive
              ? (widget.onBackgroundTap ?? controller.disable)
              : null,
          behavior: widget.hitTestBehavior,
          child: widget.child,
        ),
      ),
    );
  }

  bool _hitTestSelectableItem(Offset position) {
    final controller = SelectionMode.of(context);
    for (final entry in controller.positionCallbacks.entries) {
      final rect = entry.value();
      if (rect != null && rect.contains(position)) {
        return true;
      }
    }
    return false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Pass through if hitting selectable items
    if (_hitTestSelectableItem(event.localPosition)) return;

    final controller = SelectionMode.of(context);

    // Only handle rectangle selection if enabled via options
    if (controller.options.rectangleSelection == null) return;

    // Auto-enable selection mode if configured
    if (!controller.isActive && _shouldAutoEnable(controller)) {
      controller.enable();
    }

    // Only start if selection mode is active
    if (controller.isActive) {
      controller.startRectangleSelection(event.localPosition);
      setState(() {
        _isDragging = true;
        _startPosition = event.localPosition;
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection (item-to-item)
    if (controller.isDragInProgress) {
      controller.handleDragUpdate(event.position);
      return;
    }

    // Handle rectangle selection
    if (_isDragging && _startPosition != null) {
      controller.updateRectangleSelection(event.localPosition);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection end
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }

    // Handle rectangle selection end
    if (_isDragging) {
      controller.endRectangleSelection();
      setState(() {
        _isDragging = false;
        _startPosition = null;
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection cancel
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }

    // Handle rectangle selection cancel
    if (_isDragging) {
      controller.cancelRectangleSelection();
      setState(() {
        _isDragging = false;
        _startPosition = null;
      });
    }
  }

  bool _shouldAutoEnable(SelectionModeController controller) {
    final behavior = controller.options.behavior;
    return behavior == SelectionBehavior.autoEnable ||
        behavior == SelectionBehavior.autoToggle;
  }
}
