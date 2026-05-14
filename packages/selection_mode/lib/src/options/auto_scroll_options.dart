import 'package:flutter/animation.dart';

/// Configuration for auto-scroll behavior during drag selection
class SelectionAutoScrollOptions {
  const SelectionAutoScrollOptions({
    this.edgeThreshold = 80,
    this.scrollSpeed = 300,
    this.speedCurve = Curves.linear,
  });

  /// Distance from viewport edge to trigger auto-scroll
  final double edgeThreshold;

  /// Scroll speed in pixels per second
  final double scrollSpeed;

  /// Curve applied to proximity-based speed calculation
  final Curve speedCurve;

  SelectionAutoScrollOptions copyWith({
    double? edgeThreshold,
    double? scrollSpeed,
    Curve? speedCurve,
  }) {
    return SelectionAutoScrollOptions(
      edgeThreshold: edgeThreshold ?? this.edgeThreshold,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      speedCurve: speedCurve ?? this.speedCurve,
    );
  }
}
