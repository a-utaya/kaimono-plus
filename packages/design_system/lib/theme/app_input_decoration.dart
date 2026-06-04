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

  static InputDecoration emailDecoration({String? errorText}) =>
      authOutlined.copyWith(
        labelText: 'メールアドレス',
        errorText: errorText,
      );

  static InputDecoration passwordDecoration({
    String labelText = 'パスワード',
    String? errorText,
    Widget? suffixIcon,
  }) => authOutlined.copyWith(
    labelText: labelText,
    errorText: errorText,
    suffixIcon: suffixIcon,
  );

  static InputDecoration codeDecoration({String? errorText}) =>
      authOutlined.copyWith(
        labelText: '認証コード（6桁）',
        errorText: errorText,
      );
}
