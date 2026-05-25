# 設計

## 1. アーキテクチャ概要

```
Stroop (BaseGame)               ← scripts/games/stroop/stroop.gd
  ├ StroopTierConfig            ← scripts/games/stroop/tier_config.gd
  └ StimulusGenerator (Object)  ← scripts/games/stroop/stimulus_generator.gd

StroopView (Control)            ← scripts/ui/stroop_view.gd
  └ AnswerButton (Button)       ← scenes/games/stroop/answer_button.tscn
                                    + scripts/ui/components/answer_button.gd
```

`game_type = "stroop"` 維持。

**ティア方針（v1.1 確定 / review C1 反映）**:
- コード上は T1〜T3 を完全サポート（StimulusGenerator / TierConfig / Shape レンダリング全部 MVP に含む）
- MVP 起動時はティア選択 UI が無いため **T1 固定で開始**
- ティア決定は `_resolve_tier()` ヘルパー経由（GameManager → TierManager の優先順）。TierManager 未実装の現状では `"T1"` を返す最小 stub
- v1.1 で TierManager / ティア選択 UI を追加するとき、StimulusGenerator / View のロジックには変更不要

## 2. ファイル一覧（新規作成）

| パス | 役割 |
|---|---|
| `scripts/games/stroop/stroop.gd` | BaseGame サブクラス |
| `scripts/games/stroop/tier_config.gd` | T1〜T3 の比率 / ボタンシャッフル設定 |
| `scripts/games/stroop/stimulus_generator.gd` | デイリーシード対応の刺激プール生成 |
| `scenes/games/stroop/stroop.tscn` | プレイ画面 |
| `scenes/games/stroop/answer_button.tscn` | 4 色回答ボタン |
| `scripts/ui/components/answer_button.gd` | ボタンコンポーネント |
| `scripts/ui/stroop_view.gd` | View |

## 3. ファイル一覧（変更）

| パス | 変更 |
|---|---|
| `scripts/autoload/game_manager.gd` | GAME_SCENES に stroop 追加 + _build_play_data_for ヘルパー追加 |
| `scripts/ui/game_list_controller.gd` | _implemented_games 追加 + GAME_CARDS の名前変更 |
| `scripts/core/score_system.gd` | **変更不要**（既存式が正しい） |

## 4. Stroop.gd 設計

```gdscript
class_name Stroop
extends BaseGame

const GAME_DURATION_SEC: float = 30.0
const ANSWER_TIMEOUT_MS: int = 3000
const FEEDBACK_DURATION_SEC: float = 0.1
const COLORS: Array[String] = ["red", "blue", "green", "yellow"]

enum StimulusType { CONGRUENT, INCONGRUENT, SHAPE }

var _tier: String = "T1"
var _stimuli: Array = []          # [{type, display_color, text, correct_answer, shape?}, ...]
var _current_index: int = 0
var _correct_count: int = 0
var _wrong_count: int = 0
var _stimulus_start_ms: int = 0   # 各問題の表示時刻
var _is_finished: bool = false
var _final_score: int = 0

func _on_setup(seed_value: int) -> void:
    game_type = "stroop"
    is_time_based = true
    _tier = _resolve_tier()  # GameManager → TierManager の優先順。MVP は "T1"
    _current_index = 0
    _correct_count = 0
    _wrong_count = 0
    _is_finished = false
    _final_score = 0
    var gen = preload("res://scripts/games/stroop/stimulus_generator.gd").new()
    # 2 段階生成（spec §8-1）: ティア非依存プール → ティア別フィルタリング
    var pool: Array = gen.generate_pool(seed_value)
    _stimuli = gen.select_for_tier(pool, _tier)

# MVP は GameManager の _current_tier を読む。未設定なら T1。
func _resolve_tier() -> String:
    var gm := Engine.get_main_loop().get_root().get_node_or_null("GameManager") if Engine.get_main_loop() else null
    if gm != null and "_current_tier" in gm:
        var t: String = String(gm._current_tier)
        if t == "T1" or t == "T2" or t == "T3":
            return t
    return "T1"

func _on_start() -> void:
    _present_stimulus_start_time()

func _present_stimulus_start_time() -> void:
    _stimulus_start_ms = Time.get_ticks_msec()

func _on_user_input(input: Dictionary) -> void:
    var t := String(input.get("type", ""))
    match t:
        "answer":
            _handle_answer(String(input.get("color", "")))
        "answer_timeout":
            _handle_answer_timeout()
        "time_over":
            _handle_time_over()

func _handle_answer(color: String) -> void:
    if _is_finished or _current_index >= _stimuli.size():
        return
    var stim: Dictionary = _stimuli[_current_index]
    var is_correct: bool = (color == String(stim.get("correct_answer", "")))
    var reaction_ms: int = Time.get_ticks_msec() - _stimulus_start_ms
    if is_correct:
        _correct_count += 1
        record_event("stroop_correct", float(reaction_ms))
    else:
        _wrong_count += 1
        record_event("stroop_wrong", float(reaction_ms))
    _advance_or_finish()

func _handle_answer_timeout() -> void:
    record_event("stroop_timeout", float(ANSWER_TIMEOUT_MS))
    _advance_or_finish()

func _advance_or_finish() -> void:
    _current_index += 1
    var elapsed_sec: float = float(get_elapsed_ms()) / 1000.0
    if elapsed_sec >= GAME_DURATION_SEC or _current_index >= _stimuli.size():
        _is_finished = true
        record_event("session_end", float(_correct_count))
        finish()
        return
    _present_stimulus_start_time()

func _handle_time_over() -> void:
    if _is_finished: return
    _is_finished = true
    record_event("session_end", float(_correct_count))
    finish()

# flash_calc.gd パターンに揃え、_on_finish() で log.score をここで完成させる。
# ScoreSystem は precomputed_score をパススルー。
func _on_finish() -> PlayLog:
    var net: int = _correct_count * 100 - _wrong_count * 50
    var mult: float = float(StroopTierConfig.TIER_CONFIGS.get(_tier, {}).get("score_mult", 1.0))
    _final_score = int(round(max(0, net) * mult))
    var log := super._on_finish()
    log.game_type = "stroop"
    log.score = _final_score
    return log

func get_tier() -> String: return _tier
func get_final_score() -> int: return _final_score

# Getter
func get_current_stimulus() -> Dictionary:
    if _current_index < _stimuli.size():
        return _stimuli[_current_index]
    return {}
func get_correct_count() -> int: return _correct_count
func get_wrong_count() -> int: return _wrong_count
func get_total_stimuli() -> int: return _stimuli.size()
```

