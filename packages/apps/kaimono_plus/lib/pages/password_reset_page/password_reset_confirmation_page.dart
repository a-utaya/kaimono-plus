import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/app_bar.dart';
import '../../components/primary_filled_button.dart';
import '../../ui/app_snack_bar.dart';
import 'password_reset_confirmation_page_view_model.dart';

class PasswordResetConfirmationPage extends HookConsumerWidget {
  const PasswordResetConfirmationPage({
    required this.email,
    super.key,
  });

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passwordResetConfirmationPageViewModelProvider);
    final notifier = ref.read(
      passwordResetConfirmationPageViewModelProvider.notifier,
    );
    final isLoading = state.isLoading;

    final codeController = useTextEditingController();
    final passwordController = useTextEditingController();
    final passwordConfirmController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscurePasswordConfirm = useState(true);
    final inputDecoration = AppInputDecoration.authOutlined;

    Future<void> registerNewPassword() async {
      final success = await notifier.confirmPasswordReset(
        email: email,
        code: codeController.text,
        password: passwordController.text,
        passwordConfirm: passwordConfirmController.text,
      );
      if (!context.mounted) return;

      final snackBarError = ref
          .read(passwordResetConfirmationPageViewModelProvider)
          .snackBarError;
      if (snackBarError != null) {
        showAppSnackBar(context, snackBarError, isError: true);
        notifier.clearSnackBarError();
      }

      if (!success) return;

      showAppSnackBar(context, 'パスワードを変更しました。新しいパスワードでログインしてください。');
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'パスワード再設定',
        backgroundColor: Colors.grey[50]!,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
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
                const SizedBox(height: 32),
                Text('$email に送信した認証コードと、新しいパスワードを入力してください。'),
                const SizedBox(height: 48),
                TextField(
                  controller: codeController,
                  decoration: inputDecoration.copyWith(
                    labelText: '認証コード（6桁）',
                    errorText: state.codeError,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enabled: !isLoading,
                  onChanged: (_) => notifier.clearCodeError(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordController,
                  decoration: inputDecoration.copyWith(
                    labelText: '新しいパスワード',
                    errorText: state.passwordError,
                  ),
                  obscureText: obscurePassword.value,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !isLoading,
                  onChanged: (_) => notifier.clearPasswordError(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordConfirmController,
                  decoration: inputDecoration.copyWith(
                    labelText: '新しいパスワード（確認用）',
                    errorText: state.passwordConfirmError,
                  ),
                  obscureText: obscurePasswordConfirm.value,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !isLoading,
                  onChanged: (_) => notifier.clearPasswordConfirmError(),
                ),
                const SizedBox(height: 48),
                PrimaryFilledButton(
                  onPressed: isLoading ? null : registerNewPassword,
                  isLoading: isLoading,
                  label: '登録',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
