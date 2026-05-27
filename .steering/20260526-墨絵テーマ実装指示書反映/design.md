# 設計書 — 墨絵テーマ実装指示書反映

## アーキテクチャ概要

レイヤード構成: **素材 → トークン → テーマ → 画面**。各層に単一責任を持たせ、上位は下位を参照のみ。

```
┌────────────────────────────────────────────────────────────┐
│ 画面層 (scenes/main/, scenes/ui/)                          │
│  home.tscn / game_list.tscn / 他 (背景差し替えのみ)         │
└────────────┬───────────────────────────────────────────────┘
             │ use
┌────────────▼───────────────────────────────────────────────┐
│ テーマ層 (assets/themes/sumi_theme.tres)                   │
│  Button / Panel / Label / NinePatchRect の StyleBox 統一    │
└────────────┬───────────────────────────────────────────────┘
             │ reference
┌────────────▼───────────────────────────────────────────────┐
│ トークン層 (scripts/constants/colors.gd = SumiColors)      │
│  9 色定数 + HITODAMA_FILL                                  │
└────────────┬───────────────────────────────────────────────┘
             │ load
┌────────────▼───────────────────────────────────────────────┐
│ 素材層 (assets/textures/{backgrounds,frames,...}/)         │
│  Pillow 切り出し PNG + フォント (OFL DL)                   │
└────────────────────────────────────────────────────────────┘
```

## コンポーネント設計

### 1. シート切り出しスクリプト (`scripts_build/cut_sumi_sheets.py`)

**責務**:
- 5 シート画像から 33 パーツ + 4 home パーツを矩形クロップ
- 白背景透過 (RGB 各チャンネル ≥ 240 を α=0 に)
- 周囲トリム (透明ピクセル除去) → padding 2px で余白付与
- 出力先ディレクトリを自動生成

**対象シート (7 枚)** — README が想定する `home_components_sheet.png` は実在しないため、4 分割版を使用:
- ui_parts_sheet.png (24 パーツ)
- game_cards.png (6 ゲームアイコン)
- card_states.png (3 フレーム状態)
- ui_parts_home_nenrei.png / ui_parts_home_score.png / ui_parts_home_graph.png / ui_parts_home_daily.png (home 系 4 分割)

**実装の要点**:
- Pillow (`PIL.Image`) のみ使用。numpy 等の重い依存は避ける
- 矩形座標は CSV 風の dict で管理 (シート別)
- 矩形が画像範囲外の場合は警告のみ (中断しない)
- α マスク化: `Image.convert("RGBA")` → 各ピクセル走査 → 白い箇所 (R/G/B 全て ≥ threshold) を `(r,g,b,0)` に
- トリム: `image.getbbox()` で非透明領域の bbox を取得 → crop → padding 2px
- 閾値はコマンドライン引数 `--threshold` で上書き可能 (デフォルト 240、輪郭がジャギーな場合は 230 に下げる)

**矩形座標の決定プロセス** (スクリプト作成前に必須):
1. 7 シートをそれぞれ Pillow で開いて `size` を取得 (シート別 px サイズ把握)
2. 各シートを目視で確認し、各パーツの矩形 (x, y, w, h) を確定
3. 確定した辞書を `scripts_build/cut_sumi_sheets.py` の冒頭 const として記述
4. 切り出し直後に確認用サムネイル (`docs/ideas/sumi-theme/parts/_thumbs.png`) を生成して目視確認

### 2. アセットコピー (`scripts_build/copy_sumi_assets.sh`)

**責務**:
- `docs/ideas/sumi-theme/{backgrounds,parts}/*` を `assets/textures/*` 配下にコピー
- 既存ファイルがあれば上書き (バックアップ不要)
- `.import` ファイルは存在しても上書きしない (Godot が再生成)

**実装の要点**:
- `cp -r` ベース。シェルで完結
- コピー後に `ls -la` で確認出力

### 3. SumiColors 定数 (`scripts/constants/colors.gd`)

**責務**:
- 9 色 + 1 塗り色を GDScript の static const で公開
- 既存コードからは `SumiColors.WASHI` で参照可能

**実装の要点**:
```gdscript
class_name SumiColors

const WASHI = Color("#F5F0E8")
const SUMI_DARK = Color("#2C2C2C")
const SUMI_LIGHT = Color("#8C8C8C")
const HITODAMA = Color("#B8D8E8")
const WAKATAKE = Color("#7DB88A")
const KINDEI = Color("#C9A84C")
const SHU = Color("#C85A4A")
const GINNEZUMI = Color("#9EA1A3")
const HITODAMA_FILL = Color(0.72, 0.85, 0.91, 0.2)
```

