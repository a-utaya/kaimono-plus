import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../ sign_up_page/sign_up_page.dart';
import '../kaimono_list_page/kaimono_list_page.dart';
import '../password_reset_page/password_reset_page.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const .all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'ログイン',
                  style: TextStyle(fontSize: 28, fontWeight: .bold),
                  textAlign: .center,
                ),
                const SizedBox(height: 48),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: .new(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: const .new(color: Colors.amber),
                    ),
                  ),
                  keyboardType: .emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: .new(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: .circular(8),
                      borderSide: const .new(color: Colors.amber),
                    ),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const Gap(32),
                ElevatedButton(
                  onPressed: () {
                    // FIXME: サインイン処理を実装
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const KaimonoListPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const .symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: .circular(8)),
                  ),
                  child: const Text(
                    'ログイン',
                    style: TextStyle(fontSize: 16, fontWeight: .bold),
                  ),
                ),
                const Gap(24),
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    const Text('アカウントをお持ちでない方は'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
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
                  mainAxisAlignment: .center,
                  children: [
                    const Text('パスワードを忘れた方は'),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
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
