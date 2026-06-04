import 'models/auth_user.dart';

/// メール/パスワード認証とユーザープロフィール保存の抽象
abstract class Authenticator {
  /// ログイン状態の変化（未ログインは null）
  Stream<AuthUser?> get authStateChanges;

  /// サインイン。成功時は [AuthUser] を返す
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// 新規登録と Firestore への初期ユーザードキュメント作成
  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// サインアウト
  Future<void> signOut();

  /// パスワード再設定用の認証コード（6桁）をメール送信する
  Future<void> sendPasswordResetCode({required String email});

  /// 認証コードを検証し、新しいパスワードを設定する
  Future<void> confirmPasswordResetWithCode({
    required String email,
    required String code,
    required String newPassword,
  });
}
