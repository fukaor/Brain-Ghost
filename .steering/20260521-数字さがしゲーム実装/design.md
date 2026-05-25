# 設計

## 1. アーキテクチャ概要

既存ゲーム（sequence_memory / flash_calc）と同じ「BaseGame サブクラス + View」 2 層構成を踏襲。

```
NumberSearch (BaseGame)         ← scripts/games/number_search/number_search.gd
  ├ NumberSearchTierConfig      ← scripts/games/number_search/tier_config.gd
  └ GridGenerator (Object)      ← scripts/games/number_search/grid_generator.gd

NumberSearchView (Control)      ← scripts/ui/number_search_view.gd
  └ NumberCell (Button)         ← scenes/games/number_search/number_cell.tscn
                                    + scripts/ui/components/number_cell.gd
```

## 2. ファイル一覧（新規作成）

| パス | 役割 |
|---|---|
| `scripts/games/number_search/number_search.gd` | ゲームロジック（BaseGame サブクラス） |
| `scripts/games/number_search/tier_config.gd` | T1〜T6 定数集約（MVP は T3 のみ参照） |
| `scripts/games/number_search/grid_generator.gd` | デイリーシード対応の数字配列生成 |
| `scenes/games/number_search/number_search.tscn` | プレイ画面 |
| `scenes/games/number_search/number_cell.tscn` | グリッドセルコンポーネント |
| `scripts/ui/components/number_cell.gd` | セル状態管理（未タップ / タップ済み） |
| `scripts/ui/number_search_view.gd` | View（HUD / グリッド / タイマー / 結果遷移） |

## 3. ファイル一覧（変更）

| パス | 変更内容 |
|---|---|
| `scripts/autoload/game_manager.gd` | `GAME_SCENES` / `_build_play_data_for` に number_search 追加 |
| `scripts/core/score_system.gd` | `number_search` 計算式を残り時間比率ベースに変更 |
| `scripts/ui/game_list_controller.gd` | `_implemented_games` に `"number_search"` 追加 |

## 4. NumberSearch.gd 設計

```gdscript
class_name NumberSearch
extends BaseGame

const TIME_LIMIT_SEC: float = 60.0  # T3 MVP のみ。ティア別は tier_config 参照
const MAX_NUMBER_T3: int = 25
const GRID_ROWS_T3: int = 5
const GRID_COLS_T3: int = 5

var _tier: String = "T3"
var _grid_numbers: Array[int] = []  # 0..24 のセル index → 中身の数字
var _current_target: int = 1
var _miss_taps: int = 0
var _is_clear: bool = false

func _on_setup(seed_value: int) -> void:
    game_type = "number_search"
    is_time_based = false
    _tier = "T3"
    _current_target = 1
    _miss_taps = 0
    _is_clear = false
    var gen = preload("res://scripts/games/number_search/grid_generator.gd").new()
    _grid_numbers = gen.generate(_tier, seed_value)

func _on_start() -> void:
    record_event("session_start", 0.0)

# View からセルタップを受ける
func _on_user_input(input: Dictionary) -> void:
    if String(input.get("type", "")) != "cell_tap":
        return
    var cell_index: int = int(input.get("cell_index", -1))
    if cell_index < 0 or cell_index >= _grid_numbers.size():
        return
    var number: int = _grid_numbers[cell_index]
    if number != _current_target:
        _miss_taps += 1
        record_event("miss_tap", float(number))
        return
    record_event("correct_tap", float(number))
    _current_target += 1
    if _current_target > MAX_NUMBER_T3:
        _is_clear = true
        record_event("clear", float(get_elapsed_ms()))
        finish()

# 制限時間到達時に View が呼ぶ
func timeout() -> void:
    if not _is_active:
        return
    _is_clear = false
    # NOTE: timeout イベントの value は到達数字（=正解タップした数）。秒ではない。
    # GameManager 側の _extract_clear_time_sec はこの value を読まず log.duration_ms を使う。
    record_event("timeout", float(_current_target - 1))
    finish()

# NOTE: BaseGame 契約上、_on_finish() ではゲーム固有フィールド (events / duration_ms / game_type)
# のみ完成させる。log.id / log.score / log.mode / log.played_at / log.played_date / log.is_new_best
# は GameManager.on_game_finished_handler() が一括で埋める設計（sequence_memory.gd と同パターン）。
func _on_finish() -> PlayLog:
    var log := super._on_finish()
    log.game_type = "number_search"
    return log

# View 用 getter
func get_tier() -> String: return _tier
func get_current_target() -> int: return _current_target
func get_grid_numbers() -> Array[int]: return _grid_numbers
func get_miss_taps() -> int: return _miss_taps
func get_is_clear() -> bool: return _is_clear
func get_clear_time_sec() -> float: return float(get_elapsed_ms()) / 1000.0
```

## 5. TierConfig 設計

MVP では T3 のみ参照するが、後続拡張のため全 6 ティアを定義しておく（拡張時に table 追加だけで済むように）:

```gdscript
class_name NumberSearchTierConfig
extends Object

const TIER_CONFIGS: Dictionary = {
    "T1": {"rows": 3, "cols": 3, "max_number":  9, "time_limit": 30.0, "multiplier": 1.0, "visual": "uniform"},
    "T2": {"rows": 4, "cols": 4, "max_number": 16, "time_limit": 45.0, "multiplier": 1.0, "visual": "uniform"},
    "T3": {"rows": 5, "cols": 5, "max_number": 25, "time_limit": 60.0, "multiplier": 1.0, "visual": "uniform"},
    # T4-T6 は将来拡張。今は参照しない。
}
```

