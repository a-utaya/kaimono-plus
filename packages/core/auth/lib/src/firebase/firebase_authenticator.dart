import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../authenticator.dart';
import '../exceptions/auth_exception.dart';
import '../models/auth_user.dart';

/// Firebase Auth / Firestore / Cloud Functions を用いた [Authenticator] 実装
class FirebaseAuthenticator implements Authenticator {
  FirebaseAuthenticator({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _maxRetries = 3;
  static const _retryDelay = Duration(milliseconds: 800);

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAuthUser);

  @override
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

  @override
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

      final authUser = _toAuthUser(user)!;
      await _saveUserToFirestoreWithRetry(
        uid: authUser.uid,
        email: authUser.email ?? email.trim(),
      );
      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_signUpErrorMessage(e.code), code: e.code);
    } on FirebaseException catch (e) {
      throw AuthException(_firestoreErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
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

  @override
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

  Future<void> _saveUserToFirestoreWithRetry({
    required String uid,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    FirebaseException? lastError;
    for (var i = 0; i < _maxRetries; i++) {
      try {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      } on FirebaseException catch (e) {
        lastError = e;
        if (i < _maxRetries - 1) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }
    if (lastError != null) {
      throw AuthException(_firestoreErrorMessage(lastError));
    }
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

  String _firestoreErrorMessage(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Firestore への保存に失敗しました。コンソールのセキュリティルールを確認してください。';
    }
    final msg = e.message ?? '';
    if (msg.contains('connection on channel') || msg.contains('UNAVAILABLE')) {
      return '通信に失敗しました。ネットワークを確認して、しばらく経ってから再度お試しください。';
    }
    return '登録に失敗しました: $msg';
  }

  String _signInErrorMessage(String code) {
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
