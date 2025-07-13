import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

const _kDefaultAnimationDuration = Duration(milliseconds: 200);

class SelectionFooter extends StatelessWidget {
  const SelectionFooter({
    super.key,
    this.controller,
    this.animated = true,
    required this.child,
  });

  final SelectionModeController? controller;
  final bool animated;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        if (!animated) {
          return ctrl.isActive ? child : const SizedBox.shrink();
        }

        return _AnimatedFooter(
          enabled: ctrl.isActive,
          duration: _kDefaultAnimationDuration,
          curve: Curves.easeInOut,
          child: child,
        );
      },
    );
  }
}

class _AnimatedFooter extends StatelessWidget {
  const _AnimatedFooter({
    required this.enabled,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final bool enabled;
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: enabled ? colorScheme.surface : Colors.transparent,
      child: SafeArea(
        top: false,
        child: AnimatedSlide(
          duration: duration,
          curve: curve,
          offset: enabled ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: duration,
            curve: curve,
            opacity: enabled ? 1.0 : 0.0,
            child: enabled ? child : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
