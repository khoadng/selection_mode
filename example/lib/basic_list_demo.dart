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
      onEnabledChanged: (enabled) {
        print('Selection mode: $enabled');
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
          ],
          child: AppBar(title: const Text('Basic Selection')),
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
    if (_controller.enabled) {
      _controller.toggleSelection(index);
    } else {
      // Handle normal tap
      print('Tapped: ${_items[index]}');
    }
  }

  void _shareSelected() {
    final selectedItems = _controller.selectedItemsList
        .map((index) => _items[index])
        .join(', ');
    print('Sharing: $selectedItems');
  }

  void _copySelected() {
    print('Copied ${_controller.selectedCount} items');
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
      onTap: onTap,
      index: index,
      builder: (context, isSelected) {
        return ListTile(
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
