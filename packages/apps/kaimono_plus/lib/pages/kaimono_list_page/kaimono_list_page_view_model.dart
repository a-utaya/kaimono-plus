import 'package:cloud_functions/cloud_functions.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [KaimonoListState.copyWith] で `editingItemId` を変更しない場合と、
/// 明示的に `null` へ更新する場合を区別するための sentinel。
const Object _editingItemIdUnset = Object();

@immutable
class SharedKaimonoList {
  const SharedKaimonoList({
    required this.id,
    required this.url,
    required this.shareText,
  });

  final String id;
  final String url;
  final String shareText;
}

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
class CreatedKaimonoList {
  const CreatedKaimonoList({
    required this.id,
    required this.title,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.colorValue,
  });

  final String id;
  final String title;
  final List<KaimonoItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? colorValue;

  List<KaimonoItem> get visibleItems =>
      items.where((item) => item.text.trim().isNotEmpty).toList();

  String get displayTitle => title.trim().isEmpty ? '買うものリスト' : title;

  int get completedCount =>
      visibleItems.where((item) => item.isCompleted).length;

  int get pendingCount => visibleItems.length - completedCount;

  CreatedKaimonoList copyWith({
    String? title,
    List<KaimonoItem>? items,
    DateTime? updatedAt,
    int? colorValue,
  }) {
    return CreatedKaimonoList(
      id: id,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

@immutable
class KaimonoListState {
  const KaimonoListState({
    required this.currentListId,
    required this.currentListTitle,
    required this.currentListCreatedAt,
    required this.currentListUpdatedAt,
    required this.items,
    this.currentListColorValue,
    this.historyLists = const [],
    this.editingItemId,
  });

  final String currentListId;
  final String currentListTitle;
  final DateTime currentListCreatedAt;
  final DateTime currentListUpdatedAt;
  final List<KaimonoItem> items;
  final int? currentListColorValue;
  final List<CreatedKaimonoList> historyLists;
  final String? editingItemId;

  List<KaimonoItem> get visibleItems =>
      items.where((item) => item.text.trim().isNotEmpty).toList();

  List<KaimonoItem> get shareableItems => items
      .where((item) => item.text.trim().isNotEmpty && !item.isCompleted)
      .toList();

  bool get hasShareableItems => shareableItems.isNotEmpty;

  List<CreatedKaimonoList> get createdLists {
    final currentList = _currentListSnapshot();
    return [
      if (currentList != null) currentList,
      ...historyLists,
    ];
  }

  String get shareText {
    final lines = <String>['買うもの', ''];
    for (final item in shareableItems) {
      lines.add('・${item.text.trim()}');
    }
    return lines.join('\n');
  }

  KaimonoListState copyWith({
    String? currentListId,
    String? currentListTitle,
    DateTime? currentListCreatedAt,
    DateTime? currentListUpdatedAt,
    List<KaimonoItem>? items,
    int? currentListColorValue,
    List<CreatedKaimonoList>? historyLists,
    Object? editingItemId = _editingItemIdUnset,
  }) {
    return KaimonoListState(
      currentListId: currentListId ?? this.currentListId,
      currentListTitle: currentListTitle ?? this.currentListTitle,
      currentListCreatedAt: currentListCreatedAt ?? this.currentListCreatedAt,
      currentListUpdatedAt: currentListUpdatedAt ?? this.currentListUpdatedAt,
      items: items ?? this.items,
      currentListColorValue:
          currentListColorValue ?? this.currentListColorValue,
      historyLists: historyLists ?? this.historyLists,
      editingItemId: identical(editingItemId, _editingItemIdUnset)
          ? this.editingItemId
          : editingItemId as String?,
    );
  }

  CreatedKaimonoList? _currentListSnapshot() {
    if (visibleItems.isEmpty) return null;
    return CreatedKaimonoList(
      id: currentListId,
      title: currentListTitle,
      items: items,
      createdAt: currentListCreatedAt,
      updatedAt: currentListUpdatedAt,
      colorValue: currentListColorValue,
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
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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
    final now = clock.now();
    return KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      items: const [],
    );
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
    state = state.copyWith(items: nextItems, currentListUpdatedAt: clock.now());
  }

  void updateListTitle(String title) {
    state = state.copyWith(
      currentListTitle: title.trim(),
      currentListUpdatedAt: clock.now(),
    );
  }

  void addItem() {
    final newId = _newItemId();
    state = state.copyWith(
      items: [
        ...state.items,
        KaimonoItem(id: newId, text: ''),
      ],
      currentListUpdatedAt: clock.now(),
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
    state = state.copyWith(items: nextItems, currentListUpdatedAt: clock.now());
  }

  void removeItem(String id) {
    final nextItems = state.items.where((item) => item.id != id).toList();
    _itemControllers[id]?.dispose();
    _itemControllers.remove(id);

    final nextEditing = state.editingItemId == id ? null : state.editingItemId;
    state = state.copyWith(
      items: nextItems,
      editingItemId: nextEditing,
      currentListUpdatedAt: clock.now(),
    );
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final nextItems = [...state.items];
    final item = nextItems.removeAt(oldIndex);
    nextItems.insert(newIndex, item);
    state = state.copyWith(items: nextItems, currentListUpdatedAt: clock.now());
  }

  void clearAllItems() {
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();
    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      items: const [],
      historyLists: _historyWithCurrentSnapshot(),
    );
  }

  bool saveCurrentList() {
    if (state.visibleItems.isEmpty) return false;

    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();

    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      items: const [],
      historyLists: _historyWithCurrentSnapshot(),
    );
    return true;
  }

  void openCreatedList(String id) {
    if (id == state.currentListId) return;

    final selectedList = state.historyLists
        .where((list) => list.id == id)
        .firstOrNull;
    if (selectedList == null) return;

    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();

    state = KaimonoListState(
      currentListId: selectedList.id,
      currentListTitle: selectedList.title,
      currentListCreatedAt: selectedList.createdAt,
      currentListUpdatedAt: clock.now(),
      items: selectedList.items,
      currentListColorValue: selectedList.colorValue,
      historyLists: [
        ..._historyWithCurrentSnapshot(),
      ].where((list) => list.id != selectedList.id).toList(),
    );
  }

  void deleteCreatedList(String id) {
    deleteCreatedLists({id});
  }

  void deleteCreatedLists(Set<String> ids) {
    final nextHistoryLists = state.historyLists
        .where((list) => !ids.contains(list.id))
        .toList();

    if (!ids.contains(state.currentListId)) {
      state = state.copyWith(historyLists: nextHistoryLists);
      return;
    }

    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();

    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      items: const [],
      historyLists: nextHistoryLists,
    );
  }

  void moveCreatedList(String movedId, String targetId) {
    if (movedId == targetId) return;
    if (movedId == state.currentListId || targetId == state.currentListId) {
      return;
    }

    final nextHistoryLists = [...state.historyLists];
    final oldIndex = nextHistoryLists.indexWhere((list) => list.id == movedId);
    final newIndex = nextHistoryLists.indexWhere((list) => list.id == targetId);
    if (oldIndex == -1 || newIndex == -1) return;

    final movedList = nextHistoryLists.removeAt(oldIndex);
    nextHistoryLists.insert(newIndex, movedList);
    state = state.copyWith(historyLists: nextHistoryLists);
  }

  void updateCreatedListColor(String id, int colorValue) {
    if (id == state.currentListId) {
      state = state.copyWith(
        currentListColorValue: colorValue,
        currentListUpdatedAt: clock.now(),
      );
      return;
    }

    state = state.copyWith(
      historyLists: [
        for (final list in state.historyLists)
          if (list.id == id)
            list.copyWith(colorValue: colorValue, updatedAt: clock.now())
          else
            list,
      ],
    );
  }

  Future<SharedKaimonoList> createSharedList() async {
    final items = state.shareableItems;
    if (items.isEmpty) {
      throw StateError('共有できるアイテムがありません');
    }

    final result = await _functions
        .httpsCallable('createSharedList')
        .call<Map<Object?, Object?>>({
          'items': [
            for (final item in items)
              {
                'text': item.text.trim(),
              },
          ],
        });
    final data = result.data;
    final id = data['id'];
    final url = data['url'];
    if (id is! String || id.isEmpty || url is! String || url.isEmpty) {
      throw StateError('共有リンクの作成に失敗しました');
    }

    return SharedKaimonoList(
      id: id,
      url: url,
      shareText: '${state.shareText}\n\nKaimono+で開く:\n$url',
    );
  }

  Future<void> openSharedList(String id) async {
    final result = await _functions
        .httpsCallable('getSharedListForApp')
        .call<Map<Object?, Object?>>({'id': id});
    final data = result.data;
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw StateError('共有リストを開けませんでした');
    }

    final nextItems = <KaimonoItem>[];
    for (final (index, rawItem) in rawItems.indexed) {
      if (rawItem is! Map) continue;
      final text = rawItem['text'];
      if (text is! String || text.trim().isEmpty) continue;
      nextItems.add(
        KaimonoItem(
          id: '${clock.now().microsecondsSinceEpoch}-$index',
          text: text.trim(),
        ),
      );
    }

    if (nextItems.isEmpty) {
      throw StateError('共有リストを開けませんでした');
    }

    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();
    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      items: nextItems,
      historyLists: _historyWithCurrentSnapshot(),
    );
  }

  List<CreatedKaimonoList> _historyWithCurrentSnapshot() {
    final currentList = state._currentListSnapshot();
    if (currentList == null) return state.historyLists;

    return [
      currentList,
      ...state.historyLists.where((list) => list.id != currentList.id),
    ];
  }

  String _newListId() => 'list-${clock.now().microsecondsSinceEpoch}';

  String _newItemId() => 'item-${clock.now().microsecondsSinceEpoch}';
}
