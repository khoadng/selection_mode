import 'package:flutter/material.dart';
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
  final GlobalKey _canvasKey = GlobalKey();
  SelectionModeController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = SelectionMode.maybeOf(context);

    if (_controller == null) {
      throw FlutterError(
        'SelectionCanvas must be used within a SelectionMode widget.',
      );
    }

    _controller!.setCanvasKey(_canvasKey);
  }

  @override
  void dispose() {
    _controller?.setCanvasKey(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) => Listener(
        key: _canvasKey,
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

  void _handlePointerMove(PointerMoveEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection (item-to-item)
    if (controller.isDragInProgress) {
      controller.handleDragUpdate(event.position);
      return;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection end
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final controller = SelectionMode.of(context);

    // Handle regular drag selection cancel
    if (controller.isDragInProgress) {
      controller.endRangeSelection();
    }
  }
}
