import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../options/auto_scroll_options.dart';

/// Manages auto-scrolling during drag selection
class AutoScrollManager {
  AutoScrollManager({
    required this.scrollController,
    required this.config,
  });

  final ScrollController scrollController;
  final SelectionAutoScrollOptions config;

  VoidCallback? onScrollUpdate;

  Ticker? _ticker;
  AxisDirection? _direction;
  double _speed = 0.0;

  bool get isScrolling =>
      _ticker?.isActive == true && _direction != null && _speed > 0;

  Size? getViewportSize() {
    if (!scrollController.hasClients) return null;
    final context = scrollController.position.context.storageContext;
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size;
  }

  /// Start auto-scroll session for drag operation
  void startDragAutoScroll() {
    _ticker?.dispose();
    _ticker = Ticker(_performScroll)..start();
  }

  /// Update scroll parameters during drag
  void updateScrollParams(AxisDirection? direction, double speed) {
    _direction = direction;
    _speed = speed;
  }

  /// Handle drag update and determine scroll parameters
  void handleDragUpdate(Offset globalPosition, Size viewportSize) {
    if (!scrollController.hasClients) return;

    final axis = scrollController.position.axis;
    final direction =
        _calculateScrollDirection(globalPosition, viewportSize, axis);
    final speed = _calculateScrollSpeed(
      globalPosition,
      viewportSize,
      direction,
      axis,
    );

    updateScrollParams(direction, speed);
  }

  /// Stop auto-scroll session
  void stopDragAutoScroll() {
    _ticker?.dispose();
    _ticker = null;
    _direction = null;
    _speed = 0.0;
  }

  void _performScroll(Duration elapsed) {
    if (_direction == null || _speed <= 0) return;

    if (!scrollController.hasClients) {
      stopDragAutoScroll();
      return;
    }

    final increment = _speed / 60;
    final currentOffset = scrollController.offset;
    final maxOffset = scrollController.position.maxScrollExtent;
    final minOffset = scrollController.position.minScrollExtent;

    final newOffset = switch (_direction!) {
      AxisDirection.up ||
      AxisDirection.left =>
        (currentOffset - increment).clamp(
          minOffset,
          maxOffset,
        ),
      AxisDirection.down ||
      AxisDirection.right =>
        (currentOffset + increment).clamp(
          minOffset,
          maxOffset,
        ),
    };

    if (newOffset != currentOffset) {
      scrollController.jumpTo(newOffset);
      onScrollUpdate?.call();
    } else {
      updateScrollParams(null, 0.0);
    }
  }

  AxisDirection? _calculateScrollDirection(
    Offset globalPosition,
    Size viewportSize,
    Axis axis,
  ) {
    final (position, size) = switch (axis) {
      Axis.vertical => (globalPosition.dy, viewportSize.height),
      Axis.horizontal => (globalPosition.dx, viewportSize.width),
    };

    // Stop if pointer is in center area (away from edges)
    if (position > config.edgeThreshold &&
        position < size - config.edgeThreshold) {
      return null;
    }

    // Scroll towards start when pointer is at start edge or beyond viewport
    if (position <= config.edgeThreshold) {
      return axis == Axis.vertical ? AxisDirection.up : AxisDirection.left;
    }

    // Scroll towards end when pointer is at end edge or beyond viewport
    if (position >= size - config.edgeThreshold) {
      return axis == Axis.vertical ? AxisDirection.down : AxisDirection.right;
    }

    return null;
  }

  double _calculateScrollSpeed(
    Offset globalPosition,
    Size viewportSize,
    AxisDirection? direction,
    Axis axis,
  ) {
    if (direction == null) return 0.0;

    final (position, size) = switch (axis) {
      Axis.vertical => (globalPosition.dy, viewportSize.height),
      Axis.horizontal => (globalPosition.dx, viewportSize.width),
    };

    final (distanceFromEdge, beyondDistance) = switch (direction) {
      AxisDirection.up || AxisDirection.left => (
          position,
          position < 0 ? -position : 0.0
        ),
      AxisDirection.down || AxisDirection.right => (
          size - position,
          position > size ? position - size : 0.0
        ),
    };

    // Beyond viewport: progressive acceleration
    if (beyondDistance > 0) {
      final accelerationFactor =
          1.0 + (beyondDistance / config.edgeThreshold).clamp(0.0, 3.0);
      return config.scrollSpeed * accelerationFactor;
    }

    // Within edge threshold: proximity-based speed
    final proximity =
        (config.edgeThreshold - distanceFromEdge) / config.edgeThreshold;
    return config.scrollSpeed *
        config.speedCurve.transform(proximity.clamp(0.0, 1.0));
  }

  void dispose() {
    stopDragAutoScroll();
  }
}
