import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'selection_options.dart';

enum ScrollDirection { up, down, none }

/// Manages auto-scrolling during drag selection
class AutoScrollManager {
  AutoScrollManager({
    required this.scrollController,
    required this.config,
  });

  final ScrollController scrollController;
  final AutoScrollConfig config;

  Ticker? _ticker;
  ScrollDirection _currentDirection = ScrollDirection.none;
  double _currentSpeed = 0.0;

  /// Handle drag update and determine if auto-scroll should trigger
  void handleDragUpdate(Offset globalPosition, Size viewportSize) {
    if (!scrollController.hasClients) return;

    final direction = _calculateScrollDirection(globalPosition, viewportSize);
    final speed = _calculateScrollSpeed(
      globalPosition,
      viewportSize,
      direction,
    );

    if (direction != _currentDirection || speed != _currentSpeed) {
      _updateAutoScroll(direction, speed);
    }
  }

  /// Start auto-scrolling in the specified direction
  void startAutoScroll(ScrollDirection direction, double speed) {
    if (direction == ScrollDirection.none || speed <= 0) {
      stopAutoScroll();
      return;
    }

    _updateAutoScroll(direction, speed);
  }

  /// Stop auto-scrolling
  void stopAutoScroll() {
    _ticker?.dispose();
    _ticker = null;
    _currentDirection = ScrollDirection.none;
    _currentSpeed = 0.0;
  }

  void _updateAutoScroll(ScrollDirection direction, double speed) {
    if (direction == ScrollDirection.none || speed <= 0) {
      stopAutoScroll();
      return;
    }

    if (_currentDirection == direction && _currentSpeed == speed) {
      return; // No change needed
    }

    _currentDirection = direction;
    _currentSpeed = speed;

    _ticker?.dispose();
    _ticker = Ticker((_) => _performScroll())..start();
  }

  void _performScroll() {
    if (!scrollController.hasClients) {
      stopAutoScroll();
      return;
    }

    if (_currentDirection == ScrollDirection.none) {
      return; // No scrolling needed
    }

    final increment = _currentSpeed / 60; // Per-frame increment at 60fps
    final currentOffset = scrollController.offset;
    final maxOffset = scrollController.position.maxScrollExtent;
    final minOffset = scrollController.position.minScrollExtent;

    final newOffset = switch (_currentDirection) {
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
    } else {
      stopAutoScroll();
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
    final speed = config.scrollSpeed * proximity.clamp(0.1, 1.0);

    return speed;
  }

  /// Dispose resources
  void dispose() {
    stopAutoScroll();
  }
}
