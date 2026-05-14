import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:selection_model/selection_model.dart' as model;

import '../managers/auto_scroll_manager.dart';
import '../options/selection_options.dart';
import 'selection_item_info.dart';

class SelectionModeController extends model.SelectionModeController
    implements Listenable {
  SelectionModeController({
    super.initialEnabled,
    super.initialSelected,
  });

  AutoScrollManager? _autoScrollManager;

  final Map<int, Rect? Function()> positionCallbacks = {};

  @override
  SelectionOptions get options => super.options as SelectionOptions;

  bool get isAutoScrolling => _autoScrollManager?.isScrolling ?? false;

  @override
  void initializeOptions(covariant SelectionOptions options) {
    super.initializeOptions(options);
  }

  @override
  void updateOptions(covariant SelectionOptions options) {
    super.updateOptions(options);
  }

  @override
  void register(covariant SelectionItemInfo info) {
    super.register(info);

    if (info.positionCallback != null) {
      positionCallbacks[info.index] = info.positionCallback!;
    }
  }

  @override
  void unregister(int index) {
    super.unregister(index);
    positionCallbacks.remove(index);
  }

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
    if (manager != null) {
      manager.onScrollUpdate = _onAutoScrollUpdate;
    }
  }

  @override
  void startRangeSelection(int index) {
    super.startRangeSelection(index);
    if (isDragInProgress) {
      _autoScrollManager?.startDragAutoScroll();
    }
  }

  void handleDragUpdate(Offset globalPosition) {
    if (!isDragInProgress) return;

    final autoScrollManager = _autoScrollManager;
    if (autoScrollManager != null) {
      final viewportSize = autoScrollManager.getViewportSize();
      if (viewportSize != null) {
        autoScrollManager.handleDragUpdate(globalPosition, viewportSize);
      }
    }
  }

  @override
  void endRangeSelection() {
    super.endRangeSelection();
    _autoScrollManager?.stopDragAutoScroll();
  }

  void _onAutoScrollUpdate() {
    if (!isDragInProgress) return;

    final position = _autoScrollManager?.currentDragPosition;
    if (position == null) return;

    _checkItemUnderPointer(position);
  }

  void _checkItemUnderPointer(Offset position) {
    for (final entry in positionCallbacks.entries) {
      final rect = entry.value();
      if (rect != null && rect.contains(position)) {
        handleDragOver(entry.key);
        return;
      }
    }
  }

  @override
  void dispose() {
    _autoScrollManager?.dispose();
    positionCallbacks.clear();
    super.dispose();
  }
}