## 6. GridGenerator 設計

spec §8-1（ティア別独立シャッフル）に準拠:

```gdscript
extends Object

const TIER_OFFSETS: Dictionary = {"T1": 0, "T2": 100, "T3": 200}

func generate(tier: String, seed_value: int) -> Array[int]:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value + int(TIER_OFFSETS.get(tier, 200))
    var max_num: int = int(NumberSearchTierConfig.TIER_CONFIGS[tier]["max_number"])
    var nums: Array[int] = []
    for i in range(1, max_num + 1):
        nums.append(i)
    # Fisher-Yates
    for i in range(nums.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var tmp: int = nums[i]
        nums[i] = nums[j]
        nums[j] = tmp
    return nums
```

## 7. View 設計

`sequence_memory_view.gd` をテンプレートに、以下を採用:

- `SafeAreaMargin` / `MainColumn` / `HeaderArea` / `GridCenter` の階層構造を踏襲。
- 上部 HUD:
  - **NextNumberPill**（左）: `次: 14` 表示。Material Symbols は使わず数字のみ。
  - **TimerLabel**（右）: 秒数（CYAN_300 系）+ 残り 10 秒で `GOLD_400` にトーン切替。
- 中央 GridContainer（5 列 × 5 行）: NumberCell インスタンス × 25。
- 下部 BestDisplay: `★ ベスト: N pts` 形式（MVP）。`DataStore.load_best("number_search").best_score` から取得。スコアが 0（未プレイ）なら `— pts`。
  - **v1.1 で `ベスト: N秒` 形式に拡張する。MVP は self_best 比較がスコア軸のため統一**。
- _process(delta) で経過秒を毎フレーム更新し、`TIME_LIMIT - elapsed <= 0` で `_game.timeout()` を呼ぶ。
- **`_process` 冒頭で `_game._is_active` をチェックし、非アクティブなら即 return**（sequence_memory_view L94-96 パターン）。

### セル状態（NumberCell）

```
[normal]  ← 暗グラス背景（COLOR_TAPPABLE_BG 系）+ INK_100 数字
[found]   ← 緑系背景（`Color(0.27, 0.71, 0.45, 0.85)` ≒ Emerald 500 α=0.85）
            + 数字を一段暗く（INK_60）+ shadow を薄める
```

不正解タップ時は視覚フィードバックなし（spec §3-2）。経過秒の進行のみがペナルティ。

## 8. ScoreSystem 改訂

```gdscript
"number_search":
    var clear_sec := float(play_data.get("clear_time_sec", 60.0))
    var is_clear := bool(play_data.get("is_clear", false))
    var tier_mult := float(play_data.get("tier_multiplier", 1.0))
    if not is_clear:
        return 0
    const BASE_SCORE := 1500
    const TIME_LIMIT := 60.0  # MVP は T3 のみ
    var remaining_ratio := max(0.0, (TIME_LIMIT - clear_sec) / TIME_LIMIT)
    return int(round(BASE_SCORE * remaining_ratio * tier_mult))
```

## 9. GameManager 統合

```gdscript
# GAME_SCENES に追加
"number_search": "res://scenes/games/number_search/number_search.tscn",

# _build_play_data_for に追加
"number_search":
    var clear_sec := _extract_clear_time_sec(log)
    var is_clear := _extract_is_clear(log)
    return {
        "clear_time_sec": clear_sec,
        "is_clear": is_clear,
        "tier_multiplier": 1.0,  # T3 only
    }

# ヘルパー
func _extract_clear_time_sec(log) -> float:
    if log == null or log.events == null:
        return 60.0
    for evt in log.events:
        if evt != null and evt.event_type == "clear":
            return evt.value / 1000.0
    return float(log.duration_ms) / 1000.0

func _extract_is_clear(log) -> bool:
    if log == null or log.events == null:
        return false
    for evt in log.events:
        if evt != null and evt.event_type == "clear":
            return true
    return false
```

## 10. ゴーストデータ（MVP は不要）

`individual_result_controller.gd` L121-129 で number_search は **`compare_mode = "self_best"`** が設定済み。MVP は「YOU スコア vs 自己ベスト スコア」の比較で結果を表示する。

→ **MVP では GhostData Autoload への保存は行わない**。`DataStore.update_best_if_better(log)` が `on_game_finished_handler` で自動呼び出されるため、ベスト記録だけは自動で残る。

v1.1 で `GhostData` の汎用化（クリアタイム / スコアの直近 5 回平均）を行い、`compare_mode = "ghost"` に切り替える方針。

## 11. 受け入れテスト

| # | シナリオ | 期待結果 |
|---|---|---|
| 1 | 脳トレ一覧 → 数字さがしカード → スタート | rule_explain → countdown → プレイ画面遷移 |
| 2 | 1〜25 を順にタップ | 25 タップ目でクリア確定、結果画面に遷移 |
| 3 | 60 秒経過してもクリアしない | スコア 0、「タイムアウト」表示 |
| 4 | 同じ日に再プレイ | グリッド配置が同一（デイリーシード一致） |
| 5 | ベストタイム更新時 | 結果画面に `★BEST` バッジ表示 |