## 5. StimulusGenerator 設計（2 段階 / spec §8-1 準拠）

ティア非依存のコア属性プールを生成 → ティア別の出現比率でフィルタリング。これにより同じシードでも T1/T2/T3 ユーザーが**同じプール**から比率に応じてサンプリングする「Wordle 公平性」が保たれる。

```gdscript
extends Object

const COLORS = ["red", "blue", "green", "yellow"]
const JP = {"red": "あか", "blue": "あお", "green": "みどり", "yellow": "きいろ"}
const SHAPES = ["circle", "square", "triangle", "diamond"]

# Step 1: ティア非依存のコア属性プールを生成（全 40 問）
func generate_pool(seed_value: int) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var pool: Array = []
    for i in range(40):
        var display_color := COLORS[rng.randi() % 4]
        var others := COLORS.filter(func(c): return c != display_color)
        var interfere := others[rng.randi() % others.size()]
        var shape := SHAPES[rng.randi() % 4]
        pool.append({
            "index": i,
            "display_color": display_color,
            "interfere_color": interfere,
            "shape": shape,
        })
    return pool

# Step 2: 共通プールからティア別比率で刺激を組み立てる（型を決める）
func select_for_tier(pool: Array, tier: String) -> Array:
    var ratios := _tier_ratios(tier)
    # ティア別に決定論的な型シーケンスを構築するため、seed は tier 名のハッシュで派生
    var type_rng := RandomNumberGenerator.new()
    type_rng.seed = hash(tier)
    var stimuli: Array = []
    for item in pool:
        var stim_type := _pick_type(type_rng, ratios)
        var display_color := String(item["display_color"])
        var interfere := String(item["interfere_color"])
        var text: String = JP[display_color] if stim_type == "congruent" else JP[interfere]
        var stim := {
            "type": stim_type,
            "display_color": display_color,    # 正解判定の基準色
            "interfere_color": interfere,
            "correct_answer": display_color,   # spec §2-2 統一原則: 中央の色 = display_color
            "text": text,
            "shape": String(item["shape"]),    # T3 Shape 時のみ View が使う
        }
        stimuli.append(stim)
    return stimuli

func _tier_ratios(tier: String) -> Dictionary:
    match tier:
        "T1": return {"congruent": 0.5, "incongruent": 0.5, "shape": 0.0}
        "T2": return {"congruent": 0.3, "incongruent": 0.7, "shape": 0.0}
        "T3": return {"congruent": 0.2, "incongruent": 0.5, "shape": 0.3}
        _:   return {"congruent": 0.5, "incongruent": 0.5, "shape": 0.0}

func _pick_type(rng: RandomNumberGenerator, ratios: Dictionary) -> String:
    var r := rng.randf()
    var cumulative := 0.0
    for key in ["congruent", "incongruent", "shape"]:
        cumulative += float(ratios.get(key, 0.0))
        if r < cumulative:
            return key
    return "incongruent"
```

