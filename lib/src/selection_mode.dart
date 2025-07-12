import 'package:flutter/material.dart';
import 'controller.dart';
import 'auto_scroll_manager.dart';
import 'selection_mode_options.dart';

class SelectionMode extends StatefulWidget {
  const SelectionMode({
    super.key,
    this.controller,
    this.onEnabledChanged,
    this.scrollController,
    required this.child,
  });

  final SelectionModeController? controller;
  final ScrollController? scrollController;
  final void Function(bool enabled)? onEnabledChanged;
  final Widget child;

  /// Access the selection controller from the widget tree
  static SelectionModeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SelectionModeScope>();
    if (scope == null) {
      throw FlutterError(
        'SelectionMode.of() called with a context that does not contain a SelectionMode.',
      );
    }
    return scope.controller;
  }

  /// Access the selection controller from the widget tree (nullable)
  static SelectionModeController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SelectionModeScope>();
    return scope?.controller;
  }

  @override
  State<SelectionMode> createState() => _SelectionModeState();
}

class _SelectionModeState extends State<SelectionMode> {
  late SelectionModeController _controller;
  late bool _previousEnabled;
  AutoScrollManager? _autoScrollManager;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SelectionModeController();
    _previousEnabled = _controller.enabled;
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
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChanged);
      _controller = widget.controller ?? SelectionModeController();
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
    final autoScrollConfig =
        _controller.options.autoScroll ?? AutoScrollConfig();

    // Dispose existing manager
    _autoScrollManager?.dispose();
    _autoScrollManager = null;
    final scrollController = widget.scrollController;

    if (scrollController != null) {
      _autoScrollManager = AutoScrollManager(
        scrollController: scrollController,
        config: autoScrollConfig,
      );

      _controller.setAutoScrollManager(_autoScrollManager);
    }
  }

  void _onControllerChanged() {
    final currentEnabled = _controller.enabled;

    if (_previousEnabled != currentEnabled) {
      widget.onEnabledChanged?.call(currentEnabled);
      _previousEnabled = currentEnabled;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionModeScope(
      controller: _controller,
      child: PopScope(
        canPop: !_controller.enabled,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _controller.enabled) {
            _controller.disable();
          }
        },
        child: widget.child,
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
