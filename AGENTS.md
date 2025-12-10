# リポジトリガイドライン

このワークスペースには Flutter アプリ（`packages/apps/kaimono_plus`）と共有認証パッケージ（`packages/core/auth`）が含まれています。変更をレビューしやすく保つため、以下に従ってください。

## 言語とコミュニケーション
- やり取りや説明は日本語で行うこと。回答・コメント・レビューも日本語に統一してください。

## プロジェクト構成
- ルートの `pubspec.yaml` が Dart ワークスペースを定義し、各パッケージは `packages/` 配下に配置されています。
- アプリ本体：`packages/apps/kaimono_plus`。エントリーポイントは `lib/main.dart` で、ページウィジェットは `lib/pages/` にあります。`android/ios/web/windows/macos/linux` は Flutter が生成するフォルダーです。
- 共有ライブラリ：`packages/core/auth`。公開インターフェースは `lib/auth.dart`、テストは `test/auth_test.dart` にあります。アプリは `path: ../../core/auth` で依存します。
- `build/` 配下は生成物なので直接編集しないでください。

## セットアップ・ビルド・実行
```
dart pub get                                   # ワークスペースのツールを取得
cd packages/apps/kaimono_plus && flutter pub get
cd packages/apps/kaimono_plus && flutter run    # ローカル起動
cd packages/apps/kaimono_plus && flutter build apk --release
cd packages/apps/kaimono_plus && flutter analyze
cd packages/core/auth && flutter test           # パッケージのテスト実行
```

## コーディングスタイルと命名
- Lint: `analysis_options.yaml` で `flutter_lints` を使用。`flutter analyze` をクリーンに保つこと。
- フォーマット: `dart format .` を使う（2 スペースインデント、複数行の引数/コレクションには末尾カンマ）。
- 命名: ウィジェット/クラスは `PascalCase`、メンバーやローカル変数は `lowerCamelCase`、ファイルは `snake_case`（例：`list_page.dart`）。
- build メソッドは小さく保ち、肥大化する場合は `lib/pages/` や必要に応じた新フォルダーにウィジェット/プロバイダーを切り出す。

## テストの指針
- フレームワーク: `flutter_test`。各パッケージの `test/` 配下に `*_test.dart` を追加。
- 新しいビジネスロジック（ビューモデル、プロバイダー、共有 auth ヘルパー）をカバーするテストを書く。前準備→実行→検証の流れで決定的なテストを好む。
- PR 前にパッケージルートで `flutter test` を実行。UI 変更時は可能ならゴールデン/ウィジェットテストも追加する。

## コミットと PR の指針
- 直近のコミットは短く記述的（日本語が多い）。命令形で簡潔に（例：「Add sign-in validation」）。関連イシューがあれば ID を含める。
- PR には範囲の概要、実行したテストコマンド、UI 変更時はスクリーンショット/GIF を含める。関連イシューを紐づけ、差分は小さくレビューしやすく保つ。
- 秘密情報や環境依存ファイルはコミットしない。設定は Flutter/Dart のデフォルトやプラットフォーム別の `.env` などリポジトリ外の仕組みを用いる。
