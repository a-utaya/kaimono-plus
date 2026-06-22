# Kaimono+

Flutter で開発している買い物リスト管理アプリです。
日常の買い物をスムーズに管理できるよう、リスト作成、アイテム管理、購入状態の切り替え、履歴・タグ管理など、実利用を想定した機能を実装しています。

## アプリ概要

Kaimono+ は、Flutter / Dart を用いた個人開発の買い物リスト管理アプリです。
モノレポ構成を採用し、アプリ本体、認証パッケージ、デザインシステムパッケージを分離することで、機能追加や保守をしやすい構成を意識しています。

実装だけでなく、画面遷移、データベーススキーマ、パッケージ構成、機能ごとの実装計画を `docs/` 配下に整理しながら開発しています。

## 主な機能

- 買い物リストの作成・編集・削除
- 買い物アイテムの追加・編集・削除
- 購入済み / 未購入の状態管理
- 作成済みリストの履歴表示
- 買い物アイテム用タグの作成・編集・削除
- タグからのアイテム追加
- 買い物リストの共有
- メールアドレス / パスワードによる認証
- 認証コードを使ったパスワード再設定
- マイページ、ログアウト、アカウント削除

## 使用技術

- Flutter
- Dart
- Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Cloud Functions
  - Firebase Hosting
- Riverpod / Hooks Riverpod
- Riverpod Generator
- App Links
- share_plus
- Melos
- Dart workspace
- FVM
- flutter_test
- altive_lints

## プロジェクト構成

```text
kaimono_plus/
├── packages/
│   ├── apps/
│   │   └── kaimono_plus/        # Flutter アプリ本体
│   ├── core/
│   │   └── auth/                # 認証共有パッケージ
│   └── design_system/           # 共通テーマ・UI定義
└── docs/                        # 設計メモ・実装計画
```

アプリ本体と共通機能を分けることで、認証やデザインの変更がアプリ全体へ与える影響を把握しやすい構成にしています。

## 工夫した点

### モノレポ構成の採用

アプリ本体、認証パッケージ、デザインシステムをパッケージ単位で分離しています。
小規模な個人開発でも、機能追加や責務分離を意識した構成にすることで、後から見返したときに変更箇所を追いやすくしています。

### 認証機能の共通パッケージ化

Firebase Authentication と Cloud Functions を用いた認証処理を `packages/core/auth` に切り出しています。
アプリ側の画面実装から Firebase 依存の詳細を分離し、認証まわりの変更を局所化できるようにしています。

### 実利用を意識した買い物体験

単純なリスト作成だけでなく、履歴、タグ、共有、購入状態の切り替えなど、実際の買い物前後の流れを想定して機能を追加しています。
手入力だけに寄せすぎず、よく買うものをタグから追加できるようにするなど、日常利用時の操作負荷を下げることを意識しています。

### 設計・実装計画の整理

画面遷移、データベーススキーマ、パッケージ選定、機能ごとの実装計画を `docs/` 配下にまとめています。
すべてを一度に作り込むのではなく、実装しながら判断した内容や残課題もドキュメントとして残し、後から方針を追えるようにしています。

### AI開発ツールの活用

Claude Code や Codex などの生成AIツールを、実装方針の整理、コードレビュー、技術調査、ドキュメント作成の補助として活用しています。
生成されたコードをそのまま採用するのではなく、既存設計との整合性、保守性、実装範囲を確認しながら取り入れています。

## ドキュメント一覧

- [プロジェクト概要・アプリ仕様・要件](./docs/project-overview.md)
- [ユビキタス言語](./docs/ubiquitous-language.md)
- [アーキテクチャ](./docs/architecture.md)
- [パッケージ選定ガイド](./docs/package-selection.md)
- [アプリ画面遷移図](./docs/navigation.md)
- [データベーススキーマ設計](./docs/database-schema.md)
- [パスワードリセット設定手順](./docs/password-reset-code-setup.md)
- [実装計画一覧](./docs/plans/README.md)

## セットアップ

このプロジェクトでは Flutter SDK の管理に FVM を使用しています。

```bash
# ワークスペースの依存関係を取得
dart pub get

# アプリの依存関係を取得
cd packages/apps/kaimono_plus
fvm flutter pub get

# アプリを起動
fvm flutter run -t lib/main.dart
```

### よく使うコマンド

```bash
# 静的解析
cd packages/apps/kaimono_plus
fvm flutter analyze

# テスト
cd packages/core/auth
fvm flutter test

# iOS 向けビルド
cd packages/apps/kaimono_plus
fvm flutter build ipa -t lib/main.dart --release
```
