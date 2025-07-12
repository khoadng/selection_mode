# Selection Mode

A powerful Flutter package for multi-item selection with drag gestures, range selection, and flexible behavior patterns.

## Features

- **Drag selection** - Touch and drag to select multiple items
- **Range selection** - Shift+click for desktop, long-press+drag for mobile  
- **Auto-scroll** - Smooth scrolling during drag selection
- **Flexible behaviors** - Auto-enable, manual control, or implicit mode
- **Built-in widgets** - Selection app bar, footer, and item builders
- **Platform adaptive** - Works great on mobile and desktop

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
            enableRangeSelection: true,             // Enable range selection
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
    if (_controller.enabled) {
      _controller.toggleSelection(index);
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
  options: SelectionModeOptions(
    hapticResolver: HapticFeedbackResolver.all,         // Haptic feedback for all events
    maxSelections: 5,                                   // Limit selection count
    enableDragSelection: true,                          // Touch drag to select
    enableLongPress: true,                              // Long press to start
    selectionBehavior: SelectionBehavior.autoEnable,    // Auto-enable mode
    hapticResolver: HapticFeedbackResolver.all,         // Haptic feedback
    autoScroll: AutoScrollConfig(
      edgeThreshold: 80.0,                              // Distance from edge to trigger
      scrollSpeed: 20.0,                                // Scroll speed in pixels
      scrollInterval: Duration(milliseconds: 16),       // Scroll frequency
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

