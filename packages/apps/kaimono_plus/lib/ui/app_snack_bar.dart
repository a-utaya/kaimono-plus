import 'package:flutter/material.dart';

/// アプリ全体で共通の SnackBar 表示用ヘルパー。
/// 既存の SnackBar を隠してから新しいメッセージを表示する。
void showAppSnackBar(
  BuildContext context,
  String message, {

  /// true のとき背景を赤にしてエラー表示とする。
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}
