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
    final searchQuery = useState('');
    final selectedColor = useState<Color?>(null);
    final selectedTagIds = useState<List<String>>(const []);
    final isCreating = useState(false);

    useEffect(() {
      void listener() {
        searchQuery.value = newTagController.text.trim();
      }

      newTagController.addListener(listener);
      return () => newTagController.removeListener(listener);
    }, [newTagController]);

    final tagById = {
      for (final tag in listState.shoppingItemTags) tag.id: tag,
    };
    final selectedTags = [
      for (final id in selectedTagIds.value)
        if (tagById[id] != null) tagById[id]!,
    ];
    final selectedTagIdSet = selectedTags.map((tag) => tag.id).toSet();
    final filteredTags = [
      for (final tag in listState.shoppingItemTags)
        if (!selectedTagIdSet.contains(tag.id) &&
            (searchQuery.value.isEmpty || tag.name.contains(searchQuery.value)))
          tag,
    ]..sort(_compareShoppingItemTags);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    void toggleSelectedTag(ShoppingItemTag tag) {
      final nextIds = [...selectedTagIds.value];
      if (!nextIds.remove(tag.id)) {
        nextIds.add(tag.id);
      }
      selectedTagIds.value = nextIds;
    }

    void addSelectedTags() {
      if (selectedTags.isEmpty) return;
      notifier.addItemsFromTags(selectedTags);
      selectedTagIds.value = const [];
      Navigator.of(context).pop();
    }

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
                            hintText: 'タグ名を入力・検索',
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
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '選択したもの',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(10),
                  if (selectedTags.isEmpty)
                    const SizedBox(
                      height: 48,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '未選択',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final tag in selectedTags)
                          _SelectedShoppingItemTagChip(
                            tag: tag,
                            onRemove: () => toggleSelectedTag(tag),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                              isSelected: selectedTagIdSet.contains(tag.id),
                              onTap: () => toggleSelectedTag(tag),
                              onLongPress: () =>
                                  _openShoppingItemTagDetailPage(context, tag),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: selectedTags.isEmpty ? null : addSelectedTags,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: Text(
                selectedTags.isEmpty ? 'タグを選択' : '${selectedTags.length}件を追加',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _compareShoppingItemTags(ShoppingItemTag a, ShoppingItemTag b) {
  final colorComparison = _shoppingItemTagColorOrder(
    a.colorValue,
  ).compareTo(_shoppingItemTagColorOrder(b.colorValue));
  if (colorComparison != 0) return colorComparison;

  final categoryComparison = _shoppingItemTagNameCategory(
    a.name,
  ).compareTo(_shoppingItemTagNameCategory(b.name));
  if (categoryComparison != 0) return categoryComparison;

  final nameComparison = _shoppingItemTagSortText(
    a.name,
  ).compareTo(_shoppingItemTagSortText(b.name));
  if (nameComparison != 0) return nameComparison;

  return a.id.compareTo(b.id);
}

int _shoppingItemTagColorOrder(int? colorValue) {
  if (colorValue == null) return _shoppingItemTagPaletteColors.length + 1;

  final paletteIndex = _shoppingItemTagPaletteColors.indexWhere(
    (color) => color.toARGB32() == colorValue,
  );
  if (paletteIndex >= 0) return paletteIndex;

  return _shoppingItemTagPaletteColors.length;
}

int _shoppingItemTagNameCategory(String name) {
  final text = name.trimLeft();
  if (text.isEmpty) return 3;

  final firstRune = text.runes.first;
  if (_isKanaRune(firstRune)) return 0;
  if (_isKanjiRune(firstRune)) return 1;
  if (_isAsciiLetterRune(firstRune)) return 2;
  return 3;
}

String _shoppingItemTagSortText(String name) {
  final text = name.trim().toLowerCase();
  return String.fromCharCodes(text.runes.map(_katakanaToHiraganaRune));
}

int _katakanaToHiraganaRune(int rune) {
  if (rune < 0x30A1 || rune > 0x30F6) return rune;
  return rune - 0x60;
}

bool _isKanaRune(int rune) {
  return (rune >= 0x3041 && rune <= 0x3096) ||
      (rune >= 0x30A1 && rune <= 0x30FA);
}

bool _isKanjiRune(int rune) {
  return (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0x3400 && rune <= 0x4DBF);
}

bool _isAsciiLetterRune(int rune) {
  return (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
}

class _ShoppingItemTagChip extends StatelessWidget {
  const _ShoppingItemTagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final ShoppingItemTag tag;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorValue = tag.colorValue;
    final color = colorValue == null ? null : Color(colorValue);
    final selectedColor = color ?? Colors.grey.shade600;
    final borderColor = isSelected
        ? selectedColor
        : color ?? Colors.black.withValues(alpha: 0.24);
    final backgroundColor = color == null
        ? Colors.white
        : color.withValues(alpha: isSelected ? 0.16 : 0.08);
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
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
            if (isSelected) ...[
              const Gap(6),
              Icon(Icons.check_circle, color: selectedColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedShoppingItemTagChip extends StatelessWidget {
  const _SelectedShoppingItemTagChip({
    required this.tag,
    required this.onRemove,
  });

  final ShoppingItemTag tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorValue = tag.colorValue;
    final color = colorValue == null ? Colors.grey.shade600 : Color(colorValue);
    final maxTextWidth = MediaQuery.widthOf(context) - 150;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: StadiumBorder(
          side: BorderSide(color: color),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxTextWidth),
            child: Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Gap(4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Icon(Icons.cancel, color: color, size: 18),
          ),
        ],
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
        width: 24,
        height: 24,
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
