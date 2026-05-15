import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ全体で共有する [Authenticator]（Firebase 実装）
final authenticatorProvider = Provider<Authenticator>(
  (ref) => FirebaseAuthenticator(),
);
