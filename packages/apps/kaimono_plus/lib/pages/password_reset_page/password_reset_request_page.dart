import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:kaimono_plus/components/app_bar.dart';
import 'package:kaimono_plus/components/primary_filled_button.dart';

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'パスワード再設定',
        backgroundColor: Colors.grey[50]!,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        height: double.infinity,
        color: Colors.grey[50],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const .all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'パスワードリセット用の認証リンクを送信します。登録済みのメールアドレスを入力してください。',
                ),
                const SizedBox(height: 48),
                TextField(
                  decoration: AppInputDecoration.authOutlined.copyWith(
                    labelText: 'メールアドレス',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 48),
                PrimaryFilledButton(
                  onPressed: () {
                    // FIXME: パスワードリセット処理を実装
                    Navigator.of(context).pop();
                  },
                  label: '認証リンクを送る',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
