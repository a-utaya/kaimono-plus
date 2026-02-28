import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.content,
    this.cancelText = 'キャンセル',
    required this.confirmText,

    /// true のとき確認ボタンを赤系で表示する（削除など危険な操作向け）。
    this.isDestructive = false,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final bool isDestructive;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      title: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(content),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: onConfirm,
              style: isDestructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text(confirmText),
            ),
          ],
        ),
      ],
    );
  }
}
