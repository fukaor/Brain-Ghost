# 設計書 — 反射タップ実装

## アーキテクチャ概要

反射タップは **BaseGame を継承した純粋なロジッククラス** + **Control シーン** + **GameManager によるフロー制御** の 3 層構成。既存の ScoreSystem / PlayLog / GhostCharacter / Theme リソースを **何も変更せずに** 組み上げる。

```
┌─────────────────────────────────────────────────────────────┐
│                          HomeScreen                          │
│        StartButton.pressed → GameManager.start_reflex_tap() │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GameManager (Autoload)                    │
│  _current_game: BaseGame                                     │
│  _current_play_log: PlayLog                                  │
│  _previous_score: int                                        │
│  start_reflex_tap(mode) → rule_explain → countdown           │
│    → reflex_tap → individual_result → home                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
┌──────────────┐  ┌────────────────┐  ┌──────────────┐
│ RuleExplain  │  │  Countdown     │  │ ReflexTap    │
│   scene      │  │   scene        │  │   scene      │
│              │  │                │  │              │
│ GhostChar    │  │ GhostChar      │  │ ReflexTap    │
│   吹き出し    │  │   "3..2..1.." │  │   (BaseGame) │
│              │  │                │  │   ロジック    │
└──────────────┘  └────────────────┘  └──────────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │ IndividualResult │
                                    │     scene        │
                                    │                  │
                                    │ GhostChar        │
                                    │   結果反応       │
                                    │                  │
                                    │ [もう一度][ホーム]│
                                    └──────────────────┘
```

**重要な設計原則**:

1. **ゲームロジックとビジュアルを完全分離**: `reflex_tap.gd` は Control の UI ノードを直接操作しない。UI シグナルを受けて状態を更新し、UI 側が状態を参照する（正確には逆に、reflex_tap.tscn が reflex_tap.gd を持ち、ビジュアルノードに直接アクセスする。Godot の慣習に従う。ロジックはメソッドで切り出して unit test 可能にする）
2. **BaseGame の既存 API のみを使う**: `setup() / start() / handle_input() / record_event() / finish()` のライフサイクルを守る
3. **決定論性を最初から保証**: `rng.randi_range()` のみ使用、`Array.shuffle()` は禁止
4. **GhostCharacter を再利用**: インスタンス化するだけで 3 つの画面で使い回す
5. **patterns.md §1 のボイラープレートを守る**: すべての新規画面は SafeAreaMargin + MainColumn 構造

## コンポーネント設計

### 1. `scripts/games/reflex_tap.gd`

**責務**:
- BaseGame のライフサイクルフックを実装
- ターゲット生成・タップ判定・反応時間計測・PlayEvent 記録
- 終了時に `PlayLog` を組み立てて返す

**ファイル構造**:

