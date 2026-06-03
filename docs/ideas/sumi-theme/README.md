# Brain Ghost — 墨絵テーマ実装指示書 v2

## この指示書の使い方

本ドキュメントは **Phase ごとに Claude Code へ渡す**。
一括で全タスクを投げない。各 Phase 内のチケットも **1つずつ** 実行し、
人間が Godot エディタで確認・微調整してから次に進む。

```
[Phase 0] 基盤構築（CLAUDE.md・カラー・テーマ）
    ↓ 人間確認
[Phase 1] アセット素材の準備（背景コピー・汚染パーツの対処方針決定）
    ↓ 人間確認
[Phase 2] UIコンポーネント生成（1チケット＝1 .tscn）
    ↓ 各チケットごとに人間がエディタでRev・微調整→確定
[Phase 3] 画面アセンブリ（確定コンポーネントを組み立て）
    ↓ 人間がエディタで最終レイアウト調整
[Phase 4] 全画面の背景差し替え・仕上げ
```

---

## Phase 0: 基盤構築

> Claude Code に最初に渡す。全て完了してから Phase 1 に進む。

### 0-1. CLAUDE.md にルールを追記

プロジェクトルートの `CLAUDE.md` に以下を追記すること:

```markdown
## 墨絵テーマ — アセット生成ルール

### コンポーネント生成
- UIコンポーネントは必ず **単体 .tscn + .gd** のペアで出力する
- ベースノードは Control 系（PanelContainer / HBoxContainer 等）を使う
- サイズはチケットで指定された固定値を使う。指定がなければ確認する
- アンカーは設定しない（親シーン側で配置時に決める）
- テクスチャ・アイコンは `@export` var で外部注入可能にする
- signal は必ずスクリプト冒頭で宣言する
- レイアウト座標（position / offset）はハードコードしない。
  Container の構造で相対配置し、微調整は人間がエディタで行う

### テーマ・スタイル
- 全コンポーネントは `res://assets/theme/sumi_theme.tres` を参照する
- カラーは `SumiColors` 定数を使う。直接 Color() リテラルを書かない
- フォントサイズはチケット指示値を使う

### ファイル配置
- コンポーネント: `res://scenes/ui/components/[component_name].tscn`
- スクリプト: `res://scripts/ui/[component_name].gd`
- 画面シーン: `res://scenes/screens/[screen_name].tscn`
- テクスチャ: `res://assets/textures/[category]/`
- テーマ: `res://assets/theme/`

### 禁止事項
- `docs/ideas/sumi-theme/parts/` の汚染パーツを texture として使用禁止
  （bg_*.png と確認済みクリーンパーツのみ使用可）
