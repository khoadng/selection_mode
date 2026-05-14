import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Axis;
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
  Offset? _currentDragCanvasPosition;
  Offset? _marqueeStartContentPosition;
  Offset? _currentMarqueeCanvasPosition;
  Rect? _currentMarqueeContentRect;
  Set<int> _preMarqueeSelection = {};
  Map<int, Rect> _marqueeKnownContentRects = {};
  bool _isMarqueeSelectionInProgress = false;
  bool _marqueeAdditive = false;

  final Map<int, Rect? Function()> positionCallbacks = {};
  final Map<int, Object> _positionIdentifiers = {};

  @override
  SelectionOptions get options => super.options as SelectionOptions;

  bool get isAutoScrolling => _autoScrollManager?.isScrolling ?? false;
  bool get isMarqueeSelectionInProgress => _isMarqueeSelectionInProgress;
  Rect? get currentMarqueeCanvasRect {
    final contentRect = _currentMarqueeContentRect;
    if (contentRect == null) return null;
    return _contentRectToCanvasRect(contentRect);
  }

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
      _positionIdentifiers[info.index] = info.identifier;
      positionCallbacks[info.index] = info.positionCallback!;
      final rect = info.positionCallback!();
      if (_isMarqueeSelectionInProgress && rect != null) {
        _marqueeKnownContentRects[info.index] = _canvasRectToContentRect(rect);
      }
    }
  }

  @override
  bool unregister(
    int index, {
    bool removeSelection = false,
    Object? identifier,
  }) {
    final didUnregister = super.unregister(
      index,
      removeSelection: removeSelection,
      identifier: identifier,
    );
    if (!didUnregister) {
      return false;
    }

    if (identifier == null || _positionIdentifiers[index] == identifier) {
      _positionIdentifiers.remove(index);
      positionCallbacks.remove(index);
    }
    return true;
  }

  void setAutoScrollManager(AutoScrollManager? manager) {
    _autoScrollManager?.dispose();
    _autoScrollManager = manager;
    if (manager != null) {
      manager.onScrollUpdate = _onAutoScrollUpdate;
    }
  }

  void startMarqueeSelection(
    Offset canvasStart, {
    bool additive = false,
  }) {
    if (options.behavior == model.SelectionBehavior.manual && !isActive) {
      return;
    }

    _isMarqueeSelectionInProgress = true;
    _marqueeAdditive = additive;
    _marqueeStartContentPosition = _canvasToContentPosition(canvasStart);
    _currentMarqueeCanvasPosition = canvasStart;
    _currentMarqueeContentRect = Rect.fromPoints(
      _marqueeStartContentPosition!,
      _marqueeStartContentPosition!,
    );
    _preMarqueeSelection = Set<int>.from(visibleSelection);
    _marqueeKnownContentRects = {};
    _autoScrollManager?.startDragAutoScroll();
    notifyListeners();
  }

  void updateMarqueeSelection(
    Offset canvasPosition, {
    Offset? globalPosition,
  }) {
    if (!_isMarqueeSelectionInProgress) return;

    _currentMarqueeCanvasPosition = canvasPosition;
    final contentRect = _buildMarqueeContentRect();
    if (contentRect == null) return;
    _currentMarqueeContentRect = contentRect;

    final autoScrollManager = _autoScrollManager;
    if (autoScrollManager != null) {
      final viewportSize = autoScrollManager.getViewportSize();
      if (viewportSize != null) {
        autoScrollManager.handleDragUpdate(
          globalPosition ?? canvasPosition,
          viewportSize,
        );
      }
    }

    _applyMarqueeSelection(contentRect);
    notifyListeners();
  }

  void endMarqueeSelection() {
    _isMarqueeSelectionInProgress = false;
    _marqueeAdditive = false;
    _marqueeStartContentPosition = null;
    _currentMarqueeCanvasPosition = null;
    _preMarqueeSelection = {};
    _marqueeKnownContentRects = {};
    _currentMarqueeContentRect = null;
    _autoScrollManager?.stopDragAutoScroll();
    notifyListeners();
  }

  @override
  void startRangeSelection(int index) {
    super.startRangeSelection(index);
    if (isDragInProgress) {
      _autoScrollManager?.startDragAutoScroll();
    }
  }

  void handleDragUpdate(Offset canvasPosition, {Offset? globalPosition}) {
    if (!isDragInProgress) return;
    _currentDragCanvasPosition = canvasPosition;

    final autoScrollManager = _autoScrollManager;
    if (autoScrollManager != null) {
      final viewportSize = autoScrollManager.getViewportSize();
      if (viewportSize != null) {
        autoScrollManager.handleDragUpdate(
          globalPosition ?? canvasPosition,
          viewportSize,
        );
      }
    }

    _checkItemUnderPointer(canvasPosition);
  }

  @override
  void endRangeSelection() {
    super.endRangeSelection();
    _currentDragCanvasPosition = null;
    _autoScrollManager?.stopDragAutoScroll();
  }

  void _onAutoScrollUpdate() {
    if (_isMarqueeSelectionInProgress) {
      final contentRect = _buildMarqueeContentRect();
      if (contentRect != null) {
        _currentMarqueeContentRect = contentRect;
        _applyMarqueeSelection(contentRect);
        notifyListeners();
      }
      return;
    }

    if (!isDragInProgress) return;

    final position = _currentDragCanvasPosition;
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

  void _applyMarqueeSelection(Rect contentRect) {
    final intersectingItems = <int>{};

    for (final entry in positionCallbacks.entries) {
      final itemRect = entry.value();
      if (itemRect != null) {
        _marqueeKnownContentRects[entry.key] =
            _canvasRectToContentRect(itemRect);
      }
    }

    for (final entry in _marqueeKnownContentRects.entries) {
      if (entry.value.overlaps(contentRect)) {
        intersectingItems.add(entry.key);
      }
    }

    final desiredSelection = _marqueeAdditive
        ? {..._preMarqueeSelection, ...intersectingItems}
        : intersectingItems;

    if (visibleSelection.length == desiredSelection.length &&
        visibleSelection.containsAll(desiredSelection)) {
      return;
    }

    deselectAll();
    if (desiredSelection.isNotEmpty) {
      selectAll(desiredSelection.toList()..sort());
    }
  }

  Rect? _buildMarqueeContentRect() {
    final start = _marqueeStartContentPosition;
    final currentCanvasPosition = _currentMarqueeCanvasPosition;
    if (start == null || currentCanvasPosition == null) return null;

    return Rect.fromPoints(
      start,
      _canvasToContentPosition(currentCanvasPosition),
    );
  }

  Offset _canvasToContentPosition(Offset canvasPosition) {
    final autoScrollManager = _autoScrollManager;
    final offset = autoScrollManager?.scrollOffset ?? 0.0;
    return switch (autoScrollManager?.axis) {
      Axis.horizontal => Offset(canvasPosition.dx + offset, canvasPosition.dy),
      Axis.vertical => Offset(canvasPosition.dx, canvasPosition.dy + offset),
      null => canvasPosition,
    };
  }

  Rect _canvasRectToContentRect(Rect canvasRect) {
    final autoScrollManager = _autoScrollManager;
    final offset = autoScrollManager?.scrollOffset ?? 0.0;
    return switch (autoScrollManager?.axis) {
      Axis.horizontal => canvasRect.shift(Offset(offset, 0)),
      Axis.vertical => canvasRect.shift(Offset(0, offset)),
      null => canvasRect,
    };
  }

  Rect _contentRectToCanvasRect(Rect contentRect) {
    final autoScrollManager = _autoScrollManager;
    final offset = autoScrollManager?.scrollOffset ?? 0.0;
    return switch (autoScrollManager?.axis) {
      Axis.horizontal => contentRect.shift(Offset(-offset, 0)),
      Axis.vertical => contentRect.shift(Offset(0, -offset)),
      null => contentRect,
    };
  }

  @override
  void dispose() {
    _autoScrollManager?.dispose();
    _currentDragCanvasPosition = null;
    _marqueeStartContentPosition = null;
    _currentMarqueeCanvasPosition = null;
    _currentMarqueeContentRect = null;
    _preMarqueeSelection = {};
    _marqueeKnownContentRects = {};
    _isMarqueeSelectionInProgress = false;
    _positionIdentifiers.clear();
    positionCallbacks.clear();
    super.dispose();
  }
}
