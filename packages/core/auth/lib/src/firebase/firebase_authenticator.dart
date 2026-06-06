import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../exceptions/auth_exception.dart';
import '../models/auth_user.dart';

/// Firebase Auth / Cloud Functions を用いた認証実装。
class FirebaseAuthenticator {
  FirebaseAuthenticator({
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAuthUser);

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('サインインに失敗しました');
      }
      return _toAuthUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_signInErrorMessage(e.code), code: e.code);
    }
  }

  Future<AuthUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('登録に失敗しました。しばらく経ってからお試しください');
      }

      return _toAuthUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_signUpErrorMessage(e.code), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetCode({required String email}) async {
    try {
      await _functions.httpsCallable('sendPasswordResetCode').call<void>({
        'email': email.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        _passwordResetFunctionsMessage(e),
        code: _passwordResetAuthCode(e),
      );
    }
  }

  Future<void> confirmPasswordResetWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _functions.httpsCallable('confirmPasswordResetWithCode').call<void>(
        {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        _passwordResetFunctionsMessage(e),
        code: _passwordResetAuthCode(e),
      );
    }
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }

  String? _passwordResetAuthCode(FirebaseFunctionsException e) {
    final details = e.details;
    if (details is Map) {
      final authCode = details['authCode'];
      if (authCode is String && authCode.isNotEmpty) {
        return authCode;
      }
    }
    return e.code;
  }

  String _passwordResetFunctionsMessage(FirebaseFunctionsException e) {
    if (e.code == 'permission-denied') {
      return 'パスワード再設定用の Cloud Functions を呼び出せません。Cloud Run の呼び出し権限を確認してください。';
    }
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    switch (e.code) {
      case 'invalid-argument':
        return '入力内容を確認してください';
      case 'resource-exhausted':
        return '試行回数の上限に達しました。再度認証コードを送信してください';
      case 'unavailable':
        return '通信に失敗しました。しばらく経ってからお試しください';
      default:
        return 'パスワードの再設定に失敗しました';
    }
  }

  String _signInErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
      case 'invalid-credential':
      case 'wrong-password':
        return 'メールアドレスまたはパスワードが間違っています';
      case 'network-request-failed':
        return '通信に失敗しました。ネットワーク接続を確認してください';
      case 'user-disabled':
        return 'アカウントが無効です';
      case 'user-not-found':
        return 'アカウントが見つかりません';
      default:
        return 'サインインに失敗しました';
    }
  }

  String _signUpErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードは6文字以上の英数字（英字と数字の両方を含む）で設定してください';
      case 'operation-not-allowed':
        return 'メール/パスワード認証が有効になっていません';
      default:
        return '登録に失敗しました。しばらく経ってからお試しください';
    }
  }
}
