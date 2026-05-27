# 要求内容

## 概要

直前の「墨絵テーマ刷新（タスク #9）」と「マスコット書換版（タスク #12）」が、デザインシステム不在のまま着手された結果、実機で **黒背景 + 黒テキストの不可視状態** に陥っている。本ステアリングでは:

1. **デザインシステム文書** `docs/design/sumi_ghost_design_system.md` を新設して色の発生源・適用ルール・移行表を一元化
2. その文書に従って、**シーンに残った旧 Midnight Cat 残骸**（背景ノード / インライン色オーバーライド / StyleBoxFlat 直書き）を全面除去
3. 実機キャプチャで「ホームが和紙、テキストが墨色で読める」状態まで持っていく

アプリ名・マスコット ID・パレット定数（v4 Sumi Ghost）は変更しない。**今までの "上書き失敗" 部分を回復する作業に限定**する。

## 背景

直近 2 本のステアリング実装後、ユーザ確認で以下が判明:
- ホーム画面が黒のまま（和紙背景が見えない）
- 和紙テクスチャがウィンドウ枠内にしか出ていない
- パネル背景は変わったが、内部テキストの色がそのまま → 読めない

根本原因:
1. `home.tscn` を含む **15 シーンに `VoidBg` (黒 ColorRect) + `NebulaBg` (TextureRect) が生存**。WashiBackground を z_index=-100 にしても、これら 2 つは z_index=0 で上に描画される
2. tscn 内に **inline `theme_override_colors/font_color = Color(...)` が 115 件** あり、theme.tres 変更で吸収できない
3. tscn 内に **StyleBoxFlat の `bg_color = Color(...)` 直書きが 31 件**、これも theme.tres と独立
4. デザインシステム文書がないため「どの色を何に使う」のルールが曖昧で、機械置換時の判断軸が無い

## 実装対象の機能

### 1. デザインシステム文書の作成

新ファイル `docs/design/sumi_ghost_design_system.md` を作成。内容:

- **トークン**：13 色（前ステアリング `project_palette_sumi_ghost` メモリと整合）
- **表面階層（surface hierarchy）**：3 層 + 命名規約
- **テキスト階層**：H1 / H2 / Body / Caption / Disabled の 5 段
- **背景レイヤリング規約**：**シーン内に背景ノードは WashiBackground 1 つだけ**、他は禁止
- **コンポーネントパターン**：Button / Card / Panel / Badge / Pill / Headline それぞれの色マッピング
- **状態色**：normal / hover / pressed / disabled
- **v3 → v4 移行表**：頻出するインライン色値の置換マップ
- **禁止事項**：白系テキスト直書き / 黒系背景直書き / NebulaBg 系の使用

### 2. 全シーンからの旧背景ノード除去

15 シーンすべてから以下を**削除**（visible=false ではなくノードごと削除）:
- `VoidBg` (ColorRect)
- `NebulaBg` (TextureRect)
- `StarLayer` (Control)

WashiBackground のみが背景レイヤとして残る。

対象シーン:
- scenes/main/launch.tscn
- scenes/main/home.tscn
- scenes/ui/game_list.tscn
- scenes/ui/rule_explain.tscn / rule_explain_landscape.tscn
- scenes/ui/countdown.tscn / countdown_landscape.tscn
- scenes/ui/individual_result.tscn
- scenes/games/flash_calc/flash_calc_home.tscn / flash_calc_play.tscn
- scenes/games/sequence_memory.tscn
- scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn
- scenes/games/number_search/number_search.tscn
- scenes/games/card_match/card_match.tscn
- scenes/games/stroop/stroop.tscn
- **scenes/ui/components/nav_link_button.tscn**（インスタンス共通の NavLink ボタン、複数シーンから参照される）

### 3. インライン font_color 一括置換

tscn 内の `theme_override_colors/font_color = Color(...)` 115 件をデザインシステム文書の移行表に沿って Sumi 系へ機械置換。

