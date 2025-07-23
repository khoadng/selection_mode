import 'package:flutter/material.dart';
import 'controller.dart';
import 'selection_consumer.dart';
import 'selection_mode.dart';
import 'selection_options.dart';

/// Interactive canvas for selection mode gestures.
///
/// - Tap on canvas → exit selection mode (standard UX)
/// - Drag on canvas → rectangle selection (if enabled)
/// - Hit selectable item → pass through to existing drag selection
class SelectionCanvas extends StatefulWidget {
  const SelectionCanvas({
    super.key,
    required this.child,
    this.enableRectangleSelection = false,
    this.isToggleMode = false,
    this.onBackgroundTap,
  });

  final Widget child;

  /// Enable rectangle selection via drag gestures on background
  final bool enableRectangleSelection;

  /// If true, rectangle selection toggles items (add unselected, remove selected).
  /// If false, rectangle selection replaces current selection.
  final bool isToggleMode;

  /// Called when canvas is tapped while selection mode is active.
  /// If null, defaults to disabling selection mode.
  final VoidCallback? onBackgroundTap;

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
          behavior: HitTestBehavior.translucent,
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

    // Only handle rectangle selection if enabled
    if (!widget.enableRectangleSelection) return;

    final controller = SelectionMode.of(context);

    // Auto-enable selection mode if configured
    if (!controller.isActive && _shouldAutoEnable(controller)) {
      controller.enable();
    }

    // Only start if selection mode is active and rectangle selection is configured
    if (controller.isActive && controller.options.rectangleSelection != null) {
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
      controller.updateRectangleSelection(
        event.localPosition,
        isToggleMode: widget.isToggleMode,
      );
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
