import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

import '../../components/confirm_dialog.dart';
import '../../ui/app_snack_bar.dart';
import 'kaimono_list_page_view_model.dart';

part 'components/kaimono_list_item.part.dart';

class KaimonoListPage extends ConsumerStatefulWidget {
  const KaimonoListPage({super.key});

  @override
  ConsumerState<KaimonoListPage> createState() => _KaimonoListPageState();
}

class _KaimonoListPageState extends ConsumerState<KaimonoListPage> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialLink();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      await _handleLink(uri);
    }
  }

  Future<void> _handleLink(Uri uri) async {
    final id = _sharedListIdFromUri(uri);
    if (id == null) return;
    try {
      await ref
          .read(kaimonoListPageViewModelProvider.notifier)
          .openSharedList(id);
      if (!mounted) return;
      showAppSnackBar(context, '共有リストを開きました');
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        '共有リストを開けませんでした。リンクを確認してください。',
        isError: true,
      );
    }
  }

  String? _sharedListIdFromUri(Uri uri) {
    if (uri.scheme == 'kaimono-plus' && uri.host == 'share') {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    if (uri.scheme == 'https' &&
        uri.host == 'kaimono-plus.web.app' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'share') {
      return uri.pathSegments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(kaimonoListPageViewModelProvider);
    final notifier = ref.read(kaimonoListPageViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('買い物リスト'),
        leading: IconButton(
          onPressed: () {
            // アイテムがない場合は何もしない
            if (listState.items.isEmpty) return;

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
                  notifier.clearAllItems();
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
          },
          icon: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: listState.hasShareableItems
                ? () async {
                    try {
                      final sharedList = await notifier.createSharedList();
                      if (!context.mounted) return;
                      final box = context.findRenderObject() as RenderBox?;
                      await SharePlus.instance.share(
                        ShareParams(
                          text: sharedList.shareText,
                          subject: '買い物リスト',
                          sharePositionOrigin: box == null
                              ? null
                              : box.localToGlobal(Offset.zero) & box.size,
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      showAppSnackBar(
                        context,
                        '共有リンクの作成に失敗しました。しばらく経ってから再度お試しください。',
                        isError: true,
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.ios_share, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.addItem,
        backgroundColor: Colors.amber,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        color: Colors.grey[100],
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: listState.items.length,
          itemBuilder: (context, index) {
            final item = listState.items[index];
            final isEditing = listState.editingItemId == item.id;
            final controller = notifier.getControllerForItem(item.id);

            return KaimonoListItem(
              key: ValueKey(item.id),
              item: item,
              isEditing: isEditing,
              controller: controller!,
              notifier: notifier,
            );
          },
          onReorder: notifier.reorderItems,
        ),
      ),
    );
  }
}