- `class_name` でグローバル登録するので autoload 不要
- ※ Rev 指摘により、既存 `color_palette.gd` への alias 追加は **実施しない**。`class_name` 解決順序の問題で「Unknown class SumiColors」エラーになる可能性。既存定数はそのまま残置し、新コードでは `SumiColors` を直接参照する段階的移行方針

### 4. sumi_theme.tres (`assets/themes/sumi_theme.tres`)

> **重要**: README は `assets/theme/` (単数形) と書いているが誤記。実配置は `assets/themes/` (複数形)。
> **重要**: 手書き .tres は StyleBoxTexture のプロパティ名・id 参照ミスでパースエラーを起こしやすい。**GDScript で生成** する方針 (既存 `scripts_build/build_theme.gd` を拡張、または新規 `scripts_build/build_sumi_theme.gd`)。

**責務**:
- フォント 3 種を登録 (`Theme.set_default_font` + 個別カスタム名)
- ボタン (Button) の `normal/hover/pressed/disabled` StyleBox を NinePatchRect 風に
- Panel の bg_color = WASHI
- Label の `font_color = SUMI_DARK` (デフォルト)

**実装の要点**:
- `Theme` リソースを GDScript で組み立てて `ResourceSaver.save()` で .tres 化
- フォント未取得時は NotoSansJP-Bold を Space Grotesk / JetBrains Mono 枠で再利用
- ボタン背景は `StyleBoxTexture` で `btn_primary.png` を指定。NinePatch マージンは `expand_margin_*` (Godot 4 でのプロパティ名)
- フォント拡張子は `.ttf` で統一 (Space Grotesk Static / JetBrains Mono は ttf)

**GDScript 生成擬似コード**:
```gdscript
# scripts_build/build_sumi_theme.gd
@tool
extends EditorScript
func _run():
    var theme = Theme.new()
    var noto_serif = load("res://assets/fonts/NotoSerifJP-Bold.otf")
    var space = load("res://assets/fonts/SpaceGrotesk-Bold.ttf") if FileAccess.file_exists("res://assets/fonts/SpaceGrotesk-Bold.ttf") else load("res://assets/fonts/NotoSansJP-Bold.otf")
    var mono = load("res://assets/fonts/JetBrainsMono-Regular.ttf") if FileAccess.file_exists(...) else load("res://assets/fonts/NotoSansJP-Bold.otf")
    theme.default_font = noto_serif
    theme.default_font_size = 14
    var sb_btn = StyleBoxTexture.new()
    sb_btn.texture = load("res://assets/textures/buttons/btn_primary.png")
    sb_btn.expand_margin_left = 12; sb_btn.expand_margin_top = 12
    sb_btn.expand_margin_right = 12; sb_btn.expand_margin_bottom = 12
    theme.set_stylebox("normal", "Button", sb_btn)
    var sb_panel = StyleBoxFlat.new()
    sb_panel.bg_color = SumiColors.WASHI
    theme.set_stylebox("panel", "Panel", sb_panel)
    theme.set_color("font_color", "Label", SumiColors.SUMI_DARK)
    ResourceSaver.save(theme, "res://assets/themes/sumi_theme.tres")
```

**参考用 .tres 構造** (実際は build スクリプト経由で生成):
```
[gd_resource type="Theme" load_steps=N format=3]
[ext_resource type="FontFile" path="res://assets/fonts/NotoSerifJP-Bold.otf" id="1"]
[ext_resource type="FontFile" path="res://assets/fonts/SpaceGrotesk-Bold.ttf" id="2"]  # 取得失敗時は ExtResource id=1 を再利用
[ext_resource type="FontFile" path="res://assets/fonts/JetBrainsMono-Regular.ttf" id="3"]
[ext_resource type="Texture2D" path="res://assets/textures/buttons/btn_primary.png" id="10"]
[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_btn_primary"]
texture = ExtResource("10")
expand_margin_left = 12.0
expand_margin_top = 12.0
expand_margin_right = 12.0
expand_margin_bottom = 12.0
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel_washi"]
bg_color = Color(0.96, 0.94, 0.91, 1)
[resource]
default_font = ExtResource("1")
default_font_size = 14
Button/styles/normal = SubResource("StyleBoxTexture_btn_primary")
Button/colors/font_color = Color(1, 1, 1, 1)
Panel/styles/panel = SubResource("StyleBoxFlat_panel_washi")
Label/colors/font_color = Color(0.173, 0.173, 0.173, 1)
```

