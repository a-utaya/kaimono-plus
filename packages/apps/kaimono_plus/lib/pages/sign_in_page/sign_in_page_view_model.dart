import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );

        if (credential.user == null) {
          throw const SignInException('サインインに失敗しました');
        }
      } on FirebaseAuthException catch (e) {
        throw SignInException(_authErrorMessage(e.code));
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw const SignInException(
            'Firestore への保存に失敗しました。コンソールのセキュリティルールを確認してください。',
          );
        }

        final message = e.message ?? '';
        if (message.contains('connection on channel') ||
            message.contains('UNAVAILABLE')) {
          throw const SignInException(
            '通信に失敗しました。ネットワークを確認して、しばらく経ってから再度お試しください。',
          );
        }
        throw SignInException('サインインに失敗しました: $message');
      }
    });
  }

  /// エラー表示後などにアイドル状態へ戻す
  void reset() {
    state = const AsyncData(null);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
      case 'wrong-password':
        return 'メールアドレスまたはパスワードが間違っています';
      case 'user-disabled':
        return 'アカウントが無効です';
      case 'user-not-found':
        return 'アカウントが見つかりません';
      default:
        return 'サインインに失敗しました';
    }
  }
}

/// サインイン失敗時に [AsyncError] へ載せる例外（表示用メッセージを保持）
class SignInException implements Exception {
  const SignInException(this.message);

  final String message;

  @override
  String toString() => message;
}
