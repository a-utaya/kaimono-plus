import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_page_view_model.g.dart';

/// サインイン画面の状態
class SignInState {
  const SignInState({this.isLoading = false});

  final bool isLoading;

  SignInState copyWith({bool? isLoading}) =>
      SignInState(isLoading: isLoading ?? this.isLoading);
}

@riverpod
class SignInPageViewModel extends _$SignInPageViewModel {
  @override
  SignInState build() => const SignInState();

  /// サインインを実行する。
  /// 成功時は null、失敗時は表示用のエラーメッセージを返す。
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Firestore への保存に失敗しました。コンソールのセキュリティルールを確認してください。';
      }

      final msg = e.message ?? '';
      if (msg.contains('connection on channel') ||
          msg.contains('UNAVAILABLE')) {
        return '通信に失敗しました。ネットワークを確認して、しばらく経ってから再度お試しください。';
      }
      return 'サインインに失敗しました: $msg';
    } finally {
      state = state.copyWith(isLoading: false);
    }
    return null;
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
