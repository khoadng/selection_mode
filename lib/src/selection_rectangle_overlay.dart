import 'package:flutter/material.dart';
import 'selection_consumer.dart';

/// Overlay widget that displays rectangle selection feedback
class SelectionRectangleOverlay extends StatelessWidget {
  const SelectionRectangleOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectionConsumer(
      builder: (context, controller, _) {
        final options = controller.options.rectangleSelection;
        if (options == null || !controller.isRectangleSelectionInProgress) {
          return const SizedBox.shrink();
        }

        final rect = controller.selectionRect;
        if (rect == null) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: CustomPaint(
            painter: _SelectionRectanglePainter(
              rect: rect,
              strokeWidth: options.strokeWidth,
              strokeColor:
                  options.strokeColor ?? Theme.of(context).colorScheme.primary,
              fillColor: options.fillColor,
            ),
          ),
        );
      },
    );
  }
}

class _SelectionRectanglePainter extends CustomPainter {
  const _SelectionRectanglePainter({
    required this.rect,
    required this.strokeWidth,
    required this.strokeColor,
    this.fillColor,
  });

  final Rect rect;
  final double strokeWidth;
  final Color strokeColor;
  final Color? fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;

    // Draw fill if specified
    if (fillColor != null) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor!;
      canvas.drawRect(rect, fillPaint);
    }

    // Draw border
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_SelectionRectanglePainter oldDelegate) {
    return rect != oldDelegate.rect ||
        strokeWidth != oldDelegate.strokeWidth ||
        strokeColor != oldDelegate.strokeColor ||
        fillColor != oldDelegate.fillColor;
  }
}
