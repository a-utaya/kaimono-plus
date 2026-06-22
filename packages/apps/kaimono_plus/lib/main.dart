import 'package:design_system/design_system.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'firebase_options.dart';
import 'pages/home_shell_page/home_shell_page.dart';
import 'pages/sign_in_page/sign_in_page.dart';
import 'pages/splash_page/animated_splash_page.dart';
import 'providers/authenticator_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      title: 'Kaimono+',
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

/// 起動時にスプラッシュを表示してから、認証状態に応じた画面を表示する
class _AuthGate extends HookConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowSplash = useState(true);
    final authState = ref.watch(authStateChangesProvider);

    if (shouldShowSplash.value) {
      return AnimatedSplashPage(
        onFinished: () => shouldShowSplash.value = false,
      );
    }

    return authState.when(
      data: (user) => user == null ? const SignInPage() : const HomeShellPage(),
      error: (_, _) => const SignInPage(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