### 5. ホーム画面 (`scenes/main/home.tscn`)

**責務**: 6 ブロック構成 + 和紙背景 + 墨スクリプト要素

**レイアウト** (VBoxContainer ベース):

```
Home (Control, anchors_preset=15)
├ WashiBackground (TextureRect, bg_home.png, z_index=-100)
└ SafeArea (MarginContainer, margins 24/56/24/48)
   └ MainColumn (VBoxContainer, separation 16)
      ├ TopRow (HBoxContainer): BrainAgeBlock + Spacer + SettingsButton
      ├ HeroRow (HBoxContainer): MascotController + SpeechBubble + MascotImage
      ├ DailyScoreCard (NinePatchRect + 内部 VBox)
      ├ StatsAndStreakRow (HBoxContainer)
      │   ├ StatsBlock (左半分: 通算 + 15勝 + 8敗 + 猫シルエット)
      │   └ StreakBlock (右半分: 7 個スタンプ + ラベル)
      ├ DividerThin (TextureRect, divider_thin.png)
      ├ RadarCard (PanelContainer + RadarChart + 鍛えるリンク)
      ├ DailyChallengeStrip (HBoxContainer + 3 ゲームアイコン + AccentBtn)
      └ AllGamesButton (Button with btn_secondary.png style)
```

**実装の要点**:
- 既存 home.tscn の構造を破棄せず、ブロック単位で **置き換え** する形で進める (既存の MascotController / SpeechBubble は維持)
- `脳年齢カード` の乾筆アンダーラインは `Line2D` を VBox 内に入れて offset_top で位置調整
- 各 NinePatchRect の `texture_margin_*` は 12px (frame_ink_border.png に合わせる)
- 右上隅装飾 (猫シルエット・人魂等) は z_index = 1 で前面に出す

### 6. レーダーチャート (`scripts/ui/radar_chart.gd`)

**責務**: 円相風 6 軸レーダーを `_draw()` で描画

> **既存 API 互換**: 既存 `set_values(v: Array)` を維持 (`home_controller.gd:138` が呼び出し)。
> **書き換え戦略**: 旧 `_draw()` をコメントアウトせず、`_draw_v1_legacy()` にリネームして一時並存。新実装は `_draw_v2_sumi()`。動作確認後に旧を削除。

**実装の要点**:
- `extends Control` で `custom_minimum_size = Vector2(280, 280)` を既定
- ※ Godot 4 で `rand_range` は廃止。`randf_range(-0.5, 0.5)` を使用
- `_draw()` 内で以下を順に描画:
  1. 3 つの同心円 (`r = max_radius * [0.33, 0.66, 1.0]`)
     - 既存実装パターン (`draw_polyline` で多角形近似) を踏襲。draw_arc を直接使わず、64 セグメント程度の `draw_polyline` で円を描画
     - **隙間**: 3 等分位置で polyline のセグメントを間引く (一周を 6 分割 → 偶数番だけ描画)
     - 線幅は `width + randf_range(-0.5, 0.5)` で微変動
  2. 6 本の軸: 短いセグメントを分割描画 (8 セグメント程度) して太→細テーパー
  3. 軸先端の小丸: `draw_circle(vertex_i, 2, SUMI_DARK)`
  4. データ塗り: `draw_colored_polygon(data_points, HITODAMA_FILL)`
  5. データ輪郭: `draw_polyline(data_points + [data_points[0]], HITODAMA, 1.5)`
  6. 最強軸頂点: `draw_circle(data_points[max_idx], 4, KINDEI)`
- 軸ラベルは `Label` ノードを子に持たせ、`_draw()` 後に `set_position()` で配置
- 「鍛える →」リンクは最弱軸ラベルの下に `Button` (`flat = true`) を配置し、`pressed.connect()` でゲーム一覧へ
- API: 既存 `set_values(v: Array)` を主、内部で `_set_radar_values_impl()` に転送。`queue_redraw()` を呼ぶ

### 7. game_list.tscn (`scenes/ui/game_list.tscn`)

**責務**: 6 ゲームカードを 2 列 GridContainer で表示