- NinePatchRect に未検証パーツを設定しない
- 1チケットで複数コンポーネントを同時生成しない
```

### 0-2. カラーパレット定数

**指示:** `scripts/constants/colors.gd` を作成せよ。

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

### 0-3. テーマリソース

**指示:** `assets/theme/sumi_theme.tres` を構築せよ。

| 項目 | 設定 |
|---|---|
| フォント（和文見出し） | Noto Serif JP Bold |
| フォント（数字スコア） | Space Grotesk Bold |
| フォント（等幅タイマー） | JetBrains Mono Regular |
| Panel 背景色 | SumiColors.WASHI |
| Label デフォルト色 | SumiColors.SUMI_DARK |
| Button/Primary | 背景 SumiColors.SUMI_DARK、文字 白 |
| Button/Secondary | 背景 透明 + 1px border SUMI_DARK、文字 SUMI_DARK |
| Button/Accent | 背景 SumiColors.SHU、文字 白 |

**注意:**
- ボタンスタイルは StyleBoxFlat で構築する（汚染パーツ btn_*.png は使わない）
- パーツ画像が将来クリーンに再切り出しされたら NinePatchRect に差し替え可

---

## Phase 1: アセット素材の準備

> 背景画像のコピーと、使用可能パーツの棚卸し。

### 1-1. 背景画像をプロジェクトにコピー

**指示:** 以下をコピーせよ。

```
docs/ideas/sumi-theme/backgrounds/bg_washi_base.png → assets/textures/backgrounds/
docs/ideas/sumi-theme/backgrounds/bg_home.png       → assets/textures/backgrounds/
docs/ideas/sumi-theme/backgrounds/bg_play.png       → assets/textures/backgrounds/
docs/ideas/sumi-theme/backgrounds/bg_result_win.png → assets/textures/backgrounds/
docs/ideas/sumi-theme/backgrounds/bg_result_lose.png→ assets/textures/backgrounds/
docs/ideas/sumi-theme/backgrounds/bg_onboarding.png → assets/textures/backgrounds/
```

### 1-2. クリーン確認済みパーツをコピー

**指示:** 以下の **確認済みクリーンパーツのみ** コピーせよ。

```
badges/badge_new.png      → assets/textures/badges/
badges/badge_best.png     → assets/textures/badges/
badges/stamp_shuin.png    → assets/textures/badges/
```

### 1-3. キャラクターアセットをコピー

**指示:**

```
assets/characters/sumineko_*.png → assets/textures/characters/
```

（既にプロジェクト内にあればスキップ）

### ⚠️ 汚染パーツの扱い

以下は **現時点では使用しない**。Phase 2 のコンポーネント生成では代替手段で対応する。

| 汚染パーツ | Phase 2 での代替 |
|---|---|
| frame_ink_border*.png | StyleBoxFlat（角丸+border）で代替 |
| game_icon_*.png | Material Symbols フォントアイコンで代替 |
| btn_*.png | StyleBoxFlat で代替（テーマ側で定義済み） |
| divider_*.png | ColorRect 細線 or Line2D で代替 |
| hitodama.png | `_draw()` で円＋グロー描画 or 後日クリーン版差し替え |
| arrow_up/down_brush.png | Label テキスト「↑」「↓」+ SumiColors で代替 |
| icon_lock.png | Material Symbols 🔒 で代替 |
| stamp_shuin_faded / stamp_empty | 後日クリーン版を用意。暫定は Circle描画 + alpha |
| bar_fill_*.png | StyleBoxFlat グラデーションで代替 |
| ink_splatter_*.png | 省略 or `_draw()` で簡易描画 |

**将来の差し替えポイント:**
各コンポーネントで `@export var texture_xxx: Texture2D` を用意しておけば、
クリーンパーツが揃った時点でエディタから差し替えるだけで済む。

---

## Phase 2: UIコンポーネント生成

> **1チケット = 1コンポーネント。** 各チケットを個別に Claude Code に渡す。
> 生成後、人間が Godot エディタで開いて確認・微調整→確定してから次へ。

### ■ チケットテンプレート（Claude Code への渡し方）

```
## コンポーネント: [名前]
- ベースノード: [PanelContainer / HBoxContainer / Control 等]
- サイズ: 横___px × 縦___px
- 子要素ツリー:
  - [ノード型]: [役割] (サイズ・フォント等)
    - [子ノード]: ...
- 振る舞い: [signal / tween / 状態変化]
- @export var: [外部から差し替え可能にするもの]
- 出力:
  - scenes/ui/components/[name].tscn
  - scripts/ui/[name].gd
