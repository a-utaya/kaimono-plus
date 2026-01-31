import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'kaimono_list_page_view_model.dart';

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
            child: ListView.builder(
              controller: vm.scrollController,
              itemCount: vm.items.length,
              padding: const .all(16.0),
              itemBuilder: (context, index) {
                final item = vm.items[index];
                final isEditing = vm.editingItemId == item.id;
                final controller = vm.getControllerForItem(item.id);

                return Container(
                  margin: const .only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!isEditing) {
                        vm.startEditing(item.id);
                      }
                    },
                    child: Row(
                      children: [
                        Padding(
                          padding: const .only(left: 16.0),
                          child: InkWell(
                            onTap: () {
                              vm.toggleItem(item.id);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const .all(4.0),
                              child: item.isCompleted
                                  ? const Icon(
                                      Icons.check_box,
                                      color: Colors.amber,
                                      size: 24,
                                    )
                                  : Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[600]!,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Padding(
                            padding: const .symmetric(vertical: 16.0),
                            child: isEditing && controller != null
                                ? TextField(
                                    controller: controller,
                                    cursorColor: Colors.amber,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: .zero,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                    onChanged: (text) {
                                      // リアルタイムで保存
                                      vm.updateItemText(
                                        item.id,
                                        text,
                                        removeIfEmpty: false,
                                      );
                                    },
                                    onSubmitted: (_) {
                                      vm.stopEditing(item.id);
                                    },
                                    onEditingComplete: () {
                                      vm.stopEditing(item.id);
                                    },
                                  )
                                : Text(
                                    item.text,
                                    style: TextStyle(
                                      color: item.isCompleted
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                      fontSize: 16,
                                      height: 1.5,
                                      decoration: item.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            vm.removeItem(item.id);
                          },
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAllDialog(BuildContext context, KaimonoListPageViewModel vm) {
    if (vm.items.isEmpty) return;
    showDialog(
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
