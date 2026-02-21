import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

final signUpPageViewModelProvider =
    ChangeNotifierProvider.autoDispose<SignUpPageViewModel>(
      (ref) => SignUpPageViewModel(),
    );

class SignUpPageViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 新規登録を実行する。
  /// 成功時は null、失敗時は表示用のエラーメッセージを返す。
  Future<String?> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final validationError = _validate(email, password, passwordConfirm);
    if (validationError != null) {
      return validationError;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final user = credential.user;

      if (user != null) {
        await _saveUserToFirestoreWithRetry(
          uid: user.uid,
          email: user.email ?? email.trim(),
        );
      }
      return null;
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
      return '登録に失敗しました: $msg';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static const _maxRetries = 3;
  static const _retryDelay = Duration(milliseconds: 800);

  Future<void> _saveUserToFirestoreWithRetry({
    required String uid,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    FirebaseException? lastError;
    for (var i = 0; i < _maxRetries; i++) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
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
    if (lastError != null) throw lastError;
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

  String _authErrorMessage(String code) {
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