- 参照画像: docs/ideas/sumi-theme/references/[該当シート].png の [どの部分]
```

---

### チケット 2-1: BrainAgeCard（脳年齢カード）

```
## コンポーネント: BrainAgeCard
- ベースノード: PanelContainer
- サイズ: 横 340px × 縦 160px
- 子要素ツリー:
  - MarginContainer (margins: 上16 下16 左20 右20)
    - VBoxContainer (separation: 8)
      - Label: 「脳年齢」 (Noto Serif JP, 14sp, SumiColors.SUMI_LIGHT)
      - HBoxContainer (alignment: center)
        - Label: 「31」 (Space Grotesk Bold, 64sp, SumiColors.SUMI_DARK)
        - Label: 「歳」 (Noto Serif JP, 24sp, SumiColors.SUMI_DARK, align: bottom)
      - ColorRect: 乾筆風アンダーライン (横stretch, 高さ2px, SumiColors.SUMI_DARK)
      - HBoxContainer
        - ProgressBar (横stretch, 高さ4px, fill: SumiColors.HITODAMA)
        - Label: 「精度: 100%」 (10sp, SumiColors.SUMI_LIGHT)
- 振る舞い: なし（表示専用）
- @export var:
  - brain_age: int = 31
  - accuracy: float = 1.0
- PanelContainer の StyleBoxFlat:
  - bg_color: SumiColors.WASHI, corner_radius: 8
  - border: 1px SumiColors.SUMI_LIGHT alpha 0.3
- 出力:
  - scenes/ui/components/brain_age_card.tscn
  - scripts/ui/brain_age_card.gd
- 参照: home_components_sheet.png の左上エリア
```

---

### チケット 2-2: DailyScoreCard（デイリースコアカード）

```
## コンポーネント: DailyScoreCard
- ベースノード: PanelContainer
- サイズ: 横 340px × 縦 180px
- 子要素ツリー:
  - MarginContainer (margins: 16 all)
    - VBoxContainer (separation: 8)
      - Label: 「3,230 pts」 (Space Grotesk Bold, 36sp, SumiColors.SUMI_DARK)
      - HBoxContainer (separation: 4)
        - Label: 「↑」 (16sp, SumiColors.WAKATAKE)
        - Label: 「+285」 (Space Grotesk, 16sp, SumiColors.WAKATAKE)
      - Label: 「脳年齢: 31歳」 (14sp, SumiColors.SUMI_LIGHT)
      - HBoxContainer (separation: 8)
        - Label × 2: 「○」(20sp, SumiColors.SUMI_DARK) ← 勝ちマーク代替
        - Label × 1: 「×」(20sp, SumiColors.SUMI_LIGHT) ← 負けマーク代替
- 振る舞い: なし（表示専用）
- @export var:
  - score: int = 3230
  - score_diff: int = 285
  - brain_age: int = 31
  - wins: int = 2
  - losses: int = 1
  - texture_frame: Texture2D  ← 将来 frame_ink_border 差し替え用
- PanelContainer の StyleBoxFlat:
  - bg_color: SumiColors.WASHI
  - border: 2px SumiColors.SUMI_DARK, corner_radius: 4
- 出力:
  - scenes/ui/components/daily_score_card.tscn
  - scripts/ui/daily_score_card.gd
- 参照: home_components_sheet.png の中央左エリア
```

---

### チケット 2-3: GhostRecordStrip（戦績＋ストリーク横並び）

```
## コンポーネント: GhostRecordStrip
- ベースノード: HBoxContainer
- サイズ: 横 340px × 縦 120px
- 子要素ツリー:
  - PanelContainer: 戦績（左半分, size_flags_horizontal: EXPAND_FILL）
    - MarginContainer (margins: 12 all)
      - VBoxContainer (separation: 4)
        - Label: 「通算」 (12sp, SumiColors.SUMI_LIGHT)
        - HBoxContainer
          - Label: 「15勝」 (Space Grotesk + Noto Serif, 28sp, SumiColors.SUMI_DARK)
          - HSeparator (8px)
          - Label: 「8敗」 (28sp, SumiColors.SUMI_LIGHT)
  - VSeparator: 1px ColorRect (SumiColors.SUMI_LIGHT alpha 0.3)
  - PanelContainer: ストリーク（右半分, size_flags_horizontal: EXPAND_FILL）
    - MarginContainer (margins: 12 all)
      - VBoxContainer (separation: 8)
        - HBoxContainer (separation: 6)
          - TextureRect × 7: スタンプ枠 (各 28x28)
            - 済み当日: badge_best.png を暫定利用 or 円描画+SHU
            - 済み過去: 同上 alpha 0.4
            - 未: 点線円（_draw）
        - Label: 「5日連続！」 (12sp, SumiColors.SUMI_DARK)
