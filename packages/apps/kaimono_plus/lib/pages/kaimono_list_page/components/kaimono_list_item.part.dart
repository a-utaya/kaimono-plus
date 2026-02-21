part of '../kaimono_list_page.dart';

class KaimonoListItem extends StatelessWidget {
  const KaimonoListItem({
    required this.item,
    required this.isEditing,
    required this.controller,
    required this.viewModel,
    super.key,
  });

  final KaimonoItem item;
  final bool isEditing;
  final TextEditingController controller;
  final KaimonoListPageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
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
              padding: const EdgeInsets.only(left: 16.0),
              child: InkWell(
                onTap: () {
                  vm.toggleItem(item.id);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: isEditing
                    ? TextField(
                        controller: controller,
                        cursorColor: Colors.amber,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 16, height: 1.5),
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
              icon: Icon(Icons.cancel, color: Colors.grey[400], size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
