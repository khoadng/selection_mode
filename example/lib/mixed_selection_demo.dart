import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

class MixedSelectionDemo extends StatefulWidget {
  const MixedSelectionDemo({super.key});

  @override
  State<MixedSelectionDemo> createState() => _MixedSelectionDemoState();
}

class _MixedSelectionDemoState extends State<MixedSelectionDemo> {
  final _controller = SelectionModeController(
    options: SelectionOptions(
      constraints: SelectionConstraints(maxSelections: 5),
      behavior: SelectionBehavior.autoToggle,
    ),
  );
  final _items = _generateMixedItems();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<ListItem> _generateMixedItems() {
    final items = <ListItem>[];
    final categories = ['Work', 'Personal', 'Family', 'Other'];

    for (int i = 0; i < categories.length; i++) {
      items.add(HeaderItem(title: categories[i]));

      for (int j = 0; j < 4; j++) {
        final contactIndex = i * 4 + j + 1;
        items.add(
          ContactItem(
            name: 'Contact $contactIndex',
            email: 'contact$contactIndex@example.com',
            isImportant: contactIndex % 7 == 0,
          ),
        );
      }

      if (i < categories.length - 1) {
        items.add(SeparatorItem());
      }
    }

    return items;
  }

  (int start, int end) _getSectionRange(int headerIndex) {
    final start = headerIndex + 1;
    int end = _items.length - 1;

    for (int i = start; i < _items.length; i++) {
      if (_items[i] is HeaderItem || _items[i] is SeparatorItem) {
        end = i - 1;
        break;
      }
    }

    return (start, end);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionMode(
      controller: _controller,
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          controller: _controller,
          child: AppBar(
            title: const Text('Implicit Selection Demo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showOptionsInfo(context),
              ),
              // Note: No manual select all button needed with implicit behavior
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _BehaviorIndicator(controller: _controller),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildItemWidget(item, index);
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SelectionActionBar(
                spacing: 16,
                borderRadius: BorderRadius.circular(20),
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showOptionsInfo(context),
                    tooltip: 'Info',
                  ),
                  IconButton(
                    icon: const Icon(Icons.email),
                    onPressed: _controller.hasSelection ? _emailContacts : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _controller.hasSelection
                        ? _deleteContacts
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(ListItem item, int index) {
    return GestureDetector(
      onTap: () => _handleItemTap(index),
      child: SelectionBuilder(
        index: index,
        isSelectable: item.isSelectable,
        builder: (context, isSelected) => switch (item.runtimeType) {
          const (HeaderItem) => _HeaderWidget(
            header: item as HeaderItem,
            controller: _controller,
            onSectionToggle: () => _toggleSection(index),
            sectionState: _getSectionState(index),
          ),
          const (ContactItem) => _ContactWidget(
            contact: item as ContactItem,
            isSelected: isSelected,
          ),
          const (SeparatorItem) => const _SeparatorWidget(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  SectionSelectionState _getSectionState(int headerIndex) {
    final (start, end) = _getSectionRange(headerIndex);

    if (_controller.isRangeFullySelected(start, end)) {
      return SectionSelectionState.all;
    } else if (_controller.hasSelectionInRange(start, end)) {
      return SectionSelectionState.partial;
    } else {
      return SectionSelectionState.none;
    }
  }

  void _toggleSection(int headerIndex) {
    final (start, end) = _getSectionRange(headerIndex);

    if (_controller.isRangeFullySelected(start, end)) {
      _controller.deselectRange(start, end);
      // Note: With implicit behavior, mode will auto-exit if this was the last selection
    } else {
      _controller.selectRange(start, end);
      // Note: With implicit behavior, mode will auto-enable if not already enabled
    }
  }

  void _handleItemTap(int index) {
    final item = _items[index];

    if (item.isSelectable) {
      // With implicit behavior: first tap enables mode and selects item
      // Subsequent taps toggle selection
      // When last item is deselected, mode auto-exits
      _controller.toggleItem(index);
    } else if (item is ContactItem) {
      print('Opening contact: ${item.name}');
    }
  }

  void _emailContacts() {
    final selectedContacts = _controller.selection
        .map((index) => _items[index])
        .whereType<ContactItem>()
        .map((contact) => contact.email)
        .join(', ');
    print('Emailing: $selectedContacts');
    // Note: Mode will auto-exit after clearing selection
    _controller.deselectAll();
  }

  void _deleteContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contacts'),
        content: Text('Delete ${_controller.selectedCount} contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _performDelete();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete() {
    final selected = _controller.selection.toList();
    selected.sort((a, b) => b.compareTo(a));
    for (final index in selected) {
      _items.removeAt(index);
    }
    // Note: Mode will auto-exit after clearing selection
    _controller.deselectAll();
    setState(() {});
  }

  void _showOptionsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Implicit Selection Demo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This demo uses implicit selection behavior:'),
            SizedBox(height: 12),
            Text('• Auto-enables on first item selection'),
            Text('• Auto-exits when all items deselected'),
            Text('• Max 5 selections'),
            Text('• No manual enable/disable buttons needed'),
            SizedBox(height: 12),
            Text(
              'Try selecting items - notice how the mode automatically starts and stops!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _BehaviorIndicator extends StatelessWidget {
  const _BehaviorIndicator({required this.controller});

  final SelectionModeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isEnabled = controller.isActive;
        final hasSelection = controller.hasSelection;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green[50] : Colors.grey[50],
            border: Border(
              bottom: BorderSide(
                color: isEnabled ? Colors.green[200]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEnabled ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isEnabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Implicit Mode: ${isEnabled ? 'Active' : 'Inactive'}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? Colors.green[700] : Colors.grey[700],
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 8),
                Text(
                  '(${controller.selectedCount} selected)',
                  style: TextStyle(fontSize: 12, color: Colors.green[600]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Data models and other widgets remain the same...
abstract class ListItem {
  bool get isSelectable;
}

class HeaderItem extends ListItem {
  HeaderItem({required this.title});
  final String title;

  @override
  bool get isSelectable => false;
}

class ContactItem extends ListItem {
  ContactItem({
    required this.name,
    required this.email,
    this.isImportant = false,
  });

  final String name;
  final String email;
  final bool isImportant;

  @override
  bool get isSelectable => !isImportant;
}

class SeparatorItem extends ListItem {
  SeparatorItem();

  @override
  bool get isSelectable => false;
}

enum SectionSelectionState { none, partial, all }

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget({
    required this.header,
    required this.controller,
    required this.onSectionToggle,
    required this.sectionState,
  });

  final HeaderItem header;
  final SelectionModeController controller;
  final VoidCallback onSectionToggle;
  final SectionSelectionState sectionState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.folder, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              header.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onSectionToggle,
            icon: Icon(_getSectionIcon()),
            color: _getSectionColor(colorScheme),
            tooltip: _getSectionTooltip(),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon() {
    switch (sectionState) {
      case SectionSelectionState.all:
        return Icons.check_box;
      case SectionSelectionState.partial:
        return Icons.indeterminate_check_box;
      case SectionSelectionState.none:
        return Icons.check_box_outline_blank;
    }
  }

  Color _getSectionColor(ColorScheme colorScheme) {
    switch (sectionState) {
      case SectionSelectionState.all:
      case SectionSelectionState.partial:
        return colorScheme.primary;
      case SectionSelectionState.none:
        return colorScheme.outline;
    }
  }

  String _getSectionTooltip() {
    switch (sectionState) {
      case SectionSelectionState.all:
        return 'Deselect all in ${header.title}';
      case SectionSelectionState.partial:
      case SectionSelectionState.none:
        return 'Select all in ${header.title}';
    }
  }
}

class _ContactWidget extends StatelessWidget {
  const _ContactWidget({required this.contact, required this.isSelected});

  final ContactItem contact;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: _buildAvatar(context),
      title: Row(
        children: [
          Text(contact.name),
          if (contact.isImportant) ...[
            const SizedBox(width: 8),
            Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              'VIP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(contact.email),
      trailing: contact.isImportant
          ? Icon(Icons.lock, color: colorScheme.outline, size: 20)
          : null,
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSelected) {
      return CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
      );
    }

    final color = contact.isImportant ? Colors.amber : Colors.blue;
    final initial = contact.name.isNotEmpty
        ? contact.name[0].toUpperCase()
        : '?';

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

class _SeparatorWidget extends StatelessWidget {
  const _SeparatorWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}

void print(String message) {
  debugPrint(message);
}
