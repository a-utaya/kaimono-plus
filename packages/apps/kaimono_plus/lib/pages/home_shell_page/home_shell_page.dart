import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ShoppingListHistoryPage(),
          KaimonoListPage(showFloatingActionButton: false),
          MyPage(),
        ],
      ),
      bottomNavigationBar: _HomeBottomNavigationBar(
        currentIndex: _currentIndex,
        onSelectTab: _selectTab,
        onCreateItem: _createShoppingListItem,
      ),
    );
  }
}

class ShoppingListHistoryPage extends StatelessWidget {
  const ShoppingListHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('履歴'),
      ),
      body: Container(
        width: double.infinity,
        color: Colors.grey[100],
        child: const SafeArea(
          child: Center(
            child: Text(
              'まだ履歴はありません',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  bool _isSigningOut = false;

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
    final email = ref
        .watch(authStateChangesProvider)
        .when(
          data: (user) => user?.email,
          error: (_, _) => null,
          loading: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('マイページ'),
      ),
      body: Container(
        width: double.infinity,
        color: Colors.grey[100],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.amber.shade100,
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Text(
                            email ?? 'ログイン中',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                OutlinedButton.icon(
                  onPressed: _isSigningOut ? null : _showSignOutDialog,
                  icon: _isSigningOut
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.storefront_outlined),
                  label: Text(
                    _isSigningOut ? 'お店を出ています...' : 'お店を出る（ログアウト）',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(38),
              ),
              child: SizedBox(
                height: 76,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BottomNavigationItem(
                        icon: Icons.history,
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
