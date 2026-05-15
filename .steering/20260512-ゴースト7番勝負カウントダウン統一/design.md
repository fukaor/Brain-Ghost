# 設計書

## アーキテクチャ概要

縦/横の 2 軸でルール説明・カウントダウンを分岐。共通スクリプト (`rule_explain_controller.gd` / `countdown_controller.gd`) を `find_child()` ベースに書き換えてノードパス非依存にし、別シーンファイル (`*_landscape.tscn`) を新規作成。GameManager で game_type → orientation 分岐し、project.godot の `handheld/orientation=6` (SENSOR) でランタイム回転を許可。orientation 復帰は横画面シーン側の `_exit_tree()` に集約することで遷移漏れを防ぐ。

```
                  ┌───────────────┐
                  │   Home (縦)    │ catboy_electric
                  └───────┬───────┘
                          │ start_game(game_type)
                          │
              ┌───────────┴───────────┐
              │ _is_landscape_game()? │
              └─┬─────────────────────┘
            No  │                 Yes
                ▼                  ▼
       rule_explain.tscn   rule_explain_landscape.tscn
        (縦 720x1280)         (横 1280x720)
        VBoxContainer         HBoxContainer (左右2カラム
                                + 右に Step 横3列)
                │                  │
                │   _ready: enter_landscape()
                │   _exit_tree: enter_portrait()
                │
                └──────┬───────────┘
       on_rule_explain_confirmed()
                       │
              ┌────────┴────────────┐
              │ _is_landscape_game()│
              └─┬───────────────────┘
            No  │                 Yes
                ▼                  ▼
       countdown.tscn      countdown_landscape.tscn
        catboy_electric     catboy_electric
        (縦)                  (横)
                │                  │
                └──────┬───────────┘
       on_countdown_finished()
                       │
                       ▼
                GAME_SCENES[type]
                  (例: ghost_7ban_shobu.tscn 横)
```

両 controller は **`find_child()` でノード参照**するため、縦版/横版でルートの型 (VBox/HBox) が変わってもスクリプト変更不要。

## コンポーネント設計

### 1. project.godot の変更

**変更箇所**:
```
window/handheld/orientation=1   ← 旧 (PORTRAIT 固定)
window/handheld/orientation=6   ← 新 (SENSOR、ランタイム切替を許可)
```

**実装の要点**:
- AndroidManifest 側にも反映される
- ランタイムで `DisplayServer.screen_set_orientation()` が効くようになる
- 副作用 (端末傾きで縦画面シーンも回転) は、**各 controller の `_ready()` で `enter_portrait()` を強制呼び**することで完全抑制 (シーン直接設計)

### 2. orientation_helper.gd (新規ユーティリティ)

**配置**: `scripts/utils/orientation_helper.gd`

**実装**:
```gdscript
## OrientationHelper
##
## 実機 (Android/iOS) でのみ動作する画面向き制御ヘルパー。
## Web / エディタ / Linux/macOS デスクトップでは no-op。
class_name OrientationHelper
extends Object

static func enter_landscape() -> void:
    if OS.has_feature("mobile"):
        DisplayServer.screen_set_orientation(
            DisplayServer.SCREEN_LANDSCAPE
        )

static func enter_portrait() -> void:
    if OS.has_feature("mobile"):
        DisplayServer.screen_set_orientation(
            DisplayServer.SCREEN_PORTRAIT
        )
```

`extends Object` で軽量 static 関数のみ。インスタンス化不要。

### 3. countdown.tscn (縦版リデザイン)

**責務**: 縦画面ミニゲーム (reflex_tap / flash_calc / sequence_memory) 前のカウントダウン。

**ノード構造** (リデザイン後):
```
Countdown (Control 720x1280)
├ VoidBg (ColorRect, 黒)
├ NebulaBg (TextureRect + Gradient_nebula)
├ StarLayer (Control + star_layer.gd)
└ SafeArea (MarginContainer)
   └ MainContent (VBoxContainer)
      ├ TopSpacer
      ├ ReadyLabel ("まもなく開始！")
      ├ ReadyDecorLine (細いシアン線)
      ├ CountSpacer1
      ├ CountCenter (CenterContainer)
      │  └ CountLabel ("3", NotoSerifJP-Bold, size 280)
      ├ BottomSpacer
      └ ChibiArea (HBoxContainer)
         └ ChibiColumn (VBoxContainer)
            ├ SpeechBubble (glass_bubble)
            │  └ BubbleMargin → BubbleText
            └ ChibiBg (PanelContainer 280x280)
               └ ChibiTexture (catboy_electric.png)
```