- @export var:
  - total_wins: int = 15
  - total_losses: int = 8
  - streak_days: int = 5
  - streak_stamps: Array[bool] = [true,true,true,true,true,false,false]
- 出力:
  - scenes/ui/components/ghost_record_strip.tscn
  - scripts/ui/ghost_record_strip.gd
- 参照: home_components_sheet.png の中央エリア
```

---

### チケット 2-4: SumiRadarChart（レーダーチャート）

```
## コンポーネント: SumiRadarChart
- ベースノード: Control
- サイズ: 横 300px × 縦 300px
- 描画: 全て _draw() で実装（PNG不使用）
  - 同心円 × 3: 円相風（不完全な円、3箇所に隙間）
    - 線幅に ±0.5px ランダム変動、色: SumiColors.SUMI_LIGHT
  - 放射軸 × 6: 中心→外周、width 2px→0.5px 先細り、色: SUMI_LIGHT
  - 軸先端: 小丸 radius 2px、SUMI_DARK
  - データ塗り: Polygon2D 相当、色: SumiColors.HITODAMA_FILL
  - データ輪郭: 線 width 1.5px、色: SumiColors.HITODAMA
  - 最強軸の頂点: 丸 radius 4px、SumiColors.KINDEI
- 軸ラベル（6軸、外周の外側に配置）:
  - 上: 計算力 / 右上: 記憶力 / 右下: 注意力
  - 下: 反射速度 / 左下: 観察力 / 左上: 判断力
  - Noto Serif JP, 11sp, SumiColors.SUMI_DARK
- 最弱軸ラベル下: Label「鍛える →」(10sp, SumiColors.SHU)
- @export var:
  - values: Array[float] = [0.8, 0.6, 0.7, 0.5, 0.9, 0.4]  ← 0.0〜1.0
  - axis_labels: Array[String] = ["計算力","記憶力","注意力","反射速度","観察力","判断力"]
- signal: weakest_axis_tapped(axis_index: int)
- 出力:
  - scenes/ui/components/sumi_radar_chart.tscn
  - scripts/ui/sumi_radar_chart.gd
- 参照: home_components_sheet.png の右側エリア
```

---

### チケット 2-5: DailyChallengeStrip（デイリーチャレンジ帯）

```
## コンポーネント: DailyChallengeStrip
- ベースノード: PanelContainer
- サイズ: 横 340px × 縦 100px
- 子要素ツリー:
  - MarginContainer (margins: 12 all)
    - VBoxContainer (separation: 8)
      - HBoxContainer
        - Label: 「今日のチャレンジ」 (Noto Serif JP, 14sp, SumiColors.SUMI_DARK)
        - Control (横stretch) ← spacer
        - Label: 「🔥」 (14sp) ← hitodama 代替
      - HBoxContainer (separation: 12)
        - VBoxContainer × 3: ゲーム枠（各 80px 幅）
          - Label: ゲームアイコン代替テキスト (Material Symbols or emoji, 24sp)
          - Label: ゲーム名 (10sp, SumiColors.SUMI_DARK)
        - Button: 「始める」
          - StyleBoxFlat: bg SumiColors.SHU, corner_radius 4
          - 文字: 白, 14sp
- @export var:
  - challenge_games: Array[Dictionary]
    ← [{name: "数字さがし", icon: "🔍"}, ...]
- signal: start_pressed()
- 出力:
  - scenes/ui/components/daily_challenge_strip.tscn
  - scripts/ui/daily_challenge_strip.gd
