import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../options/auto_scroll_options.dart';

enum ScrollDirection { up, down, none }

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
  ScrollDirection _direction = ScrollDirection.none;
  double _speed = 0.0;

  bool get isScrolling =>
      _ticker?.isActive == true && _direction != ScrollDirection.none;

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
  void updateScrollParams(ScrollDirection direction, double speed) {
    _direction = direction;
    _speed = speed;
  }

  /// Handle drag update and determine scroll parameters
  void handleDragUpdate(Offset globalPosition, Size viewportSize) {
    if (!scrollController.hasClients) return;

    final direction = _calculateScrollDirection(globalPosition, viewportSize);
    final speed = _calculateScrollSpeed(
      globalPosition,
      viewportSize,
      direction,
    );

    updateScrollParams(direction, speed);
  }

  /// Stop auto-scroll session
  void stopDragAutoScroll() {
    _ticker?.dispose();
    _ticker = null;
    _direction = ScrollDirection.none;
    _speed = 0.0;
  }

  void _performScroll(Duration elapsed) {
    if (_direction == ScrollDirection.none || _speed <= 0) return;

    if (!scrollController.hasClients) {
      stopDragAutoScroll();
      return;
    }

    final increment = _speed / 60;
    final currentOffset = scrollController.offset;
    final maxOffset = scrollController.position.maxScrollExtent;
    final minOffset = scrollController.position.minScrollExtent;

    final newOffset = switch (_direction) {
      ScrollDirection.up => (currentOffset - increment).clamp(
          minOffset,
          maxOffset,
        ),
      ScrollDirection.down => (currentOffset + increment).clamp(
          minOffset,
          maxOffset,
        ),
      ScrollDirection.none => currentOffset,
    };

    if (newOffset != currentOffset) {
      scrollController.jumpTo(newOffset);
      onScrollUpdate?.call();
    } else {
      updateScrollParams(ScrollDirection.none, 0.0);
    }
  }

  ScrollDirection _calculateScrollDirection(
    Offset globalPosition,
    Size viewportSize,
  ) {
    // Stop if pointer is in center area (away from edges)
    if (globalPosition.dy > config.edgeThreshold &&
        globalPosition.dy < viewportSize.height - config.edgeThreshold) {
      return ScrollDirection.none;
    }

    // Scroll up when pointer is at top edge or above viewport
    if (globalPosition.dy <= config.edgeThreshold) {
      return ScrollDirection.up;
    }

    // Scroll down when pointer is at bottom edge or below viewport
    if (globalPosition.dy >= viewportSize.height - config.edgeThreshold) {
      return ScrollDirection.down;
    }

    return ScrollDirection.none;
  }

  double _calculateScrollSpeed(
    Offset globalPosition,
    Size viewportSize,
    ScrollDirection direction,
  ) {
    if (direction == ScrollDirection.none) return 0.0;

    final (distanceFromEdge, beyondDistance) = switch (direction) {
      ScrollDirection.up => (
          globalPosition.dy,
          globalPosition.dy < 0 ? -globalPosition.dy : 0.0
        ),
      ScrollDirection.down => (
          viewportSize.height - globalPosition.dy,
          globalPosition.dy > viewportSize.height
              ? globalPosition.dy - viewportSize.height
              : 0.0
        ),
      ScrollDirection.none => (0.0, 0.0),
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
