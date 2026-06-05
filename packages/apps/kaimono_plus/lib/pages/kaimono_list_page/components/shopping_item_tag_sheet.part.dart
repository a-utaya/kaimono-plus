part of '../kaimono_list_page.dart';

const _shoppingItemTagPaletteColors = [
  Color(0xFF81C784),
  Color(0xFFFF8A65),
  Color(0xFF64B5F6),
  Color(0xFFFFB300),
  Color(0xFFBA68C8),
  Color(0xFFA1887F),
];

class ShoppingItemTagSheet extends HookConsumerWidget {
  const ShoppingItemTagSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(kaimonoListPageViewModelProvider);
    final notifier = ref.read(kaimonoListPageViewModelProvider.notifier);
    final newTagController = useTextEditingController();
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final selectedColor = useState<Color?>(null);
    final isCreating = useState(false);

    useEffect(() {
      void listener() {
        searchQuery.value = searchController.text.trim();
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    final filteredTags = [
      for (final tag in listState.shoppingItemTags)
        if (searchQuery.value.isEmpty || tag.name.contains(searchQuery.value))
          tag,
    ];
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    Future<void> createTag() async {
      if (isCreating.value) return;
      isCreating.value = true;
      try {
        final created = await notifier.createShoppingItemTag(
          newTagController.text,
          colorValue: selectedColor.value?.toARGB32(),
        );
        if (!created) {
          showAppSnackBar(context, 'タグ名を確認してください', isError: true);
          return;
        }
      } catch (_) {
        showAppSnackBar(
          context,
          'タグを保存できませんでした。Firestore の権限を確認してください。',
          isError: true,
        );
        return;
      } finally {
        isCreating.value = false;
      }
      newTagController.clear();
      selectedColor.value = null;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.heightOf(context) * 0.82,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'タグから追加',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // タグ検索
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'タグを検索',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // 新規タグ作成
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newTagController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => unawaited(createTag()),
                          decoration: const InputDecoration(
                            hintText: 'タグ名を入力',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.sell_outlined),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: isCreating.value
                            ? null
                            : () => unawaited(createTag()),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                        ),
                        child: isCreating.value
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '作成',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in _shoppingItemTagPaletteColors)
                        _ShoppingItemTagColorButton(
                          color: color,
                          isSelected: selectedColor.value == color,
                          onTap: () {
                            selectedColor.value = selectedColor.value == color
                                ? null
                                : color;
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 登録済みタグ
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '登録済みタグ',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${filteredTags.length}件',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'タグを長押しすると編集できます',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: filteredTags.isEmpty
                    ? _ShoppingItemTagEmptyState(
                        hasQuery: searchQuery.value.isNotEmpty,
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final tag in filteredTags)
                            _ShoppingItemTagChip(
                              tag: tag,
                              onTap: () => notifier.addItemFromTag(tag),
                              onLongPress: () =>
                                  _openShoppingItemTagDetailPage(context, tag),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingItemTagChip extends StatelessWidget {
  const _ShoppingItemTagChip({
    required this.tag,
    required this.onTap,
    required this.onLongPress,
  });

  final ShoppingItemTag tag;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorValue = tag.colorValue;
    final color = colorValue == null ? null : Color(colorValue);
    final borderColor = color ?? Colors.black.withValues(alpha: 0.24);
    final backgroundColor = color == null
        ? Colors.white
        : color.withValues(alpha: 0.08);
    final maxTextWidth = MediaQuery.widthOf(context) - 132;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: StadiumBorder(
            side: BorderSide(color: borderColor),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTextWidth),
          child: Text(
            tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoppingItemTagColorButton extends StatelessWidget {
  const _ShoppingItemTagColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.5),
            width: isSelected ? 3 : 1.4,
          ),
        ),
        child: isSelected ? Icon(Icons.check, color: color, size: 18) : null,
      ),
    );
  }
}

class _ShoppingItemTagEmptyState extends StatelessWidget {
  const _ShoppingItemTagEmptyState({
    required this.hasQuery,
  });

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            hasQuery ? Icons.search_off_outlined : Icons.sell_outlined,
            color: Colors.black26,
            size: 36,
          ),
          const Gap(12),
          Text(
            hasQuery ? '一致するタグがありません' : 'タグはまだありません',
            style: const TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingItemTagDetailPage extends HookConsumerWidget {
  const ShoppingItemTagDetailPage({
    required this.tag,
    super.key,
  });

  final ShoppingItemTag tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTag =
        ref
            .watch(kaimonoListPageViewModelProvider)
            .shoppingItemTags
            .where((element) => element.id == tag.id)
            .firstOrNull ??
        tag;
    final nameController = useTextEditingController(text: currentTag.name);
    final selectedColor = useState<Color?>(
      currentTag.colorValue == null ? null : Color(currentTag.colorValue!),
    );
    final isSaving = useState(false);
    final isDeleting = useState(false);

    Future<void> save() async {
      if (isSaving.value) return;
      isSaving.value = true;
      try {
        final updated = await ref
            .read(kaimonoListPageViewModelProvider.notifier)
            .updateShoppingItemTag(
              id: currentTag.id,
              name: nameController.text,
              colorValue: selectedColor.value?.toARGB32(),
            );
        if (!updated) {
          showAppSnackBar(context, 'タグ名を確認してください', isError: true);
          return;
        }
      } catch (_) {
        showAppSnackBar(
          context,
          'タグを保存できませんでした。Firestore の権限を確認してください。',
          isError: true,
        );
        return;
      } finally {
        isSaving.value = false;
      }
      Navigator.of(context).pop();
    }

    void confirmDelete() {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => ConfirmDialog(
          title: 'タグを削除',
          content: '「${currentTag.name}」を削除しますか？',
          confirmText: '削除',
          isDestructive: true,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            if (isDeleting.value) return;
            isDeleting.value = true;
            Navigator.of(dialogContext).pop();
            unawaited(
              ref
                  .read(kaimonoListPageViewModelProvider.notifier)
                  .deleteShoppingItemTag(currentTag.id)
                  .then((_) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  })
                  .catchError((Object error, StackTrace stackTrace) {
                    if (!context.mounted) return;
                    showAppSnackBar(
                      context,
                      'タグを削除できませんでした。Firestore の権限を確認してください。',
                      isError: true,
                    );
                    isDeleting.value = false;
                  }),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'タグを編集',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: isSaving.value ? null : () => unawaited(save()),
            child: isSaving.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'タグの色',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in _shoppingItemTagPaletteColors)
                          _ShoppingItemTagColorButton(
                            color: color,
                            isSelected: selectedColor.value == color,
                            onTap: () {
                              selectedColor.value = selectedColor.value == color
                                  ? null
                                  : color;
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'タグ名',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(12),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'タグ名を入力',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.sell_outlined),
                          suffixIcon: IconButton(
                            onPressed: nameController.clear,
                            icon: const Icon(Icons.cancel),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.18),
                              width: 0.8,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.14),
                              width: 0.8,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.amber.shade700,
                              width: 1,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => unawaited(save()),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(24),
              OutlinedButton(
                onPressed: isDeleting.value ? null : confirmDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isDeleting.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline),
                          Gap(8),
                          Text('タグを削除'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _openShoppingItemTagDetailPage(
  BuildContext context,
  ShoppingItemTag tag,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShoppingItemTagDetailPage(tag: tag),
    ),
  );
}