**変更点**:
- ext_resource `ghost_seirei.png` → `catboy_electric.png`
- Gradient_countbg (水色) → Gradient_nebula (黒地+シアン) を rule_explain から SubResource コピー
- StarLayer 追加
- LoadingBarBg / LoadingBarFill / LoadingTextRow ノード削除
- 色: 青 `Color(0,0.484,1)` → シアン `Color(0.7,0.93,1.0)` に統一

**スクリプト** (`countdown_controller.gd`):
- LoadingBar 関連 (`_loading_fill`, `_loading_text`, `_ready_pct`, `_update_loading_bar()`) を削除
- `@onready var` を **find_child() ベース**に書き換え
  ```gdscript
  @onready var _count_label: Label = find_child("CountLabel") as Label
  @onready var _ready_label: Label = find_child("ReadyLabel") as Label
  @onready var _bubble_text: Label = find_child("BubbleText") as Label
  ```
- Timer + on_countdown_finished は変更なし

### 4. countdown_landscape.tscn (横版、新規)

**責務**: 横画面ミニゲーム前のカウントダウン。

**ノード構造**:
```
CountdownLandscape (Control 1280x720)
├ VoidBg / NebulaBg / StarLayer (同上)
└ SafeArea (MarginContainer)
   └ MainContent (HBoxContainer)
      ├ ChibiArea (VBoxContainer, size_flags=3)
      │  ├ ChibiBg
      │  │  └ ChibiTexture (catboy_electric)
      │  └ SpeechBubble → BubbleText
      └ RightColumn (VBoxContainer, size_flags=3)
         ├ ReadyLabel
         ├ CountCenter
         │  └ CountLabel (size 320 — 横画面は余白多いので大きめ)
         └ BottomSpacer
```

**重要**: ノード命名 (`CountLabel`, `ReadyLabel`, `BubbleText`) を縦版と完全に揃え、`find_child()` で controller から検索可能にする。

**スクリプト**: `countdown_controller.gd` を共通利用

**追加**: `_ready()` で `OrientationHelper.enter_landscape()`、`_exit_tree()` で `OrientationHelper.enter_portrait()`

> controller を共通化するため、向き制御は controller 内で「自分が横版シーンかどうか」を判定して呼ぶ。判定は scene file path から、または明示的に `landscape: bool` プロパティを横版シーンの inspector で設定。

設計判断: **シーン file path 判定** が簡潔
```gdscript
func _ready() -> void:
    if scene_file_path.ends_with("_landscape.tscn"):
        OrientationHelper.enter_landscape()
    else:
        OrientationHelper.enter_portrait()  # SENSOR 副作用対策で必須
    # ... 既存ロジック

# _exit_tree() は不要 (次シーンの _ready() で必ず orientation が設定し直されるため)
```

> **重要**: `_exit_tree()` で portrait に戻す案も検討したが、次シーンの `_ready()` で必ず方向が再設定される ので冗長。シーン入場時に確定する単方向設計で十分。

### 5. rule_explain_landscape.tscn (横版、新規)

**責務**: 横画面ミニゲーム前のルール説明 (横3列ネイティブ)。

**ノード構造**:
```
RuleExplainLandscape (Control 1280x720)
├ VoidBg / NebulaBg / StarLayer (同上)
└ SafeArea (MarginContainer)
   └ MainColumn (VBoxContainer)
      ├ Header (HBoxContainer)
      │  ├ BackButton
      │  └ TitleBlock (VBoxContainer)
      │     ├ TitleLabel
      │     └ AbilityLabel
      ├ StepsColumn (HBoxContainer)  ← 横3列
      │  ├ Step1 (PanelContainer)
      │  │  └ Row (VBoxContainer) ← 縦版とは構造が異なる
      │  │     ├ Preview
      │  │     └ TextBlock
      │  │        ├ IndexRow → Index + Title
      │  │        └ Body
      │  ├ Step2 (同上)
      │  └ Step3 (同上)
      └ StartCTAWrap
         └ StartButton
```

**重要**: 縦版 (`StepsColumn` は VBoxContainer + Step1/2/3 の `Row` は HBoxContainer) と横版 (`StepsColumn` は HBoxContainer + Step1/2/3 の `Row` は VBoxContainer) で内部レイアウトが異なる。**ノード命名は完全に一致** させ、controller の `find_child()` でアクセス可能に保つ。

**スクリプト**: `rule_explain_controller.gd` を共通利用 (find_child 方式に書き換え)

**追加**: `_ready()` で landscape、`_exit_tree()` で portrait

### 6. rule_explain_controller.gd の修正 (find_child 移行)

**変更前**:
```gdscript
@onready var _title_label: Label = $SafeArea/MainColumn/TitleBlock/TitleLabel
@onready var _step1_index: Label = $SafeArea/MainColumn/StepsColumn/Step1/Row/TextBlock/IndexRow/Index
# ... 全 17 行
```

