# 要求内容 — 墨絵テーマ実装指示書反映

## 概要

`docs/ideas/sumi-theme/README.md` の Task 1〜7 に沿って、Brain Ghost の UI/UX を **墨絵テーマ (washi + sumi ink + 人魂青)** へ全面刷新する。既存の sumineko / washi 系アセットを新規 sumi-theme/ 素材で置き換え、ホーム画面・ミニゲーム一覧画面・全画面背景を再構築する。

## 背景

- 現状の UI は v3 Midnight Cat (黒基調) → v4 Sumi Ghost (washi/sumi) への移行途上で、直前ステアリング (`20260526-墨絵デザインシステムとリカバリ`) のコード変更は反映済みだがデバイスロックで実機検証が未完
- ユーザが新規に sumi-theme/ 配下に背景 7 枚 + シート画像 6 枚 (うち home 系は 4 分割) + キャラリファレンスを配置
- これを正式素材として採用し、刷新を完遂するための指示書が `docs/ideas/sumi-theme/README.md`
- 直前の試行で **デザインシステム不在のまま実装に着手して破綻** した経験があるため、今回は指示書 + 本ステアリングの 2 段構えで進める

## 実装対象の機能

### 1. シート画像からのパーツ切り出し (Task 1)

- `docs/ideas/sumi-theme/references/` のシート画像から個別 PNG を Pillow スクリプトで切り出す
- 白背景透過 (alpha 閾値 240) + 周囲トリム
- 出力先: `docs/ideas/sumi-theme/parts/{buttons,badges,decorations,bars,game_icons,frames}/`
- 切り出し対象: 33 パーツ (ui_parts_sheet 24 + game_cards 6 + card_states 3)

### 2. アセットコピー (Task 2)

- 切り出した parts/ と既存 backgrounds/ を `assets/textures/{backgrounds,frames,buttons,badges,decorations,game_icons,bars}/` へコピー
- `.import` ファイルは Godot 側で自動生成 (初回 import 実行)

### 3. カラーパレット定数 (Task 3)

- 新規 `scripts/constants/colors.gd` を作成し `class_name SumiColors` で公開
- 9 色 (+ `HITODAMA_FILL` レーダー塗り用) を `const` で定義
- 既存 `scripts/utils/color_palette.gd` は alias として残置 (移行期)

### 4. テーマリソース (Task 4)

- 新規 `assets/themes/sumi_theme.tres` を **GDScript で生成** (`scripts_build/build_sumi_theme.gd`)
  - 手書き .tres は StyleBoxTexture プロパティ名・SubResource 参照ミスでパースエラーを起こしやすい
  - README の `assets/theme/` (単数形) は誤記。実配置は `assets/themes/` (複数形)
- フォント 3 種登録: Noto Serif JP Bold (見出し) / Space Grotesk Bold (数字) / JetBrains Mono Regular (タイマー)
- ボタン 3 系統 (primary / secondary / accent) を NinePatchRect 背景で定義 (`expand_margin_*` を使用)
- Panel デフォルト背景: WASHI

### 5. ホーム画面再構築 (Task 5)

- `scenes/main/home.tscn` を指示書の 6 ブロック構成に再構築:
  1. 脳年齢カード (墨洗い)
  2. デイリースコアカード (墨枠 NinePatchRect)
  3. ゴースト戦績 + ストリーク (相撲番付 + 朱印帳)
  4. レーダーチャート (円相 `_draw()`)
  5. デイリーチャレンジ帯 (絵巻物)
  6. 全ゲーム一覧ボタン (secondary)

### 6. ミニゲーム一覧画面 (Task 6)

- `scenes/ui/game_list.tscn` を 2 列 GridContainer に再構築
- 6 ゲーム × 各カード (NinePatchRect 墨枠 + アイコン + 名前 + 能力 + ベスト)
- ロック中 / NEW / ティア選択中の各状態に対応

### 7. 全画面の背景差し替え (Task 7)

- home / play / result_win / result_lose / onboarding / rule / その他 の 7 種背景を TextureRect 最背面に配置
- stretch_mode = 6 (KEEP_ASPECT_COVERED) 統一

### 8. フォント取得 (Task 0 = 前提整備)

- Space Grotesk Bold (OFL) と JetBrains Mono Regular (OFL) を **curl** で取得 (※ WebFetch はバイナリ非対応)
- Space Grotesk は GitHub Release zip → `static/SpaceGrotesk-Bold.ttf` を抽出
- JetBrains Mono は JetBrains 公式 zip → `fonts/ttf/JetBrainsMono-Regular.ttf` を抽出
- ライセンス確認のうえ `assets/fonts/` に配置
- 取得失敗時は NotoSansJP-Bold で代替 (タスク本文に明記)

