/// Configuration for auto-scroll behavior during drag selection
class SelectionAutoScrollOptions {
  const SelectionAutoScrollOptions({
    this.edgeThreshold = 80,
    this.scrollSpeed = 300,
  });

  /// Distance from viewport edge to trigger auto-scroll
  final double edgeThreshold;

  /// Scroll speed in pixels per second
  final double scrollSpeed;

  SelectionAutoScrollOptions copyWith({
    double? edgeThreshold,
    double? scrollSpeed,
  }) {
    return SelectionAutoScrollOptions(
      edgeThreshold: edgeThreshold ?? this.edgeThreshold,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
    );
  }
}