## 6. View 設計（stroop_view.gd）

```gdscript
extends Control

@onready var _stimulus_label: Label = $UI/StimulusContainer/StimulusLabel
@onready var _shape_container: Control = $UI/StimulusContainer/ShapeContainer
@onready var _timer_label: Label = $UI/Header/TimerLabel
@onready var _answer_buttons: HBoxContainer = $UI/Footer/AnswerButtons
@onready var _feedback: Control = $UI/Feedback
@onready var _player_bar: ProgressBar = $UI/Ghost/PlayerBar
@onready var _ghost_bar: ProgressBar = $UI/Ghost/GhostBar
@onready var _score_label: Label = $UI/Footer/ScoreLabel

var _game: Stroop
var _seed: int = -1
var _ghost_target: int = 10  # 初回ゴースト
var _answer_timer: Timer
var _is_locked: bool = false  # フィードバック表示中

func _ready() -> void:
    _game = Stroop.new()
    add_child(_game)
    _game.game_finished.connect(_on_game_finished)
    _game.setup(_seed)
    _game.start()
    _present_current()

func _process(_delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec := float(_game.get_elapsed_ms()) / 1000.0
    var remaining := max(0.0, Stroop.GAME_DURATION_SEC - elapsed_sec)
    _timer_label.text = "%ds" % int(round(remaining))
    if remaining <= 0.0:
        # close-race 対策: time_over 発火直後に answer_timer を停止
        if _answer_timer != null:
            _answer_timer.stop()
        _game.handle_input({"type": "time_over"})
        return
    _update_ghost_bar(elapsed_sec)

func _present_current() -> void:
    # close-race ガード: time_over や手動 finish 後の遅延コールで状態が壊れないように
    if _game == null or not _game._is_active:
        return
    var stim := _game.get_current_stimulus()
    if stim.is_empty(): return
    var display_color := _color_to_godot(String(stim.get("display_color", "red")))
    if String(stim.get("type", "")) == "shape":
        _stimulus_label.visible = false
        _shape_container.visible = true
        _render_shape(stim, display_color)
    else:
        _shape_container.visible = false
        _stimulus_label.visible = true
        _stimulus_label.text = String(stim.get("text", ""))
        _stimulus_label.add_theme_color_override("font_color", display_color)
    _is_locked = false
    _start_answer_timeout()

# Shape 刺激のレンダリング（spec §3-2）
# 図形の塗りつぶし色 = display_color、内側に Label で interfere_color の色名（白文字で重ねる）
func _render_shape(stim: Dictionary, display_color: Color) -> void:
    var shape_panel: Panel = _shape_container.get_node("ShapePanel")
    var inner_label: Label = _shape_container.get_node("ShapePanel/InnerLabel")
    var sb := StyleBoxFlat.new()
    sb.bg_color = display_color
    sb.corner_radius_top_left = 16
    sb.corner_radius_top_right = 16
    sb.corner_radius_bottom_right = 16
    sb.corner_radius_bottom_left = 16
    shape_panel.add_theme_stylebox_override("panel", sb)
    inner_label.text = String(stim.get("text", ""))
    inner_label.add_theme_color_override("font_color", Color(0.957, 0.969, 1.0))  # INK_100 白文字

func _start_answer_timeout() -> void:
    if _answer_timer == null:
        _answer_timer = Timer.new()
        _answer_timer.one_shot = true
        _answer_timer.timeout.connect(_on_answer_timeout)
        add_child(_answer_timer)
    _answer_timer.start(Stroop.ANSWER_TIMEOUT_MS / 1000.0)

func _on_answer_pressed(color: String) -> void:
    if _is_locked: return
    _is_locked = true
    _answer_timer.stop()
    var stim := _game.get_current_stimulus()
    var is_correct := (color == String(stim.get("correct_answer", "")))
    _flash_feedback(is_correct)
    _game.handle_input({"type": "answer", "color": color})
    _update_score_label()
    _maybe_shuffle_buttons()
    await get_tree().create_timer(Stroop.FEEDBACK_DURATION_SEC).timeout
    if _game._is_active:
        _present_current()
```

色マッピング:

```gdscript
func _color_to_godot(s: String) -> Color:
    match s:
        "red":    return Color(0.898, 0.224, 0.208)
        "blue":   return Color(0.118, 0.533, 0.898)
        "green":  return Color(0.263, 0.627, 0.278)
        "yellow": return Color(0.992, 0.847, 0.208)
    return Color.WHITE
```

## 7. TierConfig

