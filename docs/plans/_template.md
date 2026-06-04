# [機能名] 実装計画 / [Feature Name] Implementation Plan

- **作成日**: YYYY-MM-DD
- **ステータス**: 草案 / レビュー中 / 実装中 / 完了
- **関連 Issue**: [#番号](https://github.com/a-utaya/kaimono-plus/issues/番号)
- **関連 PR**: （あれば）

---

## Summary (EN)

> 海外向けポートフォリオ・PR 用の短い要約。本文は日本語のままでよい。

**Goal:** [One sentence: what user problem this solves]

**Approach:** [One to two sentences: how it will be built — e.g. screens, APIs, external services]

**Acceptance criteria (high level):**

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

**Out of scope:** [What this plan intentionally does not cover]

---

## 1. 目的・背景

### なぜやるか

- [解決したい課題・ユーザーのニーズ]
- [現状の問題点]

### 前提・制約

- [既存仕様・デザイン・期限など]
- [スコープ外にすること（あれば）]

---

## 2. 実装概要

### 何を実装するか

- [ユーザーから見える変化・完了条件]
- [受け入れ条件（例：〇〇したときに△△になる）]

### どのように実装するか

- [方針の要約（1〜3 文）]
- [採用するアプローチと、採用しなかった案があれば簡潔に]

### 影響範囲（パッケージ・レイヤー）

| 対象 | 変更の有無 | メモ |
| --- | --- | --- |
| `packages/apps/kaimono_plus` | あり / なし | |
| `packages/core/auth` | あり / なし | |
| その他 | | |

### 使用パッケージ（該当する場合）

**新規追加する pub 依存**がある場合のみ記載。既存パッケージだけならこのセクションは削除してよい。

リンクは **パッケージ名をテキスト**にする（外部: pub.dev、ワークスペース内: `packages/...` への相対パス）。

| パッケージ | 新規 / 既存 | 追加先（`pubspec.yaml`） | 用途 | リンク |
| --- | --- | --- | --- | --- |
| `[package_name]` | 新規 / 既存 | `packages/apps/kaimono_plus` など | [用途] | [package_name](https://pub.dev/packages/package_name) |
| `auth` | 既存 | `packages/core/auth` など | [用途] | [`packages/core/auth`](../../packages/core/auth) |

> 2 行目はワークスペース内パッケージの書き方の例。不要なら削除する。

---

## 3. タスク一覧

実装の順序が分かるように並べ、**PR ごとに完了した項目だけ `[x]` に更新**する。  
機能全体を一度に実装しない場合は、パッケージや Phase ごとに見出しを分けると進捗が追いやすい。

### 準備

- [ ] [調査・設計の確認など]

### 実装（`packages/core/auth` など — 該当する場合）

- [ ] [タスク 1：例）`Authenticator` API 追加]
- [ ] [タスク 2：例）`FirebaseAuthenticator` 実装]

### 実装（`packages/apps/kaimono_plus` など — 該当する場合）

- [ ] [タスク 1：例）ViewModel 追加]
- [ ] [タスク 2：例）画面・ウィジェットの追加]
- [ ] [タスク 3：例）ルーティング・ナビゲーションの接続]

> **Phase 分けの例:** Phase 1 = 送信画面のみ / Phase 2 = ディープリンク + 確定画面  
> 今回の PR に含まれないタスクは `[ ]` のままでよい。

### 品質

- [ ] `flutter analyze` が通る
- [ ] 該当パッケージで `flutter test` を実行
- [ ] （UI 変更時）手動確認・スクリーンショット

### 仕上げ

- [ ] ドキュメント更新（必要な場合）
- [ ] PR 作成・レビュー対応

---

## 4. 実装詳細（レビュー用）

レビュアーが差分の意図を把握しやすいよう、**作成・変更するファイルと公開 API** を列挙する。

### 新規作成

| パス | 種別（Page / Widget / Provider など） | 役割 |
| --- | --- | --- |
| `packages/.../lib/...` | | |

### 既存ファイルの変更

| パス | 変更内容 |
| --- | --- |
| `packages/.../lib/...` | [追加するメソッド・プロパティ、修正する挙動] |

### API・インターフェースの追加・変更

| ファイル | 追加 / 変更する API | 概要 |
| --- | --- | --- |
| `packages/core/auth/lib/auth.dart` | `exampleMethod()` | [呼び出し元・責務] |

### 画面・ナビゲーション（該当する場合）

- **ルート名 / パス**: 
- **遷移元**: 
- **遷移先**: 

### データ・外部連携（該当する場合）

- [Supabase / ローカル DB / その他]

---

## 5. テスト計画

| 種別 | 内容 | コマンド / 手順 |
| --- | --- | --- |
| 静的解析 | | `cd packages/apps/kaimono_plus && flutter analyze` |
| 単体テスト | | `cd packages/core/auth && flutter test` |
| 手動確認 | | [操作手順] |

---

## 6. リスク・未決事項

- [ ] [未決の仕様・確認が必要な点]
- [ ] [技術的リスクと対策]

---

## 7. レビュー用メモ（任意）

- **重点的に見てほしい箇所**: 
- **意図的に今回やらないこと**: 
- **参考リンク**: 

---

## 更新履歴

計画本文の変更や PR のマイルストーンを短く残す。**レビュー依頼前・マージ前**に追記する。

| 日付 | 変更内容 |
| --- | --- |
| YYYY-MM-DD | 初版作成 |
| YYYY-MM-DD | [例）認証リンク送信画面を実装（PR #xxx）] |
| YYYY-MM-DD | [例）レビュー指摘反映：〇〇を Authenticator 側に移動] |
| YYYY-MM-DD | [例）機能完了、ステータスを「完了」に更新] |
