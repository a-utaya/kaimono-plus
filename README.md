# Kaimono +

買い物リスト管理アプリのワークスペースリポジトリです。

## 概要

このリポジトリは、Flutter を使用した買い物リスト管理アプリの開発ワークスペースです。
モノレポ構成を採用しており、複数のパッケージを一元管理しています。

## プロジェクト構成

```
kaimono_plus/
├── packages/
│   ├── apps/
│   │   └── kaimono_plus/        # メインアプリケーション
│   └── core/
│       └── auth/                # 認証共有パッケージ
└── docs/                        # プロジェクトドキュメント
```

## ドキュメント

詳細なドキュメントは [`docs/`](./docs/) ディレクトリを参照してください。

- [プロジェクト概要・アプリ仕様・要件](./docs/project-overview.md)
- [ユビキタス言語](./docs/ubiquitous-language.md)
- [アーキテクチャ](./docs/architecture.md)
- [パッケージ選定ガイド](./docs/package-selection.md)
- [アプリ画面遷移図](./docs/navigation.md)
- [データベーススキーマ設計](./docs/database-schema.md)

## セットアップ

```bash
# ワークスペースの依存関係を取得
dart pub get

# アプリの依存関係を取得
cd packages/apps/kaimono_plus && fvm flutter pub get

# アプリを起動
cd packages/apps/kaimono_plus && fvm flutter run
```

## 開発ガイドライン

開発に関するガイドラインは [`AGENTS.md`](./AGENTS.md) を参照してください。

## ライセンス

[ライセンス情報を記載]