```gdscript
class_name StroopTierConfig
extends Object

const TIER_CONFIGS: Dictionary = {
    "T1": {"score_mult": 1.0, "shuffle_buttons_every": 0,
           "ratios": {"congruent": 0.5, "incongruent": 0.5, "shape": 0.0},
           "initial_ghost": 10},
    "T2": {"score_mult": 1.2, "shuffle_buttons_every": 0,
           "ratios": {"congruent": 0.3, "incongruent": 0.7, "shape": 0.0},
           "initial_ghost": 9},
    "T3": {"score_mult": 1.5, "shuffle_buttons_every": 3,
           "ratios": {"congruent": 0.2, "incongruent": 0.5, "shape": 0.3},
           "initial_ghost": 8},
}
```

## 8. GameManager 統合

`_on_finish()` で `log.score` をティア倍率込みで完成させる（flash_calc.gd パターン）。ScoreSystem 側は **precomputed_score をパススルー**:

```gdscript
# scripts/autoload/game_manager.gd
"stroop":
    return {"precomputed_score": int(log.score)}

# scripts/core/score_system.gd
"stroop":
    # 既存式は廃止。stroop.gd の _on_finish() でティア倍率込みで計算済み。
    return max(0, int(play_data.get("precomputed_score", 0)))
```

これにより `_build_play_data_for` のヘルパー（_extract_stroop_count 等）は不要。tasklist でも削除する。

## 9. ゴーストバー表示

- 30 秒のうち x 秒経過時の **ゴーストの想定累計正答数** = `initial_ghost * (elapsed_sec / 30.0)`（MVP は線形近似。v1.1 で GhostData の events 平均に差し替え）。
- バー max_value は **固定 20**（30 秒 × 1.5 秒/問 ≈ 20 問が上限想定 / spec §6-3 の T1=10, T2=9, T3=8 + バッファ）。
- `_ghost_target` は `_ready()` でティアに応じて `StroopTierConfig.TIER_CONFIGS[tier]["initial_ghost"]` から取得。

```gdscript
const GHOST_BAR_MAX: float = 20.0

func _ready() -> void:
    # ...（略）
    _ghost_target = int(StroopTierConfig.TIER_CONFIGS.get(_game.get_tier(), {}).get("initial_ghost", 10))
    _player_bar.max_value = GHOST_BAR_MAX
    _ghost_bar.max_value = GHOST_BAR_MAX

func _update_ghost_bar(elapsed_sec: float) -> void:
    _player_bar.value = float(_game.get_correct_count())
    var ghost_eta := float(_ghost_target) * (elapsed_sec / Stroop.GAME_DURATION_SEC)
    _ghost_bar.value = ghost_eta
```

**GhostData 連携（MVP 対象外）**: `individual_result_controller.gd` L94-102 で stroop は **`compare_mode = "self_best"`**。結果画面の比較カードはスコアの自己ベスト比較を表示する。プレイ中の `_ghost_target` 線形近似は **ゴーストキャラの存在感を出すための演出専用**で、結果画面のスコア判定には影響しない。

## 10. game_list_controller 変更

GAME_CARDS の `"stroop"` 要素の `name` を `"色文字テスト"` → `"色文字ストループ"` に変更（`category = "ATTENTION"` のまま）。`_implemented_games` に追加。

## 10b. ScoreSystem 改訂

```gdscript
# scripts/core/score_system.gd
"stroop":
    # v1.1: stroop.gd の _on_finish() でティア倍率込みで計算済み。パススルー。
    return max(0, int(play_data.get("precomputed_score", 0)))
```

## 11. レイアウト指針

- StimulusLabel: 中央配置、font_size = 96px（mc_h1 相当）、太字。色は display_color で上書き。
- AnswerButtons: 4 ボタン横並び、各幅 80dp、間 16dp、最小タップ領域 56dp。
- ShapeContainer は Panel(StyleBoxFlat) で塗りつぶし色 + 内側に Label（テキスト色を `INK_100` 白で重ねる）。

## 12. 受け入れテスト

| # | シナリオ | 期待結果 |
|---|---|---|
| 1 | game_list → 色文字ストループ → スタート | rule_explain → countdown → プレイ |
| 2 | 30 秒間連続回答 | タイマ 0 で session_end → 結果画面 |
| 3 | 正解タップ | 緑フラッシュ + 正解カウンタ +1 |
| 4 | 誤答タップ | グレーフラッシュ + 誤答カウンタ +1 |
| 5 | 3 秒以内に回答せず | timeout で次の問題へ |
| 6 | 結果画面に正答数 / 誤答数 / 平均反応時間 表示 | OK |
| 7 | 同日シードで刺激が同一 | OK |
