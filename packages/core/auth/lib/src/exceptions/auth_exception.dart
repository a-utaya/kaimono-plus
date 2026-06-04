/// 認証・ユーザー保存の失敗（画面表示用メッセージを [message] に保持）
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