```gdscript
class_name ReflexTap
extends BaseGame

# 定数
const TARGET_COUNT: int = 20
const SCREEN_MARGIN_PX: int = 40
const TARGET_SIZE_MIN: int = 80
const TARGET_SIZE_MAX: int = 120
const WAIT_MS_MIN: int = 400
const WAIT_MS_MAX: int = 1200
const FAKE_INTERVAL_MIN: int = 3
const FAKE_INTERVAL_MAX: int = 5
const FAKE_PENALTY_MS: int = 50

# 状態
var _tapped_count: int = 0
var _fake_tapped_count: int = 0
var _reaction_times_ms: Array[int] = []
var _current_target_shown_time: int = -1
var _current_is_fake: bool = false
var _next_fake_at: int = 3  # 次にフェイクを出す "タップ数" 境界

# ライフサイクル
func _on_setup(_seed_value: int) -> void:
    game_type = "reflex_tap"
    is_time_based = true
    _tapped_count = 0
    _fake_tapped_count = 0
    _reaction_times_ms = []
    _next_fake_at = rng.randi_range(FAKE_INTERVAL_MIN, FAKE_INTERVAL_MAX)

func _on_start() -> void:
    # UI 側で最初のターゲットを表示してもらうためのシグナルを発火させる責務はシーン側
    pass

func _on_user_input(input: Dictionary) -> void:
    # input = {"type": "target_tap" | "fake_tap"}
    if input.type == "target_tap":
        _handle_target_tap()
    elif input.type == "fake_tap":
        _handle_fake_tap()

func _on_finish() -> PlayLog:
    var log := super._on_finish()
    var avg_ms: float = _calculate_average_reaction_ms()
    var score := _score_system_calculate(avg_ms)
    log.score = score
    log.game_type = "reflex_tap"
    # id, played_at, played_date, is_new_best, ghost_result は GameManager 側で埋める
    return log

# ロジック（unit test 対象）
func generate_target_position(viewport_size: Vector2i) -> Vector2:
    var size := _pick_target_size()
    var x := rng.randi_range(SCREEN_MARGIN_PX, viewport_size.x - SCREEN_MARGIN_PX - size)
    var y := rng.randi_range(SCREEN_MARGIN_PX, viewport_size.y - SCREEN_MARGIN_PX - size)
    return Vector2(x, y)

func pick_target_size() -> int:
    return rng.randi_range(TARGET_SIZE_MIN, TARGET_SIZE_MAX)

func pick_wait_ms() -> int:
    return rng.randi_range(WAIT_MS_MIN, WAIT_MS_MAX)

func should_show_fake() -> bool:
    return _tapped_count + 1 >= _next_fake_at

func calculate_average_reaction_ms() -> float:
    if _reaction_times_ms.is_empty():
        return 0.0
    var total := 0
    for t in _reaction_times_ms:
        total += t
    var avg := float(total) / float(_reaction_times_ms.size())
    return avg + float(_fake_tapped_count * FAKE_PENALTY_MS)

# Private
func _handle_target_tap() -> void:
    var reaction := get_elapsed_ms() - _current_target_shown_time
    _reaction_times_ms.append(reaction)
    record_event("target_tapped", float(reaction))
    _tapped_count += 1
    if _tapped_count >= TARGET_COUNT:
        finish()

func _handle_fake_tap() -> void:
    _fake_tapped_count += 1
    record_event("fake_tapped", 1.0)
```

**技術的制約**:
- `ScoreSystem` は `calculate_score(game_type, play_data)` で呼ぶが、ReflexTap 側からは直接呼ばず、**GameManager が `_on_finish()` の結果を受け取ってスコアを計算して log.score にセット** する方が分離が綺麗。→ 再設計: `_on_finish()` では score を 0 のままにして、GameManager が ScoreSystem を呼んで埋める
- 現在の表示位置を覚えておくのは `reflex_tap.tscn` シーン側の責務（node を動的配置するため）

### 2. `scenes/games/reflex_tap.tscn`

**ノード階層**:

```
ReflexTap (Control + ReflexTapView スクリプト)
 └─ PageBackground (TextureRect, page_bg.png)
 └─ SafeAreaMargin (MarginContainer, margin 16/32/16/16)
     └─ MainColumn (VBoxContainer)
         ├─ TopHudRow (HBoxContainer)
         │   ├─ ProgressPill (PanelContainer "pill_chip")
         │   │   └─ HBox: Label "icon_pill" "radio_button_checked" + Label "value" "0 / 20"
         │   ├─ ElapsedPill (PanelContainer "pill_chip")
         │   │   └─ HBox: Label "icon_pill" "schedule" + Label "value" "0.0s"
         │   └─ SpeedPill (PanelContainer "pill_chip")
         │       └─ HBox: Label "icon_pill" "bolt" + Label "value" "— ms"
         │
         └─ GameArea (Control, size_flags_vertical=3)
             └─ (動的に TargetNode / FakeNode が追加される)

 └─ AdBannerArea (MarginContainer, anchor 下端固定, 広告枠)
```