## 受け入れ条件

### 全体

- [ ] Android 実機 (192.168.1.111:37123) で APK インストール後、ホーム画面が和紙ベージュ背景 (#F5F0E8 系) + 墨色テキストで描画される
- [ ] 通知シェードを閉じた状態のスクリーンショットで、黒背景が一切残っていない (実機解除後のスクショで目視判定)
- [ ] ヘッドレスパース 2 段階クリア
  - [ ] `godot --check-only --path /workspace` (GDScript 構文) exit 0
  - [ ] `godot --headless --import --path /workspace --quit-after 30` (.tscn の res:// 解決) exit 0
- [ ] 全ゲームから戻る/起動するルートで背景が常に和紙系 (黒画面なし)

### Task 1 (切り出し)

- [ ] 33 パーツ全てが `parts/` 配下に PNG として存在
- [ ] 各 PNG は背景透過済み (アルファチャンネル付き)
- [ ] サイズが極端に小さい (< 20px 四方) または巨大 (シート全体相当) なものがない

### Task 2 (コピー)

- [ ] `assets/textures/backgrounds/bg_*.png` が 7 枚
- [ ] `assets/textures/buttons/btn_*.png` が 3 枚
- [ ] `assets/textures/frames/frame_ink_border*.png` が 3 枚
- [ ] `assets/textures/game_icons/game_icon_*.png` が 6 枚
- [ ] `assets/textures/badges/`, `decorations/`, `bars/` も指示書通り

### Task 3 (colors.gd)

- [ ] `SumiColors.WASHI` 等が GDScript の static const として参照可能
- [ ] 既存 `color_palette.gd` 経由のアクセスも壊れていない (alias 化)

### Task 4 (sumi_theme.tres)

- [ ] `project.godot` の `gui/theme/custom` で `sumi_theme.tres` を指定
- [ ] Noto Serif JP / Space Grotesk / JetBrains Mono が theme から読める (取得失敗時は代替フォントで動作)
- [ ] ボタン 3 種が NinePatchRect 背景でレンダリングされる

### Task 5 (home)

- [ ] 起動後 1 秒以内に上記 6 ブロックが全て可視
- [ ] レーダーチャートが PNG ではなく `_draw()` 描画
- [ ] 最強軸頂点が金泥 (#C9A84C)、最弱軸下に「鍛える →」リンク
- [ ] ストリークが 7 個並ぶ (当日朱印 + 過去薄朱 + 未空)

### Task 6 (game_list)

- [ ] 6 ゲームカードが 2 列 × 3 行で表示
- [ ] ロック中ゲームは `frame_ink_border_locked` + `icon_lock` 中央配置
- [ ] 各カード右上に小さく `hitodama.png` (alpha 0.5)

### Task 7 (全画面背景)

- [ ] 全 scene の最背面に TextureRect が配置されている
- [ ] 背景が画面比率に応じて KEEP_ASPECT_COVERED で延伸
- [ ] z_index = -100 で他要素より下

## 成功指標

- 視覚: ホーム画面のキャプチャを見て「和紙の質感 + 墨色文字 + 人魂青のレーダー」が同時に成立
- 体感: タップ操作時に黒画面の瞬間が一度もない (起動 → home → game_list → ゲーム選択 → result まで)
- コード: `grep -rE "VoidBg|NebulaBg|MidnightCat|catboy_" scenes/ scripts/` のヒット数 0

## スコープ外

以下はこのフェーズでは実装しません:

- ミニゲーム本体の UI 刷新 (タップ反応、スコア表示、ゴーストバー演出など) — 次回スコープ
- マスコット (sumineko) のアニメーション差し替え — 既存 6 ポーズの再生ロジックは維持
- 結果画面 (individual_result, overall_result) の中身刷新 — 背景差し替えのみ実施
- 設定画面・オンボーディング画面の刷新 — 背景差し替えのみ実施
- 旧アセット (`assets/characters/sumineko_*.png`, `assets/backgrounds/washi_*.png`) の物理削除 — alias 残置で次回判断
- フォントが取得できなかった場合の独自フォント探索 — NotoSansJP-Bold フォールバックで確定

## 参照ドキュメント

- `docs/ideas/sumi-theme/README.md` — 一次指示書
- `docs/design/sumi_ghost_design_system.md` — 直前作成のデザインシステム SSOT
- `docs/product-requirements.md` — PRD
- `docs/functional-design.md` — 機能設計
- `docs/architecture.md` — アーキテクチャ
- `docs/development-guidelines.md` — 開発規約
- `.steering/20260526-墨絵デザインシステムとリカバリ/` — 直前ステアリング (本作業で上書き)
