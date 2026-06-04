import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/app_snack_bar.dart';
import '../kaimono_list_page/kaimono_list_page.dart';
import '../password_reset_page/password_reset_request_page.dart';
import '../sign_up_page/sign_up_page.dart';
import 'sign_in_page_view_model.dart';

class SignInPage extends HookConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInPageViewModelProvider);
    final isLoading = state.isLoading;

    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final inputDecoration = AppInputDecoration.authOutlined;

    Future<void> handleSignIn() async {
      try {
        await ref
            .read(signInPageViewModelProvider.notifier)
            .signIn(
              email: emailController.text,
              password: passwordController.text,
            );
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => const KaimonoListPage(),
          ),
        );
      } on AuthException catch (e) {
        if (!context.mounted) return;
        showAppSnackBar(context, e.message, isError: true);
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
                  decoration: inputDecoration.copyWith(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !isLoading,
                ),
                const Gap(16),
                TextField(
                  controller: passwordController,
                  decoration: inputDecoration.copyWith(
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
                  enabled: !isLoading,
                ),
                const Gap(32),
                ElevatedButton(
                  onPressed: isLoading ? null : handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
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
                      onPressed: isLoading
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
                      onPressed: isLoading
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
}
