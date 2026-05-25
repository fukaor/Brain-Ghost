# 設計

## 1. アーキテクチャ概要

```
CardMatch (BaseGame)            ← scripts/games/card_match/card_match.gd
  ├ CardMatchTierConfig         ← scripts/games/card_match/tier_config.gd
  └ CardGenerator (Object)      ← scripts/games/card_match/card_generator.gd

CardMatchView (Control)         ← scripts/ui/card_match_view.gd
  └ Card (Control)              ← scenes/games/card_match/card.tscn
                                    + scripts/ui/components/card.gd
```

`game_type = "card_match"` を維持（既存 game_list / ScoreSystem との互換性のため）。クラス名 / シーン名も `card_match` に統一。

## 2. ファイル一覧（新規作成）

| パス | 役割 |
|---|---|
| `scripts/games/card_match/card_match.gd` | ゲームロジック |
| `scripts/games/card_match/tier_config.gd` | ティア定数（MVP は T1） |
| `scripts/games/card_match/card_generator.gd` | デイリーシード対応の配置生成 |
| `scenes/games/card_match/card_match.tscn` | プレイ画面 |
| `scenes/games/card_match/card.tscn` | カードコンポーネント |
| `scripts/ui/components/card.gd` | カード状態管理 |
| `scripts/ui/card_match_view.gd` | View |

## 3. ファイル一覧（変更）

| パス | 変更 |
|---|---|
| `scripts/autoload/game_manager.gd` | GAME_SCENES / _build_play_data_for に card_match 追加 |
| `scripts/core/score_system.gd` | card_match 計算式を spec §5-1 に改訂 |
| `scripts/ui/game_list_controller.gd` | _implemented_games に "card_match" 追加 |

## 4. CardMatch.gd 設計

```gdscript
class_name CardMatch
extends BaseGame

const TIME_LIMIT_SEC: float = 60.0
const TOTAL_PAIRS: int = 8
const TOTAL_CARDS: int = 16
const MATCH_DISPLAY_SEC: float = 0.3
const MISMATCH_DISPLAY_SEC: float = 0.5

var _tier: String = "T1"
var _grid_data: Array[int] = []   # cell_index → card_id (0..7)
var _is_face_up: Array[bool] = [] # 1 枚目として表向き中
var _is_matched: Array[bool] = []
var _first_card_index: int = -1   # -1 = 未選択
var _total_taps: int = 0
var _pairs_found: int = 0
var _is_processing: bool = false  # 不一致表示中
var _is_clear: bool = false

func _on_setup(seed_value: int) -> void:
    game_type = "card_match"
    is_time_based = false
    _tier = "T1"
    _first_card_index = -1
    _total_taps = 0
    _pairs_found = 0
    _is_processing = false
    _is_clear = false
    _is_face_up = []
    _is_matched = []
    _is_face_up.resize(TOTAL_CARDS); _is_matched.resize(TOTAL_CARDS)
    var gen = preload("res://scripts/games/card_match/card_generator.gd").new()
    _grid_data = gen.generate(_tier, seed_value)

func can_tap(cell_index: int) -> bool:
    if _is_processing: return false
    if cell_index < 0 or cell_index >= TOTAL_CARDS: return false
    if _is_face_up[cell_index] or _is_matched[cell_index]: return false
    return true

# View からセルタップを受ける（受理されたタップのみカウント）
func _on_user_input(input: Dictionary) -> void:
    var t := String(input.get("type", ""))
    if t == "cell_tap":
        var idx := int(input.get("cell_index", -1))
        _handle_tap(idx)
    elif t == "mismatch_resolved":
        # View 側で 0.5 秒経過後に呼ぶ
        _resolve_mismatch(int(input.get("first", -1)), int(input.get("second", -1)))
    elif t == "match_resolved":
        _resolve_match(int(input.get("first", -1)), int(input.get("second", -1)))

func _handle_tap(idx: int) -> void:
    if not can_tap(idx):
        return
    _total_taps += 1
    _is_face_up[idx] = true
    record_event("card_flipped", float(idx))
    if _first_card_index == -1:
        _first_card_index = idx
        return
    # 2 枚目: ペア判定 → View に通知 (View は match_anim / mismatch_anim → タイマ → match_resolved / mismatch_resolved 通知)
    _is_processing = true
    var second := idx
    if _grid_data[_first_card_index] == _grid_data[second]:
        # 一致シグナル発火（実体は View が match_anim を制御し、完了時に match_resolved を返す）
        record_event("pair_match", float(_grid_data[second]))
        emit_signal("pair_evaluated", _first_card_index, second, true)
    else:
        record_event("pair_mismatch", float(_grid_data[second]))
        emit_signal("pair_evaluated", _first_card_index, second, false)

func _resolve_match(a: int, b: int) -> void:
    _is_matched[a] = true
    _is_matched[b] = true
    _pairs_found += 1
    _first_card_index = -1
    _is_processing = false
    if _pairs_found >= TOTAL_PAIRS:
        _is_clear = true
        record_event("clear", float(get_elapsed_ms()))
        finish()

func _resolve_mismatch(a: int, b: int) -> void:
    _is_face_up[a] = false
    _is_face_up[b] = false
    _first_card_index = -1
    _is_processing = false

func timeout() -> void:
    if not _is_active:
        return
    _is_clear = false
    record_event("timeout", float(_pairs_found))
    finish()

# 公開: View が _is_processing 中の timeout を保留判定する
func is_processing() -> bool:
    return _is_processing

signal pair_evaluated(first_idx: int, second_idx: int, is_match: bool)

# NOTE: BaseGame 契約上、_on_finish() ではゲーム固有フィールド (events / duration_ms / game_type)
# のみ完成させる。log.id / log.score / log.mode / log.played_at / log.played_date / log.is_new_best
# は GameManager.on_game_finished_handler() が一括で埋める設計（sequence_memory.gd と同パターン）。
func _on_finish() -> PlayLog:
    var log := super._on_finish()
    log.game_type = "card_match"
    return log

# Getter 略
```

