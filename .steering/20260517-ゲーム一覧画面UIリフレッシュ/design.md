# 設計書 — ゲーム一覧画面 Midnight Cat 化

## アーキテクチャ概要

UI レイヤのみの差し替え。カルーセルのレイアウトロジック・データ駆動 (GAME_CARDS) は温存し、`game_list.tscn` のノードと StyleBox / Theme variation を Midnight Cat に置き換える。`game_list_controller.gd` は **ほぼ無変更**（白カード前提のロジックは無く、`_apply_carousel_layout` は modulate を `Color.WHITE` 基準で扱うのみ — そのまま流用可）。

```
[game_list.tscn]
  ├ VoidBg (ColorRect #000)                  ← rule_explain / home と共通
  ├ NebulaBg (TextureRect, Gradient_nebula)
  ├ StarLayer (effects/star_layer.gd)
  ├ SafeAreaMargin (MarginContainer)
  │   └ MainColumn (VBox)
  │       ├ HeaderBlock (VBox)
  │       │   ├ Title  (mc_h1 / "脳トレ")
  │       │   └ Subtitle (font_size=20 override / 補助文)
  │       ├ CarouselArea (Control 700h)
  │       │   ├ Card0..Card5 (PanelContainer × 6)
  │       │   │   └ CardMargin / CardVBox
  │       │   │       ├ IconCircle (PanelContainer, SBF_icon_dark)
  │       │   │       │   └ IconLabel (Material Symbols, CYAN_400, 64px)
  │       │   │       ├ CategoryLabel (mc_caption upper, CYAN_400 22px)
  │       │   │       ├ GameNameLabel (mc_h2 36px)
  │       │   │       ├ DescriptionLabel (mc_body INK_80 24px)
  │       │   │       ├ ExpandSpacer
  │       │   │       ├ MetricPanel (SBF_premium_dark)
  │       │   │       │   ├ MetricCaption (mc_caption 20px)
  │       │   │       │   └ MetricValue (GOLD_400, 40px Bold)
  │       │   │       ├ CardPlayButton (mc_cta_glow, h=64)
  │       │   │       └ CardComingSoon (SBF_coming_dark)
  │       ├ DotRow (CenterContainer)
  │       │   └ DotIndicators (HBox)
  │       │       └ Dot0..Dot5 (PanelContainer, SBF_dot_cyan / SBF_dot_dim)
  │       └ BottomSpacer
  └ BottomNavPanel (PanelContainer, SBF_nav_dark)
      └ BottomNavBar (HBox)
          ├ NavTrainActive (PanelContainer, SBF_nav_active_glow)
          ├ NavAnalyticsButton
          ├ NavHomeButton
          ├ NavAwardButton
          └ NavSettingsButton
```

## コンポーネント設計

### 1. 背景レイヤ（home.tscn と完全同一）

**追加 SubResource**:

```
[sub_resource type="Gradient" id="Gradient_nebula"]
offsets = PackedFloat32Array(0, 0.4, 1)
colors = PackedColorArray(0.04, 0.08, 0.16, 1, 0.01, 0.02, 0.04, 1, 0, 0, 0, 1)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_nebula"]
gradient = SubResource("Gradient_nebula")
fill = 1
fill_from = Vector2(0.5, 0.35)
fill_to = Vector2(1, 1)
```

