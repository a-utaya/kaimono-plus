# 買い物リスト履歴・タグ追加 実装計画 / Shopping List History and Tags Implementation Plan

- **作成日**: 2026-06-05
- **ステータス**: 実装中
- **関連 Issue**: なし
- **関連 PR**: （未作成）

---

## Summary (EN)

**Goal:** Make shopping-list creation faster and easier to revisit by saving lists and allowing users to add items from reusable tags.

**Approach:** Persist created lists and shopping-item tags in Firestore. Add a history grid, a list title field, card actions, tag creation/editing, tag selection, and tag sorting in the shopping-list flow.

**Acceptance criteria (high level):**

- [x] Created shopping lists remain available after app reload
- [x] History shows saved lists as rounded two-column cards
- [x] Users can create, edit, delete, and select shopping-item tags
- [x] Selected tags can be added to the current shopping list in one action
- [ ] Remaining UX edge cases are verified on device

**Out of scope:** Web-based list viewing, shared tag libraries between users, image-based item recognition.

---

## 1. 目的・背景

### なぜやるか

- 買い物前にリストを作成しておき、買い物時に再度開けるようにする。
- 前回の買い物内容を履歴として確認し、買い忘れや余りものの記憶を呼び起こしやすくする。
- 毎回手入力する負担を減らし、よく買うものをタグから素早く追加できるようにする。

### 前提・制約

- ユーザーごとのデータは Firestore の `users/{uid}` 配下に保存する。
- タグ色は買い物リスト本体の分類ではなく、タグ選択画面で探しやすくするための補助として扱う。
- タグ色は任意。色未選択のタグは白背景・グレー配色で表示する。
- 新規 pub 依存は追加しない。

---

## 2. 実装概要

### 何を実装するか

- 買い物リスト作成画面に任意タイトルを追加し、履歴カードのタイトルとして表示する。
- 保存した買い物リストを履歴タブに 2 カラムの角丸カードで表示する。
- 履歴カードのメニューから削除できるようにする。
- 履歴カードの長押し複数選択と並び替えをできるようにする。
- 買うものタグを Firestore に保存し、作成・編集・削除できるようにする。
- タグ選択シートで、登録済みタグから複数選択して買い物リストへ追加できるようにする。
- 登録済みタグは色ごとにまとまり、色グループ内で「かな → 漢字 → 英語 → その他」の順に並べる。

### どのように実装するか

`KaimonoListPageViewModel` に履歴とタグの状態・Firestore リポジトリ連携を追加する。履歴は `HomeShellPage` の履歴タブで表示し、タグ操作は `KaimonoListPage` のボトムシートと詳細画面で完結させる。タグ選択時は登録済み一覧から選択済みタグを一時的に非表示にし、「選択したもの」エリアから解除できるようにする。

### 影響範囲

| 対象 | 変更の有無 | メモ |
| --- | --- | --- |
| `packages/apps/kaimono_plus` | あり | 買い物リスト画面、履歴タブ、Firestore rules |
| `packages/core/auth` | なし | 既存の認証ユーザー ID を利用 |
| Firebase | あり | Firestore の `kaimonoLists` / `shoppingItemTags` と rules |

---

## 3. タスク一覧

### 準備

- [x] 履歴の日付表示は更新日を使う方針に決定
- [x] 履歴カードのタイトルはユーザー任意入力にする方針に決定
- [x] タグ色はタグ選択画面で探すための補助として扱う方針に決定

### 実装（履歴）

- [x] 作成画面にリストタイトル入力を追加
- [x] 保存時に空の買うもの欄を除外する
- [x] 作成済み買い物リストを Firestore に保存する
- [x] アプリ再起動後も履歴を復元する
- [x] 履歴タブに 2 カラムの角丸カードを表示する
- [x] 履歴カードに更新日を表示する
- [x] 履歴カードの件数表示を外し、メニューを表示する
- [x] 履歴カードの削除メニューを追加
- [x] 履歴カードの長押し複数選択を追加
- [x] 履歴カードの並び替えを追加
- [x] 未設定時の履歴カード背景色をデフォルト黄色にする

### 実装（タグ）

