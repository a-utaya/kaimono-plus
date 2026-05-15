import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../authenticator.dart';
import '../exceptions/auth_exception.dart';
import '../models/auth_user.dart';

/// Firebase Auth / Firestore を用いた [Authenticator] 実装
class FirebaseAuthenticator implements Authenticator {
  FirebaseAuthenticator({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
