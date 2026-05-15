# 要求内容

## 概要

カウントダウン画面が「美少女ゴースト」(`ghost_seirei.png`) を使った別世界観になっており、ホーム/ルール説明画面 (Midnight Cat v3) との一貫性が崩れている。これを **正式マスコット catboy_electric** ベースで Midnight Cat 統一テーマにリデザインする。あわせて、ゴースト7番勝負 (横画面ゲーム) のルール説明・カウントダウンを **横画面ネイティブレイアウト** に切り替え、project.godot の orientation も SENSOR に変更してランタイム切替を実機で機能させる。

## 背景

- ホーム/ルール説明/ゴースト7番勝負本体は **Midnight Cat v3** (黒地 + 微シアン nebula + 星 + NotoSerifJP-Bold) で統一済み
- カウントダウン画面 (`scenes/ui/countdown.tscn`) だけが古い水色グラデ + `ghost_seirei.png` (廃止確定キャラ) のままで、ユーザに「全く別の UI/UX」として認識されている
- ホーム画面 (home.tscn) では **catboy_electric.png** をマスコットとして使用済み。memory「Mascot is Catboy (canonical)」とも整合
- ユーザ方針: **catboy 系を正、他のキャラ (ghost_seirei / Sleek 黒猫) は利用しない**
  - 自分役: `catboy_electric` (ホームで採用済み)
  - 敵 (ゴースト) 役: `catboy_confident` (落ち着いた立ち姿で待ち構える雰囲気)
- ゴースト7番勝負本体 (`ghost_7ban_shobu.tscn`) は現在 `Sleek_black_cat_with_icy_accents.png` を敵に使用 → catboy_confident に置換
- ゴースト7番勝負ゲーム本体は横画面 1280x720 で組まれているが、前段の rule_explain / countdown は縦画面 720x1280 のまま
- project.godot は `handheld/orientation=1` (portrait 固定)。実機でランタイム回転を効かせるには SENSOR に変更が必要

## 実装対象の機能

### 1. project.godot の orientation 変更

`window/handheld/orientation` を **1 (PORTRAIT) → 6 (SENSOR)** に変更。実機側で `DisplayServer.screen_set_orientation()` のランタイム制御が効くようにする。

> 副作用: ユーザが端末を傾けると向きが変わる可能性。`OrientationHelper.enter_portrait()` を縦画面シーン入場時に明示的に呼んで強制する。

### 2. カウントダウン画面 (縦) のリデザイン

`scenes/ui/countdown.tscn`:

- **背景**: VoidBg (黒) + NebulaBg (濃紺グラデ) + StarLayer を rule_explain と共通化
- **キャラ**: `ghost_seirei.png` を撤去 → **`catboy_electric.png`** に差し替え (ホーム画面と同一)
- **タイポグラフィ**: NotoSerifJP-Bold ベース、淡シアン (`Color(0.7, 0.93, 1.0)` 系) で統一
- **吹き出し**: 既存 SpeechBubble (glass_bubble) を維持、Midnight Cat 風配色に
- **LoadingBar 削除**: Midnight Cat の世界観に不要
- **機能維持**: 3-2-1-GO! の Timer (1.0 秒間隔) + `GameManager.on_countdown_finished()` コールバック

### 3. 横画面ルール説明シーンの新規作成 (横3列ネイティブ)

`scenes/ui/rule_explain_landscape.tscn` (1280x720):

レイアウト (Stitch 風 / 横画面ネイティブ):

```
┌─────────────────────────────────────────────────────────┐
│ [← ルール説明]                          [タイトル明朝]    │ ← Header + Title
│                                       [鍛える能力：...] │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Step1     │  │ Step2     │  │ Step3     │   ← 横3列  │
│  │ Preview   │  │ Preview   │  │ Preview   │          │
│  │ index/    │  │ index/    │  │ index/    │          │
│  │ title/body│  │ title/body│  │ title/body│          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                                          │
│                [ ▶ スタート ]                            │ ← StartCTA
└─────────────────────────────────────────────────────────┘
```

- 背景・色・StarLayer は縦版と共通
- **スクリプトは `rule_explain_controller.gd` を共通利用**: `@onready var` は literal path を撤廃し `find_child()` 方式に書き換え
- RULES Dictionary は既存のものを流用 (game_type で出し分け)

### 4. 横画面カウントダウンシーンの新規作成

`scenes/ui/countdown_landscape.tscn` (1280x720):

レイアウト:

```
┌─────────────────────────────────────────────────────────┐
│                  まもなく開始！                          │ ← ReadyLabel
│                                                          │
│  ┌────────────┐                                         │
│  │            │                                         │
│  │ catboy     │           3                             │ ← 巨大数字 (右)
│  │ electric   │                                         │
│  │            │                                         │
│  └────────────┘                                         │
│  [集中して！]                                            │ ← SpeechBubble (左下)
└─────────────────────────────────────────────────────────┘
```

- 左半分: catboy_electric + SpeechBubble
- 右半分: ReadyLabel + 巨大カウント数字
- **スクリプトは `countdown_controller.gd` を共通利用** (find_child 方式)

### 5. ノードパス共通化のための find_child 方式採用

縦版 (VBoxContainer ベース) と横版 (HBoxContainer ベース) でルートの型が変わるため、literal `$SafeArea/MainColumn/...` パスは両立しない。

**両 controller で `@onready var x := find_child("XXX")` に書き換え**:

```gdscript
# 旧
@onready var _title_label: Label = $SafeArea/MainColumn/TitleBlock/TitleLabel

# 新
@onready var _title_label: Label = find_child("TitleLabel") as Label
```

ノード命名 (`TitleLabel`, `AbilityLabel`, `Step1`, ..., `StartButton`, `BackButton`) はシーン内で一意とし、`find_child()` で一発検索できるよう保証。

### 6. GameManager の遷移ロジック拡張

```gdscript
const LANDSCAPE_GAMES: Array = ["ghost_7ban_shobu"]

const RULE_EXPLAIN_SCENES: Dictionary = {
    "portrait": "res://scenes/ui/rule_explain.tscn",
    "landscape": "res://scenes/ui/rule_explain_landscape.tscn",
}

const COUNTDOWN_SCENES: Dictionary = {
    "portrait": "res://scenes/ui/countdown.tscn",
    "landscape": "res://scenes/ui/countdown_landscape.tscn",
}

func _is_landscape_game(game_type: String) -> bool:
    return game_type in LANDSCAPE_GAMES
```

新ゲームを横画面で追加する場合は `LANDSCAPE_GAMES` に 1 行追加。

### 7. orientation 制御の責務をシーン側 `_exit_tree()` に集約

GameManager の遷移先メソッド (navigate_to_home / on_individual_result_home / on_rule_explain_cancelled 等) に `enter_portrait()` を散らばらせると漏れが必発。

**横画面シーンの `_exit_tree()` で `OrientationHelper.enter_portrait()` を呼ぶ** 設計に変更:

- 横画面シーンの `_ready()` で `enter_landscape()`
- 横画面シーンの `_exit_tree()` で `enter_portrait()`
- どこに遷移しても、横画面シーンを抜けた瞬間に portrait に戻る

縦画面シーンは何もしない (元から portrait 固定の期待値で動く)。

### 8. orientation_helper.gd の実装

`scripts/utils/orientation_helper.gd`:

```gdscript
class_name OrientationHelper
extends Object

static func enter_landscape() -> void:
    if OS.has_feature("mobile"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

static func enter_portrait() -> void:
    if OS.has_feature("mobile"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
```

Web / エディタでは `mobile` feature が無いため no-op。

### 9. 縦画面シーンでの portrait 強制 (SENSOR 副作用対策)

`handheld/orientation=6` (SENSOR) にすると、ユーザが端末を傾けただけで縦画面シーンも回転してしまう副作用がある。

対策: **すべての rule_explain / countdown controller の `_ready()` で、シーンが横版でなければ `enter_portrait()` を明示呼びする**:

```gdscript
func _ready() -> void:
    if scene_file_path.ends_with("_landscape.tscn"):
        OrientationHelper.enter_landscape()
    else:
        OrientationHelper.enter_portrait()
    # ... 既存ロジック
```

### 10. ゴースト7番勝負本体の敵キャラ置換

`scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` の `ext_resource`:
- `Sleek_black_cat_with_icy_accents.png` → `catboy_confident.png` に差し替え
- TextureRect の参照ノードはそのまま (パス変更のみ、size 等のレイアウトは保持)

## 受け入れ条件

### project.godot

- [ ] `window/handheld/orientation=6` (SENSOR) に変更されている
- [ ] その他の display 設定 (viewport_width=720, viewport_height=1280, stretch/mode=canvas_items) は変更しない

### カウントダウン画面 (縦)