**ReflexTapView (`scripts/games/reflex_tap_view.gd`)**:
- `_game: ReflexTap` を保持
- Timer で次のターゲットを出す
- タップ検知 → `_game.handle_input({"type": "target_tap"})` を呼ぶ
- `_game.game_finished` シグナルを購読して GameManager に通知

**技術的制約**:
- GameArea の子ノードを動的追加・削除する（ターゲットノードの生成）
- ターゲットノードは `Button` を使い、theme variation `target_circle` を Theme に追加して丸い見た目にする
- フェイクは `target_circle_fake` variation で別色（NEUTRAL_LIGHT_GRAY）

### 3. `scenes/ui/rule_explain.tscn`

**責務**:
- ゲームプレイ開始前に、ゴーストキャラがルールを説明する
- データドリブン: `RuleExplainController.set_rule(game_type)` でルール文字列を差し替え可能

**ノード階層**:

```
RuleExplain (Control)
 └─ PageBackground (TextureRect)
 └─ SafeAreaMargin
     └─ MainColumn
         ├─ TitleLabel (Label h1, "反射タップ")  ← set_rule で変更
         ├─ GhostCharacter (instance)             ← ルール説明セリフを持つ
         ├─ FlexSpacer
         └─ ButtonRow (HBoxContainer)
             ├─ SkipButton (Button "secondary", "スキップ")  ← onboarding 完了時のみ visible
             └─ StartButton (Button "cta_gradient", "▶ スタート")
```

**データ管理**:
```gdscript
const RULES: Dictionary = {
    "reflex_tap": {
        "title": "反射タップ",
        "dialogue": "ランダムに出てくる丸をできるだけ速くタップしてね。20 回の平均時間でスコアが決まるよ。違う色の偽物はタップしちゃダメ！",
    },
    # 将来他ゲームもここに追加
}
```

### 4. `scenes/ui/countdown.tscn`

**責務**:
- 3 → 2 → 1 → "いくよ！" の 4 秒アニメーション
- ゴーストのセリフも段階的に更新
- 完了で `countdown_finished` シグナルを発火

**ノード階層**:

```
Countdown (Control)
 └─ PageBackground
 └─ CenterContainer
     └─ VBoxContainer
         ├─ CountLabel (Label "display", text="3")  ← 1 秒ごとに更新
         └─ GhostCharacter (instance)
```

**実装**:
```gdscript
# Timer で 1 秒ごとに update
# CountLabel を "3" → "2" → "1" → "いくよ！"
# Ghost dialogue を "3..." → "2..." → "1..." → "いくよ！" に同期
# 最後の 1 秒後に countdown_finished シグナル発火
```

**アニメーション**: 各カウント表示時に `scale` を 1.5 → 1.0 に Tween で落とす簡易演出。AnimationPlayer は使わず Tween で十分

### 5. `scenes/ui/individual_result.tscn`

**責務**:
- 直近プレイの結果を表示
- ゴーストが結果に応じて反応セリフを出す
- `[もう一度]` で同じゲームを再スタート、`[ホームへ]` で home 画面へ

**ノード階層**:

```
IndividualResult (Control)
 └─ PageBackground
 └─ SafeAreaMargin
     └─ MainColumn
         ├─ TitleLabel (Label h1, "結果")
         ├─ ResultCard (PanelContainer "hero_card")
         │   └─ VBox
         │       ├─ ScoreLabel (Label "display", "1020")  ← スコア
         │       ├─ DiffLabel (Label "caption", "前回比 +120")
         │       ├─ AvgReactionLabel (Label "body", "平均 298ms")
         │       └─ BestBadge (HBoxContainer, visible=is_new_best)
         │           ├─ BestIcon (Label "icon_hero", "auto_awesome")
         │           └─ BestLabel (Label "h2", "ベスト更新！")
         ├─ GhostCharacter (instance, 反応セリフ)
         ├─ FlexSpacer
         └─ ButtonRow (HBoxContainer)
             ├─ ReplayButton (Button "secondary", "もう一度")
             └─ HomeButton (Button, "ホームへ")
```

