import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/authenticator_provider.dart';

@immutable
class PasswordResetConfirmationState {
  const PasswordResetConfirmationState({
    this.isLoading = false,
    this.codeError,
    this.passwordError,
    this.passwordConfirmError,
    this.snackBarError,
  });

  final bool isLoading;
  final String? codeError;
  final String? passwordError;
  final String? passwordConfirmError;
  final String? snackBarError;

  PasswordResetConfirmationState copyWith({
    bool? isLoading,
    String? codeError,
    bool clearCodeError = false,
    String? passwordError,
    bool clearPasswordError = false,
    String? passwordConfirmError,
    bool clearPasswordConfirmError = false,
    String? snackBarError,
    bool clearSnackBarError = false,
  }) {
    return PasswordResetConfirmationState(
      isLoading: isLoading ?? this.isLoading,
      codeError: clearCodeError ? null : (codeError ?? this.codeError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      passwordConfirmError: clearPasswordConfirmError
          ? null
          : (passwordConfirmError ?? this.passwordConfirmError),
      snackBarError: clearSnackBarError
          ? null
          : (snackBarError ?? this.snackBarError),
    );
  }
}

final passwordResetConfirmationPageViewModelProvider =
    NotifierProvider.autoDispose<
      PasswordResetConfirmationPageNotifier,
      PasswordResetConfirmationState
    >(PasswordResetConfirmationPageNotifier.new);

class PasswordResetConfirmationPageNotifier
    extends Notifier<PasswordResetConfirmationState> {
  @override
  PasswordResetConfirmationState build() =>
      const PasswordResetConfirmationState();

  void clearCodeError() {
    if (state.codeError == null) return;
    state = state.copyWith(clearCodeError: true);
  }

  void clearPasswordError() {
    if (state.passwordError == null) return;
    state = state.copyWith(clearPasswordError: true);
  }

  void clearPasswordConfirmError() {
    if (state.passwordConfirmError == null) return;
    state = state.copyWith(clearPasswordConfirmError: true);
  }

  void clearSnackBarError() {
    if (state.snackBarError == null) return;
    state = state.copyWith(clearSnackBarError: true);
  }

  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    final validationError = _validate(code, password, passwordConfirm);
    if (validationError != null) {
      state = state.copyWith(
        codeError: validationError.codeError,
        passwordError: validationError.passwordError,
        passwordConfirmError: validationError.passwordConfirmError,
        clearSnackBarError: true,
      );
      return false;
    }

    state = state.copyWith(
      clearCodeError: true,
      clearPasswordError: true,
      clearPasswordConfirmError: true,
      clearSnackBarError: true,
      isLoading: true,
    );

    try {
      await ref.read(authenticatorProvider).confirmPasswordResetWithCode(
            email: email,
            code: code,
            newPassword: password,
          );
      return true;
    } on AuthException catch (e) {
      if (e.code == 'weak-password') {
        state = state.copyWith(passwordError: e.message);
      } else if (e.code == 'invalid-verification-code' ||
          e.code == 'expired-verification-code' ||
          e.code == 'too-many-requests') {
        state = state.copyWith(codeError: e.message);
      } else {
        state = state.copyWith(snackBarError: e.message);
      }
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  _PasswordValidationErrors? _validate(
    String code,
    String password,
    String passwordConfirm,
  ) {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      return const _PasswordValidationErrors(
        codeError: '認証コードを入力してください',
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      return const _PasswordValidationErrors(
        codeError: '認証コードは6桁の数字で入力してください',
      );
    }
    if (password.isEmpty) {
      return const _PasswordValidationErrors(
        passwordError: 'パスワードを入力してください',
      );
    }
    if (password.length < 6) {
      return const _PasswordValidationErrors(
        passwordError: 'パスワードは6文字以上で入力してください',
      );
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return const _PasswordValidationErrors(
        passwordError: 'パスワードは英字を1文字以上含めてください',
      );
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return const _PasswordValidationErrors(
        passwordError: 'パスワードは数字を1文字以上含めてください',
      );
    }
    if (passwordConfirm.isEmpty) {
      return const _PasswordValidationErrors(
        passwordConfirmError: 'パスワード（確認用）を入力してください',
      );
    }
    if (password != passwordConfirm) {
      return const _PasswordValidationErrors(
        passwordConfirmError: 'パスワードが一致しません',
      );
    }
    return null;
  }
}

@immutable
class _PasswordValidationErrors {
  const _PasswordValidationErrors({
    this.codeError,
    this.passwordError,
    this.passwordConfirmError,
  });

  final String? codeError;
  final String? passwordError;
  final String? passwordConfirmError;
}