**レイアウト**:
```
GameList (Control)
├ WashiBackground (TextureRect, bg_washi_base.png, z=-100)
└ SafeArea (MarginContainer)
   └ VBox
      ├ HeaderRow (戻るボタン + タイトル "ゲーム一覧")
      └ GridContainer (columns=2, separations 12/12)
         ├ Card_7ban (NinePatchRect + HBox)
         ├ Card_ippon
         ├ Card_search
         ├ Card_stroop
         ├ Card_sequence
         └ Card_memory
```

**各カード**:
- NinePatchRect (frame_ink_border.png, texture_margin 12px) を背景に
- HBox: 左 TextureRect (80×60 game_icon) + 右 VBox (名前 + 能力 + ベスト)
- 右上隅: TextureRect (hitodama.png 24×24, alpha 0.5)
- 状態は `card.gd` (既存) を再利用 or 新規 `game_list_card.gd` で状態切替

### 8. 全画面背景差し替え (Task 7)

**対象 scene 一覧** (`scenes/` 配下を grep して確定):
- `scenes/main/launch.tscn` → bg_washi_base
- `scenes/main/home.tscn` → bg_home
- `scenes/ui/game_list.tscn` → bg_washi_base
- `scenes/ui/rule_explain.tscn` → bg_onboarding (or bg_rule)
- `scenes/ui/rule_explain_landscape.tscn` → bg_onboarding
- `scenes/ui/countdown.tscn` → bg_play
- `scenes/ui/countdown_landscape.tscn` → bg_play
- `scenes/ui/individual_result.tscn` → 動的: result_win or result_lose
- `scenes/games/*.tscn` (6 種) → bg_play

**実装**: 各 .tscn の最初の子に `WashiBackground` TextureRect を追加。既存ノードがあれば上書きせず差し替え。Python ヘルパーで自動化。

## データフロー

### ホーム画面起動時のレーダー描画
```
1. home_controller.gd._ready()
2.   DataStore から能力スコア 6 軸を読む (0.0-1.0)
3.   RadarChart.set_values(scores)   # 既存 API を維持
4.   RadarChart.queue_redraw() → _draw() がトリガー
5.   最強軸を判定して KINDEI 頂点を描画
6.   最弱軸ラベルの下に「鍛える →」ボタンを配置
```

### 背景の動的切替 (individual_result)
```
1. result_controller.gd._ready()
2.   GameManager.last_result.ghost_won の真偽を取得
3.   WashiBackground.texture = preload("res://assets/textures/backgrounds/bg_result_win.png") or bg_result_lose.png
```

## エラーハンドリング戦略

### フォント取得失敗

- **curl 必須** (WebFetch はバイナリ非対応)
- 公式 URL からの DL 失敗時は `assets/fonts/NotoSansJP-Bold.otf` を Space Grotesk / JetBrains Mono 枠で再利用
- `scripts_build/build_sumi_theme.gd` の `_run()` で `FileAccess.file_exists()` 分岐により自動切替

### シート切り出しで矩形が画像範囲外

- Pillow で `crop()` 前に範囲チェック
- 範囲外の場合は `print(f"WARN: rect {name} out of bounds")` のみ。スクリプト続行
- tasklist のサブタスクで「警告ゼロ」を確認

### 既存 .tscn の上書きでパースエラー

- 各置換後に **2 段階チェック** を実行 (`--check-only` だけでは .tscn のリソース参照切れを検出できない):
  1. `godot --check-only --path /workspace > /tmp/godot_check.log 2>&1` — GDScript 構文チェック
  2. `godot --headless --import --path /workspace --quit-after 30 > /tmp/godot_import.log 2>&1` — .tscn 内の `res://` パス解決確認
- エラー検出時はその場で修正 → 再 check

## テスト戦略

### ユニットテスト

新規追加なし (UI 変更が主体のため、既存 GUT テストの非リグレッションを優先)。
- `tests/unit/core/test_score_system.gd` — 既存
- `tests/unit/core/test_data_store.gd` — 既存

### 統合テスト (手動)

- [ ] 起動 → home 表示 (黒画面なし)
- [ ] home → game_list → 個別ゲーム → result → home の循環
- [ ] result_win / result_lose の背景切替
- [ ] レーダー軸 0% (= プレイ未) の時の描画 (中心の点だけになる想定)

### 視覚回帰テスト

- 重要画面 (home, game_list, individual_result × 2) の Android スクリーンショットを `docs/design/snapshots/sumi_theme_v2/` に保存

## 依存ライブラリ

新規追加なし。Python 切り出しスクリプトは Pillow のみ (既に環境にあり)。

