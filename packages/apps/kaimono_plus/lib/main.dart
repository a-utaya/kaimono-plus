import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'pages/kaimono_list_page/kaimono_list_page.dart';
import 'pages/sign_in_page/sign_in_page.dart';
import 'providers/authenticator_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 開発中: Keychain に残ったログイン状態を毎回クリアする（不要になったら削除）
  if (kDebugMode) {
    await FirebaseAuth.instance.signOut();
  }
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaimono Plus',
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

/// 起動時に認証状態を確認し、ログイン済みならリスト画面・未ログインならログイン画面を表示する
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticatorProvider).authStateChanges;

    return StreamBuilder<AuthUser?>(
      stream: authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const KaimonoListPage();
        }
        return const SignInPage();
      },
    );
  }
}