**コントローラ**:
```gdscript
func set_result(log: PlayLog, previous_score: int) -> void:
    _score_label.text = str(log.score)
    var diff := log.score - previous_score
    _diff_label.text = "前回比 %+d" % diff if previous_score > 0 else "初プレイ"
    # 平均反応時間は play_data から取得か、events から再計算
    _best_badge.visible = log.is_new_best
    _update_ghost_dialogue(log, previous_score)

func _update_ghost_dialogue(log: PlayLog, previous_score: int) -> void:
    if previous_score == 0:
        _ghost.set_dialogue("お疲れさま！\nこれがきみの初めての記録だよ")
    elif log.is_new_best:
        _ghost.set_dialogue("ベスト更新！\n今日のきみはすごい！")
    elif log.score > previous_score:
        _ghost.set_dialogue("前より早くなってるよ！\nこの調子")
    else:
        _ghost.set_dialogue("惜しい！\nでも確実に良くなってるよ")
```

### 6. `scripts/autoload/game_manager.gd`

**新規メソッド**:

```gdscript
var _current_play_log: PlayLog
var _previous_score: int = 0
var _current_game_type: String = ""

func start_reflex_tap(mode: String = "free") -> void:
    _current_game_type = "reflex_tap"
    # home → rule_explain へ遷移
    get_tree().change_scene_to_file("res://scenes/ui/rule_explain.tscn")
    # rule_explain_controller が _ready() で rule をセット

func on_rule_explain_confirmed() -> void:
    # rule_explain → countdown へ
    get_tree().change_scene_to_file("res://scenes/ui/countdown.tscn")

func on_countdown_finished() -> void:
    # countdown → reflex_tap へ
    get_tree().change_scene_to_file("res://scenes/games/reflex_tap.tscn")

func on_game_finished(log: PlayLog) -> void:
    # log のフィールドを埋める (id, played_at, played_date, score 計算, is_new_best)
    log.id = UuidUtil.v4()
    log.played_at = Time.get_datetime_string_from_system(true)
    log.played_date = DateUtil.today_jst()
    # スコア計算
    var score_sys := ScoreSystem.new()
    var avg_ms: float = _compute_avg_from_events(log.events)
    log.score = score_sys.calculate_score(log.game_type, {"average_reaction_ms": avg_ms})
    # ベスト判定
    _previous_score = _load_previous_score(log.game_type)
    log.is_new_best = log.score > _previous_score
    # DataStore に保存
    DataStore.append_play_log(log)  # スタブ OK
    _current_play_log = log
    # individual_result へ
    get_tree().change_scene_to_file("res://scenes/ui/individual_result.tscn")

func on_individual_result_replay() -> void:
    start_reflex_tap(_current_game_type == "reflex_tap" ? "free" : "free")

func on_individual_result_home() -> void:
    get_tree().change_scene_to_file("res://scenes/main/home.tscn")
```

**技術的制約**:
- シーン遷移時に `_current_play_log` を保持する必要がある (Autoload なので生存する)
- `DataStore.append_play_log` は既存スタブが存在するなら使う、存在しないなら今回 `push_warning` で代替
- `scenes/ui/individual_result_controller.gd` が GameManager から `_current_play_log` を読む構造にする

### 7. `scripts/ui/home_controller.gd` 修正

**変更箇所**:

```gdscript
# Before
func _on_start_button_pressed() -> void:
    _ghost.set_dialogue("よーし！3 種類、約 2 分だよ。\n一緒にがんばろう！")
    print("[Home] StartButton pressed (TODO: 次ステアリングで GameManager.start_daily_challenge() を呼ぶ)")

# After
func _on_start_button_pressed() -> void:
    _ghost.set_dialogue("よーし！一緒にがんばろう！")
    GameManager.start_reflex_tap("free")
```

## データフロー

### プレイフロー (成功ケース)