## ディレクトリ構造

```
.steering/20260526-墨絵テーマ実装指示書反映/   ← 本ステアリング
  ├ requirements.md
  ├ design.md
  └ tasklist.md

scripts_build/   ← 既存ディレクトリに追加
  ├ build_gradients.gd      (既存)
  ├ build_theme.gd          (既存 — 拡張 or 新規 build_sumi_theme.gd)
  ├ connect_android.sh      (既存)
  ├ deploy_android.sh       (既存 — APK ビルド + adb install を担当)
  ├ logcat_android.sh       (既存)
  ├ run_unit_tests.sh       (既存)
  ├ cut_sumi_sheets.py      ← 新規
  ├ copy_sumi_assets.sh     ← 新規 (もしくは Bash 直接で OK)
  ├ apply_sumi_backgrounds.py ← 新規 (全 scene の WashiBackground 一括差替え)
  └ build_sumi_theme.gd     ← 新規 (sumi_theme.tres 生成)

assets/textures/   ← 新規ディレクトリ
  ├ backgrounds/   (7 PNG)
  ├ frames/        (3 PNG)
  ├ buttons/       (3 PNG)
  ├ badges/        (12 PNG)
  ├ decorations/   (9 PNG)
  ├ game_icons/    (6 PNG)
  └ bars/          (4 PNG)

assets/fonts/    ← 既存 + 2 追加
  ├ NotoSerifJP-Bold.otf      (既存)
  ├ NotoSansJP-Bold.otf       (既存)
  ├ SpaceGrotesk-Bold.ttf     (新規: GitHub Release `static/` から取得。取得失敗時は NotoSansJP-Bold で代替)
  └ JetBrainsMono-Regular.ttf (新規: 同上)

scripts/constants/   ← 新規
  └ colors.gd

assets/themes/
  ├ default_theme.tres   ← 既存 (残置)
  └ sumi_theme.tres      ← 新規

scenes/main/home.tscn          ← 全面再構築
scenes/ui/game_list.tscn       ← 全面再構築
scenes/**/*.tscn                ← 背景 TextureRect 追加 (Python 自動化)
```

## 実装の順序

1. **Task 0**: フォント DL (**curl 必須**、WebFetch 不可) → unzip → `assets/fonts/` に配置
2. **Task 1**: 7 シートの座標確認 → Pillow スクリプトでシート切り出し → `parts/` に出力 → サムネ確認
3. **Task 2**: parts/ と backgrounds/ を assets/textures/ にコピー
4. **Task 3**: `scripts/constants/colors.gd` 作成 (alias 追加なし)
5. **Task 4**: `build_sumi_theme.gd` で `sumi_theme.tres` 生成 + `project.godot` の theme 設定切替
6. **Task 5**: 3 サブフェーズで進行 (5-A radar_chart.gd / 5-B home.tscn / 5-C home_controller.gd)
7. **Task 6**: game_list.tscn 再構築
8. **Task 7**: Python ヘルパーで全 scene に WashiBackground 追加
9. **Task 8**: ヘッドレスパース (2 段階) 確認 → APK ビルド → 実機デプロイ → スクショ取得 → 受け入れ判定

## セキュリティ考慮事項

- フォント取得時は Google Fonts 公式 (`fonts.google.com`) または公式 GitHub Release のみ使用
- ダウンロード後にファイルサイズ確認 (極端に小さい場合は CDN リダイレクトミス疑い)
- ライセンスファイル (OFL.txt) は既に存在。新規フォントのライセンスはコメントとして `colors.gd` または `CREDITS.md` に追記

## パフォーマンス考慮事項

- 背景 PNG は 2MB 前後あるため、`compress/mode=1 (lossless)` ではなく現状の `compress/mode=0 (Image)` で OK (Godot 内で WebP 圧縮)
- レーダー `_draw()` は毎フレーム描画ではない (`queue_redraw()` 明示時のみ)。スコア更新時のみ呼ぶ
- NinePatchRect は GPU 効率が良いので問題なし

## 将来の拡張性

- カラートークン (SumiColors) が確立されたので、今後の画面追加では「色を直書きせず必ず参照」のガイドラインを `docs/development-guidelines.md` に追記
- フォント 3 種が theme に登録済みなので、画面固有の指定は不要 (theme override で十分)
- 旧アセット (sumineko / washi 系) の物理削除は次回ステアリングで判断 (使用箇所の完全置換後)