頻出値（最低限カバー）:
| 旧値 | 新値 (役割) |
|---|---|
| `Color(0.7, 0.93, 1, 1)` × 15 | `SUMI_INK` 主要見出し |
| `Color(1, 0.914, 0.659, 1)` × 11 | `GOLD_AGED` 達成/強調 |
| `Color(0.722, 0.878, 1, 1)` × 10 | `SUMI_INK` 本文 |
| `Color(0.435, 0.706, 1, 1)` × 9 | `ONIBI_DEEP` リンク/強アクセント |
| `Color(0.78, 0.824, 0.91, 1)` × 7 | `SUMI_MID` サブ本文 |
| `Color(0.533, 0.588, 0.69, 1)` × 7 | `SUMI_LIGHT` キャプション |
| `Color(0.961, 0.78, 0.416, 1)` × 6 | `GOLD_AGED` |
| `Color(0.722, 0.878, 1, 0.7)` × 6 | `Color(0.106, 0.106, 0.122, 0.85)` 半透明 |
| その他 | デザインシステム移行表に従う |

### 4. シーン内 StyleBoxFlat の bg_color 一括置換

`bg_color = Color(...)` 31 件を Washi/Sumi 系に置換。

頻出値:
| 旧値 | 新値 |
|---|---|
| `Color(0.067, 0.094, 0.153, 0.7)` × 7 | WASHI_PANEL × 0.85 |
| `Color(0.04, 0.08, 0.16, 0.55)` × 4 | WASHI_PANEL × 0.7 |
| `Color(0.7, 0.93, 1, 0.6)` × 2 | ONIBI_GLOW × 0.6 |
| `Color(0.435, 0.706, 1, ...)` 系 | ONIBI_BLUE × 同 alpha |
| その他 | デザインシステムに従う |

### 5. 実機キャプチャによる検証

- 各主要画面（home / game_list / rule_explain / countdown / play / individual_result）の **実機スクリーンショットを取得**し、`docs/design/snapshots/sumi_ghost/` に保存
- ロック画面が邪魔する場合は、`adb shell input keyevent KEYCODE_WAKEUP` + ロック解除 PIN コードを試す。それも難しければ実機ユーザに手動撮影を依頼してフォルダ配置

## 受け入れ条件

### デザインシステム文書

- [ ] `docs/design/sumi_ghost_design_system.md` が新設されている
- [ ] 13 色トークン + 表面階層 + テキスト階層 + 背景規約 + コンポーネントパターン + v3→v4 移行表 をすべて含む

### 背景ノード除去

- [ ] `grep -rE '\[node name="(VoidBg|NebulaBg|StarLayer)"' scenes/` で 0 件
- [ ] 各シーンの背景は WashiBackground のみ
- [ ] 起動・ホーム・ゲーム画面で**黒地が見えない**（実機目視）

### インライン色置換

- [ ] **修正済 grep**（ERE で `\|` ではなく `(a|b|c)` グループ化）:
  - `grep -rE 'font_color = Color\((0\.7, 0\.93, 1|0\.722, 0\.878, 1|0\.435, 0\.706, 1|0\.78, 0\.824, 0\.91|0\.533, 0\.588, 0\.69)' scenes/` で 0 件
  - `grep -rE 'bg_color = Color\((0\.067, 0\.094, 0\.153|0\.04, 0\.08, 0\.16|0\.063, 0\.075, 0\.118|0\.043, 0\.071, 0\.125)' scenes/` で 0 件

### 実機キャプチャ検証

- [ ] ホーム / 個別結果（NEW BEST / NICE TRY） / ゲーム画面 1 種 の最低 4 枚を `docs/design/snapshots/sumi_ghost/` に保存
- [ ] ホームで「和紙背景 + 墨黒テキスト」になっている目視確認

## 成功指標

- 実機で文字が読める（コントラスト比 AA 以上）
- 和紙背景が画面全体を占めている（ウィンドウ枠内だけではない）
- パネル・カード内のテキストも墨色で読める

## スコープ外

- マスコット強化版ステアリングで掲げた残タスク（ホーム常駐タップ反応の演出磨きなど）
- 7 種の不足ポーズ作成
- ゲーム内マスコット演出
- 旧 catboy_* / VoidBg 系の物理削除以外のリファクタ（命名変更等）

## 参照ドキュメント

- `docs/product-requirements.md` / `docs/architecture.md`
- `docs/development-guidelines.md`
- 既存: `scripts/utils/color_palette.gd` (v4 Sumi Ghost 定義)
- 既存メモリ: `project_palette_sumi_ghost.md`
- 直前ステアリング: `20260525-墨絵テーマ刷新/` / `20260526-SDキャラ強化UX書換版/`
