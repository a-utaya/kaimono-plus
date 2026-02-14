import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'kaimono_list_page_view_model.dart';

part 'components/kaimono_list_item.part.dart';

class KaimonoListPage extends StatelessWidget {
  const KaimonoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KaimonoListPageViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: const Text('買い物リスト'),
            leading: IconButton(
              onPressed: () {
                _showDeleteAllDialog(context, vm);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            actions: [
              IconButton(
                // FIXME: シェアボタンの実装
                onPressed: () {},
                icon: const Icon(Icons.ios_share, color: Colors.white),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => vm.addItem(),
            backgroundColor: Colors.amber,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Container(
            height: double.infinity,
            color: Colors.grey[100],
            child: ReorderableListView.builder(
              padding: const .all(16.0),
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final item = vm.items[index];
                final isEditing = vm.editingItemId == item.id;
                final controller = vm.getControllerForItem(item.id);

                return KaimonoListItem(
                  key: ValueKey(item.id),
                  item: item,
                  isEditing: isEditing,
                  controller: controller!,
                );
              },
              onReorder: vm.reorderItems,
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAllDialog(BuildContext context, KaimonoListPageViewModel vm) {
    if (vm.items.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Center(
            child: Text(
              '全件削除',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          content: const Text('すべてのアイテムを削除しますか？'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    vm.clearAllItems();
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('削除'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
