# 買い物リスト共有 実装計画 / Shopping List Share Implementation Plan

- **作成日**: 2026-06-04
- **ステータス**: 完了
- **関連 Issue**: なし
- **関連 PR**: （未作成）

---

## Summary (EN)

**Goal:** Let users share a shopping list in a way that works even when the recipient has poor network access or does not have the app installed.

**Approach:** Share plain text as the primary content, and add a Firebase Hosting link as an optional app-open path. Cloud Functions creates and reads shared-list snapshots for app import, while the web page only provides an app/install entry point and does not render the list.

**Acceptance criteria (high level):**

- [x] Share sheet opens from the shopping list screen
- [x] Shared text includes pending items in a readable bullet-list format
- [x] Completed items and blank items are excluded
- [x] A recipient with Kaimono+ installed can open the shared list in the app
- [x] A recipient without the app sees an app-open/install landing page, not a web copy of the list

**Out of scope:** Real-time collaborative lists, public web list viewing, editing shared lists on the web, universal link production setup.

---

## 1. 目的・背景

### なぜやるか

- 買い物リストを家族や同居人へ素早く渡せるようにする。
- ネットワークが悪い場所でも、共有本文だけで買うものが分かるようにする。
- アプリを持っている相手には、共有リンクからリストをアプリへ取り込める体験を用意する。

### 前提・制約

- 共有本文が主役。リンクはアプリ取り込み用の補助導線とする。
- 未インストール相手には Web でリスト本文を表示しない。共有メッセージ本文に買うものが残るため、最低限の UX は担保する。
- 共有リストはスナップショットとして保存し、リアルタイム同期や共同編集は今回やらない。
- 共有リンク作成・読み取りは Cloud Functions 経由にし、Firestore ルールを公開読み取りへ寄せない。

---

## 2. 実装概要

### 何を実装するか

- 買い物リスト画面右上のシェアボタンを実装する。
- 未完了かつ空でないアイテムだけを共有対象にする。
- 共有時に `sharedLists` へスナップショットを作り、以下の形式で共有する。

```text
買うもの

・牛乳
・パン
・卵

Kaimono+で開く:
https://kaimono-plus.web.app/share/{id}
```

- `kaimono-plus://share/{id}` をアプリで受け取り、共有リストを現在のリストとして開く。
- `/share/{id}` の Web ページはリスト本文を表示せず、「アプリで開く」「Kaimono+ を見る」だけを表示する。

### どのように実装するか

```text
共有する側
  KaimonoListPage
    -> createSharedList callable Function
    -> Firestore sharedLists/{id}
    -> share_plus で本文 + Hosting URL を共有

受け取る側
  https://kaimono-plus.web.app/share/{id}
    -> kaimono-plus://share/{id}
    -> app_links
    -> getSharedListForApp callable Function
    -> アプリ内リストへ取り込み
```

### 影響範囲

| 対象 | 変更の有無 | メモ |
| --- | --- | --- |
| `packages/apps/kaimono_plus` | あり | リスト画面、ViewModel、URL scheme、Hosting ページ、Functions |
| `packages/core/auth` | なし | 認証 API は変更しない |
| Firebase | あり | Functions、Firestore、Hosting、Cloud Run public invoker |

### 使用パッケージ