**変更後**:
```gdscript
@onready var _title_label: Label = find_child("TitleLabel") as Label
@onready var _ability_label: Label = find_child("AbilityLabel") as Label
# ... 個別 Step は名前で識別する必要があるため、Step1/Step2/Step3 ノード自体を find_child してから子を find_child
@onready var _step1_node: PanelContainer = find_child("Step1") as PanelContainer
@onready var _step1_index: Label = _step1_node.find_child("Index") as Label
@onready var _step1_title: Label = _step1_node.find_child("Title") as Label
@onready var _step1_body: Label = _step1_node.find_child("Body") as Label
@onready var _step1_preview: Control = _step1_node.find_child("Preview") as Control
# Step2, Step3 同様
```

`Index`, `Title`, `Body`, `Preview` という命名は Step1/2/3 内に重複するため、**Step ノード起点で find_child を呼ぶ**ことで重複解決。

**追加**: `_ready()` 冒頭で orientation 設定:
```gdscript
func _ready() -> void:
    if scene_file_path.ends_with("_landscape.tscn"):
        OrientationHelper.enter_landscape()
    else:
        OrientationHelper.enter_portrait()
    _wire_signals()
    # ... 既存ロジック
```

### 7. countdown_controller.gd の修正 (find_child 移行 + LoadingBar 削除)

```gdscript
@onready var _count_label: Label = find_child("CountLabel") as Label
@onready var _ready_label: Label = find_child("ReadyLabel") as Label
@onready var _bubble_text: Label = find_child("BubbleText") as Label
# LoadingBar 関連は削除

func _ready() -> void:
    if scene_file_path.ends_with("_landscape.tscn"):
        OrientationHelper.enter_landscape()
    else:
        OrientationHelper.enter_portrait()
    _step = 0
    _show_step()
    _start_timer()
```

`_update_loading_bar()` 関数全体を削除、`_show_step()` から呼び出しを除去。

### 8. GameManager の拡張

**追加**:
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

func _orientation_key(game_type: String) -> String:
    return "landscape" if _is_landscape_game(game_type) else "portrait"
```

**変更**:
```gdscript
func start_game(game_type: String) -> void:
    # ... 既存検証 ...
    _current_game_type = game_type
    current_mode = PlayMode.FREE
    _previous_score = DataStore.load_best(game_type).best_score
    var key := _orientation_key(game_type)
    _safe_change_scene(RULE_EXPLAIN_SCENES[key])

func on_rule_explain_confirmed() -> void:
    var key := _orientation_key(_current_game_type)
    _safe_change_scene(COUNTDOWN_SCENES[key])
```

`enter_portrait()` / `enter_landscape()` 呼び出しは **GameManager には書かない** (各シーン (rule_explain / countdown / 各ゲーム) の `_ready()` で scene_file_path 判定により自己解決)。

**ゲーム本体シーン (例: ghost_7ban_shobu.tscn)** にも同じパターンが必要:
- `ghost_7ban_shobu_view.gd` の `_ready()` で `OrientationHelper.enter_landscape()` を呼ぶ
- `reflex_tap.tscn` 等の縦画面ゲームの controller の `_ready()` で `OrientationHelper.enter_portrait()` を呼ぶ
- または、`scene_file_path` の慣習 (`_landscape.tscn` で終わるか) を全シーンで踏襲する

### 9. ghost_7ban_shobu.tscn の敵キャラ置換

**変更箇所**:
```
ext_resource path="res://assets/characters/Sleek_black_cat_with_icy_accents.png"
↓
ext_resource path="res://assets/characters/catboy_confident.png"
```

- TextureRect のサイズ・位置・stretch_mode は変更しない
- 画像のアスペクト比が異なる場合、Texture の枠内で内側 fit に
- ゴースト7番勝負本体の `_ready()` で `OrientationHelper.enter_landscape()` を呼ぶようにスクリプト追加 (現状未実装)

## データフロー

### 縦画面ゲーム

```
home (catboy_electric) → start_game("reflex_tap")
  → _is_landscape_game = false
  → rule_explain.tscn (縦, find_child)
  → on_rule_explain_confirmed()
  → countdown.tscn (縦, catboy_electric)
  → on_countdown_finished()
  → reflex_tap.tscn (縦)
```

### 横画面ゲーム

```
home (_ready: enter_portrait) → start_game("ghost_7ban_shobu")
  → rule_explain_landscape.tscn
    _ready: enter_landscape()
  → on_rule_explain_confirmed()
  → countdown_landscape.tscn
    _ready: enter_landscape() (継続)
  → on_countdown_finished()
  → ghost_7ban_shobu.tscn
    _ready: enter_landscape() (継続)
  → on_game_finished_handler()
  → individual_result.tscn
    _ready: enter_portrait() ← 縦シーンに戻り
