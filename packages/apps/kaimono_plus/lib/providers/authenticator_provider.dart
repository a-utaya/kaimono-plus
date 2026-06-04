import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ全体で共有する Firebase 認証実装。
final authenticatorProvider = Provider<FirebaseAuthenticator>(
  (ref) => FirebaseAuthenticator(),
);

/// 認証状態の変更をアプリ全体で購読する [StreamProvider]。
final authStateChangesProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authenticatorProvider).authStateChanges,
);
