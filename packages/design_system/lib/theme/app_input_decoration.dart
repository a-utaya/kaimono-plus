import 'package:flutter/material.dart';

/// 認証フォームなどで共用するテキストフィールドのベースとなる装飾。
/// [labelText] などは [InputDecoration.copyWith] で付与する。
class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration get authOutlined => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.amber),
    ),
  );
}
