import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthException exposes display message', () {
    const exception = AuthException('テストメッセージ', code: 'test-code');
    expect(exception.message, 'テストメッセージ');
    expect(exception.code, 'test-code');
    expect(exception.toString(), 'テストメッセージ');
  });
}
