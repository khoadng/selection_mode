import 'package:flutter/material.dart';
import 'package:selection_mode/selection_mode.dart';

class FileManagerDemo extends StatefulWidget {
  const FileManagerDemo({super.key});

  @override
  State<FileManagerDemo> createState() => _FileManagerDemoState();
}

class _FileManagerDemoState extends State<FileManagerDemo> {
  final _controller = SelectionModeController();
  final _scrollController = ScrollController();

  bool _isGridView = false;
  FileItem? _lastFocusedItem;

  final List<FileItem> _files = [
    FileItem(
      'Documents',
      FileType.folder,
      size: null,
      modified: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FileItem(
      'Pictures',
      FileType.folder,
      size: null,
      modified: DateTime.now().subtract(const Duration(days: 5)),
    ),
    FileItem(
      'Downloads',
      FileType.folder,
      size: null,
      modified: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FileItem(
      'project_report.pdf',
      FileType.document,
      size: 2457600,
      modified: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    FileItem(
      'budget_2024.xlsx',
      FileType.spreadsheet,
      size: 98304,
      modified: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FileItem(
      'presentation.pptx',
      FileType.presentation,
      size: 5242880,
      modified: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    FileItem(
      'vacation_photo.jpg',
      FileType.image,
      size: 3145728,
      modified: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FileItem(
      'meeting_notes.txt',
      FileType.text,
      size: 2048,
      modified: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    FileItem(
      'backup.zip',
      FileType.archive,
      size: 52428800,
      modified: DateTime.now().subtract(const Duration(days: 7)),
    ),
    FileItem(
      'config.json',
      FileType.code,
      size: 1024,
      modified: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    FileItem(
      'README.md',
      FileType.code,
      size: 4096,
      modified: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    FileItem(
      'invoice_march.pdf',
      FileType.document,
      size: 1048576,
      modified: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

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
      scrollController: _scrollController,
      options: const SelectionOptions(
        behavior: SelectionBehavior.autoEnable,
        tapBehavior: TapBehavior.replace,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('File Manager'),
              Text(
                '${_files.length} items',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
              tooltip: _isGridView ? 'List View' : 'Grid View',
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ],
        ),

        body: SelectionShortcuts(
          totalItems: _files.length,
          child: Focus(
            autofocus: true,
            child: SelectionCanvas(
              child: _isGridView ? _buildGridView() : _buildListView(),
            ),
          ),
        ),
        bottomSheet: _buildActionSheet(),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _files.length,
      itemBuilder: (context, index) => SelectableBuilder(
        key: ValueKey(_files[index].name),
        index: index,
        builder: (context, isSelected) => _FileListTile(
          file: _files[index],
          isSelected: isSelected,
          isFocused: _lastFocusedItem == _files[index],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _files.length,
          itemBuilder: (context, index) => SelectableBuilder(
            key: ValueKey(_files[index].name),
            index: index,
            builder: (context, isSelected) => _FileGridTile(
              file: _files[index],
              isSelected: isSelected,
              isFocused: _lastFocusedItem == _files[index],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSheet() {
    return SelectionConsumer(
      builder: (context, controller, _) {
        if (!controller.isActive) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Text(
                  '${controller.selection.length} selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => controller.selectAll(
                    List.generate(_files.length, (i) => i),
                  ),
                  icon: const Icon(Icons.select_all),
                  label: const Text('All'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: controller.deselectAll,
                  icon: const Icon(Icons.clear),
                  label: const Text('None'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FileListTile extends StatelessWidget {
  const _FileListTile({
    required this.file,
    required this.isSelected,
    required this.isFocused,
  });

  final FileItem file;
  final bool isSelected;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isFocused
            ? theme.colorScheme.surfaceContainerHighest
            : isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        border: isFocused
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        leading: _buildIcon(context),
        title: Text(file.name),
        subtitle: Text(_buildSubtitle()),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Icon(
      file.type.icon,
      color: color,
      size: 32,
    );
  }

  String _buildSubtitle() {
    final sizeStr = file.size != null ? _formatFileSize(file.size!) : '';
    final dateStr = _formatDate(file.modified);
    return [sizeStr, dateStr].where((s) => s.isNotEmpty).join(' • ');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _FileGridTile extends StatelessWidget {
  const _FileGridTile({
    required this.file,
    required this.isSelected,
    required this.isFocused,
  });

  final FileItem file;
  final bool isSelected;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isFocused
            ? theme.colorScheme.surfaceContainerHighest
            : isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.primary
              : isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isFocused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: Icon(
                    file.type.icon,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        file.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (file.size != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(file.size!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class FileItem {
  final String name;
  final FileType type;
  final int? size;
  final DateTime modified;

  FileItem(this.name, this.type, {this.size, required this.modified});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

enum FileType {
  folder(Icons.folder),
  document(Icons.description),
  image(Icons.image),
  video(Icons.video_file),
  audio(Icons.audio_file),
  archive(Icons.archive),
  code(Icons.code),
  text(Icons.text_snippet),
  spreadsheet(Icons.table_chart),
  presentation(Icons.slideshow);

  const FileType(this.icon);
  final IconData icon;
}
