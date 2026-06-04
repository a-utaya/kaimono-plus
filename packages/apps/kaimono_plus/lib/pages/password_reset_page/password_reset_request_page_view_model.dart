import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authenticator_provider.dart';

/// パスワード再設定（認証コード送信）画面の状態
@immutable
class PasswordResetRequestState {
  const PasswordResetRequestState({
    this.isLoading = false,
    this.emailError,
    this.snackBarError,
  });

  final bool isLoading;
  final String? emailError;
  final String? snackBarError;

  PasswordResetRequestState copyWith({
    bool? isLoading,
    String? emailError,
    bool clearEmailError = false,
    String? snackBarError,
    bool clearSnackBarError = false,
  }) {
    return PasswordResetRequestState(
      isLoading: isLoading ?? this.isLoading,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      snackBarError: clearSnackBarError
          ? null
          : (snackBarError ?? this.snackBarError),
    );
  }
}

final passwordResetRequestPageViewModelProvider =
    NotifierProvider.autoDispose<
      PasswordResetRequestPageNotifier,
      PasswordResetRequestState
    >(PasswordResetRequestPageNotifier.new);

class PasswordResetRequestPageNotifier
    extends Notifier<PasswordResetRequestState> {
  @override
  PasswordResetRequestState build() => const PasswordResetRequestState();

  void clearEmailError() {
    if (state.emailError == null) return;
    state = state.copyWith(clearEmailError: true);
  }

  void clearSnackBarError() {
    if (state.snackBarError == null) return;
    state = state.copyWith(clearSnackBarError: true);
  }

  /// 認証コード付きメールを送信する。成功時は true。
  Future<bool> sendPasswordResetCode({required String email}) async {
    final validationError = _validate(email);
    if (validationError != null) {
      state = state.copyWith(
        emailError: validationError,
        clearSnackBarError: true,
      );
      return false;
    }

    state = state.copyWith(
      clearEmailError: true,
      clearSnackBarError: true,
      isLoading: true,
    );

    try {
      await ref.read(authenticatorProvider).sendPasswordResetCode(email: email);
      return true;
    } on AuthException catch (e) {
      if (e.code == 'invalid-email') {
        state = state.copyWith(emailError: e.message);
      } else {
        state = state.copyWith(snackBarError: e.message);
      }
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String? _validate(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed)) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }
}
