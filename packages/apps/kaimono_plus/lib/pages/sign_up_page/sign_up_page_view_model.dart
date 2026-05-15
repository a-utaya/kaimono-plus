import 'package:auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/authenticator_provider.dart';

part 'sign_up_page_view_model.g.dart';

/// サインアップ画面の状態
@immutable
class SignUpState extends Equatable {
  const SignUpState({this.isLoading = false});

  final bool isLoading;

  @override
  List<Object?> get props => [isLoading];

  SignUpState copyWith({bool? isLoading}) =>
      SignUpState(isLoading: isLoading ?? this.isLoading);
}

@riverpod
class SignUpPageViewModel extends _$SignUpPageViewModel {
  @override
  SignUpState build() => const SignUpState();

  /// 新規登録を実行する。
  /// 成功時は null、失敗時は表示用のエラーメッセージを返す。
  Future<String?> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final validationError = _validate(email, password, passwordConfirm);
    if (validationError != null) return validationError;

    state = state.copyWith(isLoading: true);

    try {
      await ref.read(authenticatorProvider).signUpWithEmailAndPassword(
            email: email,
            password: password,
          );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String? _validate(String email, String password, String passwordConfirm) {
    if (email.trim().isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (password.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (password.length < 6) {
      return 'パスワードは6文字以上で入力してください';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'パスワードは英字を1文字以上含めてください';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'パスワードは数字を1文字以上含めてください';
    }
    if (password != passwordConfirm) {
      return 'パスワードが一致しません';
    }
    return null;
  }
}