```

横画面 → 横画面のシーン遷移では `enter_landscape()` が連続呼びされるだけなので無駄なちらつきがない。

### ホームに戻る (どのシーンからでも)

home / individual_result / game_list 等の縦シーンの `_ready()` で `enter_portrait()` を呼ぶため、どこから戻っても確実に portrait に戻る。

## エラーハンドリング戦略

- `DisplayServer.screen_set_orientation()` は `OS.has_feature("mobile")` 判定で no-op (Web/エディタ)
- `find_child()` が null を返した場合は `_ready()` で警告ログを出す
- シーン切替失敗時は既存の `_safe_change_scene` フォールバック (home.tscn へ)

## テスト戦略

### キャプチャ検証 (memory: UI/UX 変更後はキャプチャ必須)

xvfb 経由で取得:
- `scenes/ui/countdown.tscn` (リデザイン後)
- `scenes/ui/rule_explain_landscape.tscn`
- `scenes/ui/countdown_landscape.tscn`

ホーム/縦 rule/縦 count/横 rule/横 count/ghost_7ban_shobu の 6 画面でトーン比較。

### 実機検証 (memory: 実機タップ感の検証)

`bash scripts_build/deploy_android.sh --logcat` で moto g 66j に流す:
- 縦動線: reflex_tap (or flash_calc) → 向きが portrait 維持
- 横動線: ghost_7ban_shobu → landscape 切替 → ホーム戻りで portrait 復帰
- logcat に新規 WARN/ERROR が出ないこと

### ユニットテスト (任意)

`GameManager._is_landscape_game()` / `_orientation_key()` の薄いテスト:
- `tests/unit/autoload/test_game_manager_orientation.gd`

## 依存ライブラリ

新規追加なし。

## ディレクトリ構造

```
/workspace/
├── project.godot                          ← orientation 1 → 6 に変更
├── scenes/ui/
│   ├── countdown.tscn                    ← 大幅リデザイン (catboy_electric)
│   ├── countdown_landscape.tscn          ← 新規 (1280x720, catboy_electric)
│   ├── rule_explain.tscn                 ← 変更なし
│   └── rule_explain_landscape.tscn       ← 新規 (1280x720, 横3列)
├── scenes/games/ghost_7ban_shobu/
│   └── ghost_7ban_shobu.tscn             ← 敵キャラを catboy_confident に置換
├── scripts/
│   ├── ui/
│   │   ├── countdown_controller.gd       ← find_child 化 + LoadingBar 削除 + orientation 制御
│   │   ├── rule_explain_controller.gd    ← find_child 化 + orientation 制御
│   │   └── ghost_7ban_shobu_view.gd      ← _ready で enter_landscape() を呼ぶ
│   ├── autoload/
│   │   └── game_manager.gd               ← LANDSCAPE_GAMES + 分岐ロジック
│   └── utils/
│       └── orientation_helper.gd         ← 新規
└── tests/unit/autoload/
    └── test_game_manager_orientation.gd  ← 任意
```

## 実装の順序

1. **Phase 0**: project.godot orientation 1 → 6 に変更
2. **orientation_helper.gd** 作成
3. **GameManager 拡張** (LANDSCAPE_GAMES + シーンマップ + 分岐)
4. **rule_explain_controller.gd を find_child 化 + orientation 制御** (縦版で動作確認)
5. **countdown_controller.gd を find_child 化 + LoadingBar 削除 + orientation 制御** (縦版動作確認)
6. **countdown.tscn リデザイン** (ghost_seirei → catboy_electric, Midnight Cat 統一)
7. **rule_explain_landscape.tscn 新規** (横3列レイアウト)
8. **countdown_landscape.tscn 新規** (左右2分割)
9. **ghost_7ban_shobu.tscn の敵キャラを catboy_confident に置換** + view.gd で enter_landscape()
10. **xvfb キャプチャ取得** + ユーザ確認
11. **実機検証** (両動線)
12. **振り返り**

## セキュリティ考慮事項

なし (UI 変更のみ)

## パフォーマンス考慮事項

- 横画面シーンは縦と同じ背景 (NebulaBg + StarLayer) を使用、追加負荷ほぼ無視
- `DisplayServer.screen_set_orientation()` のコストは無視できる
- シーン中継時の短時間 orientation トグルは実機検証で違和感を確認

## 将来の拡張性

- 新規ミニゲームの横画面化: `LANDSCAPE_GAMES` に 1 行追加
- 縦横切替時のトランジション (フェード等) は別フェーズで検討
- ノード命名規約 (Step1/Step2/Step3 + Index/Title/Body/Preview) を docs/repository-structure.md に明記すれば、横画面新規 minigame もこのパターンで増やせる