- [x] タグから追加するボトムシートを追加
- [x] タグ名入力欄に検索機能を統合
- [x] タグの作成・編集・削除を Firestore に保存する
- [x] タグ長押しで編集画面へ遷移する
- [x] タグ色を任意選択にする
- [x] 選択中の色を再タップすると色選択を解除する
- [x] タグ作成後も選択中の色を維持する
- [x] 色未選択タグを白背景・グレー配色で表示する
- [x] 登録済みタグから選択したタグを一覧から非表示にする
- [x] 「選択したもの」エリアから解除したタグを登録済み一覧へ戻す
- [x] 「選択したもの」エリアは 1 行分の高さを維持し、2 行目以降で自然に伸ばす
- [x] 登録済みタグを色グループごとに並べる
- [x] 色グループ内を「かな → 漢字 → 英語 → その他」で並べる

### 品質

- [x] `fvm dart format`
- [x] `fvm flutter analyze`
- [ ] 実機またはシミュレータで履歴保存・再起動後復元を確認
- [ ] 実機またはシミュレータでタグ作成・編集・削除・選択・解除を確認
- [ ] Firestore rules をデプロイ済み環境で確認

---

## 4. 実装詳細（レビュー用）

### 新規作成

| パス | 種別 | 役割 |
| --- | --- | --- |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/components/shopping_item_tag_sheet.part.dart` | Widget / Page | タグ追加ボトムシート、タグチップ、タグ詳細編集画面 |

### 既存ファイルの変更

| パス | 変更内容 |
| --- | --- |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/kaimono_list_page.dart` | タイトル入力、保存、タグ追加導線、入力フォーカス改善 |
| `packages/apps/kaimono_plus/lib/pages/kaimono_list_page/kaimono_list_page_view_model.dart` | 履歴・タグ状態、Firestore 保存/購読、タグ追加ロジック |
| `packages/apps/kaimono_plus/lib/pages/home_shell_page/home_shell_page.dart` | 履歴カード表示、カード削除、複数選択、並び替え |
| `packages/apps/kaimono_plus/firestore.rules` | `kaimonoLists` と `shoppingItemTags` の本人用 read/write ルール |

### データ・外部連携

- `users/{uid}/kaimonoLists/{listId}` に作成済み買い物リストを保存する。
- `users/{uid}/shoppingItemTags/{tagId}` に買うものタグを保存する。
- Firestore からの購読結果を ViewModel に反映し、画面側は Riverpod の state を watch する。

---

## 5. テスト計画

| 種別 | 内容 | コマンド / 手順 |
| --- | --- | --- |
| 静的解析 | アプリ全体の解析 | `cd packages/apps/kaimono_plus && fvm flutter analyze` |
| 手動確認 | リスト保存後、履歴カードが表示される | シミュレータ / 実機 |
| 手動確認 | アプリ再起動後、履歴カードが残る | シミュレータ / 実機 |
| 手動確認 | 空欄を含むリストを保存しても空項目が保存されない | シミュレータ / 実機 |
| 手動確認 | タグ作成・編集・削除が再起動後も保持される | シミュレータ / 実機 |
| 手動確認 | 登録済みタグの選択・解除・買い物リストへの追加が自然に動く | シミュレータ / 実機 |
| 手動確認 | 登録済みタグのソート順が意図通り | シミュレータ / 実機 |

---

## 6. リスク・未決事項

- [ ] タグ数が多くなった時の検索・スクロール体験を追加確認する。
- [ ] タグ色を買い物リスト本体にも反映するかは、画面が騒がしくならないかを見て判断する。
- [ ] 履歴カードの背景色変更 UI は、カテゴリ分け用途として必要になった段階で磨き込む。
- [ ] 履歴・タグのウィジェットテスト追加範囲を検討する。

---

## 7. レビュー用メモ

- **重点的に見てほしい箇所**: Firestore の保存・購読、タグ選択シートの状態管理、履歴カードの並び替え。
- **意図的に今回やらないこと**: Web での共有リスト表示、タグ色のリスト本体への反映、タグのユーザー間共有。

---

## 更新履歴

| 日付 | 変更内容 |
| --- | --- |
| 2026-06-05 | 初版作成。履歴永続化、履歴カード表示、タグ作成・編集・選択、タグソートの実装方針と進捗を反映 |
