import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

class BasicListDemo extends StatefulWidget {
  const BasicListDemo({super.key});

  @override
  State<BasicListDemo> createState() => _BasicListDemoState();
}

class _BasicListDemoState extends State<BasicListDemo> {
  final _controller = SelectionModeController();
  final _items = List.generate(50, (index) => 'Item ${index + 1}');
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
      scrollController: _scrollController,
      controller: _controller,
      options: const SelectionOptions(behavior: SelectionBehavior.manual),
      onModeChanged: (enabled) {
        print('Selection mode: $enabled');
      },
      onChanged: (selectedItems) {
        print('Selected items: $selectedItems');
      },
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          controller: _controller,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share selected',
              onPressed: () => _shareSelected(),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy selected',
              onPressed: () => _copySelected(),
            ),
            IconButton(
              icon: const Icon(Icons.done),
              tooltip: 'Done',
              onPressed: () => _controller.disable(),
            ),
          ],
          child: AppBar(
            title: const Text('Basic Selection'),
            actions: [
              // Button to enable/disable selection mode
              TextButton(
                child: Text('Enable Selection'),
                onPressed: () {
                  if (_controller.isActive) {
                    _controller.disable();
                  } else {
                    _controller.enable();
                  }
                },
              ),
            ],
          ),
        ),
        body: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 0),
          itemCount: _items.length,
          itemBuilder: (context, index) => SelectableListTile(
            index: index,
            onTap: () => _handleItemTap(index),
            title: _items[index],
            subtitle: 'Subtitle for item $index',
          ),
        ),
      ),
    );
  }

  void _handleItemTap(int index) {
    if (_controller.isActive) {
      _controller.toggleItem(index);
    } else {
      // Handle normal tap
      print('Tapped: ${_items[index]}');
    }
  }

  void _shareSelected() {
    final selectedItems = _controller.selection
        .map((index) => _items[index])
        .join(', ');
    print('Sharing: $selectedItems');
  }

  void _copySelected() {
    print('Copied ${_controller.selection.length} items');
    _controller.disable();
  }
}

class SelectableListTile extends StatelessWidget {
  const SelectableListTile({
    super.key,
    required this.index,
    required this.onTap,
    required this.title,
    this.subtitle,
  });

  final int index;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SelectionBuilder(
      index: index,
      builder: (context, isSelected) {
        final inSelectionMode = SelectionMode.of(context).isActive;
        return ListTile(
          onTap: onTap,
          onLongPress: () {
            if (inSelectionMode) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Selected: $title'),
                  content: const Text('You can now select more items.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Text('Long pressed on $title'),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              );
            }
          },
          leading: _buildAvatar(context, isSelected),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSelected) {
      return CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
      );
    }

    // Generate avatar based on index for variety
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final color = colors[index % colors.length];
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void print(String message) {
  debugPrint(message);
}
