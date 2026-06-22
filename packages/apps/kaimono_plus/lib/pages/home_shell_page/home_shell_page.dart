import 'package:auth/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/confirm_dialog.dart';
import '../../providers/authenticator_provider.dart';
import '../../ui/app_snack_bar.dart';
import '../kaimono_list_page/kaimono_list_page.dart';
import '../kaimono_list_page/kaimono_list_page_view_model.dart';

class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  static const _listTabIndex = 1;

  int _currentIndex = _listTabIndex;

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _createShoppingListItem() {
    _selectTab(_listTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(kaimonoListPageViewModelProvider.notifier).addItem();
    });
  }

  void _openCreatedList(String id) {
    ref.read(kaimonoListPageViewModelProvider.notifier).openCreatedList(id);
    _selectTab(_listTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                ShoppingListHistoryPage(onOpenList: _openCreatedList),
                const KaimonoListPage(showFloatingActionButton: false),
                const MyPage(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _HomeBottomNavigationBar(
              currentIndex: _currentIndex,
              onSelectTab: _selectTab,
              onCreateItem: _createShoppingListItem,
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingListHistoryPage extends ConsumerStatefulWidget {
  const ShoppingListHistoryPage({
    required this.onOpenList,
    super.key,
  });

  final ValueChanged<String> onOpenList;

  @override
  ConsumerState<ShoppingListHistoryPage> createState() =>
      _ShoppingListHistoryPageState();
}

class _ShoppingListHistoryPageState
    extends ConsumerState<ShoppingListHistoryPage> {
  final Set<String> _selectedListIds = {};
  bool _isReorderMode = false;

  bool get _isSelectionMode => _selectedListIds.isNotEmpty;

  void _enterReorderMode() {
    setState(() {
      _selectedListIds.clear();
      _isReorderMode = true;
    });
  }

  void _exitReorderMode() {
    setState(() {
      _isReorderMode = false;
    });
  }

  void _clearSelection() {
    setState(_selectedListIds.clear);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedListIds.add(id)) {
        _selectedListIds.remove(id);
      }
    });
  }

  void _syncSelectionWithLists(List<CreatedKaimonoList> createdLists) {
    final validIds = createdLists.map((list) => list.id).toSet();
    if (_selectedListIds.every(validIds.contains)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedListIds.removeWhere((id) => !validIds.contains(id));
      });
    });
  }

  void _confirmDeleteList(
    BuildContext context,
    WidgetRef ref,
    CreatedKaimonoList list,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: 'リストを削除',
        content: '「${list.displayTitle}」を削除しますか？',
        confirmText: '削除',
        isDestructive: true,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          ref
              .read(kaimonoListPageViewModelProvider.notifier)
              .deleteCreatedList(list.id);
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _confirmDeleteSelectedLists(BuildContext context) {
    final selectedCount = _selectedListIds.length;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: 'リストを削除',
        content: '選択した$selectedCount件のリストを削除しますか？',
        confirmText: '削除',
        isDestructive: true,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          ref
              .read(kaimonoListPageViewModelProvider.notifier)
              .deleteCreatedLists(_selectedListIds);
          Navigator.of(dialogContext).pop();
          _clearSelection();
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, CreatedKaimonoList list) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'カードの色を変える',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const Gap(16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _historyPaletteColors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final color = _historyPaletteColors[index];
                    final isSelected = list.colorValue == color.toARGB32();
                    return InkWell(
                      onTap: () {
                        ref
                            .read(kaimonoListPageViewModelProvider.notifier)
                            .updateCreatedListColor(list.id, color.toARGB32());
                        Navigator.of(dialogContext).pop();
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black87
                                : Colors.black.withValues(alpha: 0.08),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.black87)
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(kaimonoListPageViewModelProvider);
    final createdLists = listState.createdLists;
    _syncSelectionWithLists(createdLists);
    final selectedCount = _selectedListIds.length;

    final appBarTitle = _isSelectionMode
        ? Text('$selectedCount件選択中')
        : Text(_isReorderMode ? '並び替え' : '履歴');
    final leading = _isSelectionMode
        ? IconButton(
            onPressed: _clearSelection,
            icon: const Icon(Icons.close, color: Colors.white),
          )
        : _isReorderMode
        ? IconButton(
            onPressed: _exitReorderMode,
            icon: const Icon(Icons.check, color: Colors.white),
          )
        : null;
    final actions = _isSelectionMode
        ? [
            IconButton(
              tooltip: '削除',
              onPressed: () => _confirmDeleteSelectedLists(context),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
            ),
          ]
        : _isReorderMode
        ? [
            TextButton(
              onPressed: _exitReorderMode,
              child: const Text(
                '完了',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]
        : [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'reorder') {
                  _enterReorderMode();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'reorder',
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert, size: 20),
                      Gap(8),
                      Text('並び替え'),
                    ],
                  ),
                ),
              ],
            ),
          ];

    final historyGrid = GridView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 24,
      ),
      itemCount: createdLists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final list = createdLists[index];
        final isSelected = _selectedListIds.contains(list.id);
        final canReorder = _isReorderMode;
        final cardColor = _cardColorFor(list);

        final card = _CreatedListCard(
          list: list,
          color: cardColor,
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          isReorderMode: _isReorderMode,
          canReorder: canReorder,
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(list.id);
              return;
            }
            if (_isReorderMode) return;
            widget.onOpenList(list.id);
          },
          onLongPress: _isReorderMode ? null : () => _toggleSelection(list.id),
          onChangeColor: () => _showColorPicker(context, list),
          onDelete: () => _confirmDeleteList(context, ref, list),
        );

        if (!_isReorderMode) {
          return card;
        }

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => details.data != list.id,
          onAcceptWithDetails: (details) {
            ref
                .read(kaimonoListPageViewModelProvider.notifier)
                .moveCreatedList(details.data, list.id);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return LongPressDraggable<String>(
              data: list.id,
              feedback: SizedBox(
                width: 160,
                height: 196,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.92,
                    child: _CreatedListCard(
                      list: list,
                      color: cardColor,
                      isSelected: false,
                      isSelectionMode: false,
                      isReorderMode: true,
                      canReorder: false,
                      onTap: () {},
                      onLongPress: null,
                      onChangeColor: () {},
                      onDelete: () {},
                    ),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: AnimatedScale(
                scale: isHovering ? 0.96 : 1,
                duration: const Duration(milliseconds: 120),
                child: card,
              ),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        leading: leading,
        title: appBarTitle,
        actions: actions,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: createdLists.isEmpty
              ? const _HistoryEmptyState()
              : historyGrid,
        ),
      ),
    );
  }

  Color _cardColorFor(CreatedKaimonoList list) {
    final colorValue = list.colorValue;
    if (colorValue != null) {
      return Color(colorValue);
    }
    return _defaultHistoryCardColor;
  }
}

