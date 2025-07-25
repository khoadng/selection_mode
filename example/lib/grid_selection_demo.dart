import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

class GridSelectionDemo extends StatefulWidget {
  const GridSelectionDemo({super.key});

  @override
  State<GridSelectionDemo> createState() => _GridSelectionDemoState();
}

class _GridSelectionDemoState extends State<GridSelectionDemo> {
  final _controller = SelectionModeController();
  final _scrollController = ScrollController();
  final _allPhotos = List.generate(
    1000,
    (index) => Photo(
      id: index + 100,
      title: 'Photo ${index + 1}',
      color: Colors.primaries[index % Colors.primaries.length],
      isHidden: index % 7 == 0, // Some photos start hidden
    ),
  );

  bool _showHidden = false;
  bool _isHorizontalScroll = false;
  int _currentNavIndex = 0;

  List<Photo> get _visiblePhotos =>
      _allPhotos.where((photo) => _showHidden || !photo.isHidden).toList();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _randomReorder() {
    setState(() {
      _allPhotos.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visiblePhotos = _visiblePhotos;

    return SelectionMode(
      scrollController: _scrollController,
      options: const SelectionOptions(
        haptics: HapticFeedbackResolver.all,
        dragSelection: DragSelectionOptions(),
      ),
      controller: _controller,
      child: Scaffold(
        appBar: MaterialSelectionAppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              tooltip: 'Show Selected',
              onPressed: () => _showSelectedDialog(),
            ),
            IconButton(
              icon: Icon(_showHidden ? Icons.visibility_off : Icons.visibility),
              tooltip: _showHidden ? 'Hide filtered items' : 'Show all items',
              onPressed: () => setState(() => _showHidden = !_showHidden),
            ),
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: 'Random Reorder',
              onPressed: _randomReorder,
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () {
                if (_controller.isActive) {
                  _controller.selectAll(
                    visiblePhotos.map((photo) => photo.id).toList(),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              tooltip: 'Clear Selection',
              onPressed: () {
                if (_controller.isActive) {
                  _controller.deselectAll();
                }
              },
            ),
          ],
          child: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Grid Selection Demo'),
                Text(
                  'Showing ${visiblePhotos.length}/${_allPhotos.length} photos',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isHorizontalScroll ? Icons.view_column : Icons.view_agenda,
                ),
                tooltip: _isHorizontalScroll
                    ? 'Switch to vertical'
                    : 'Switch to horizontal',
                onPressed: () =>
                    setState(() => _isHorizontalScroll = !_isHorizontalScroll),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SelectionShortcuts(
              totalItems: _visiblePhotos.length,
              child: Focus(
                autofocus: true,
                child: SelectionCanvas(
                  child: _buildGrid(),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: DragSelectionIgnore(
                child: SelectionActionBar(
                  spacing: 16,
                  borderRadius: BorderRadius.circular(20),
                  children: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      tooltip: 'Show Selected',
                      onPressed: _showSelectedDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share Selected',
                      onPressed: _controller.isActive ? _shareSelected : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Selected',
                      onPressed: _controller.isActive ? _deletePhotos : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _isHorizontalScroll
            ? null
            : _SelectionAwareBottomNav(
                controller: _controller,
                currentIndex: _currentNavIndex,
                onTap: (index) => setState(() => _currentNavIndex = index),
              ),
      ),
    );
  }

  Widget _buildGrid() {
    final visiblePhotos = _visiblePhotos;

    return GridView.builder(
      controller: _scrollController,
      scrollDirection: _isHorizontalScroll ? Axis.horizontal : Axis.vertical,
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: visiblePhotos.length,
      itemBuilder: (context, index) => SelectableItem(
        key: ValueKey(visiblePhotos[index].id),
        index: index,
        onTap: () => _handlePhotoTap(index),
        itemBuilder: (context, index) =>
            _PhotoTile(photo: visiblePhotos[index]),
      ),
    );
  }

  void _handlePhotoTap(int index) {
    if (_controller.isActive) {
      _controller.toggleItem(index);
    } else {
      print('Opening photo: ${_visiblePhotos[index].title}');
    }
  }

  void _showSelectedDialog() {
    final selectedPhotos = _controller.selectedFrom(_visiblePhotos).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selected Photos (${selectedPhotos.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: selectedPhotos.isEmpty
              ? const Center(child: Text('No photos selected'))
              : ListView.builder(
                  itemCount: selectedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = selectedPhotos[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: photo.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${photo.id + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(photo.title),
                      subtitle: Text(
                        'ID: ${photo.id}${photo.isHidden ? ' (Hidden)' : ''}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareSelected() {
    final selectedTitles = _controller
        .selectedFrom(_visiblePhotos)
        .map((p) => p.title)
        .toList();

    print('Sharing: ${selectedTitles.join(', ')}');
  }

  void _deletePhotos() {
    final selectedPhotos = _controller.selectedFrom(_visiblePhotos).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Delete ${selectedPhotos.length} photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _performDelete(selectedPhotos);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete(List<Photo> photosToDelete) {
    // Remove photos from the main list
    for (final photo in photosToDelete) {
      _allPhotos.removeWhere((p) => p.id == photo.id);
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
        border: photo.isHidden
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'ID: ${photo.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          if (photo.isHidden)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_off,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Photo {
  Photo({
    required this.id,
    required this.title,
    required this.color,
    this.isHidden = false,
  });

  final int id;
  final String title;
  final Color color;
  final bool isHidden;
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
    return SelectionConsumer(
      builder: (context, controller, _) {
        final isHidden = controller.isActive;
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

const _kDefaultAnimationDuration = Duration(milliseconds: 200);

class SelectableItem extends StatefulWidget {
  const SelectableItem({
    super.key,
    required this.onTap,
    required this.itemBuilder,
    required this.index,
  });

  final int index;
  final VoidCallback onTap;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<SelectableItem> createState() => _SelectableItemState();
}

class _SelectableItemState extends State<SelectableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _animationController.duration = Duration(
      milliseconds: (_kDefaultAnimationDuration.inMilliseconds * 0.4).round(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SelectableBuilder(
        key: widget.key,
        index: widget.index,
        builder: (context, isSelected) {
          Widget child = SelectionListener(
            controller: SelectionMode.of(context),
            index: widget.index,
            onSelectionChanged: (selected) {
              if (selected && _kDefaultAnimationDuration != Duration.zero) {
                _animationController.forward().then(
                  (value) => _animationController.reverse(),
                );
              }
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                widget.itemBuilder(context, widget.index),
                if (isSelected) const _SelectionIcon(),
              ],
            ),
          );

          // Skip scale animation if animations are disabled
          if (_kDefaultAnimationDuration == Duration.zero) {
            return child;
          }

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
      ),
    );
  }
}

class _SelectionIcon extends StatelessWidget {
  const _SelectionIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: 18, color: colorScheme.onPrimary),
    );
  }
}

class SelectionListener extends StatefulWidget {
  const SelectionListener({
    super.key,
    required this.controller,
    required this.index,
    required this.onSelectionChanged,
    required this.child,
  });

  final SelectionModeController controller;
  final int index;
  final void Function(bool selected) onSelectionChanged;
  final Widget child;

  @override
  State<SelectionListener> createState() => _SelectionListenerState();
}

class _SelectionListenerState extends State<SelectionListener> {
  late bool _previousSelected;

  @override
  void initState() {
    super.initState();
    _previousSelected = widget.controller.isSelected(widget.index);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final currentSelected = widget.controller.isSelected(widget.index);
    if (_previousSelected != currentSelected) {
      widget.onSelectionChanged(currentSelected);
      _previousSelected = currentSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