**ノード**:
- `VoidBg` (ColorRect, color=#000, mouse_filter=2)
- `NebulaBg` (TextureRect, expand_mode=1, stretch_mode=6, mouse_filter=2)
- `StarLayer` (Control + `scripts/ui/effects/star_layer.gd`, mouse_filter=2)

旧 `BgTexture` (sky blue gradient) は撤去。

### 2. ヘッダー

**Title**: `theme_type_variation = &"mc_h1"`, text = "脳トレ"
- 明朝 44px、INK_100 (#F4F7FF) — mc_h1 既定値そのまま使用可
- ホーム / individual_result が日本語ベースのため、英字は採用しない（一貫性優先）

**Subtitle**: Label（theme variation 無し）, text = "今日のメニューを選ぼう"
- `theme_override_font_sizes/font_size = 20` を明示指定（mc_subtitle 既定 18px は規約未達のため不採用）
- `theme_override_colors/font_color = Color(0.533, 0.588, 0.690, 1)` (INK_60)
- 旧 2 行サブタイトルは情報量過多 → 1 行に簡略化

**戻るボタンについて**: ボトムナビに NavHomeButton があり、ヘッダーに追加の BackChip を置くと機能重複となる。ナビ一貫性を優先し、ヘッダー側には設けない。

### 3. カード（暗グラスパネル）

**新規 StyleBoxFlat: `SBF_card_dark`**

```
content_margin_left/right = 20
content_margin_top/bottom = 24
bg_color = Color(0.04, 0.08, 0.16, 0.55)
border_width_* = 1
border_color = Color(0.435, 0.706, 1, 0.45)   # CYAN_400 α=0.45
corner_radius_* = 28
shadow_color = Color(0, 0, 0, 0.45)
shadow_size = 24
shadow_offset = Vector2(0, 12)
```

中央カードのみ強調する案として、modulate ではなく `_apply_carousel_layout` で隣接 / 遠方カードに `Color(0.7, 0.7, 0.7, 0.6)` 等を modulate でかける既存ロジックに乗る。中央のみ Color.WHITE → そのままシアン縁取りが見える。

### 4. アイコン円

**新規 StyleBoxFlat: `SBF_icon_dark`**

```
content_margin_* = 18
bg_color = Color(0.043, 0.071, 0.125, 0.85)   # BG_PANEL α=0.85
border_width_* = 2
border_color = Color(0.435, 0.706, 1, 0.6)     # CYAN_400
corner_radius_* = 9999                          # 円
shadow_color = Color(0.435, 0.706, 1, 0.35)
shadow_size = 16
shadow_offset = Vector2(0, 0)
```

- IconLabel: Material Symbols 64px, font_color = CYAN_300 (#B8E0FF)
- custom_minimum_size = (108, 108)

### 5. カテゴリ・ゲーム名・説明

| ノード | variation | font_size override | font_color | フォント解決 |
|---|---|---|---|---|
| CategoryLabel | なし | **22**（必須） | CYAN_400 | tscn 直 ext_resource NotoSansJP-Bold |
| GameNameLabel | `mc_h2` | **36**（必須、mc_h2 既定 32 を上書き） | INK_100（mc_h2 既定） | mc_h2 経由 NotoSerifJP-Bold |
| DescriptionLabel | `mc_body` | **24**（必須、mc_body 既定 17 を上書き） | INK_80（mc_body 既定） | mc_body 経由 |

CategoryLabel は theme variation を新設するほどでもないので、ノード側で個別 override する（既存 home の TopRow と同じやり方）。

**重要**: `default_theme.tres` の `mc_subtitle=18` / `mc_body=17` / `mc_caption=14` は 2026-05-16 最低サイズ規約に届かないため、本画面では **必ず font_size override を併用** する。theme バリアントだけ当てて満足してはいけない。

### 6. MetricPanel（ハイスコア）

**個別 StyleBoxFlat: `SBF_metric_dark`**

```
content_margin_left/right = 16
content_margin_top/bottom = 12
bg_color = Color(0.067, 0.094, 0.153, 0.6)    # BG_ELEV α=0.6
border_width_* = 1
border_color = Color(0.435, 0.706, 1, 0.25)    # 薄シアン
corner_radius_* = 18
```

- MetricCaption: font_size=20 override 必須 (mc_caption 既定 14 は不採用), INK_60, NotoSansJP-Bold, 大文字（"High Score" / "Best Time"）
- MetricValue: font_size=40 override, GOLD_400 (#F5C76A), NotoSansJP-Bold

### 7. CardPlayButton（シアン発光ピル）

`theme_type_variation = &"mc_cta_glow"` をそのまま流用すると **font_size=38** が継承されるため、ピル小型版として個別 override する:

```
custom_minimum_size = (0, 64)
theme_override_font_sizes/font_size = 28
text = "スタート"
```

mc_cta_glow が `StyleBoxFlat_mc_pill_glow` を normal に持つので、シアン発光ピルが自動で適用される。pressed のみ `mc_pill_glow_pressed`。

**custom_minimum_size.y=64 が必須な理由**: mc_pill_glow の content_margin は実 tres 上 `top/bottom` 計でも 56px に届かないケースがあるため、最低サイズ規約 (タップ要素 ≥ 56px) を確実に守るには custom_minimum_size を明示する必要がある。

### 8. CardComingSoon（暗グラスチップ）

**新規 StyleBoxFlat: `SBF_coming_dark`**

```
content_margin_left/right = 20
content_margin_top/bottom = 10
bg_color = Color(0.067, 0.094, 0.153, 0.6)
border_width_* = 1
border_color = Color(0.435, 0.706, 1, 0.2)
corner_radius_* = 16
```

- Label: 18-20px, CYAN_300 alpha=0.7, text = "COMING SOON"

### 9. DotIndicators

**採用方針: 既存 controller の幅 + modulate.a ロジックをそのまま維持し、StyleBox を 1 個（CYAN_400 塗り）に統一する（最小変更）。**

- 旧 `SBF_dot`: `bg_color = Color(0, 0.484, 1, 1)`（青塗り）
- 新 `SBF_dot`: `bg_color = Color(0.435, 0.706, 1, 1)` (CYAN_400), corner_radius=9999

controller の `_update_dots()` は無変更（active = width 32 + alpha 1.0, inactive = width 11 + alpha 0.4）。

### 10. BottomNavPanel（暗グラス）

**新規 StyleBoxFlat: `SBF_nav_dark`**

```
content_margin_left/right = 12
content_margin_top = 10
content_margin_bottom = 24
bg_color = Color(0.04, 0.08, 0.16, 0.85)     # 暗ガラス
border_width_top = 1
border_color = Color(0.435, 0.706, 1, 0.2)    # 上辺だけ薄シアン
corner_radius_top_left = 32
corner_radius_top_right = 32
```

**NavTrainActive（アクティブピル）**:
- 既存 `SBF_nav_act`（青塗り）→ `mc_pill_glow` 流用、ただし内側パディングは個別 SBF で調整
- 新規 `SBF_nav_act_cyan`:
  ```
  bg_color = Color(0.435, 0.706, 1, 0.18)    # シアン薄塗り
  border_width_* = 1
  border_color = Color(0.435, 0.706, 1, 0.7)
  corner_radius_* = 24
  shadow_color = Color(0.435, 0.706, 1, 0.4)
  shadow_size = 12
  ```

| ノード | font_color (active=cyan, inactive=INK_60) | font_size |
|---|---|---|
| Icon (Material Symbols) | CYAN_300 / INK_60 | 44 |
| Text | CYAN_300 / INK_60 | 22 |

## 実装の影響範囲

### 変更ファイル

| ファイル | 変更種別 |
|---|---|
| `scenes/ui/game_list.tscn` | StyleBox 全差し替え + StarLayer/Nebula 追加 + ノード再構成（ヘッダー） |
| `scripts/ui/game_list_controller.gd` | 軽微（HeaderGlass → HeaderRow の `@onready` パス更新があれば） |

### 影響しないファイル

- `game_manager.gd` — 遷移ロジックは無変更
- `data_store.gd` — ベストスコア取得は無変更
- `default_theme.tres` — テーマ追加・改変は不要。ただし下記の通り **theme variation 流用 + tscn 側 font_size override** の併用が前提:
  - `mc_h1` (44px) → そのまま使える
  - `mc_h2` (32px) → GameNameLabel で font_size=36 を override
  - `mc_body` (17px) → DescriptionLabel で font_size=24 を override
  - `mc_subtitle` (18px) → 採用せず、Subtitle は variation 無し + font_size=20 直指定
  - `mc_caption` (14px) → 採用せず、Category/MetricCaption も variation 無し + font_size=20-22 直指定
  - `mc_cta_glow` (38px) → CardPlayButton で font_size=28 を override + custom_minimum_size.y=64
  - `mc_back_btn` → 採用しない（BackChip を設けないため）

### controller 側の確認ポイント

- `@onready var _carousel_area := $SafeAreaMargin/MainColumn/CarouselArea` — パスが変わらないように `SafeAreaMargin/MainColumn` ツリーは維持
- `_collect_card_nodes()` の `Card%d` 命名 → 維持
- `_populate_cards()` の子ノードパス `CardMargin/CardVBox/IconCircle/IconLabel` 等 → 維持
- ボトムナビの `@onready` 5 本 → 維持
- 旧 `HeaderGlass/SubtitleLabel` を参照しているコードが無いことを確認（controller には参照無し、安全）

## カルーセルの modulate との整合

`_apply_carousel_layout` で `target_color` を:
- 中央: `Color.WHITE`
- 隣接: `Color(0.70, 0.70, 0.70, 0.60)`
- 遠方: `Color(0.50, 0.50, 0.50, 0.25)`

を modulate にかける。Midnight Cat 化後も背景が暗いため、modulate でグレーをかけると意図通り「奥のカードは暗く見える」になる。**変更不要**。

ただし、StarLayer のキラキラが手前に来るのを避けるため `StarLayer` は CarouselArea より下層に配置（=ルート直下、SafeAreaMargin より前）。

## カラーリファレンス（実装で参照する値）

| 用途 | Color() リテラル | 出典 (color_palette.gd 定数 / α) |
|---|---|---|
| void bg | `Color(0, 0, 0, 1)` | BG_VOID |
| dark panel bg | `Color(0.04, 0.08, 0.16, 0.55)` | individual_result の SBF_premium_dark 流用 |
| dark panel border | `Color(0.435, 0.706, 1, 0.45)` | CYAN_400 (α=0.45 指定) |
| icon circle border | `Color(0.435, 0.706, 1, 0.6)` | CYAN_400 (α=0.6 指定) |
| metric panel border | `Color(0.435, 0.706, 1, 0.25)` | CYAN_400 (α=0.25 指定) |
| nav top border | `Color(0.435, 0.706, 1, 0.2)` | CYAN_400 (α=0.2 指定) |
| cyan accent (CategoryLabel font) | `Color(0.435, 0.706, 1, 1)` | CYAN_400 (フル alpha) |
| cyan glow text (icon / coming soon) | `Color(0.722, 0.878, 1, 1)` | CYAN_300 (フル alpha) |
| ink primary (GameName) | `Color(0.957, 0.969, 1, 1)` | INK_100 |
| ink secondary (Description) | `Color(0.780, 0.824, 0.910, 1)` | INK_80 |
| ink muted (Subtitle/MetricCaption/inactive nav) | `Color(0.533, 0.588, 0.690, 1)` | INK_60 |
| ink ghost (inactive dot 代替) | `Color(0.290, 0.333, 0.439, 1)` | INK_40 (今回未使用、modulate.a で代替) |
| gold (best score MetricValue) | `Color(0.961, 0.780, 0.416, 1)` | GOLD_400 |

リテラル値は `color_palette.gd` の定数と一致。alpha 値は用途ごとに上記の通り個別指定する。

## リスクと対策

| リスク | 対策 |
|---|---|
| `_apply_carousel_layout` の modulate がシアン縁取りを暗くしすぎる | 隣接カードの ADJACENT_BRIGHTNESS = 0.70 を維持。実機で暗すぎたら 0.80 に上げる |
| StarLayer が CarouselArea のタップを奪う | star_layer.gd 側で `_ready()` 内に `mouse_filter = MOUSE_FILTER_IGNORE` 設定済み（home.tscn の用例と同様）。tscn 側の明示指定は不要 |
| theme variation 既定値が規約未達のまま見過ごされる | mc_h2/mc_body/mc_caption/mc_subtitle はすべて tscn 側で font_size override を併用。Editor 目視確認をフェーズ 7 に含める |
| ボトムナビの shadow が暗すぎてゴースト感が出ない | border-top でシアン薄線を入れて区切る（SBF_nav_dark に border_width_top=1） |
| Web エクスポートで StarLayer の draw が重い | 既存実装で home / individual_result が動いているので問題ない見込み |

## 検証方針

1. Godot Editor で `scenes/ui/game_list.tscn` を単独実行（home から start）→ 視覚確認
2. `home.tscn` の AllGamesLink → game_list 遷移 → 1 つのデザインシステムとして連続性があるか
3. カルーセル左右スワイプ・矢印キー・ドットタップが全て動作
4. スタート押下 → reflex_tap / flash_calc / sequence_memory が起動
5. ナビ「ホーム」で戻れる
6. Web エクスポート（任意）でも崩れがない
