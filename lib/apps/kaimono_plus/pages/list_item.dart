class ListItem {
  final String id;
  final String text;
  bool isCompleted;

  ListItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });
}
