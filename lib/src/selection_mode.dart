import 'package:flutter/material.dart';
import 'controller.dart';
import 'auto_scroll_manager.dart';
import 'selection_options.dart';

class SelectionMode extends StatefulWidget {
  const SelectionMode({
    super.key,
    this.controller,
    this.options,
    this.onModeChanged,
    this.onChanged,
    this.scrollController,
    required this.child,
  });

  final SelectionModeController? controller;
  final SelectionOptions? options;
  final ScrollController? scrollController;
  final void Function(bool value)? onModeChanged;
  final void Function(Set<int> selection)? onChanged;
  final Widget child;

  /// Access the selection controller from the widget tree
  static SelectionModeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SelectionModeScope>();
    if (scope == null) {
      throw FlutterError(
        'SelectionMode.of() called with a context that does not contain a SelectionMode.',
      );
    }
    return scope.controller;
  }

  /// Access the selection controller from the widget tree (nullable)
  static SelectionModeController? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SelectionModeScope>();
    return scope?.controller;
  }

  @override
  State<SelectionMode> createState() => _SelectionModeState();
}

class _SelectionModeState extends State<SelectionMode> {
  late SelectionModeController _controller;
  late bool _previousActive;
  Set<int> _previousSelection = {};
  AutoScrollManager? _autoScrollManager;
  late final ValueNotifier<bool> _enable;
  late SelectionOptions _effectiveOptions;

  @override
  void initState() {
    super.initState();
    _effectiveOptions = widget.options ?? const SelectionOptions();
    _controller = widget.controller ?? SelectionModeController();
    _controller.initializeOptions(_effectiveOptions);
    _enable = ValueNotifier(_controller.isActive);
    _previousActive = _controller.isActive;
    _previousSelection = Set.from(_controller.selection);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupAutoScroll();
  }

  @override
  void didUpdateWidget(SelectionMode oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.options != oldWidget.options) {
      _effectiveOptions = widget.options ?? const SelectionOptions();
      _controller.updateOptions(_effectiveOptions);
      _setupAutoScroll();
    }

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChanged);
      _controller = widget.controller ?? SelectionModeController();
      _controller.updateOptions(_effectiveOptions);
      _enable.value = _controller.isActive;
      _previousActive = _controller.isActive;
      _previousSelection = Set.from(_controller.selection);
      _controller.addListener(_onControllerChanged);
      _setupAutoScroll();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _autoScrollManager?.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _setupAutoScroll() {
    final autoScrollConfig = _effectiveOptions.autoScroll;

    _autoScrollManager?.dispose();
    _autoScrollManager = null;
    final scrollController = widget.scrollController;

    if (scrollController != null && autoScrollConfig != null) {
      _autoScrollManager = AutoScrollManager(
        scrollController: scrollController,
        config: autoScrollConfig,
      );

      _controller.setAutoScrollManager(_autoScrollManager);
    }
  }

  void _onControllerChanged() {
    final currentEnabled = _controller.isActive;
    final currentSelection = _controller.selection;
    _enable.value = currentEnabled;

    if (_previousActive != currentEnabled) {
      widget.onModeChanged?.call(currentEnabled);
      _previousActive = currentEnabled;
    }

    if (_previousSelection != currentSelection) {
      widget.onChanged?.call(Set.from(currentSelection));
      _previousSelection = Set.from(currentSelection);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_controller.isDragInProgress) return;

    _controller.handleDragUpdate(event.position);
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionModeScope(
      controller: _controller,
      child: ValueListenableBuilder(
        valueListenable: _enable,
        builder: (context, enabled, child) => PopScope(
          canPop: !enabled,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && enabled) {
              _controller.disable();
            }
          },
          child: Listener(
            onPointerMove: enabled ? _handlePointerMove : null,
            onPointerUp: enabled
                ? (event) {
                    if (_controller.isDragInProgress) {
                      _controller.endRangeSelection();
                    }
                  }
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SelectionModeScope extends InheritedWidget {
  const _SelectionModeScope({
    required this.controller,
    required super.child,
  });

  final SelectionModeController controller;

  @override
  bool updateShouldNotify(_SelectionModeScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