| パッケージ | 新規 / 既存 | 追加先 | 用途 | リンク |
| --- | --- | --- | --- | --- |
| `share_plus` | 新規 | `packages/apps/kaimono_plus` | OS 標準の共有シートを開く | [share_plus](https://pub.dev/packages/share_plus) |
| `app_links` | 新規 | `packages/apps/kaimono_plus` | `kaimono-plus://share/{id}` の起動時・起動中リンクを受け取る | [app_links](https://pub.dev/packages/app_links) |
| `cloud_functions` | 新規 | `packages/apps/kaimono_plus` | 共有リスト作成・取得 callable Functions を呼ぶ | [cloud_functions](https://pub.dev/packages/cloud_functions) |

---

## 3. タスク一覧

### 準備

- [x] 共有本文を「未完了アイテムの箇条書き」にする方針を決定
- [x] Web ではリストを表示せず、インストール/アプリ起動導線だけにする方針を決定
- [x] Firebase Dynamic Links は使わず、Hosting + custom URL scheme にする方針を決定

### 実装（アプリ）

- [x] `share_plus` を追加
- [x] `app_links` を追加
- [x] `KaimonoListState.shareableItems` を追加
- [x] `KaimonoListState.shareText` を追加
- [x] 共有ボタンから OS 共有シートを開く
- [x] 空・完了済みのみの場合は共有ボタンを無効化
- [x] `createSharedList` を呼び、共有リンクを本文に含める
- [x] 起動時リンクを `getInitialLink` で処理
- [x] 起動中リンクを `uriLinkStream` で処理
- [x] 共有リストをアプリ内リストへ取り込む
- [x] iOS `Info.plist` に `kaimono-plus` URL scheme を追加
- [x] Android `AndroidManifest.xml` に `kaimono-plus://share` intent filter を追加

### 実装（Functions / Hosting）

- [x] `createSharedList` callable Function を追加
- [x] `getSharedListForApp` callable Function を追加
- [x] `sharedLists/{id}` に共有スナップショットを保存
- [x] `/share/**` を `web/share/index.html` に rewrite
- [x] `web/share/index.html` を追加
- [x] Web ページではリスト本文を表示しない

### 運用設定

- [x] `functions,hosting` をデプロイ
- [x] `createsharedlist` の公開アクセスを許可
- [x] `getsharedlistforapp` の公開アクセスを許可

### 品質

- [x] `npm run build`
- [x] `fvm flutter analyze`
- [x] `pod install`
- [x] `fvm flutter build ios --debug --no-codesign`
- [x] 実機で共有シートと共有文を確認

---

## 4. 実装詳細（レビュー用）

### 新規作成

| パス | 種別 | 役割 |
| --- | --- | --- |
| `packages/apps/kaimono_plus/web/share/index.html` | Hosting Page | アプリ起動/インストール導線のみを表示 |

### 既存ファイルの変更

| パス | 変更内容 |
| --- | --- |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/kaimono_list_page.dart` | `ConsumerStatefulWidget` 化、共有ボタン、App Links 購読、共有リスト取り込み |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/kaimono_list_page_view_model.dart` | 共有本文生成、`createSharedList`、`openSharedList` |
| `packages/apps/kaimono_plus/functions/src/index.ts` | `createSharedList` / `getSharedListForApp` 追加 |
| `packages/apps/kaimono_plus/firebase.json` | Hosting 設定と `/share/**` rewrite を追加 |
| `packages/apps/kaimono_plus/android/app/src/main/AndroidManifest.xml` | custom URL scheme intent filter 追加 |
| `packages/apps/kaimono_plus/ios/Runner/Info.plist` | custom URL scheme 追加 |
| `packages/apps/kaimono_plus/pubspec.yaml` | `share_plus` / `app_links` / `cloud_functions` 追加 |
| `pubspec.lock` | 依存解決更新 |
| `packages/apps/kaimono_plus/ios/Podfile.lock` | Firebase iOS SDK / Pods 更新 |
| `packages/apps/kaimono_plus/macos/Flutter/GeneratedPluginRegistrant.swift` | 追加 plugin 登録 |

### API・インターフェース

| API | 種別 | 概要 |
| --- | --- | --- |
| `createSharedList` | callable Function | 認証済みユーザーが共有スナップショットを作成し、Hosting URL を返す |
| `getSharedListForApp` | callable Function | 認証済みユーザーが共有リストをアプリ取り込み用に取得する |
| `kaimono-plus://share/{id}` | custom URL scheme | アプリで共有リストを開く |
| `https://kaimono-plus.web.app/share/{id}` | Hosting URL | アプリ起動/インストール導線 |

### データ・外部連携

| 名称 | 役割 |
| --- | --- |
| `sharedLists/{id}` | 共有時点の未完了アイテムのスナップショット |
| Firebase Hosting | `/share/{id}` の導線ページ配信 |
| Cloud Run | callable Functions の実行基盤。public invoker 設定が必要 |

---

## 5. テスト計画

| 種別 | 内容 | コマンド / 手順 |
| --- | --- | --- |
| Functions build | TypeScript がコンパイルできる | `cd packages/apps/kaimono_plus/functions && npm run build` |
| 静的解析 | Flutter/Dart 解析 | `cd packages/apps/kaimono_plus && fvm flutter analyze` |
| iOS Pods | Pod 解決 | `cd packages/apps/kaimono_plus/ios && pod install` |
| iOS build | 署名なし debug build | `cd packages/apps/kaimono_plus && fvm flutter build ios --debug --no-codesign` |
| 手動確認 | 未完了アイテムだけが本文に含まれる | 実機 |
| 手動確認 | 共有リンクからアプリに取り込める | 実機 |
| 手動確認 | 未インストール相当のブラウザで `/share/{id}` を開くと本文なしの導線ページが出る | ブラウザ |

---

## 6. リスク・未決事項

- [ ] Custom URL scheme は他アプリと衝突しうる。将来的には Universal Links / Android App Links を検討する。
- [ ] `sharedLists` の保存期間・自動削除を決める。
- [ ] 共有リスト取り込み時に既存リストを上書きする仕様でよいか、追加/マージ UX を検討する。
- [ ] Functions の濫用対策として App Check / rate limit を検討する。
- [ ] Web の「Kaimono+ を見る」リンク先は、本番ランディング/ストアURLが決まったら差し替える。

---

## 7. レビュー用メモ

- **重点的に見てほしい箇所**: 共有本文の UX、Web でリスト本文を表示しない判断、`sharedLists` のセキュリティ境界。
- **意図的に今回やらないこと**: Web でのリスト閲覧、共同編集、リアルタイム同期。

---

## 更新履歴

| 日付 | 変更内容 |
| --- | --- |
| 2026-06-04 | 初版作成。実装済み内容を反映し、ステータスを完了に設定 |
