import 'dart:async';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authenticator_provider.dart';

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
    required this.currentListIsSaved,
    required this.items,
    this.currentListColorValue,
    this.historyLists = const [],
    this.editingItemId,
  });

  final String currentListId;
  final String currentListTitle;
  final DateTime currentListCreatedAt;
  final DateTime currentListUpdatedAt;
  final bool currentListIsSaved;
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
    final currentList = currentListIsSaved ? _currentListSnapshot() : null;
    if (currentList == null) {
      return historyLists;
    }

    var didReplaceCurrentList = false;
    final lists = <CreatedKaimonoList>[];
    for (final list in historyLists) {
      if (list.id == currentList.id) {
        lists.add(currentList);
        didReplaceCurrentList = true;
      } else {
        lists.add(list);
      }
    }

    return [
      if (!didReplaceCurrentList) currentList,
      ...lists,
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
    bool? currentListIsSaved,
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
      currentListIsSaved: currentListIsSaved ?? this.currentListIsSaved,
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
    final savedItems = visibleItems;
    if (savedItems.isEmpty) return null;
    return CreatedKaimonoList(
      id: currentListId,
      title: currentListTitle,
      items: savedItems,
      createdAt: currentListCreatedAt,
      updatedAt: currentListUpdatedAt,
      colorValue: currentListColorValue,
    );
  }
}

