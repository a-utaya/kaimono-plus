# パスワード再設定（認証コード方式）

マジックリンク（Universal Links）の代わりに、メールで **6桁の認証コード** を送り、アプリ内でコードと新パスワードを入力して再設定します。

## アーキテクチャ

```text
[アプリ] → Cloud Functions (sendPasswordResetCode / confirmPasswordResetWithCode)
              ↓
         Firestore (passwordResetCodes) + mail コレクション（メール送信）
              ↓
         Firebase Auth Admin（パスワード更新）
```

## 初回セットアップ

### 1. Trigger Email 拡張（メール送信）

Cloud Functions は `mail` コレクションにドキュメントを追加してメールを送ります。

1. [Firebase Console](https://console.firebase.google.com/) → Extensions
2. **Trigger Email from Firestore** をインストール
3. コレクション名を `mail` に設定（拡張のデフォルトと合わせる）

SMTP / SendGrid 等の設定は拡張のウィザードに従ってください。

### 2. Cloud Functions のデプロイ

```bash
cd packages/apps/kaimono_plus/functions
npm install
cd ..
npx firebase-tools deploy --only functions
```

Firebase CLI は Cloud Functions の `engines.node` に合わせて Node.js 22 系で実行してください。
このリポジトリでは Flutter/Dart は FVM で管理しますが、Node.js は FVM の管理対象外です。

Gen2 Functions で実機から `PERMISSION DENIED` が返る場合は、Cloud Run 側で未認証呼び出しが許可されていない可能性があります。Firebase Console / Google Cloud Console で以下の 2 関数に `allUsers` の Cloud Run Invoker 権限を付与してください。

- `sendpasswordresetcode`
- `confirmpasswordresetwithcode`

### 3. 動作確認

1. アプリで「パスワードを忘れた方はこちら」→ メール入力 → **認証コードを送る**
2. メールの6桁コードを入力 → 新パスワードを設定 → **登録**
3. ログイン画面で新パスワードでサインイン

## セキュリティ

- 未登録メールでも送信 API は成功を返す（列挙防止）
- コードは Firestore にハッシュのみ保存、有効期限10分、試行上限5回
- `passwordResetCodes` はクライアントから読めないよう Firestore ルールで拒否すること

## ローカル開発

Functions Emulator を使う場合:

```bash
cd packages/apps/kaimono_plus
npx firebase-tools emulators:start --only functions,firestore
```

アプリ側で `FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001)` をデバッグ時のみ有効化してください（本番では不要）。
