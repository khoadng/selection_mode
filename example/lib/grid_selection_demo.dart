import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

import 'common/selectable_item.dart';
import 'common/selection_footer.dart';

class GridSelectionDemo extends StatefulWidget {
  const GridSelectionDemo({super.key});

  @override
  State<GridSelectionDemo> createState() => _GridSelectionDemoState();
}

class _GridSelectionDemoState extends State<GridSelectionDemo> {
  final _controller = SelectionModeController();
  final _scrollController = ScrollController();
  final _photos = List.generate(
    100,
    (index) => Photo(
      id: index,
      title: 'Photo ${index + 1}',
      color: Colors.primaries[index % Colors.primaries.length],
    ),
  );
  int _currentNavIndex = 0;

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
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          controller: _controller,
          actions: [
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () {
                if (_controller.enabled) {
                  _controller.selectAll(
                    List.generate(_photos.length, (i) => i),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: 'Clear Selection',
              onPressed: () {
                if (_controller.enabled) {
                  _controller.clearSelected();
                }
              },
            ),
          ],
          child: AppBar(title: const Text('Photo Gallery')),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) => SelectableItem(
                      index: index,
                      onTap: () => _handlePhotoTap(index),
                      itemBuilder: (context, index) =>
                          _PhotoTile(photo: _photos[index]),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SelectionFooter(child: _buildSelectionFooter()),
            ),
          ],
        ),
        bottomNavigationBar: _SelectionAwareBottomNav(
          controller: _controller,
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
        ),
      ),
    );
  }

  Widget _buildSelectionFooter() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: _controller.hasSelection ? _shareSelected : null,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: _controller.hasSelection ? _copySelected : null,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              onPressed: _controller.hasSelection ? _deletePhotos : null,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePhotoTap(int index) {
    if (_controller.enabled) {
      _controller.toggleSelection(index);
    } else {
      print('Opening photo: ${_photos[index].title}');
    }
  }

  void _shareSelected() {
    final selectedItems = _controller.selectedItemsList
        .map((index) => _photos[index].title)
        .join(', ');
    print('Sharing: $selectedItems');
  }

  void _copySelected() {
    print('Copied ${_controller.selectedCount} items');
    _controller.disable();
  }

  void _deletePhotos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Delete ${_controller.selectedCount} photos?'),
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
    final selected = _controller.selectedItemsList;
    selected.sort((a, b) => b.compareTo(a));
    for (final index in selected) {
      _photos.removeAt(index);
    }
    _controller.disable();
    setState(() {});
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: photo.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          photo.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class Photo {
  const Photo({required this.id, required this.title, required this.color});

  final int id;
  final String title;
  final Color color;
}

void print(String message) {
  debugPrint(message);
}

class _SelectionAwareBottomNav extends StatelessWidget {
  const _SelectionAwareBottomNav({
    this.controller,
    required this.currentIndex,
    required this.onTap,
  });

  final SelectionModeController? controller;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? SelectionMode.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final isHidden = ctrl.enabled;

        return isHidden ? const SizedBox.shrink() : _buildNav();
      },
    );
  }

  Widget _buildNav() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
