# Selection Mode

A Flutter package for multi-item selection with range selection.

> **⚠️ Alpha Stage**: This package is in alpha. Expect breaking changes in version updates.

## Features

- **Drag selection** - Touch and drag to select multiple items
- **Range selection** - Long-press+drag for range selection
- **Auto-scroll** - Smooth scrolling during drag selection
- **Stable selection** - Uses ValueKey identifiers for persistent selection across data changes
- **Flexible behaviors** - Manual, auto-enable, or auto-toggle modes
- **Selection constraints** - Limit maximum selections
- **Haptic feedback** - Configurable haptic responses

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
  Widget build(BuildContext context) {
    return SelectionMode(
      controller: _controller,
      scrollController: _scrollController, // For auto-scroll during drag
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share selected',
              onPressed: () => _shareSelected(),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete selected',
              onPressed: () => _deleteSelected(),
            ),
          ],
          child: AppBar(title: const Text('Selection Demo')),
        ),
        body: GridView.builder(
          controller: _scrollController,
          itemBuilder: (context, index) => SelectableBuilder(
            key: ValueKey(photos[index].id), // Stable selection with ValueKey
            index: index,
            isSelectable: photos[index].canSelect,
            builder: (context, isSelected) => PhotoTile(
              photo: photos[index],
              isSelected: isSelected,
              onTap: () => _handleTap(index),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Flexible Layout - Custom UI Positioning

```dart
// Put SelectionMode somewhere at the top of your widget tree
SelectionMode(
  controller: _controller,
  child: Stack(
    children: [
      GridView.builder(
        // Wrap with SelectableBuilder for each item to handle selection
        itemBuilder: (context, index) => SelectableBuilder(
          index: index,
          builder: (context, isSelected) => GestureDetector(
            onTap: () => _controller.toggleItem(index),
            child: Container(
              decoration: isSelected ? BoxDecoration(border: Border.all(color: Colors.blue)) : null,
              child: Card(child: Center(child: Text('Item $index'))),
            ),
          ),
        ),
      ),

      // Custom selection status + selection controls
      SelectionConsumer(
        builder: (context, controller, _) => controller.isActive ? Positioned(
          top: 20, left: 20,
          child: ActionChip(
            label: Text('${_controller.selection.length} selected'),
            onPressed: _controller.disable,
          ),
        ) : SizedBox.shrink(),
      ),

      // Custom selection controls
      SelectionBuilder(
        builder: (context, controller, _) => controller.isActive ? Positioned(
          bottom: 20,
          child: Row(
            children: [
              IconButton(icon: Icon(Icons.share), onPressed: _share),
              IconButton(icon: Icon(Icons.delete), onPressed: _delete),
              IconButton(icon: Icon(Icons.copy), onPressed: _copy),
            ],
          ),
        ) : SizedBox.shrink(),
      ),
    ],
  ),
)
```

## Stable Selection with ValueKey (Optional)

**ValueKey is optional** - the package works fine without it if your data doesn't change during selection.

```dart
// With ValueKey - for dynamic data that may reorder/change
SelectableBuilder(
  key: ValueKey(item.id), // Selection persists when list changes
  index: index,
  builder: (context, isSelected) => ItemWidget(item: item),
)

// Without ValueKey - for static data
SelectableBuilder(
  index: index, // Works fine if data doesn't change
  builder: (context, isSelected) => ItemWidget(item: item),
)
```

## Working with Selected Items

**Static data** (no changes during selection):
```dart
// Direct index access - simple and fast
final selectedItems = controller.selection
    .map((index) => items[index])
    .toList();
```

**Dynamic data** (changes during selection):
```dart
// Query selected items fluently
final selectedPhotos = controller.selectedFrom(photos).toList();

// Transform selected items
final titles = controller
    .selectedFrom(contacts)
    .where((c) => c.isActive)
    .map((c) => c.name)
    .toList();

// Check selection state
if (controller.selectedFrom(items).hasAny) {
  print('${controller.selectedFrom(items).length} items selected');
}
```

## Configuration

```dart
SelectionModeController(
  options: SelectionOptions(
    behavior: SelectionBehavior.autoToggle,     // Auto enable/disable
    constraints: SelectionConstraints(
      maxSelections: 10,                        // Limit selections
    ),
    haptics: HapticFeedbackResolver.all,        // Haptic feedback
    autoScroll: AutoScrollConfig(
      edgeThreshold: 80,                        // Auto-scroll trigger distance
      scrollSpeed: 900,                         // Scroll speed (px/sec)
    ),
  ),
);
```

## Selection Behaviors

### Manual (Explicit Control)
```dart
SelectionOptions(behavior: SelectionBehavior.manual)
// - Must call enable()/disable() explicitly
// - Selection blocked when disabled
```

### Auto Enable (Default)
```dart
SelectionOptions(behavior: SelectionBehavior.autoEnable)
// - Auto-enables on first selection
// - Manual disable required
```

### Implicit (Auto Toggle)
```dart
SelectionOptions(behavior: SelectionBehavior.autoToggle)
// - Auto-enables on first selection
// - Auto-disables when all items deselected
```

## Haptic Feedback

```dart
// Haptic options
HapticFeedbackResolver.all       // Feedback for all events
HapticFeedbackResolver.modeOnly  // Only mode enter/exit
HapticFeedbackResolver.none      // No haptic feedback

// Custom haptic resolver
void customHaptics(HapticEvent event) {
  switch (event) {
    case HapticEvent.itemSelected:
      HapticFeedback.lightImpact();
    case HapticEvent.maxItemsReached:
      HapticFeedback.heavyImpact();
    // Handle other events...
  }
}
```



## Range Operations

```dart
// Select/deselect ranges
controller.selectRange(0, 5);
controller.deselectRange(2, 4);
controller.toggleRange(1, 3);

// Range queries
final count = controller.getSelectedCountInRange(0, 10);
final hasSelection = controller.hasSelectionInRange(5, 8);
final fullySelected = controller.isRangeFullySelected(2, 6);
```

## Bulk Operations

```dart
// Select specific items
controller.selectAll([1, 3, 5, 7, 9]);

// Invert selection
controller.invertSelection(allItemIndices);

// Clear all
controller.deselectAll();
```

## UI Components

### Selection App Bar
```dart
MaterialSelectionAppBar(
  controller: controller,
  actions: [...], // Selection mode actions
  child: AppBar(...), // Normal app bar
)
```

### Action Bar
```dart
SelectionActionBar(
  children: [
    IconButton(icon: Icon(Icons.share), onPressed: share),
    IconButton(icon: Icon(Icons.delete), onPressed: delete),
  ],
)
```

### Status Bar
```dart
SelectionStatusBar(
  leftActions: [backButton],
  rightActions: [menuButton],
  statusBuilder: (context, count) => Text('$count selected'),
)
```

## Examples

- **Basic List** - Simple list with manual selection mode
- **Photo Grid** - Grid with drag selection and auto-scroll
- **Mixed Content** - Complex lists with constraints and implicit behavior

See `/example` folder for complete implementations.
