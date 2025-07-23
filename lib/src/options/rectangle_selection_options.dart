import 'package:flutter/widgets.dart';

/// Configuration for rectangle selection behavior
class RectangleSelectionOptions {
  const RectangleSelectionOptions({
    this.strokeWidth = 2.0,
    this.strokeColor,
    this.fillColor,
    this.delay,
  });

  /// Width of the rectangle border
  final double strokeWidth;

  /// Color of the rectangle border. If null, uses theme accent color
  final Color? strokeColor;

  /// Fill color of the rectangle. If null, uses transparent
  final Color? fillColor;

  /// Delay before starting rectangle selection
  final Duration? delay;

  RectangleSelectionOptions copyWith({
    double? strokeWidth,
    Color? strokeColor,
    Color? fillColor,
    Duration? delay,
  }) {
    return RectangleSelectionOptions(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      delay: delay ?? this.delay,
    );
  }
}