```
1. ユーザーがホーム画面で [スタート] タップ
2. home_controller._on_start_button_pressed() が呼ばれる
3. GhostCharacter のセリフが "よーし！一緒にがんばろう！" に更新
4. GameManager.start_reflex_tap("free") が呼ばれる
5. シーン遷移 → scenes/ui/rule_explain.tscn
6. rule_explain_controller._ready() が "reflex_tap" のルールを set_rule()
7. GhostCharacter のセリフが "ランダムに出てくる丸をできるだけ速くタップしてね..." に更新
8. ユーザーが [スタート] タップ
9. GameManager.on_rule_explain_confirmed() → countdown.tscn へ遷移
10. countdown_controller が 1 秒ごとに 3 → 2 → 1 → "いくよ！" と更新
11. GhostCharacter のセリフも同期
12. 完了で GameManager.on_countdown_finished() → reflex_tap.tscn へ遷移
13. reflex_tap_view._ready() で ReflexTap インスタンス化・setup() → start()
14. Timer で wait_ms 後にターゲット生成 (position, size, 色)
15. ユーザーがターゲットをタップ → reflex_tap.handle_input({"type": "target_tap"})
16. reflex_tap が反応時間を記録 → events に追加
17. 20 回タップ完了で reflex_tap.finish() → game_finished シグナル発火
18. reflex_tap_view が GameManager.on_game_finished(log) を呼ぶ
19. GameManager が log のフィールド埋め + ScoreSystem 呼び出し + DataStore 保存
20. シーン遷移 → individual_result.tscn
21. individual_result_controller が GameManager._current_play_log を読み set_result()
22. GhostCharacter のセリフが結果に応じて 4 パターンのうち 1 つに更新
23. ユーザーが [もう一度] or [ホームへ] タップ → 対応するフロー
```

### フェイクタップのペナルティフロー

```
1. reflex_tap が次ターゲット生成時に should_show_fake() を判定
2. True ならフェイク色 (NEUTRAL_LIGHT_GRAY) のターゲットを生成
3. ユーザーがフェイクをタップ → handle_input({"type": "fake_tap"})
4. _fake_tapped_count += 1, record_event("fake_tapped")
5. _calculate_average_reaction_ms() 時に _fake_tapped_count * 50ms を平均に加算
```

## エラーハンドリング戦略

本フェーズで想定されるエラー:

- **DataStore 保存失敗**: スタブ実装のため失敗しない想定だが、push_warning でログのみ残しフローは継続
- **PlayLog の events が空（0 回タップで finish）**: score=0 で終了、ゴーストが「お疲れさま！次はもう少し挑戦してみよう」
- **Theme の variation が見つからない**: 開発時のみ発生。push_error で即座に気づけるようにする
- **シーン遷移失敗**: `get_tree().change_scene_to_file()` が err を返したら push_error、フォールバックで home へ

```gdscript
func _safe_change_scene(path: String) -> void:
    var err := get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("Scene change failed: %s (err=%d)" % [path, err])
        get_tree().change_scene_to_file("res://scenes/main/home.tscn")
```

## テスト戦略

### ユニットテスト (GUT)

`tests/unit/games/test_reflex_tap.gd` に以下を実装:

