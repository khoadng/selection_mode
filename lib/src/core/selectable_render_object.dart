import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'controller.dart';

/// Custom render object that handles hit testing for selection operations
class RenderSelectable extends RenderProxyBox {
  RenderSelectable({
    required int index,
    required SelectionModeController controller,
    required bool isSelectable,
    RenderBox? child,
  })  : _index = index,
        _controller = controller,
        _isSelectable = isSelectable,
        super(child);

  int _index;
  SelectionModeController _controller;
  bool _isSelectable;

  int get index => _index;
  set index(int value) {
    if (_index != value) {
      _index = value;
      markNeedsPaint();
    }
  }

  SelectionModeController get controller => _controller;
  set controller(SelectionModeController value) {
    if (_controller != value) {
      _controller = value;
      markNeedsPaint();
    }
  }

  bool get isSelectable => _isSelectable;
  set isSelectable(bool value) {
    if (_isSelectable != value) {
      _isSelectable = value;
      markNeedsPaint();
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Handle drag selection hit testing
    if (_isSelectable && _controller.isDragInProgress) {
      _controller.handleDragOver(_index);
    }

    return super.hitTest(result, position: position);
  }
}

/// Widget that creates the custom render object for selection hit testing
class SelectableWidget extends SingleChildRenderObjectWidget {
  const SelectableWidget({
    super.key,
    required this.index,
    required this.controller,
    required this.isSelectable,
    required super.child,
  });

  final int index;
  final SelectionModeController controller;
  final bool isSelectable;

  @override
  RenderSelectable createRenderObject(BuildContext context) {
    return RenderSelectable(
      index: index,
      controller: controller,
      isSelectable: isSelectable,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSelectable renderObject) {
    renderObject
      ..index = index
      ..controller = controller
      ..isSelectable = isSelectable;
  }
}
