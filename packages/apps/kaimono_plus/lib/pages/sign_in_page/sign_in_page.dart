import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ sign_up_page/sign_up_page.dart';
import '../../ui/app_snack_bar.dart';
import '../kaimono_list_page/kaimono_list_page.dart';
import '../password_reset_page/password_reset_page.dart';
import 'sign_in_page_view_model.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SignInPageContent();
  }
}

class _SignInPageContent extends HookConsumerWidget {
  const _SignInPageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch<SignInState>(signInPageViewModelProvider);
    final notifier = ref.read<SignInPageViewModel>(
      signInPageViewModelProvider.notifier,
    );

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);

    /// ログインボタン押下時の処理
    Future<void> handleSignIn() async {
      final message = await notifier.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!context.mounted) return;

      if (message == null) {
        // リスト画面へ入場後はログイン画面に戻らないよう push ではなく pushReplacement で差し替える
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const KaimonoListPage(),
          ),
        );
      } else {
        showAppSnackBar(context, message, isError: true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Kaimono+'),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        color: Colors.grey[50],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(32),
                const Text(
                  'ログイン',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(48),
                TextField(
                  controller: emailController,
                  decoration: _inputDecoration().copyWith(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !state.isLoading,
                ),
                const Gap(16),
                TextField(
                  controller: passwordController,
                  decoration: _inputDecoration().copyWith(
                    labelText: 'パスワード',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () =>
                          obscurePassword.value = !obscurePassword.value,
                    ),
                  ),
                  obscureText: obscurePassword.value,
                  autofillHints: const [AutofillHints.password],
                  enabled: !state.isLoading,
                ),
                const Gap(32),
                ElevatedButton(
                  onPressed: state.isLoading ? null : handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ログイン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('アカウントをお持ちでない方は'),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const SignUpPage(),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                      child: const Text('こちら'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('パスワードを忘れた方は'),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const PasswordResetPage(),
                                fullscreenDialog: true,
                              ),
                            ),
                      child: const Text('こちら'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// メール・パスワード欄で共通利用する InputDecoration。
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.amber),
      ),
    );
  }
}