## 5. CardGenerator 設計

spec §8-1 の Fisher-Yates 共通プール方式:

```gdscript
extends Object

func generate(tier: String, seed_value: int) -> Array[int]:
    # MVP: T1=16 枚 = 8 ペア
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var ids: Array[int] = []
    for i in range(8):
        ids.append(i); ids.append(i)
    for i in range(ids.size() - 1, 0, -1):
        var j: int = rng.randi() % (i + 1)
        var tmp := ids[i]; ids[i] = ids[j]; ids[j] = tmp
    return ids
```

## 6. Card 状態（components/card.gd）

```gdscript
class_name CardComponent
extends Control

enum State { FACE_DOWN, FACE_UP, MATCHED }

const CARD_DATA: Array[Dictionary] = [
    {"icon": "circle",        "color": Color(0.898, 0.224, 0.208)},
    {"icon": "square",        "color": Color(0.118, 0.533, 0.898)},
    {"icon": "change_history","color": Color(0.263, 0.627, 0.278)},
    {"icon": "diamond",       "color": Color(0.992, 0.847, 0.208)},
    {"icon": "star",          "color": Color(1.0,   0.420, 0.208)},
    {"icon": "hexagon",       "color": Color(0.482, 0.122, 0.635)},
    {"icon": "favorite",      "color": Color(0.925, 0.251, 0.478)},
    {"icon": "pentagon",      "color": Color(0.0,   0.737, 0.831)},
]

signal card_pressed(cell_index: int)

@export var cell_index: int = -1
var _state: int = State.FACE_DOWN
var _card_id: int = -1
```

カード裏面は `assets/branding/catboy_electric.png` を 0.18 アルファで TextureRect 配置 + 暗グラス背景 + シアン縁。

## 7. View 設計（card_match_view.gd）

`sequence_memory_view.gd` をテンプレに:

- `_on_pair_evaluated(first, second, is_match)` シグナルを受けて:
  - 一致: 0.3 秒の緑フラッシュ tween → `match_resolved` を game に通知 → matched 状態へ。
  - 不一致: 0.5 秒のグレーフラッシュ → 裏向きアニメ → `mismatch_resolved` を game に通知。
- `_process(delta)` で経過秒を毎フレーム更新し、`TIME_LIMIT - elapsed <= 0` で `timeout()`。
- HUD: `ProgressLabel.text = "タップ: %d  ペア: %d/8" % [taps, pairs]`。

### timeout 保留フラグ（spec §2-5 末尾「タップ最後まで処理」対応）

View 側で `_pending_timeout: bool = false` を保持し、60 秒到達時:

```gdscript
func _process(delta: float) -> void:
    if _game == null or not _game._is_active:
        return
    var elapsed_sec := float(_game.get_elapsed_ms()) / 1000.0
    if elapsed_sec >= 60.0 and not _pending_timeout:
        # _is_processing 中（不一致表示 0.5 秒中など）は保留
        if _game.is_processing():
            _pending_timeout = true
        else:
            _game.timeout()

func _on_match_anim_finished(...) -> void:
    # match_resolved を通知した直後にチェック
    _game.handle_input({"type": "match_resolved", "first": a, "second": b})
    _drain_pending_timeout()

func _on_mismatch_anim_finished(...) -> void:
    _game.handle_input({"type": "mismatch_resolved", "first": a, "second": b})
    _drain_pending_timeout()

func _drain_pending_timeout() -> void:
    if _pending_timeout and _game._is_active:
        _pending_timeout = false
        _game.timeout()
```

これにより spec §2-5 末尾「制限時間ちょうどのタップで逆転クリアの可能性を残す」が成立する。

## 8. ScoreSystem 改訂

```gdscript
"card_match":
    var pairs := int(play_data.get("pair_count", 0))
    var taps := int(play_data.get("total_tap_count", 0))
    var clear_sec := float(play_data.get("clear_time_sec", 60.0))
    var time_limit := float(play_data.get("time_limit_sec", 60.0))
    var tier_mult := float(play_data.get("tier_multiplier", 1.0))
    if taps <= 0:
        return 0
    var efficiency := float(pairs * 2) / float(taps)
    var efficiency_score := int(efficiency * 1000)
    var time_remaining := max(0.0, time_limit - clear_sec)
    var time_bonus := int((time_remaining / time_limit) * 500)
    return max(0, int(round((efficiency_score + time_bonus) * tier_mult)))
```

## 9. GameManager 統合

```gdscript
"card_match":
    var pairs := _extract_card_pairs(log)
    var taps := _extract_card_taps(log)
    var clear_sec := _extract_card_clear_time_sec(log)
    return {
        "pair_count": pairs,
        "total_tap_count": taps,
        "clear_time_sec": clear_sec,
        "time_limit_sec": 60.0,
        "tier_multiplier": 1.0,
    }

func _extract_card_pairs(log) -> int:
    var n := 0
    if log == null or log.events == null: return 0
    for e in log.events:
        if e != null and e.event_type == "pair_match":
            n += 1
    return n

func _extract_card_taps(log) -> int:
    var n := 0
    if log == null or log.events == null: return 0
    for e in log.events:
        if e != null and e.event_type == "card_flipped":
            n += 1
    return n

func _extract_card_clear_time_sec(log) -> float:
    if log == null or log.events == null: return 60.0
    for e in log.events:
        if e != null and (e.event_type == "clear" or e.event_type == "timeout"):
            return float(log.duration_ms) / 1000.0
    return float(log.duration_ms) / 1000.0
```

## 10. レイアウト指針

- カードのタップ領域: **72dp × 72dp**（spec §3-1 と一致）。
- カード本体（StyleBox 描画域）: **64dp × 64dp**、内側 padding 4dp（タップ領域は外側 4dp 拡張）。
- 間隔（GridContainer separation）: **8dp**（spec §3-1）。
- 縦画面 360dp 基準で `4×72 + 3×8 = 312dp` → 余裕あり。
- 上下に HUD / ベスト表示の安全領域確保。

## 13. GhostData 連携（MVP 対象外）

`individual_result_controller.gd` L112-120 で card_match は **`compare_mode = "self_best"`** が設定済み。
→ MVP は GhostData 連携を行わない。`DataStore.update_best_if_better(log)` がベスト記録を自動保存し、結果画面の比較カードは「YOU スコア vs BEST スコア」を表示する。

初回ゴーストスコア 800 pts（spec §6-3）は v1.1 で GhostData 汎用化と合わせて導入。

## 11. 受け入れテスト

| # | シナリオ | 期待結果 |
|---|---|---|
| 1 | game_list → 神経衰弱 → スタート | rule_explain → countdown → プレイ画面 |
| 2 | 8 ペア揃え | クリア音 + 結果画面遷移 |
| 3 | 60 秒到達 | タイムアウト処理（最後のペア判定まで処理）→ 結果画面 |
| 4 | 同一カード再タップ | 無視（タップカウント加算なし） |
| 5 | 不一致判定中タップ | 無視 |
| 6 | 結果画面でスコア / タップ効率 / 前回比表示 | OK |
| 7 | 同日のシード一致 | 配置同一 |
