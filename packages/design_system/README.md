# Design System

アプリケーションのデザインシステムパッケージです。

## 概要

テーマ、カラー、タイポグラフィなどのデザイン要素を一元管理します。

## 構成

- `lib/theme/app_theme.dart`: アプリケーションのテーマ定義

## 使用方法

```dart
import 'package:design_system/design_system.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  // ...
)
```
