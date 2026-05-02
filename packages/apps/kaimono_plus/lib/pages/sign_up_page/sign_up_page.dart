import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ui/app_snack_bar.dart';
import 'sign_up_page_view_model.dart';

/// 新規会員登録画面
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SignUpPageContent();
  }
}

class _SignUpPageContent extends HookConsumerWidget {
  const _SignUpPageContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch<SignUpState>(signUpPageViewModelProvider);
    final notifier = ref.read<SignUpPageViewModel>(
      signUpPageViewModelProvider.notifier,
    );
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final passwordConfirmController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscurePasswordConfirm = useState(true);
    useListenable(passwordController);
    useListenable(passwordConfirmController);

    /// 登録ボタン押下時の処理。成功時はモーダルを閉じて SnackBar で完了を表示する。
    Future<void> handleSignUp() async {
      final message = await notifier.signUp(
        email: emailController.text,
        password: passwordController.text,
        passwordConfirm: passwordConfirmController.text,
      );
      if (!context.mounted) return;
      if (message == null) {
        Navigator.of(context).pop();
        showAppSnackBar(context, 'アカウントを作成しました');
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
        color: Colors.grey[100],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(32),
                const Text(
                  '新規会員登録',
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
                    labelText: 'パスワード（半角英数字6文字以上）',
                    counterText: '${passwordController.text.length}/6',
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
                const SizedBox(height: 16),
                TextField(
                  controller: passwordConfirmController,
                  decoration: _inputDecoration().copyWith(
                    labelText: 'パスワード確認',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePasswordConfirm.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => obscurePasswordConfirm.value =
                          !obscurePasswordConfirm.value,
                    ),
                  ),
                  obscureText: obscurePasswordConfirm.value,
                  autofillHints: const [AutofillHints.password],
                  enabled: !state.isLoading,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading ? null : handleSignUp,
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
                          'アカウントを作成',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('既にアカウントをお持ちですか？ '),
                    TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('ログイン'),
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

  // SnackBar は共通ヘルパーへ切り出し: showAppSnackBar
}