const _defaultHistoryCardColor = Color(0xFFFFF4C2);

/// 履歴リストの背景色リスト
const _historyPaletteColors = [
  _defaultHistoryCardColor,
  Color(0xFFDFF7EA),
  Color(0xFFFFE4EC),
  Color(0xFFDDEEFF),
  Color(0xFFFFE1C7),
  Color(0xFFE8DFFF),
];

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: Colors.black38,
            ),
            Gap(12),
            Text(
              'まだ履歴はありません',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
            Gap(6),
            Text(
              '買うものを追加すると、ここにリストが表示されます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatedListCard extends StatelessWidget {
  const _CreatedListCard({
    required this.list,
    required this.color,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isReorderMode,
    required this.canReorder,
    required this.onTap,
    required this.onLongPress,
    required this.onChangeColor,
    required this.onDelete,
  });

  final CreatedKaimonoList list;
  final Color color;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isReorderMode;
  final bool canReorder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onChangeColor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final previewItems = list.visibleItems.take(3).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.amber.shade800 : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.shopping_basket_outlined,
                          size: 22,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isSelectionMode)
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Colors.amber.shade800
                            : Colors.black38,
                      )
                    else if (isReorderMode)
                      Icon(
                        canReorder ? Icons.drag_handle : Icons.lock_outline,
                        color: Colors.black45,
                      )
                    else
                      SizedBox.square(
                        dimension: 32,
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.black54,
                          ),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'changeColor') {
                              onChangeColor();
                              return;
                            }
                            if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'changeColor',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.palette_outlined,
                                    size: 20,
                                  ),
                                  Gap(8),
                                  Text('色を変える'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  Gap(8),
                                  Text(
                                    '削除',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const Gap(12),
                Text(
                  list.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in previewItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                item.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 13,
                                color: Colors.black45,
                              ),
                              const Gap(5),
                              Expanded(
                                child: Text(
                                  item.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _formatUpdatedAt(list.updatedAt),
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    return '${updatedAt.month}/${updatedAt.day} 更新';
  }
}

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _AccountDataRepository {
  _AccountDataRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _deleteBatchLimit = 450;

  final FirebaseFirestore _firestore;

  Future<void> deleteUserData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await _deleteCollection(userRef.collection('shoppingLists'));
    await _deleteCollection(userRef.collection('shoppingItemTags'));
    await _deleteQuery(
      _firestore.collection('sharedLists').where('ownerUid', isEqualTo: uid),
    );
    await _deleteQuery(
      _firestore.collection('sharedLists').where('createdBy', isEqualTo: uid),
    );
    await userRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    await _deleteQuery(collection);
  }

  Future<void> _deleteQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    while (true) {
      final snapshot = await query.limit(_deleteBatchLimit).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < _deleteBatchLimit) return;
    }
  }
}

