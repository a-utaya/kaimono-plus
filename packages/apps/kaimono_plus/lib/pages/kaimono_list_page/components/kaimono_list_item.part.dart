class KaimonoListItem {
  final String id;
  final String text;
  bool isCompleted;

  KaimonoListItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
}