- 参照: home_components_sheet.png の下部エリア
```

---

### チケット 2-6: GameListCard（ゲーム一覧カード・1枚分）

```
## コンポーネント: GameListCard
- ベースノード: PanelContainer
- サイズ: 横 160px × 縦 200px
- 子要素ツリー:
  - MarginContainer (margins: 12 all)
    - VBoxContainer (separation: 6, alignment: center)
      - Label: ゲームアイコン (Material Symbols / emoji, 32sp, center)
      - Label: ゲーム名 (Noto Serif JP, 13sp, SumiColors.SUMI_DARK, center)
      - Label: 能力 (11sp, SumiColors.SUMI_LIGHT, center)
      - Label: ベスト記録 or 「🔒」 (10sp, SumiColors.SUMI_LIGHT, center)
- 状態:
  - normal: StyleBoxFlat bg WASHI, border 1px SUMI_LIGHT
  - locked: bg SUMI_LIGHT alpha 0.1, 中央に 🔒 overlay, 他ラベル alpha 0.4
  - selected: border 2px SumiColors.HITODAMA
- 振る舞い:
  - hover: bg_color alpha +0.05
  - press: scale tween 0.97 → 1.0 (0.1秒)
- @export var:
  - game_id: String
  - game_name: String
  - ability_label: String
  - icon_text: String  ← emoji or Material Symbols
  - best_score: String = ""
  - is_locked: bool = false
  - is_new: bool = false
  - texture_icon: Texture2D  ← 将来 game_icon_*.png 差し替え用
- signal: card_pressed(game_id: String)
- 出力:
  - scenes/ui/components/game_list_card.tscn
  - scripts/ui/game_list_card.gd
- 参照: game_cards_sheet.png
```

---

### チケット 2-7: SumiDivider（区切り線）

```
## コンポーネント: SumiDivider
- ベースノード: ColorRect
- サイズ: 横 stretch × 縦 2px
- color: SumiColors.SUMI_LIGHT alpha 0.3
- @export var:
  - thickness: float = 2.0
  - divider_color: Color = SumiColors.SUMI_LIGHT
  - divider_alpha: float = 0.3
  - texture_override: Texture2D  ← 将来 divider_thick.png 差し替え用
- 出力:
  - scenes/ui/components/sumi_divider.tscn
  - scripts/ui/sumi_divider.gd
```

---

### チケット 2-8: SumiButton（共通ボタン）

```
## コンポーネント: SumiButton
- ベースノード: Button
- サイズ: 横 280px × 縦 48px（デフォルト。親コンテナで変更可）
- バリアント（@export enum で切替）:
  - PRIMARY: bg SUMI_DARK, text 白, corner_radius 6
  - SECONDARY: bg 透明, border 1px SUMI_DARK, text SUMI_DARK
  - ACCENT: bg SHU, text 白, corner_radius 6
- フォント: Noto Serif JP, 14sp
- 振る舞い:
  - hover: alpha 0.85
  - pressed: scale 0.97 tween 0.08秒
- @export var:
  - button_style: int = 0  ← enum {PRIMARY, SECONDARY, ACCENT}
  - label_text: String = "ボタン"
  - texture_bg: Texture2D  ← 将来 btn_*.png 差し替え用
- 出力:
  - scenes/ui/components/sumi_button.tscn
  - scripts/ui/sumi_button.gd
```

---

## Phase 3: 画面アセンブリ

> **Phase 2 の全コンポーネントが確定してから着手。**
> レイアウト（座標配置）は人間がエディタで行う。
> Claude Code にはシーン構造の雛形生成とスクリプトロジックを任せる。

### 3-1. ホーム画面

**指示:**

```
scenes/screens/home.tscn を作成せよ。

