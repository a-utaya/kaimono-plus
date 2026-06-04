import 'package:flutter/material.dart';

/// 共通 AppBar。白背景・戻るボタン・タイトルスタイルを統一する。
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.backgroundColor = Colors.amber,
    this.onBack,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final Color backgroundColor;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading:
          leading ??
          (automaticallyImplyLeading && canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : null),
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      actions: actions,
    );
  }
}
