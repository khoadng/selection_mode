# Selection Mode

A Flutter package for multi-item selection with drag gestures, range selection, and flexible behavior patterns.

## Features

- **Drag selection** - Touch and drag to select multiple items
- **Range selection** - Long-press+drag to select a range of items
- **Auto-scroll** - Smooth scrolling during drag selection
- **Flexible behaviors** - Auto-enable, manual control, or implicit mode

## Quick Start

```dart
class PhotoGrid extends StatefulWidget {
  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final _controller = SelectionModeController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionMode(
      controller: _controller,
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          controller: _controller,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share selected',
              onPressed: () => print('Share'),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy selected',
              onPressed: () => print('Copy'),
            ),
          ],
          child: AppBar(title: const Text('Basic Selection')),
        ),
        body: GridView.builder(
          controller: _scrollController, // Attach scroll controller for auto-scroll when dragging
          itemBuilder: (context, index) => SelectionBuilder(
            index: index,
            isSelectable: index != 0,               // Example: first item not selectable
            onTap: () => _handleTap(index),
            builder: (context, isSelected) => PhotoTile(
              photo: photos[index],
              isSelected: isSelected,
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (_controller.isActive) {
      _controller.toggleItem(index);
    } else {
      // Normal tap behavior
      openPhoto(index);
    }
  }
}
```

## Configuration

```dart
SelectionModeController(
  options: SelectionOptions(
    haptics: HapticFeedbackResolver.all,                // Haptic feedback for all events
    constraints: const SelectionConstraints(
      maxSelections: 10,                                // Maximum items to select
    ),
    behavior: SelectionBehavior.manual,        // Explicit manual control
    autoScroll: AutoScrollConfig(
      edgeThreshold: 80,                                // Distance from edge to trigger
      scrollSpeed: 900,                                 // Scroll speed in pixels per second
    ),
  ),
);

// Haptic options
HapticFeedbackResolver.all       // Feedback for all events
HapticFeedbackResolver.modeOnly  // Only mode enter/exit
HapticFeedbackResolver.none      // No haptic feedback

// Pre-configured options
SelectionModeOptions.manual      // Manual enable/disable only
SelectionModeOptions.implicit    // Auto enable + auto exit when empty  
```

## Examples

- **Basic List** - Simple list selection with action footer
- **Photo Grid** - Grid with drag selection and auto-scroll
- **Mixed Content** - Complex lists with headers and selective items

See `/example` folder for complete implementations.

