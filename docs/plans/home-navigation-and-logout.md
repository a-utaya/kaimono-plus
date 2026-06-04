# ホームナビゲーション・ログアウト 実装計画 / Home Navigation and Logout Implementation Plan

- **作成日**: 2026-06-04
- **ステータス**: 完了
- **関連 Issue**: なし
- **関連 PR**: （未作成）

---

## Summary (EN)

**Goal:** Add a logged-in home shell with bottom navigation and a clear logout entry point.

**Approach:** Introduce a three-tab shell for history, shopping-list creation, and My Page. Use the existing Firebase authentication provider for logout and let the auth-state gate switch back to the sign-in screen.

**Acceptance criteria (high level):**

- [x] Logged-in users see a bottom navigation shell instead of entering the shopping list screen directly
- [x] The center action creates a shopping-list item and remains visually prominent
- [x] My Page shows the signed-in account and provides a logout action
- [x] Logout asks for confirmation and returns the user to the sign-in screen

**Out of scope:** Persisted shopping-list history, full account settings, profile editing.

---

## 1. 目的・背景

### なぜやるか

- ログアウト機能を置く場所として、マイページ導線を先に用意する。
- 買い物リスト作成をアプリの中心操作として見せつつ、履歴・マイページへ自然に移動できるようにする。
- 起動時に毎回ログアウトする開発用コードを削除し、ユーザー操作としてのログアウトへ移行する。

### 前提・制約

- 買い物リスト履歴はまだ実データを持たないため、今回はプレースホルダー表示に留める。
- ログイン/ログアウト後の画面切り替えは `authStateChangesProvider` に任せる。
- 新規 pub 依存は追加しない。

---

## 2. 実装概要

### 何を実装するか

- ログイン後のホームとして `HomeShellPage` を追加する。
- 下部に「履歴」「作成」「マイページ」の 3 導線を配置する。
- 中央の「作成」は丸いボタンとして少し上に出し、押下時に買い物リストタブへ移動して新規アイテムを追加する。
- マイページにアカウント表示とログアウトボタンを追加する。
- ログアウト時は確認ダイアログを表示し、確定後に `FirebaseAuthenticator.signOut()` を呼ぶ。

### どのように実装するか

`_AuthGate` のログイン済み表示先を `KaimonoListPage` から `HomeShellPage` に変更する。`HomeShellPage` は `IndexedStack` で 3 タブを保持し、中央ボタンから `kaimonoListPageViewModelProvider.notifier.addItem()` を呼び出す。ログアウトは `authenticatorProvider` 経由で実行し、認証状態の変化によってログイン画面へ戻す。

### 影響範囲

| 対象 | 変更の有無 | メモ |
| --- | --- | --- |
| `packages/apps/kaimono_plus` | あり | ホームシェル、マイページ、ログアウト、共通ダイアログ |
| `packages/core/auth` | なし | 既存の `signOut()` を利用 |
| Firebase | なし | 追加設定なし |

---

## 3. タスク一覧

### 準備

- [x] ボトムナビの構成を「履歴 / 作成 / マイページ」に決定
- [x] ログアウト導線をマイページへ配置する方針を決定

### 実装（`packages/apps/kaimono_plus`）

- [x] `HomeShellPage` を追加
- [x] ログイン済み時の表示先を `HomeShellPage` に変更
- [x] ログイン成功時の手動遷移を外し、認証状態監視に寄せる
- [x] 既存の `KaimonoListPage` をホームシェル内で表示できるよう FAB 表示を切り替え可能にする
- [x] 中央の作成ボタンから買い物リストへ移動し、新規アイテムを追加する
- [x] 履歴タブをプレースホルダーとして追加
- [x] マイページにログイン中メール表示を追加
- [x] マイページに「お店を出る（ログアウト）」ボタンを追加
- [x] ログアウト確認ダイアログを追加
- [x] 起動時に毎回ログアウトする開発用コードを削除
- [x] `ConfirmDialog` の背景色・外余白・最小幅を調整

### 品質

- [x] `fvm dart format`
- [x] `fvm flutter analyze`
- [x] `packages/core/auth` で `fvm flutter test`
- [x] シミュレータでボトムナビ・ログアウト確認ダイアログの見た目を確認

---

## 4. 実装詳細（レビュー用）

### 新規作成

| パス | 種別 | 役割 |
| --- | --- | --- |
| `packages/apps/kaimono_plus/lib/pages/home_shell_page/home_shell_page.dart` | Page / Widget | ログイン後の 3 タブ構成、マイページ、ログアウト導線 |

### 既存ファイルの変更

| パス | 変更内容 |
| --- | --- |
| `packages/apps/kaimono_plus/lib/main.dart` | ログイン済み画面を `HomeShellPage` に変更、開発用自動ログアウトを削除 |
| `packages/apps/kaimono_plus/lib/pages/sign_in_page/sign_in_page.dart` | ログイン成功後の手動 `pushReplacement` を削除 |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/kaimono_list_page.dart` | FAB 表示切り替えと下部ナビ用余白を追加 |
| `packages/apps/kaimono_plus/lib/components/confirm_dialog.dart` | `backgroundColor`、`insetPadding`、`constraints` を調整 |

### 画面・ナビゲーション

- **ログイン済みホーム**: `HomeShellPage`
- **左タブ**: 履歴（プレースホルダー）
- **中央アクション**: 買い物リスト作成。買い物リストタブへ移動し、新規アイテム追加
- **右タブ**: マイページ。ログイン中メール表示とログアウト
- **ログアウト後**: `authStateChangesProvider` により `SignInPage` へ戻る

---

## 5. テスト計画

| 種別 | 内容 | コマンド / 手順 |
| --- | --- | --- |
| 静的解析 | アプリ全体の解析 | `cd packages/apps/kaimono_plus && fvm flutter analyze` |
| 単体テスト | auth パッケージの既存テスト | `cd packages/core/auth && fvm flutter test` |
| 手動確認 | 中央作成ボタンでアイテム追加 | シミュレータ / 実機 |
| 手動確認 | マイページからログアウト確認ダイアログを表示 | シミュレータ / 実機 |
| 手動確認 | ログアウト後にログイン画面へ戻る | シミュレータ / 実機 |

---

## 6. リスク・未決事項

- [ ] 履歴タブの実データ保存・表示仕様は別途設計する。
- [ ] マイページのプロフィール編集や退会などは別スコープで検討する。
- [ ] 中央作成ボタンの見た目は実機確認を続け、押しやすさと主張の強さを微調整する。

---

## 7. レビュー用メモ

- **重点的に見てほしい箇所**: `HomeShellPage` のタブ保持、ログイン/ログアウト後の AuthGate 連携、ログアウト確認文言。
- **意図的に今回やらないこと**: 履歴一覧の永続化、マイページの詳細機能、ボトムナビの共通コンポーネント化。

---

## 更新履歴

| 日付 | 変更内容 |
| --- | --- |
| 2026-06-04 | 初版作成。ボトムナビ、マイページ、ログアウト実装を完了状態で反映 |