class _MyPageState extends ConsumerState<MyPage> {
  static const _appVersion = '1.0.0';
  static const _appBuildNumber = '1';
  static final _contactFormUri = Uri.parse(
    'https://docs.google.com/forms/d/e/1FAIpQLSdBkxkPdD2iIl8suuS1WNE5YGwWrCzXjeIkmrC-Td3koIq1Hw/viewform',
  );

  final _accountDataRepository = _AccountDataRepository();
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;

  void _openPrivacyPolicyPage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyPage(),
      ),
    );
  }

  Future<void> _openContactForm() async {
    try {
      final launched = await launchUrl(
        _contactFormUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !mounted) return;

      showAppSnackBar(
        context,
        'お問い合わせフォームを開けませんでした',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'お問い合わせフォームを開けませんでした。アプリを再起動してからお試しください。',
        isError: true,
      );
    }
  }

  Future<void> _showAccountDeletionDialog() async {
    if (_isDeletingAccount) return;

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AccountDeletionDialog(
        email:
            ref.read(authStateChangesProvider).value?.email ??
            ref.read(authenticatorProvider).currentUserEmail,
      ),
    );
    if (password == null || password.isEmpty) return;

    await _deleteAccount(password);
  }

  Future<void> _deleteAccount(String password) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) {
      showAppSnackBar(context, 'ログイン状態を確認できませんでした', isError: true);
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });
    try {
      final authenticator = ref.read(authenticatorProvider);
      await authenticator.reauthenticateWithPassword(password: password);
      await _accountDataRepository.deleteUserData(user.uid);
      await authenticator.deleteCurrentUser();
      if (!mounted) return;
      showAppSnackBar(context, 'アカウントを削除しました');
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'アカウント削除に失敗しました', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  Future<void> _showSignOutDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: 'お店を出ますか？',
        content: 'ログアウトします。よろしいですか？',
        confirmText: 'お店を出る',
        isDestructive: true,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          _signOut();
        },
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      await ref.read(authenticatorProvider).signOut();
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'ログアウトに失敗しました', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: const Text('マイページ'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            color: Colors.white,
            onSelected: (value) async {
              if (value == 'deleteAccount') {
                await _showAccountDeletionDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'deleteAccount',
                child: Text('アカウント削除'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MyPageTile(
                  title: 'お問い合わせ',
                  onTap: _openContactForm,
                ),
                _MyPageTile(
                  title: 'プライバシーポリシー',
                  onTap: _openPrivacyPolicyPage,
                ),
                const _MyPageTile(
                  title: 'アプリバージョン',
                  trailingText: '$_appVersion ($_appBuildNumber)',
                  showChevron: false,
                ),
                _MyPageTile(
                  title: 'お店を出る',
                  leadingIcon: Icons.storefront_outlined,
                  foregroundColor: Colors.redAccent,
                  isLoading: _isSigningOut,
                  loadingText: 'お店を出ています...',
                  showChevron: false,
                  onTap: _isSigningOut ? null : _showSignOutDialog,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountDeletionDialog extends StatefulWidget {
  const _AccountDeletionDialog({
    required this.email,
  });

  final String? email;

  @override
  State<_AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<_AccountDeletionDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      title: const Center(
        child: Text(
          'アカウント削除',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アカウントと保存済みの買い物リスト、タグを削除します。この操作は元に戻せません。',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (email != null && email.isNotEmpty) ...[
            const Gap(12),
            Text(
              email,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
          const Gap(20),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'パスワード',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: _passwordController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _passwordController.text,
                ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text('削除する'),
        ),
      ],
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        title: const Text('プライバシーポリシー'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Kaimono+ は、アプリの提供に必要な範囲で以下の情報を取り扱います。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              Gap(28),
              _PrivacyPolicySection(
                title: '取得する情報',
                body:
                    '・ログインに使用するメールアドレス\n'
                    '・作成した買い物リスト、タグ、ウィジェット表示設定\n'
                    '・お問い合わせ時にユーザーから提供された情報',
              ),
              _PrivacyPolicySection(
                title: '利用目的',
                body:
                    '・買い物リストやタグを保存・同期するため\n'
                    '・ログイン状態を管理するため\n'
                    '・お問い合わせへの対応や不具合調査のため',
              ),
              _PrivacyPolicySection(
                title: '外部サービス',
                body:
                    '本アプリでは、認証やデータ保存のため Firebase を利用します。'
                    'また、お問い合わせフォームの提供に Google フォームを利用します。',
              ),
              _PrivacyPolicySection(
                title: '第三者提供',
                body: '法令に基づく場合を除き、ユーザーの同意なく第三者へ個人情報を提供しません。',
              ),
              _PrivacyPolicySection(
                title: 'お問い合わせ',
                body: '本ポリシーに関するお問い合わせは、マイページの「お問い合わせ」からご連絡ください。',
              ),
              Text(
                '制定日: 2026年6月6日',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyPolicySection extends StatelessWidget {
  const _PrivacyPolicySection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPageTile extends StatelessWidget {
  const _MyPageTile({
    required this.title,
    this.leadingIcon,
    this.trailingText,
    this.foregroundColor,
    this.isLoading = false,
    this.loadingText,
    this.showChevron = true,
    this.onTap,
  });

  final String title;
  final IconData? leadingIcon;
  final String? trailingText;
  final Color? foregroundColor;
  final bool isLoading;
  final String? loadingText;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  color: color,
                  size: 24,
                ),
                const Gap(12),
              ],
              Expanded(
                child: Text(
                  isLoading ? loadingText ?? title : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                )
              else if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade500,
                  size: 30,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.currentIndex,
    required this.onSelectTab,
    required this.onCreateItem,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onCreateItem;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 96 + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 20,
            right: 20,
            bottom: 12 + bottomPadding,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(38),
              ),
              child: SizedBox(
                height: 76,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BottomNavigationItem(
                        icon: Icons.receipt_long_outlined,
                        label: '履歴',
                        isSelected: currentIndex == 0,
                        onTap: () => onSelectTab(0),
                      ),
                    ),
                    const SizedBox(width: 86),
                    Expanded(
                      child: _BottomNavigationItem(
                        icon: Icons.person_outline,
                        label: 'マイページ',
                        isSelected: currentIndex == 2,
                        onTap: () => onSelectTab(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 42 + bottomPadding,
            child: _CreateListButton(
              isSelected: currentIndex == 1,
              onTap: onCreateItem,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.amber.shade800 : Colors.black54;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const Gap(4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateListButton extends StatelessWidget {
  const _CreateListButton({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '買い物リスト',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.black87 : Colors.amber,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const SizedBox.square(
              dimension: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 26,
                  ),
                  Gap(2),
                  Text(
                    '作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
