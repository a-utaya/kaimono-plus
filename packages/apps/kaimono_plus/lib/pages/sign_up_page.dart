import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const .all(24.0),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                const Gap(32),
                const Text(
                  'アカウントを作成',
                  style: TextStyle(fontSize: 28, fontWeight: .bold),
                  textAlign: .center,
                ),
                const Gap(48),
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
                const Gap(16),
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
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'パスワード確認',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // TODO: サインアップ処理を実装
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'アカウントを作成',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('既にアカウントをお持ちですか？ '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
}
