import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../components/app_bar.dart';
import '../../components/primary_filled_button.dart';
import '../../ui/app_snack_bar.dart';
import 'password_reset_confirmation_page.dart';
import 'password_reset_request_page_view_model.dart';

class PasswordResetPage extends HookConsumerWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passwordResetRequestPageViewModelProvider);
    final notifier = ref.read(
      passwordResetRequestPageViewModelProvider.notifier,
    );
    final isLoading = state.isLoading;

    final emailController = useTextEditingController();

    Future<void> sendPasswordResetCode() async {
      final email = emailController.text.trim();
      final success = await notifier.sendPasswordResetCode(email: email);
      if (!context.mounted) return;

      final snackBarError = ref
          .read(passwordResetRequestPageViewModelProvider)
          .snackBarError;
      if (snackBarError != null) {
        showAppSnackBar(context, snackBarError, isError: true);
        notifier.clearSnackBarError();
      }

      if (!success) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => PasswordResetConfirmationPage(email: email),
        ),
      );
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
                const Text(
                  '登録済みのメールアドレスに、パスワード再設定用の認証コード（6桁）を送信します。',
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: emailController,
                  decoration: AppInputDecoration.emailDecoration(
                    errorText: state.emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !isLoading,
                  onChanged: (_) => notifier.clearEmailError(),
                ),
                const SizedBox(height: 48),
                PrimaryFilledButton(
                  onPressed: isLoading ? null : sendPasswordResetCode,
                  isLoading: isLoading,
                  label: '認証コードを送る',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