class _ShoppingListRepository {
  _ShoppingListRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _shoppingListsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('shoppingLists');
  }

  Stream<List<CreatedKaimonoList>> watchShoppingLists(String uid) {
    return _shoppingListsRef(uid)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) _listFromDoc(doc),
          ],
        );
  }

  Future<void> saveShoppingLists({
    required String uid,
    required List<CreatedKaimonoList> lists,
  }) async {
    final batch = _firestore.batch();
    final collection = _shoppingListsRef(uid);
    for (final (index, list) in lists.indexed) {
      batch.set(
        collection.doc(list.id),
        _listToData(list, sortOrder: index),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> deleteShoppingLists({
    required String uid,
    required Iterable<String> ids,
  }) async {
    final batch = _firestore.batch();
    final collection = _shoppingListsRef(uid);
    for (final id in ids) {
      batch.delete(collection.doc(id));
    }
    await batch.commit();
  }

  CreatedKaimonoList _listFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawItems = data['items'];
    return CreatedKaimonoList(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      items: [
        if (rawItems is List)
          for (final rawItem in rawItems)
            if (rawItem is Map)
              KaimonoItem(
                id: (rawItem['id'] as String?) ?? _fallbackItemId(doc.id),
                text: (rawItem['text'] as String?) ?? '',
                isCompleted: (rawItem['isCompleted'] as bool?) ?? false,
              ),
      ],
      createdAt: _dateFromData(data['createdAt']),
      updatedAt: _dateFromData(data['updatedAt']),
      colorValue: data['colorValue'] as int?,
    );
  }

  Map<String, dynamic> _listToData(
    CreatedKaimonoList list, {
    required int sortOrder,
  }) {
    return {
      'title': list.title,
      'items': [
        for (final item in list.items)
          {
            'id': item.id,
            'text': item.text,
            'isCompleted': item.isCompleted,
          },
      ],
      'createdAt': Timestamp.fromDate(list.createdAt),
      'updatedAt': Timestamp.fromDate(list.updatedAt),
      'colorValue': list.colorValue,
      'sortOrder': sortOrder,
    };
  }

  DateTime _dateFromData(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return clock.now();
  }

  String _fallbackItemId(String listId) {
    return '$listId-item-${clock.now().microsecondsSinceEpoch}';
  }
}

final kaimonoListPageViewModelProvider =
    NotifierProvider.autoDispose<KaimonoListPageNotifier, KaimonoListState>(
      KaimonoListPageNotifier.new,
    );

class KaimonoListPageNotifier extends Notifier<KaimonoListState> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, FocusNode> _itemFocusNodes = {};
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final _shoppingListRepository = _ShoppingListRepository();
  StreamSubscription<List<CreatedKaimonoList>>? _shoppingListsSubscription;
  String? _uid;

  ScrollController get scrollController => _scrollController;

  @override
  KaimonoListState build() {
    ref.onDispose(() {
      _shoppingListsSubscription?.cancel();
      _disposeItemInputs();
      _scrollController.dispose();
    });
    ref.listen(authStateChangesProvider, (_, authState) {
      final user = authState.value;
      if (user == null) {
        _setUid(null);
        return;
      }
      _setUid(user.uid);
    });
    final now = clock.now();
    Future<void>.microtask(() {
      if (!ref.mounted) return;
      final user = ref.read(authStateChangesProvider).value;
      _setUid(user?.uid);
    });
    return KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      currentListIsSaved: false,
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

  FocusNode getFocusNodeForItem(String id) {
    return _itemFocusNodes.putIfAbsent(id, FocusNode.new);
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
      _itemFocusNodes[id]?.requestFocus();
    });
  }

  void stopEditing(String id, {bool skipIfEmpty = false}) {
    state = state.copyWith(editingItemId: null);
    _saveItemText(id, skipIfEmpty: skipIfEmpty);
  }

  void submitItem(String id) {
    final controller = _itemControllers[id];
    final text = controller?.text.trim() ?? '';
    if (text.isEmpty) {
      removeItem(id);
      return;
    }

    updateItemText(id, text);
    final currentIndex = state.items.indexWhere((item) => item.id == id);
    if (currentIndex == -1) return;

    final nextEmptyItem = state.items
        .skip(currentIndex + 1)
        .where((item) => item.text.trim().isEmpty)
        .firstOrNull;
    if (nextEmptyItem != null) {
      startEditing(nextEmptyItem.id);
      return;
    }

    addItem();
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
    _savePersistedLists();
  }

  void updateListTitle(String title) {
    state = state.copyWith(
      currentListTitle: title.trim(),
      currentListUpdatedAt: clock.now(),
    );
    _savePersistedLists();
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
    _savePersistedLists();
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
    _savePersistedLists();
  }

  void removeItem(String id) {
    final nextItems = state.items.where((item) => item.id != id).toList();
    _itemControllers[id]?.dispose();
    _itemControllers.remove(id);
    _itemFocusNodes[id]?.dispose();
    _itemFocusNodes.remove(id);

    final nextEditing = state.editingItemId == id ? null : state.editingItemId;
    state = state.copyWith(
      items: nextItems,
      editingItemId: nextEditing,
      currentListUpdatedAt: clock.now(),
    );
    _savePersistedLists();
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final nextItems = [...state.items];
    final item = nextItems.removeAt(oldIndex);
    nextItems.insert(newIndex, item);
    state = state.copyWith(items: nextItems, currentListUpdatedAt: clock.now());
    _savePersistedLists();
  }

  void clearAllItems() {
    _disposeItemInputs();
    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      currentListIsSaved: false,
      items: const [],
      historyLists: _historyListsWithCurrentSavedSnapshot(),
    );
    _savePersistedLists();
  }

  Future<bool> saveCurrentList() async {
    final currentList = state._currentListSnapshot();
    if (currentList == null) return false;

    final uid = _currentUid();
    if (uid == null) {
      throw StateError('ログイン状態を確認できませんでした');
    }

    final nextHistoryLists = [
      currentList,
      ...state.historyLists.where((list) => list.id != currentList.id),
    ];
    await _shoppingListRepository.saveShoppingLists(
      uid: uid,
      lists: nextHistoryLists,
    );

    _disposeItemInputs();

    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      currentListIsSaved: false,
      items: const [],
      historyLists: nextHistoryLists,
    );
    return true;
  }

  void openCreatedList(String id) {
    if (id == state.currentListId) return;

    final selectedList = state.createdLists
        .where((list) => list.id == id)
        .firstOrNull;
    if (selectedList == null) return;

    _disposeItemInputs();

    state = KaimonoListState(
      currentListId: selectedList.id,
      currentListTitle: selectedList.title,
      currentListCreatedAt: selectedList.createdAt,
      currentListUpdatedAt: clock.now(),
      currentListIsSaved: true,
      items: selectedList.items,
      currentListColorValue: selectedList.colorValue,
      historyLists: _historyListsWithCurrentSavedSnapshot(),
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
      _deletePersistedLists(ids);
      return;
    }

    _disposeItemInputs();

    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      currentListIsSaved: false,
      items: const [],
      historyLists: nextHistoryLists,
    );
    _deletePersistedLists(ids);
  }

  void moveCreatedList(String movedId, String targetId) {
    if (movedId == targetId) return;

    final nextHistoryLists = _historyListsWithCurrentSavedSnapshot();
    final oldIndex = nextHistoryLists.indexWhere((list) => list.id == movedId);
    final newIndex = nextHistoryLists.indexWhere((list) => list.id == targetId);
    if (oldIndex == -1 || newIndex == -1) return;

    final movedList = nextHistoryLists.removeAt(oldIndex);
    nextHistoryLists.insert(newIndex, movedList);
    state = state.copyWith(historyLists: nextHistoryLists);
    _savePersistedLists();
  }

  void updateCreatedListColor(String id, int colorValue) {
    if (id == state.currentListId) {
      state = state.copyWith(
        currentListColorValue: colorValue,
        currentListUpdatedAt: clock.now(),
      );
      _savePersistedLists();
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
    _savePersistedLists();
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

    _disposeItemInputs();
    final now = clock.now();
    state = KaimonoListState(
      currentListId: _newListId(),
      currentListTitle: '',
      currentListCreatedAt: now,
      currentListUpdatedAt: now,
      currentListIsSaved: false,
      items: nextItems,
      historyLists: _historyListsWithCurrentSavedSnapshot(),
    );
    _savePersistedLists();
  }

  List<CreatedKaimonoList> _historyListsWithCurrentSavedSnapshot() {
    if (!state.currentListIsSaved) return state.historyLists;

    final currentList = state._currentListSnapshot();
    if (currentList == null) return state.historyLists;

    var didReplaceCurrentList = false;
    final lists = <CreatedKaimonoList>[];
    for (final list in state.historyLists) {
      if (list.id == currentList.id) {
        lists.add(currentList);
        didReplaceCurrentList = true;
      } else {
        lists.add(list);
      }
    }
    return [
      if (!didReplaceCurrentList) currentList,
      ...lists,
    ];
  }

  String _newListId() => 'list-${clock.now().microsecondsSinceEpoch}';

  String _newItemId() => 'item-${clock.now().microsecondsSinceEpoch}';

  void _disposeItemInputs() {
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _itemFocusNodes.values) {
      focusNode.dispose();
    }
    _itemControllers.clear();
    _itemFocusNodes.clear();
  }

  void _setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    unawaited(_shoppingListsSubscription?.cancel());
    _shoppingListsSubscription = null;

    if (uid == null) return;

    _shoppingListsSubscription = _shoppingListRepository
        .watchShoppingLists(uid)
        .listen(
          (lists) {
            if (!ref.mounted) return;
            state = state.copyWith(historyLists: lists);
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('買い物リスト履歴の取得に失敗しました: $error');
          },
        );
  }

  List<CreatedKaimonoList> _persistedLists() {
    return _historyListsWithCurrentSavedSnapshot();
  }

  String? _currentUid() {
    return _uid ?? ref.read(authStateChangesProvider).value?.uid;
  }

  void _savePersistedLists() {
    final uid = _currentUid();
    if (uid == null) return;
    unawaited(
      _shoppingListRepository
          .saveShoppingLists(uid: uid, lists: _persistedLists())
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('買い物リスト履歴の保存に失敗しました: $error');
          }),
    );
  }

  void _deletePersistedLists(Set<String> ids) {
    final uid = _uid;
    if (uid == null || ids.isEmpty) return;
    unawaited(
      _shoppingListRepository
          .deleteShoppingLists(uid: uid, ids: ids)
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('買い物リスト履歴の削除に失敗しました: $error');
          }),
    );
  }
}
