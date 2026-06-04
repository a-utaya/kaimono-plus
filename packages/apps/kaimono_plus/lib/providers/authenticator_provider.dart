import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ全体で共有する [Authenticator]（Firebase 実装）
final authenticatorProvider = Provider<Authenticator>(
  (ref) => FirebaseAuthenticator(),
);

/// 認証状態の変更をアプリ全体で購読する [StreamProvider]。
final authStateChangesProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authenticatorProvider).authStateChanges,
);
