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

    if (globalPosition.dy < -config.edgeThreshold ||
        globalPosition.dy > viewportSize.height + config.edgeThreshold) {
      updateScrollParams(ScrollDirection.none, 0.0);
      return;
    }

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
  ) =>
      switch (globalPosition.dy) {
        double y when y <= config.edgeThreshold => ScrollDirection.up,
        double y when y >= viewportSize.height - config.edgeThreshold =>
          ScrollDirection.down,
        double() => ScrollDirection.none,
      };

  double _calculateScrollSpeed(
    Offset globalPosition,
    Size viewportSize,
    ScrollDirection direction,
  ) {
    final distanceFromEdge = switch (direction) {
      ScrollDirection.up => globalPosition.dy,
      ScrollDirection.down => viewportSize.height - globalPosition.dy,
      ScrollDirection.none => 0.0,
    };

    if (distanceFromEdge == 0) {
      return 0.0; // No scrolling if at edge
    }

    // Calculate speed based on proximity to edge (closer = faster)
    final proximity = (config.edgeThreshold -
            distanceFromEdge.clamp(0, config.edgeThreshold)) /
        config.edgeThreshold;
    return config.scrollSpeed * proximity.clamp(0.1, 1.0);
  }

  void dispose() {
    stopDragAutoScroll();
  }
}
