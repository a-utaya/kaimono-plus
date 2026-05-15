import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Object _editingItemIdUnset = Object();

@immutable
class KaimonoItem {
  const KaimonoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  final String id;
  final String text;
  final bool isCompleted;

  KaimonoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return KaimonoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@immutable
class KaimonoListState {
  const KaimonoListState({
    required this.items,
    this.editingItemId,
  });

  final List<KaimonoItem> items;
  final String? editingItemId;

  KaimonoListState copyWith({
    List<KaimonoItem>? items,
    Object? editingItemId = _editingItemIdUnset,
  }) {
    return KaimonoListState(
      items: items ?? this.items,
      editingItemId: identical(editingItemId, _editingItemIdUnset)
          ? this.editingItemId
          : editingItemId as String?,
    );
  }
}

final kaimonoListPageViewModelProvider =
    NotifierProvider.autoDispose<KaimonoListPageNotifier, KaimonoListState>(
      KaimonoListPageNotifier.new,
    );

class KaimonoListPageNotifier extends Notifier<KaimonoListState> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _itemControllers = {};

  ScrollController get scrollController => _scrollController;

  @override
  KaimonoListState build() {
    ref.onDispose(() {
      for (final controller in _itemControllers.values) {
        controller.dispose();
      }
      _itemControllers.clear();
      _scrollController.dispose();
    });
    return const KaimonoListState(items: []);
  }

  TextEditingController? getControllerForItem(String id) {
    if (!_itemControllers.containsKey(id)) {
      final item = state.items.firstWhere((el) => el.id == id);
      _itemControllers[id] = TextEditingController(text: item.text);
    } else {
      final item = state.items.firstWhere((el) => el.id == id);
      final controller = _itemControllers[id]!;
      if (controller.text != item.text) {
        controller.text = item.text;
      }
    }
    return _itemControllers[id];
  }

  void startEditing(String id, {bool isNewItem = false}) {
    final currentEditing = state.editingItemId;
    if (currentEditing != null && currentEditing != id) {
      stopEditing(currentEditing, skipIfEmpty: true);
    }
    state = state.copyWith(editingItemId: id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _itemControllers[id];
      if (controller != null) {
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    });
  }

  void stopEditing(String id, {bool skipIfEmpty = false}) {
    state = state.copyWith(editingItemId: null);
    _saveItemText(id, skipIfEmpty: skipIfEmpty);
  }

  void _saveItemText(String id, {bool skipIfEmpty = false}) {
    final controller = _itemControllers[id];
    if (controller != null) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        updateItemText(id, controller.text);
      } else if (!skipIfEmpty) {
        removeItem(id);
      }
    }
  }

  void updateItemText(String id, String text, {bool removeIfEmpty = true}) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && removeIfEmpty) {
      removeItem(id);
      return;
    }

    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final nextItems = [...state.items];
    nextItems[index] = nextItems[index].copyWith(text: trimmedText);
    state = state.copyWith(items: nextItems);
  }

  void addItem() {
    final newId = clock.now().millisecondsSinceEpoch.toString();
    state = state.copyWith(
      items: [
        ...state.items,
        KaimonoItem(id: newId, text: ''),
      ],
    );
    debugPrint('addItem: 新しいアイテムを追加します');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      startEditing(newId, isNewItem: true);
    });
  }

  void toggleItem(String id) {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final nextItems = [...state.items];
    final item = nextItems[index];
    nextItems[index] = item.copyWith(isCompleted: !item.isCompleted);
    state = state.copyWith(items: nextItems);
  }

  void removeItem(String id) {
    final nextItems = state.items.where((item) => item.id != id).toList();
    _itemControllers[id]?.dispose();
    _itemControllers.remove(id);

    final nextEditing = state.editingItemId == id ? null : state.editingItemId;
    state = state.copyWith(items: nextItems, editingItemId: nextEditing);
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final nextItems = [...state.items];
    final item = nextItems.removeAt(oldIndex);
    nextItems.insert(newIndex, item);
    state = state.copyWith(items: nextItems);
  }

  void clearAllItems() {
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();
    state = const KaimonoListState(items: []);
  }
}
