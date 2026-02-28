import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

class KaimonoItem {
  final String id;
  final String text;
  bool isCompleted;

  KaimonoItem({required this.id, required this.text, this.isCompleted = false});
}

final kaimonoListPageViewModelProvider = ChangeNotifierProvider.autoDispose<
    KaimonoListPageViewModel>(
  (ref) => KaimonoListPageViewModel(),
);

class KaimonoListPageViewModel extends ChangeNotifier {
  final List<KaimonoItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  String? _editingItemId;
  final Map<String, TextEditingController> _itemControllers = {};

  ScrollController get scrollController => _scrollController;
  List<KaimonoItem> get items => List.unmodifiable(_items);
  String? get editingItemId => _editingItemId;

  TextEditingController? getControllerForItem(String id) {
    if (!_itemControllers.containsKey(id)) {
      final item = _items.firstWhere((item) => item.id == id);
      _itemControllers[id] = TextEditingController(text: item.text);
    } else {
      // コントローラーが既に存在する場合も、アイテムのテキストと同期する
      final item = _items.firstWhere((item) => item.id == id);
      final controller = _itemControllers[id]!;
      if (controller.text != item.text) {
        controller.text = item.text;
      }
    }
    return _itemControllers[id];
  }

  void startEditing(String id, {bool isNewItem = false}) {
    // 現在編集中のアイテムがあれば、先に編集を終了する
    // 新しいアイテムを追加する時は前の空のアイテムを削除しない
    // 既存のアイテムを編集する時も前の空のアイテムは削除しない（連続して入力できるように）
    if (_editingItemId != null && _editingItemId != id) {
      stopEditing(_editingItemId!, skipIfEmpty: true);
    }
    _editingItemId = id;
    notifyListeners();
    // 少し遅延してからフォーカスを当てる
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
    _editingItemId = null;
    _saveItemText(id, skipIfEmpty: skipIfEmpty);
    notifyListeners();
  }

  void _saveItemText(String id, {bool skipIfEmpty = false}) {
    final controller = _itemControllers[id];
    if (controller != null) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        updateItemText(id, controller.text);
      } else if (!skipIfEmpty) {
        // 空の場合は削除する（新規追加時はskipIfEmpty=trueで呼ばれる）
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

    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = KaimonoItem(
        id: _items[index].id,
        text: trimmedText,
        isCompleted: _items[index].isCompleted,
      );
      notifyListeners();
    }
  }

  void addItem() {
    final newId = clock.now().millisecondsSinceEpoch.toString();
    _items.add(KaimonoItem(id: newId, text: ''));
    debugPrint('addItem: 新しいアイテムを追加します');
    notifyListeners();

    // リストの最後にスクロールして編集モードにする
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
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isCompleted = !_items[index].isCompleted;
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _itemControllers[id]?.dispose();
    _itemControllers.remove(id);
    if (_editingItemId == id) {
      _editingItemId = null;
    }
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    notifyListeners();
  }

  void clearAllItems() {
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();
    _items.clear();
    _editingItemId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _itemControllers.values) {
      controller.dispose();
    }
    _itemControllers.clear();
    _scrollController.dispose();
    super.dispose();
  }
}
