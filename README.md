# Selection Mode

![Pub Version](https://img.shields.io/pub/v/selection_mode)

A Flutter package for multi-item selection with drag, range selection.

> **⚠️ Alpha Stage**: This package is in alpha. Expect breaking changes in version updates.

## Features

- **Drag selection** - Touch and drag between items for range selection
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
  final List<Photo> photos = [];

  @override
  Widget build(BuildContext context) {
    return SelectionMode(
      controller: _controller,
      scrollController: _scrollController, // For auto-scroll during drag
      options: SelectionOptions(
        behavior: SelectionBehavior.autoEnable,
        dragSelection: DragSelectionOptions(),
      ),
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSelected(),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelected(),
            ),
          ],
          child: AppBar(title: const Text('Photo Gallery')),
        ),
        body: SelectionCanvas(
          child: GridView.builder(
            controller: _scrollController,
            itemCount: photos.length,
            itemBuilder: (context, index) => SelectableBuilder(
              key: ValueKey(photos[index].id), // Stable selection
              index: index,
              isSelectable: photos[index].canSelect,
              builder: (context, isSelected) => GestureDetector(
                onTap: () => _handleTap(index),
                child: PhotoTile(
                  photo: photos[index],
                  isSelected: isSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Core Components

### SelectionMode
The root widget that provides selection functionality:

```dart
SelectionMode(
  controller: _controller,           // Optional: provide your own controller
  scrollController: _scrollController, // For auto-scroll during drag
  options: SelectionOptions(...),    // Configure behavior
  onModeChanged: (enabled) => ...,   // Listen to mode changes
  onChanged: (selection) => ...,     // Listen to selection changes
  child: YourWidget(),
)
```

### SelectableBuilder
Makes individual items selectable:

```dart
SelectableBuilder(
  key: ValueKey(item.id),  // Optional: for stable selection
  index: index,            // Required: item index
  isSelectable: true,      // Optional: whether item can be selected
  builder: (context, isSelected) => ItemWidget(
    isSelected: isSelected,
  ),
)
```


## Selection Behaviors

### Manual (Explicit Control)
```dart
SelectionOptions(behavior: SelectionBehavior.manual)
// - Must call enable()/disable() explicitly
// - No automatic mode changes
```

### Auto Enable (Default)
```dart
SelectionOptions(behavior: SelectionBehavior.autoEnable)
// - Auto-enables on first item selection
// - Manual disable required
```

### Auto Toggle (Implicit)
```dart
SelectionOptions(behavior: SelectionBehavior.autoToggle)
// - Auto-enables on first item selection
// - Auto-disables when all items deselected
```

## Selection Types

### Drag Selection
Touch and drag between items to select ranges:

```dart
SelectionOptions(
  dragSelection: DragSelectionOptions(
    axis: Axis.vertical,          // Optional: constrain drag direction
    delay: Duration(milliseconds: 100), // Optional: prevent accidental drags
  ),
)
```

## Working with Selected Items

### Direct Access (Static Data)
```dart
// Direct index access - simple and fast
final selectedItems = controller.selection
    .map((index) => items[index])
    .toList();
```

### Query API (Dynamic Data)
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

## Configuration Options

```dart
SelectionOptions(
  behavior: SelectionBehavior.autoToggle,
  
  constraints: SelectionConstraints(
    maxSelections: 10,                    // Limit selections
  ),
  
  haptics: HapticFeedbackResolver.all,    // Haptic feedback
  
  autoScroll: SelectionAutoScrollOptions(
    edgeThreshold: 80,                    // Auto-scroll trigger distance
    scrollSpeed: 300,                     // Scroll speed (px/sec)
  ),
  
  dragSelection: DragSelectionOptions(
    axis: Axis.vertical,                  // Constrain drag direction
    delay: Duration(milliseconds: 100),   // Prevent accidental drags
  ),
)
```

## Haptic Feedback

```dart
// Predefined resolvers
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
    case HapticEvent.dragStart:
      HapticFeedback.mediumImpact();
    // Handle other events...
  }
}
```

## Controller Methods

### Selection Control
```dart
// Individual items
controller.toggleItem(index);
controller.selectAll(allIndices);
controller.deselectAll();
controller.invertSelection(allIndices);

// Range operations
controller.selectRange(0, 5);
controller.deselectRange(2, 4);
controller.toggleRange(1, 3);

// Mode control
controller.enable();
controller.disable();
controller.toggle();
```

### Range Queries
```dart
// Range information
final count = controller.getSelectedCountInRange(0, 10);
final hasSelection = controller.hasSelectionInRange(5, 8);
final fullySelected = controller.isRangeFullySelected(2, 6);
final selectedInRange = controller.getSelectedInRange(0, 10);
final selectableInRange = controller.getSelectableInRange(0, 10);
```

## UI Components

### Selection App Bar
Automatically switches between normal and selection modes:

```dart
MaterialSelectionAppBar(
  actions: [
    IconButton(icon: Icon(Icons.share), onPressed: _share),
    IconButton(icon: Icon(Icons.delete), onPressed: _delete),
  ],
  selectionTitle: (context, count) => Text('$count selected'),
  onCancel: () => controller.disable(),
  child: AppBar(title: Text('My App')),
)
```

### Action Bar
Bottom action bar for selection operations:

```dart
SelectionActionBar(
  children: [
    IconButton(icon: Icon(Icons.share), onPressed: _share),
    IconButton(icon: Icon(Icons.delete), onPressed: _delete),
    IconButton(icon: Icon(Icons.copy), onPressed: _copy),
  ],
  borderRadius: BorderRadius.circular(20),
  animated: true,
)
```

### Status Bar
Display selection status:

```dart
SelectionStatusBar(
  leftActions: [IconButton(...)],
  rightActions: [IconButton(...)],
  statusBuilder: (context, count) => Text('$count selected'),
)
```

### Selection Consumer
Listen to selection changes:

```dart
SelectionConsumer(
  builder: (context, controller, child) {
    return controller.isActive 
      ? SelectionUI()
      : NormalUI();
  },
)
```

### Drag Selection Ignore
Ignore pointer events during drag selection:

```dart
DragSelectionIgnore(
  child: FloatingActionButton(...), // Won't interfere with drag selection
)
```

## Custom Layout Example

```dart
// Wrap your layout in SelectionMode
SelectionMode(
  controller: _controller,
  child: Scaffold(
    body: Stack(
      children: [
        // Wrap your grid in SelectionCanvas for interaction
        SelectionCanvas(
          child: GridView.builder(
            itemBuilder: (context, index) => SelectableBuilder(
              index: index,
              builder: (context, isSelected) => GestureDetector(
                onTap: () => _controller.toggleItem(index),
                child: Container(
                  decoration: isSelected 
                    ? BoxDecoration(border: Border.all(color: Colors.blue))
                    : null,
                  child: Card(child: Center(child: Text('Item $index'))),
                ),
              ),
            ),
          ),
        ),

        // Custom status indicator
        SelectionConsumer(
          builder: (context, controller, _) => controller.isActive 
            ? Positioned(
                top: 20, left: 20,
                child: Chip(
                  label: Text('${controller.selection.length} selected'),
                  onDeleted: controller.disable,
                ),
              )
            : SizedBox.shrink(),
        ),

        // Custom action buttons
        SelectionConsumer(
          builder: (context, controller, _) => controller.isActive 
            ? Positioned(
                bottom: 20, right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: _share,
                      child: Icon(Icons.share),
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      onPressed: _delete,
                      child: Icon(Icons.delete),
                    ),
                  ],
                ),
              )
            : SizedBox.shrink(),
        ),
      ],
    ),
  ),
)
```

## Stable Selection with ValueKey

Use ValueKey for data that changes during selection:

```dart
// With ValueKey - selection persists when list reordered or mutated
SelectableBuilder(
  key: ValueKey(item.id), // Selection stable across data changes
  index: index,
  builder: (context, isSelected) => ItemWidget(item),
)

// Without ValueKey - for static data
SelectableBuilder(
  index: index, // Works fine if data doesn't change
  builder: (context, isSelected) => ItemWidget(item),
)
```

## Examples

The package includes three complete example apps:

- **Basic List Demo** - Simple list with manual selection mode
- **Grid Selection Demo** - Photo grid with drag selection and auto-scroll
- **Mixed Selection Demo** - Contact list with auto-toggle behavior and constraints

See `/example` folder for complete implementations showing different use cases and configurations.
