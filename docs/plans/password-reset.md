# パスワードリセット 実装計画 / Password Reset Implementation Plan

- **作成日**: 2026-05-23
- **最終更新日**: 2026-06-04
- **ステータス**: 完了
- **関連 Issue**: [#17](https://github.com/a-utaya/kaimono-plus/issues/17)
- **関連 PR**: https://github.com/a-utaya/kaimono-plus/pull/37

---

## Summary (EN)

**Goal:** Let users reset their password safely without relying on universal links.

**Approach:** Use a two-step in-app flow: request a six-digit verification code by email, then enter the code and a new password. Cloud Functions owns code generation, Firestore persistence, email queue writes, and Firebase Auth password updates.

**Acceptance criteria (high level):**

- [x] User can request a six-digit password reset code for a registered email address
- [x] Invalid email, invalid code, expired code, weak password, and retry-limit errors are shown in Japanese
- [x] User can set a new password in the app and sign in with it afterward
- [x] Unregistered emails do not reveal account existence

**Out of scope:** Universal Links / Dynamic Links based password reset, email template customization beyond the Trigger Email payload, non-Firebase auth providers.

---

## 1. 目的・背景

### なぜやるか

- パスワードを忘れたユーザーが、登録済みメールアドレスから安全にパスワードを再設定できるようにする。
- Universal Links / Dynamic Links の運用負荷を避け、実機で確実に確認しやすい認証コード方式にする。

### 前提・制約

- 認証処理は `packages/core/auth` の `Authenticator` 経由に集約する。
- パスワード再設定コードはクライアントへ直接保存・検証させず、Cloud Functions で扱う。
- メール送信は Firebase Extension の Trigger Email from Firestore を使い、`mail` コレクションへの書き込みで行う。
- 未登録メールでも成功レスポンスにし、アカウント列挙を防ぐ。

---

## 2. 実装概要

### 何を実装するか

1. ログイン画面の「パスワードを忘れた方はこちら」から認証コード送信画面を開く。
2. メールアドレスを入力し、6桁の認証コードをメール送信する。
3. アプリ内で認証コード・新しいパスワード・確認用パスワードを入力する。
4. Cloud Functions がコードを検証し、Firebase Auth Admin SDK でパスワードを更新する。

### どのように実装するか

```text
アプリ
  -> Authenticator
  -> FirebaseAuthenticator
  -> Cloud Functions
      -> Firestore passwordResetCodes
      -> Firestore mail
      -> Firebase Auth Admin
```

`sendPasswordResetCode` はコードの生成・ハッシュ保存・メールキュー作成を行う。`confirmPasswordResetWithCode` はコード形式、有効期限、試行回数、ハッシュ一致、新パスワード強度を検証し、パスワード更新後にコードを削除する。

### 影響範囲

| 対象 | 変更の有無 | メモ |
| --- | --- | --- |
| `packages/apps/kaimono_plus` | あり | パスワード再設定画面、ViewModel、Cloud Functions |
| `packages/core/auth` | あり | `Authenticator` API 追加、`FirebaseAuthenticator` 実装 |
| Firebase | あり | Functions、Firestore、Trigger Email Extension、Cloud Run public invoker |

### 使用パッケージ

| パッケージ | 新規 / 既存 | 追加先 | 用途 | リンク |
| --- | --- | --- | --- | --- |
| `cloud_functions` | 新規 | `packages/core/auth` | パスワード再設定用 callable Functions 呼び出し | [cloud_functions](https://pub.dev/packages/cloud_functions) |
| `cloud_firestore` | 既存 | `packages/core/auth` | ユーザー初期保存、Firebase 依存の整合 | [cloud_firestore](https://pub.dev/packages/cloud_firestore) |
| `auth` | 既存 | `packages/apps/kaimono_plus` | 認証抽象 | [`packages/core/auth`](../../packages/core/auth) |

---

## 3. タスク一覧

### 準備

- [x] Trigger Email from Firestore を `mail` コレクションで利用する方針に決定
- [x] Cloud Functions Gen2 の未認証呼び出しに Cloud Run public invoker が必要なことを確認
- [x] `docs/password-reset-code-setup.md` にセットアップ手順を記載

### 実装（`packages/core/auth`）

- [x] `Authenticator.sendPasswordResetCode` を追加
- [x] `Authenticator.confirmPasswordResetWithCode` を追加
- [x] `FirebaseAuthenticator` で callable Functions を呼び出す
- [x] `FirebaseFunctionsException` を `AuthException` に変換する
- [x] `permission-denied` 時に Cloud Run 権限確認を促す日本語メッセージを表示

### 実装（`packages/apps/kaimono_plus`）

- [x] `PasswordResetRequestPage` を追加
- [x] `PasswordResetRequestPageNotifier` を追加
- [x] `PasswordResetConfirmationPage` を追加
- [x] `PasswordResetConfirmationPageNotifier` を追加
- [x] ログイン画面からパスワード再設定画面へ遷移
- [x] `sendPasswordResetCode` Function を追加
- [x] `confirmPasswordResetWithCode` Function を追加
- [x] `mail` コレクションにメール送信用ドキュメントを作成
- [x] `passwordResetCodes` にハッシュ化コード、有効期限、試行回数を保存

### 運用設定

- [x] `sendpasswordresetcode` の公開アクセスを許可
- [x] `confirmpasswordresetwithcode` の公開アクセスを許可
- [x] Trigger Email Extension の配送成功を Firestore `mail.delivery.state = SUCCESS` で確認

### 品質

- [x] `npm run build`
- [x] `fvm flutter analyze`
- [x] 実機でコード送信、メール受信、パスワード変更、再ログインを確認

---

## 4. 実装詳細（レビュー用）

### 新規作成

| パス | 種別 | 役割 |
| --- | --- | --- |
| `packages/apps/kaimono_plus/functions/src/index.ts` | Cloud Functions | パスワード再設定コード送信・検証・パスワード更新 |
| `packages/apps/kaimono_plus/lib/pages/password_reset_page/password_reset_request_page.dart` | Page | メール入力・コード送信 |
| `packages/apps/kaimono_plus/lib/pages/password_reset_page/password_reset_request_page_view_model.dart` | ViewModel | メールバリデーション、送信状態、エラー表示 |
| `packages/apps/kaimono_plus/lib/pages/password_reset_page/password_reset_confirmation_page.dart` | Page | 認証コード・新パスワード入力 |
| `packages/apps/kaimono_plus/lib/pages/password_reset_page/password_reset_confirmation_page_view_model.dart` | ViewModel | コード・パスワード検証、確定処理 |
| `docs/password-reset-code-setup.md` | Docs | Firebase 側セットアップと確認手順 |

### 既存ファイルの変更

| パス | 変更内容 |
| --- | --- |
| `packages/core/auth/lib/src/authenticator.dart` | パスワード再設定 API 追加 |
| `packages/core/auth/lib/src/firebase/firebase_authenticator.dart` | Cloud Functions 呼び出しとエラー変換 |
| `packages/apps/kaimono_plus/lib/pages/sign_in_page/sign_in_page.dart` | パスワード再設定画面への導線追加 |
| `packages/apps/kaimono_plus/firebase.json` | Functions デプロイ設定追加 |
| `packages/core/auth/pubspec.yaml` | `cloud_functions` 追加 |

### データ・外部連携

| 名称 | 役割 |
| --- | --- |
| `passwordResetCodes/{email}` | コードハッシュ、有効期限、試行回数を保存 |
| `mail/{autoId}` | Trigger Email Extension の送信キュー |
| `sendPasswordResetCode` | メール送信用 callable Function |
| `confirmPasswordResetWithCode` | コード検証・パスワード更新用 callable Function |

---

## 5. テスト計画

| 種別 | 内容 | コマンド / 手順 |
| --- | --- | --- |
| Functions build | TypeScript がコンパイルできる | `cd packages/apps/kaimono_plus/functions && npm run build` |
| 静的解析 | Flutter/Dart 解析 | `cd packages/apps/kaimono_plus && fvm flutter analyze` |
| 手動確認 | 登録済みメールで認証コードを受信し、新パスワードへ変更 | 実機 |
| 手動確認 | 未登録メールでも画面上は成功扱いになる | 実機 |
| 手動確認 | `mail.delivery.state = SUCCESS` を確認 | Firebase Console |

---

## 6. リスク・未決事項

- [ ] Functions の濫用対策として、必要に応じて App Check / rate limit / reCAPTCHA を追加する。
- [ ] `passwordResetCodes` の古いドキュメント削除方針を検討する。
- [ ] メール送信元やテンプレートの本番用文言を調整する。

---

## 7. レビュー用メモ

- **重点的に見てほしい箇所**: Cloud Functions の入力検証、列挙防止、エラーメッセージ変換。
- **意図的に今回やらないこと**: Universal Links / Dynamic Links 化、Web 完結のリセット画面。
- **参考ドキュメント**: [`docs/password-reset-code-setup.md`](../password-reset-code-setup.md)

---

## 更新履歴

| 日付 | 変更内容 |
| --- | --- |
| 2026-05-23 | 初版作成 |
| 2026-06-04 | 認証リンク方式から6桁認証コード方式へ実装内容を更新し、ステータスを完了に変更 |
