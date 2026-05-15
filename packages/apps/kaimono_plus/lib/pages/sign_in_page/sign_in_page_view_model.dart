import 'package:auth/auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/authenticator_provider.dart';

part 'sign_in_page_view_model.g.dart';

@riverpod
class SignInPageViewModel extends _$SignInPageViewModel {
  @override
  Future<void> build() async {}

  /// サインインを実行する
  /// 成功時は [AsyncData]、失敗時は [SignInException] を含む [AsyncError]
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(authenticatorProvider).signInWithEmailAndPassword(
              email: email,
              password: password,
            );
      } on AuthException catch (e) {
        throw SignInException(e.message);
      }
    });
  }

  /// エラー表示後などにアイドル状態へ戻す
  void reset() {
    state = const AsyncData(null);
  }
}

/// サインイン失敗時に [AsyncError] へ載せる例外（表示用メッセージを保持）
class SignInException implements Exception {
  const SignInException(this.message);

  final String message;

  @override
  String toString() => message;
}
