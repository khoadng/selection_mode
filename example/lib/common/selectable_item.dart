import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

const _kDefaultAnimationDuration = Duration(milliseconds: 200);

class SelectableItem extends StatefulWidget {
  const SelectableItem({
    super.key,
    required this.onTap,
    required this.itemBuilder,
    required this.index,
  });

  final int index;
  final VoidCallback onTap;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<SelectableItem> createState() => _SelectableItemState();
}

class _SelectableItemState extends State<SelectableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _animationController.duration = Duration(
      milliseconds: (_kDefaultAnimationDuration.inMilliseconds * 0.4).round(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SelectionBuilder(
        index: widget.index,
        builder: (context, isSelected) {
          Widget child = SelectionListener(
            controller: SelectionMode.of(context),
            index: widget.index,
            onSelectionChanged: (selected) {
              if (selected && _kDefaultAnimationDuration != Duration.zero) {
                _animationController.forward().then(
                  (value) => _animationController.reverse(),
                );
              }
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                widget.itemBuilder(context, widget.index),
                if (isSelected) const _SelectionIcon(),
              ],
            ),
          );

          // Skip scale animation if animations are disabled
          if (_kDefaultAnimationDuration == Duration.zero) {
            return child;
          }

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
      ),
    );
  }
}

class _SelectionIcon extends StatelessWidget {
  const _SelectionIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: 18, color: colorScheme.onPrimary),
    );
  }
}

class SelectionListener extends StatefulWidget {
  const SelectionListener({
    super.key,
    required this.controller,
    required this.index,
    required this.onSelectionChanged,
    required this.child,
  });

  final SelectionModeController controller;
  final int index;
  final void Function(bool selected) onSelectionChanged;
  final Widget child;

  @override
  State<SelectionListener> createState() => _SelectionListenerState();
}

class _SelectionListenerState extends State<SelectionListener> {
  late bool _previousSelected;

  @override
  void initState() {
    super.initState();
    _previousSelected = widget.controller.isSelected(widget.index);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final currentSelected = widget.controller.isSelected(widget.index);
    if (_previousSelected != currentSelected) {
      widget.onSelectionChanged(currentSelected);
      _previousSelected = currentSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