- [ ] `ghost_seirei.png` への参照が `countdown.tscn` 内に存在しない
- [ ] `catboy_electric.png` が ChibiTexture として使われている
- [ ] 背景が rule_explain.tscn と同じ Nebula 濃紺グラデ + StarLayer
- [ ] LoadingBar 関連ノード / コードが削除されている
- [ ] 3-2-1-GO! のシーケンス (1.0 秒間隔) が動作する
- [ ] `GameManager.on_countdown_finished()` が呼ばれる
- [ ] xvfb キャプチャでホーム/rule_explain と並べた時にトーンが一貫している

### ゴースト7番勝負本体の敵キャラ

- [ ] `ghost_7ban_shobu.tscn` の ext_resource が `catboy_confident.png` を参照している
- [ ] `Sleek_black_cat_with_icy_accents.png` への参照がプロジェクト全体に存在しない
- [ ] ゲームプレイ中の敵キャラ画像が catboy_confident に置換されている

### 横画面ルール説明

- [ ] `scenes/ui/rule_explain_landscape.tscn` が存在し、1280x720 をルートに持つ
- [ ] Step1/Step2/Step3 が**横3列**に並んでいる
- [ ] 左上に Header (BackButton)、右上にタイトル/能力ラベル、下中央に StartButton
- [ ] ゴースト7番勝負を選択した時に横版が表示される
- [ ] StartButton で `on_rule_explain_confirmed()` → 横版カウントダウン遷移
- [ ] BackButton で `on_rule_explain_cancelled()` → ホーム (縦に復帰)
- [ ] `_ready()` で landscape、`_exit_tree()` で portrait に戻る

### 横画面カウントダウン

- [ ] `scenes/ui/countdown_landscape.tscn` が存在
- [ ] 左半分に catboy_electric + SpeechBubble、右半分にカウント数字
- [ ] 3-2-1-GO! 完了で `on_countdown_finished()` → ゴースト7番勝負ゲームへ
- [ ] `_ready()` で landscape、`_exit_tree()` で portrait に戻る

### ノードパス共通化

- [ ] `rule_explain_controller.gd` 内の `@onready var` が `find_child()` ベース
- [ ] `countdown_controller.gd` 内の `@onready var` が `find_child()` ベース
- [ ] 縦版/横版の両シーンから同じ controller で起動できる

### GameManager 拡張

- [ ] `LANDSCAPE_GAMES` 定数に `"ghost_7ban_shobu"` が含まれる
- [ ] `start_game()` で game_type に応じた rule_explain シーンに遷移
- [ ] `on_rule_explain_confirmed()` で game_type に応じた countdown シーンに遷移
- [ ] 既存縦画面ゲーム (reflex_tap / flash_calc / sequence_memory) の動線が壊れていない

### 端末向き制御

- [ ] `scripts/utils/orientation_helper.gd` が存在 (`extends Object`)
- [ ] 横画面シーン入場で landscape、退場で portrait に戻る
- [ ] エディタ / Web では no-op で例外を出さない

### 動作確認

- [ ] xvfb キャプチャでホーム / 縦 rule_explain / 縦 countdown が一貫
- [ ] xvfb キャプチャで横 rule_explain / 横 countdown / ghost_7ban_shobu が一貫
- [ ] 実機 (moto g 66j) で縦動線 (reflex_tap 等) → portrait 維持
- [ ] 実機で横動線 (ghost_7ban_shobu) → landscape 切替 → ホーム戻りで portrait 復帰

## 成功指標

- ホーム / 縦 rule_explain / 縦 countdown / 横 rule_explain / 横 countdown / ghost_7ban_shobu の 6 画面でデザイントーンが一貫
- 「全く別の UI/UX」と感じない世界観統一
- 新規ミニゲーム追加時に `LANDSCAPE_GAMES` に 1 行で済む

## スコープ外

- 他ゲーム (reflex_tap / flash_calc / sequence_memory) のリデザイン
- 個別結果画面 / 総合結果画面の横画面対応 (これらは縦画面の想定)
- countdown / rule_explain controller の機能追加
- 縦横切替時のトランジションアニメーション
- onboarding / daily challenge 内での向き切替 (Week 2 以降)

## 参照ドキュメント

- `docs/ideas/brain_training_gdd.md` - GDD (世界観の北極星)
- `docs/functional-design.md` - ルール説明 / カウントダウン仕様
- `scenes/main/home.tscn` - catboy_electric リファレンス
- `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` - 横画面 Midnight Cat リファレンス
- `scenes/ui/rule_explain.tscn` - Midnight Cat v3 縦版リファレンス
- 直近コミット: e613f4c (Midnight Cat v3), 46d1a8c (ゴースト7番勝負実装)
- memory: Mascot is Catboy (canonical), Stitch サイズ換算