```gdscript
extends "res://addons/gut/test.gd"

var game: ReflexTap

func before_each() -> void:
    game = ReflexTap.new()
    game.setup(12345)  # 決定論シード

func after_each() -> void:
    if is_instance_valid(game):
        game.queue_free()

func test_setup_initializes_state():
    assert_eq(game.game_type, "reflex_tap")
    assert_true(game.is_time_based)
    assert_eq(game._tapped_count, 0)
    assert_eq(game._reaction_times_ms.size(), 0)

func test_deterministic_target_size():
    var g1 := ReflexTap.new(); g1.setup(12345)
    var g2 := ReflexTap.new(); g2.setup(12345)
    for i in range(20):
        assert_eq(g1.pick_target_size(), g2.pick_target_size(), "Same seed same size")
    g1.queue_free(); g2.queue_free()

func test_target_size_in_range():
    for i in range(100):
        var size := game.pick_target_size()
        assert_true(size >= game.TARGET_SIZE_MIN)
        assert_true(size <= game.TARGET_SIZE_MAX)

func test_wait_ms_in_range():
    for i in range(100):
        var wait := game.pick_wait_ms()
        assert_true(wait >= game.WAIT_MS_MIN)
        assert_true(wait <= game.WAIT_MS_MAX)

func test_target_position_within_margin():
    var viewport := Vector2i(720, 1280)
    for i in range(100):
        var pos := game.generate_target_position(viewport)
        assert_true(pos.x >= game.SCREEN_MARGIN_PX)
        assert_true(pos.y >= game.SCREEN_MARGIN_PX)
        assert_true(pos.x <= viewport.x - game.SCREEN_MARGIN_PX)
        assert_true(pos.y <= viewport.y - game.SCREEN_MARGIN_PX)

func test_average_reaction_empty():
    assert_eq(game.calculate_average_reaction_ms(), 0.0)

func test_average_reaction_normal():
    game._reaction_times_ms = [300, 400, 500]
    assert_almost_eq(game.calculate_average_reaction_ms(), 400.0, 0.1)

func test_average_reaction_fake_penalty():
    game._reaction_times_ms = [300, 400, 500]
    game._fake_tapped_count = 2
    # 400 + 2*50 = 500
    assert_almost_eq(game.calculate_average_reaction_ms(), 500.0, 0.1)

func test_should_show_fake_boundary():
    # _next_fake_at がセットされていれば _tapped_count +1 で判定
    game._next_fake_at = 4
    game._tapped_count = 2
    assert_false(game.should_show_fake())
    game._tapped_count = 3
    assert_true(game.should_show_fake())
```

計 10-12 テスト。既存 45 と合わせて 55+ になる。

### 統合テスト (手動 xvfb)

`tools/manual_reflex_flow.gd` のようなスクリプトで 4 画面のスクショを取得:

```gdscript
# 各画面で wait + screenshot を繰り返す
# home → rule_explain → countdown → reflex_tap → individual_result
```

### 静的チェック

```bash
# 生 hex
grep -rnE "Color\(\s*[0-9]" scenes/games/ scenes/ui/ scripts/games/ scripts/ui/ | grep -v "color_palette.gd"

# 絶対配置
grep -rnE "offset_(left|top|right|bottom)\s*=\s*-?[0-9]" scenes/games/ scenes/ui/

# modulate (ghost 例外)
grep -rn "modulate = Color\|add_theme_.*_override" scripts/games/ scripts/ui/ | grep -v ghost_character

# OS.get_name
grep -rn "OS.get_name()" scripts/games/ scripts/ui/
```

## 依存ライブラリ

新規追加なし。既存の Godot 4.6 + GUT v9.6.0 + Noto Sans JP + Material Symbols Rounded で完結。

## ディレクトリ構造

```
workspace/
├── .steering/20260412-reflex-tap-implementation/
│   ├── requirements.md   (作成済)
│   ├── design.md         (本ファイル)
│   ├── tasklist.md       (次)
│   └── screenshots/      (実装中に生成)
│
├── scripts/games/
│   └── reflex_tap.gd           (新規)
│
├── scripts/ui/
│   ├── reflex_tap_view.gd      (新規、scene スクリプト)
│   ├── rule_explain_controller.gd   (新規)
│   ├── countdown_controller.gd (新規)
│   └── individual_result_controller.gd  (新規)
│
├── scripts/autoload/
│   └── game_manager.gd         (編集: start_reflex_tap フロー追加)
│
├── scripts/ui/
│   └── home_controller.gd      (編集: StartButton を GameManager 呼び出しに)
│
├── scenes/games/
│   └── reflex_tap.tscn         (新規)
│
├── scenes/ui/
│   ├── rule_explain.tscn       (新規)
│   ├── countdown.tscn          (新規)
│   └── individual_result.tscn  (新規)
│
├── tests/unit/games/
│   └── test_reflex_tap.gd      (新規)
│
└── assets/themes/
    └── default_theme.tres      (編集: target_circle / target_circle_fake variation 追加)
```