背景: TextureRect (res://assets/textures/backgrounds/bg_home.png, stretch: keep_aspect_covered)

VBoxContainer (anchors: full_rect, margins: 上40 左20 右20 下20) の中に
以下の確定コンポーネントをインスタンス配置する:

1. BrainAgeCard.tscn
2. SumiDivider.tscn
3. DailyScoreCard.tscn
4. SumiDivider.tscn
5. GhostRecordStrip.tscn
6. SumiDivider.tscn
7. SumiRadarChart.tscn
8. SumiDivider.tscn
9. DailyChallengeStrip.tscn
10. SumiButton.tscn (SECONDARY, label: 「全ゲーム一覧」)

VBoxContainer の separation: 16

ScrollContainer で全体をラップし、縦スクロール可能にすること。
各コンポーネントの position 微調整は人間がエディタで行うため不要。

home.gd では:
- 各コンポーネントの @export var にデータをバインドする関数を用意
- DailyChallengeStrip.start_pressed → ゲーム画面遷移
- SumiRadarChart.weakest_axis_tapped → 該当ゲーム画面遷移
- 全ゲーム一覧ボタン → game_list 画面遷移
```

### 3-2. ゲーム一覧画面

**指示:**

```
scenes/screens/game_list.tscn を作成せよ。

背景: TextureRect (res://assets/textures/backgrounds/bg_washi_base.png)

GridContainer (columns: 2, h_separation: 12, v_separation: 12)
の中に GameListCard.tscn × 6 をインスタンス配置。

6種のカードデータ:
| game_id   | game_name        | icon | ability |
|-----------|------------------|------|---------|
| 7ban      | ゴースト7番勝負  | ⚡   | 反射速度 |
| ippon     | ゴースト一本勝負  | 🔢   | 計算力   |
| search    | 数字さがし       | 👁   | 観察力   |
| stroop    | 色文字ストループ  | 🎯   | 注意力   |
| sequence  | 順番記憶         | 🧠   | 記憶力   |
| memory    | 神経衰弱ライト    | ⚖   | 判断力   |

game_list.gd では:
- GameListCard.card_pressed → 該当ゲーム画面遷移
- ロック状態・NEW状態はデータから設定
```

---

## Phase 4: 背景差し替え・仕上げ

> 全画面共通の背景設定。

### 4-1. 背景マッピング

**指示:** 以下の画面の最背面 TextureRect を設定/確認せよ。

| 画面 | 背景テクスチャ | stretch_mode |
|---|---|---|
| home.tscn | bg_home.png | keep_aspect_covered |
| 全ミニゲームプレイ画面（6種共通） | bg_play.png | keep_aspect_covered |
| リザルト（ゴースト勝利） | bg_result_win.png | keep_aspect_covered |
| リザルト（ゴースト敗北） | bg_result_lose.png | keep_aspect_covered |
| オンボーディング・ルール説明 | bg_onboarding.png | keep_aspect_covered |
| game_list.tscn | bg_washi_base.png | keep_aspect_covered |
| 設定画面・その他 | bg_washi_base.png | keep_aspect_covered |

---

## Appendix: 将来のアセット差し替え手順

パーツの再切り出し or 個別アセット作成が完了したら:

1. クリーン PNG を `assets/textures/[category]/` に配置
2. Godot エディタで該当コンポーネントを開く
3. `@export var texture_xxx` にドラッグ＆ドロップで設定
4. 動作確認

差し替え対象の優先度:

| 優先度 | パーツ | 理由 |
|---|---|---|
| 高 | frame_ink_border*.png | カードの見た目が大幅に変わる |
| 高 | game_icon_*.png | ゲーム一覧の識別性に直結 |
| 中 | stamp_shuin_faded / stamp_empty | ストリーク表示の完成度 |
| 中 | hitodama.png | 世界観の象徴パーツ |
| 低 | divider_*.png / ink_splatter_*.png | 装飾。なくても機能する |
| 低 | bar_fill_*.png | StyleBoxFlat で十分代替可 |
