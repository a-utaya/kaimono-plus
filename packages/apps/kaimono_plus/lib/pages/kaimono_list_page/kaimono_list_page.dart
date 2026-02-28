import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../components/confirm_dialog.dart';
import 'kaimono_list_page_view_model.dart';

part 'components/kaimono_list_item.part.dart';

class KaimonoListPage extends ConsumerWidget {
  const KaimonoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch<KaimonoListPageViewModel>(
      kaimonoListPageViewModelProvider,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('買い物リスト'),
        leading: IconButton(
          onPressed: () {
            // アイテムがない場合は何もしない
            if (vm.items.isEmpty) return;

            // 全件削除確認ダイアログを表示
            showDialog<void>(
              context: context,
              builder: (dialogContext) => ConfirmDialog(
                title: '全件削除',
                content: 'すべてのアイテムを削除しますか？',
                confirmText: '削除',
                isDestructive: true,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onConfirm: () {
                  vm.clearAllItems();
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
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
          padding: const EdgeInsets.all(16.0),
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
              viewModel: vm,
            );
          },
          onReorder: vm.reorderItems,
        ),
      ),
    );
  }
}