## 実装の順序

1. **フェーズ A**: 現状確認 + テスト先行
   - 既存 game_manager.gd / data_store.gd のスタブを読む
   - ScoreSystem / PlayLog の利用方法再確認
   - `tests/unit/games/test_reflex_tap.gd` スケルトン + 10 件のテスト骨格

2. **フェーズ B**: ReflexTap ゲームロジック
   - `scripts/games/reflex_tap.gd` 実装
   - テストを回して全パス確認
   - リグレッション確認 (既存 45 テスト + 新規 10)

3. **フェーズ C**: Theme 拡張
   - `target_circle` / `target_circle_fake` variation を `build_theme.gd` に追加
   - Theme 再生成
   - `godot --headless --quit` OK

4. **フェーズ D**: 反射タップシーン
   - `scenes/games/reflex_tap.tscn` 新規作成
   - `scripts/ui/reflex_tap_view.gd` 実装
   - xvfb でスクショ確認

5. **フェーズ E**: ルール説明画面
   - `scenes/ui/rule_explain.tscn` + controller
   - ゴーストキャラインスタンス化
   - RULES Dictionary で差し替え可能に
   - xvfb でスクショ確認

6. **フェーズ F**: カウントダウン画面
   - `scenes/ui/countdown.tscn` + controller
   - Timer + Tween でアニメーション
   - xvfb でスクショ確認

7. **フェーズ G**: 個別結果画面
   - `scenes/ui/individual_result.tscn` + controller
   - ゴーストのセリフ 4 パターン
   - xvfb でスクショ確認

8. **フェーズ H**: GameManager フロー統合
   - `start_reflex_tap / on_rule_explain_confirmed / on_countdown_finished / on_game_finished / on_individual_result_replay / on_individual_result_home` 実装
   - 各画面コントローラから GameManager 呼び出し

9. **フェーズ I**: ホーム画面から起動
   - `home_controller.gd` の StartButton を接続
   - TODO コメント削除

10. **フェーズ J**: エンドツーエンド動作確認
    - xvfb で 4 画面スクショ + フロー確認
    - GUT リグレッション最終確認
    - 静的チェック最終実行

11. **フェーズ K**: ドキュメント反映
    - patterns.md にゲーム画面ボイラープレートを追加
    - repository-structure.md にファイルリスト反映

12. **フェーズ L**: 振り返り
    - tasklist.md の振り返りセクション記入
    - 次のステアリング候補記録

## セキュリティ考慮事項

本フェーズに特筆すべき新しいセキュリティリスクなし。既存のデータ保存・ネットワークレスアーキテクチャを維持。

## パフォーマンス考慮事項

- **ターゲットノードの動的生成**: 20 回分を毎フレーム生成せず、1 つのターゲットを使い回して `position` を更新するか、1 つずつ追加する。後者で十分（20 ノードは軽い）
- **Timer の精度**: Godot の `Timer.wait_time` は ms 単位まで指定可能だが、実際の発火は frame interval に依存。反応時間計測は `Time.get_ticks_msec()` を直接使って正確性を担保
- **決定論性**: `rng.randi_range` のみ使用。`randomize()` は setup 時に 1 度のみ

## 将来の拡張性

- **他 5 ゲーム**: このステアリングで確立したパターン（BaseGame 継承 + scene view + GameManager フロー）をそのまま流用
- **ゴーストバー**: PlayLog 5 件蓄積後、ReflexTapView の HUD にゴースト進捗バーを追加
- **本物のゴースト対戦判定**: GhostSystem.judge_result の本実装、個別結果画面で勝敗表示
- **デイリーチャレンジ**: start_reflex_tap を start_daily_challenge で包み、3 種連続プレイに
- **カスタムアニメーション**: ターゲット出現時のフェードイン、タップ時のフィードバックエフェクト
