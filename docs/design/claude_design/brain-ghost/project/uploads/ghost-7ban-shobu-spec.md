# ⚔️ ゴースト7番勝負 詳細設計書 v1.0

> **親ドキュメント**: `brain_training_gdd_v1.2.md` §4-4
> **最終更新**: 2026-04-22
> **ステータス**: Ready for Week 1 実装
> **実装者**: ねこぽ / ReigalLabs
> **対応能力軸**: 反射速度（レーダーチャート §10b）

> **変更履歴**:
> - v1.0 (2026-04-22): 初版。競合調査（Human Benchmark / arealme.com / 反射神経検定 / Piano Tiles 2 / 脳トレ覚醒 等 6 本）を経て、予告→迎撃型 7 ラウンド決闘制を設計。GDD §5b ゴースト対戦・§5e ゴースト生霊キャラクタと統合。

---

## 1. 概要

### 1-1. コンセプト

**「今日の自分 vs いつもの自分。7 ラウンドの決闘で反射速度を鍛える」**

従来の "ランダム位置タップ 20 回" を廃し、予告ライン迎撃型の 7 ラウンド決闘制へ。ゴースト対戦 (§5b) と生霊キャラクタ (§5e) の独自要素をミニゲーム単位に結晶化する。

### 1-2. 核のメカニクス

```
[予告]  →  [ターゲット移動]  →  [判定]  →  [ラウンド結果]
 1秒前後      0.5〜2秒            瞬間        0.3秒
```

1. 予告フェーズで「いつ／どこから／どっち方向」が提示される
2. ターゲットが画面端から中央の **GHOST LINE** に向かって移動
3. ラインを通過する瞬間にタップ（タップ時刻とライン通過時刻の差 = 反応時間）
4. ラウンドごとに自分とゴーストの反応時間を比較 → 勝敗判定

### 1-3. 差別化ポイント（競合類型との比較）

| 類型 | 代表例 | 本作との違い |
|---|---|---|
| A. 純粋反応（Human Benchmark 型） | 反射神経検定 | "待つだけ" の空白を **予告→迎撃** で埋めた |
| B. モグラたたき（旧案） | ふつうのもぐらたたき | ランダム位置の単調さを **予測可能性の導入** で解消 |
| C. Go/No-Go（脳トレ覚醒） | 脳トレ覚醒 | 判断要素（ストループと役割被り）を避け、**純粋反射 + 決闘演出** で差別化 |
| D. 落下タップ（Piano Tiles 2） | Piano Tiles 2 | リズム持久戦ではなく **1 発 1 発独立したイベント** で反射速度を測定 |

---

## 2. ゲームルール

### 2-1. 全体の流れ

```
┌─ ラウンド開始 ──────────────┐
│ 1. 予告表示（0.5〜1.5秒）   │
│    「第 N 戦」+ 方向矢印     │
│ 2. ターゲット出現・移動開始  │
│ 3. GHOST LINE 通過          │
│ 4. プレイヤーのタップ        │
│ 5. 判定 → ラウンド結果演出   │
└─────────────────────────────┘
  × 7 ラウンド
  ↓
最終結果表示（「5 勝 2 敗！」）
```

### 2-2. 判定ルール

判定は **タップ時刻と GHOST LINE 通過時刻の差 (Δt, ミリ秒, 絶対値)** で決まる。

| 判定 | Δt 範囲 | ラウンド結果 | 演出 |
|---|---|---|---|
| **PERFECT** | 0〜50ms | 勝利（自分の Δt が小さい場合） | ⭐ 金色フラッシュ |
| **GREAT** | 51〜150ms | 通常勝敗判定 | 白フラッシュ |
| **GOOD** | 151〜300ms | 通常勝敗判定 | 通常 |
| **LATE** | 301ms 以上 | 敗北側扱い | グレー |
| **FLYING** (予告前/ライン通過前) | — | ラウンド無効（敗北扱い） | 黄色警告 |
| **MISS** (タイムアウト) | ラインから +1000ms 経過 | 敗北 | グレー |

FLYING と MISS は **計測除外ではなくスコア反映対象**（中央 5 発選定時に自動的に除外候補になりやすい最速／最遅扱い）。

### 2-3. 勝敗判定

各ラウンドごとに、**プレイヤーの Δt** と **ゴーストの Δt（過去 5 回の該当ラウンド中央値）** を比較：

- `player_Δt < ghost_Δt` → **プレイヤー勝利**
- `player_Δt > ghost_Δt` → **ゴースト勝利**
- `|player_Δt − ghost_Δt| ≤ 10ms` → 引き分け（稀。スコア計算ではプレイヤー勝利扱い）

7 ラウンド終了後に通算勝敗を集計。例:「👤 5 勝 👻 2 勝」

---

## 3. 画面レイアウト

### 3-1. プレイ画面

```
┌──────────────────────────────────────┐
│ ⚔️ 第 3 戦 / 7        ⏱ 18秒       │  ← 上部HUD
│                                      │
│ 👤 2勝    👻 1勝                     │  ← 現在の勝敗
│                                      │
│                                      │
│                                      │
│ ─────────── GHOST LINE ───────────   │  ← 判定ライン（画面中央）
│                                      │
│      [🎯]━━━━→                       │  ← ターゲット移動中
│                                      │
│                                      │
│                                      │
│ ┌──────────────────────────────┐    │  ← タップ判定エリア
│ │                              │    │    （画面下半分全域）
│ │       [ タップで迎撃 ]         │    │
│ │                              │    │
│ └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

**判定エリアは画面下半分全域**。小さなボタンを狙わせない（脳トレ覚醒の「端タップでミス」レビュー不満の対策）。タップ位置の精度ではなく **タイミング** のみを評価する。

### 3-2. ラウンド結果ポップアップ（0.3 秒表示）

```
┌─────────────────┐
│   ⭐ PERFECT    │
│                 │
│ 👤 87ms         │  ← 自分の反応時間
│ 👻 142ms        │  ← ゴーストの反応時間
│                 │
│  プレイヤー勝利  │
└─────────────────┘
```

### 3-3. 最終結果画面

```
┌──────────────────────────────────────┐
│ ⚔️ ゴースト7番勝負 結果               │
│                                      │
│        👤 5 勝  vs  👻 2 勝          │
│            プレイヤー勝越             │
│                                      │
│  平均反応時間（中央5発）              │
│    今日:        142 ms ★BEST         │
│    いつもの自分: 168 ms               │
│                                      │
│  ┌─ ラウンド詳細 ────────┐            │
│  │ R1 👤98ms  👻150ms ○ │           │
│  │ R2 👤145ms 👻152ms ○ │           │
│  │ R3 👤210ms 👻148ms ×  │           │
│  │ R4 👤132ms 👻155ms ○ │           │
│  │ R5 👤175ms 👻160ms ×  │           │
│  │ R6 👤120ms 👻145ms ○ │           │
│  │ R7 👤108ms 👻140ms ○ │           │
│  └──────────────────────┘            │
│                                      │
│  [次のゲームへ]  [シェア]             │
└──────────────────────────────────────┘
```

---

## 4. ラウンドごとのパラメータ（ストーリー曲線）

7 ラウンドで「起承転結」を作る。単純加速ではなく、**緩急** をつけるのがポイント。

| ラウンド | フェーズ | 移動時間 | 予告遅延 | 難度 | 演出 |
|---|---|---|---|---|---|
| R1 | ウォームアップ | 2.0 秒（遅） | 1.5 秒（予測しやすい） | 易 | "構えていこう" |
| R2 | ウォームアップ | 1.8 秒 | 1.2 秒 | 易 | — |
| R3 | 本番突入 | 1.2 秒 | 1.0 秒 | 中 | "ここからが本気" |
| R4 | 本番 | 1.0 秒 | 0.8 秒 | 中 | — |
| R5 | 本番 | 0.8 秒 | 0.6 秒 | 難 | フェイク予告（方向を直前で変える） |
| R6 | フィナーレ前哨 | 0.7 秒 | 0.5 秒（ランダム幅大） | 難 | — |
| R7 | 最終決戦 | 0.5〜1.0 秒 ランダム | 0.5〜1.5 秒 ランダム | 最難 | "最終戦" + 特別演出 |

### 所要時間計算

```
予告(0.5-1.5) + 移動(0.5-2.0) + 判定(0) + 結果演出(0.3) = 1.3〜3.8 秒/ラウンド
中央値 = 約 2.5 秒 × 7 ラウンド = 17.5 秒
+ 開始演出 5 秒 + 最終結果 7 秒 = 約 30 秒
```

→ GDD 設計原則「1 ゲーム 30 秒」を遵守。

---

## 5. スコア算出

### 5-1. 反応時間スコア

中央 5 発の平均反応時間でスコアを計算。**7 ラウンドの Δt を昇順ソートし、最速 1 発・最遅 1 発を除外した 5 発の算術平均** を採用。

```gdscript
func calculate_reaction_score(deltas_ms: Array[int]) -> int:
    deltas_ms.sort()  # 昇順ソート
    var middle_5 = deltas_ms.slice(1, 6)  # index 1-5 (最速・最遅を除外)
    var avg_ms = middle_5.reduce(func(a, b): return a + b) / 5.0
    return int(1000.0 / avg_ms * 300)
```

**例**: Δt = [87, 98, 132, 145, 175, 210, 250] の場合
- 最速 87 と最遅 250 を除外
- 中央 5 発 [98, 132, 145, 175, 210] の平均 = 152ms
- スコア = 1000 / 152 × 300 ≈ **1973 pts**

### 5-2. ゴースト勝敗ボーナス

7 ラウンド中の勝利数に応じて加点：

```gdscript
func calculate_duel_bonus(wins: int) -> int:
    return wins * 50  # 7勝なら +350, 4勝なら +200
```

### 5-3. 総合スコア

```
総合スコア = 反応時間スコア + 勝敗ボーナス
         = (1000 / 平均ms) × 300 + 勝利数 × 50
```

GDD §6 スコア表との整合性: `(1000 / 平均ms) × 300 + ゴースト勝利数 × 50`

---

## 6. ゴースト対戦との接続（§5b）

### 6-1. 比較対象

GDD §5b で定義された「直近 5 回のプレイ平均」をゴースト7番勝負では **ラウンドごとの中央値** として保持する。

```python
# 保存データ構造
ghost_data = {
    "game": "ghost_7ban_shobu",
    "last_5_plays": [
        {
            "date": "2026-04-21",
            "round_deltas_ms": [120, 145, 180, 155, 190, 165, 200],  # 7ラウンド分
            "middle_5_avg_ms": 167,
            "wins": 4
        },
        # ... 直近 5 回分
    ]
}

# 各ラウンドのゴースト Δt を算出（ラウンドインデックスごとの直近 5 回中央値）
def get_ghost_delta_for_round(round_index: int) -> int:
    deltas = [play["round_deltas_ms"][round_index] for play in ghost_data["last_5_plays"]]
    deltas.sort()
    return deltas[2]  # 中央値（5 個の中央）
```

### 6-2. 初回プレイ時のゴースト

初回はゴーストデータが存在しない。以下のいずれかで対処：

| 案 | 内容 | 採用 |
|---|---|---|
| ゴースト非表示 | 初回はゴースト戦なし、反応時間のみ表示 | ❌（物語性が弱い） |
| 固定初期値 | 平均的な成人反応時間 273ms（Human Benchmark 中央値）を各ラウンドに設定 | ✅ |
| 難度連動 | 各ラウンドの移動時間 × 0.15 を初期ゴースト値に | △（v1.1 検討） |

**採用**: 初回は **273ms を全ラウンド共通のゴースト Δt** として使用。プレイヤーが平均的な成人より速ければ初回から勝てる。2 回目以降は自分の直近プレイがゴーストになる。

---

## 7. ゴースト生霊キャラクタとの接続（§5e）

### 7-1. モード切替

`GhostCharacter.set_mode()` API を呼び、3 段階で切り替える：

```gdscript
# ゲーム開始前（ルール説明〜カウントダウン）
ghost_character.set_mode("duelist")
ghost_character.set_dialogue("今日は本気でいくよ。7 番勝負、受けて立つ")

# プレイ中（各ラウンド後）
# 勝利時
ghost_character.set_dialogue("やられた〜！")
# 敗北時
ghost_character.set_dialogue("これは取らせてもらう")

# 決着後（結果画面）
ghost_character.set_mode("companion")
# 勝越
ghost_character.set_dialogue("今日のきみ、鋭いね。完敗")
# 負越
ghost_character.set_dialogue("惜しかった！また明日やろう")
# 同点
ghost_character.set_dialogue("互角だったね。いい勝負")
```

### 7-2. 表示位置（MVP）

プレイ中はゴースト生霊をプレイ画面左上に **小さく半透明** で配置（accuracy に応じた不透明度は据え置き）。判定エリアを邪魔しない位置。

### 7-3. v1.1 での拡張

- 決闘相手モード時の表情切替（serious / determined）
- 勝敗ごとのモーション（負け = 倒れる、勝ち = ガッツポーズ）
- オーラ（ストリーク連動）の決闘モード強化

---

## 8. パラメトリック生成（デイリーシード対応）

GDD §5c のデイリーシード方式に準拠。全ユーザー共通の 7 ラウンドパターンを生成する。

```gdscript
func generate_daily_rounds(seed: int) -> Array:
    var rng = RandomNumberGenerator.new()
    rng.seed = seed

    var rounds = []
    var base_speeds = [2.0, 1.8, 1.2, 1.0, 0.8, 0.7, 0.75]  # R1-R7 基本速度
    var base_delays = [1.5, 1.2, 1.0, 0.8, 0.6, 0.5, 1.0]

    for i in range(7):
        var direction = ["left", "right", "top", "bottom"][rng.randi() % 4]
        var speed_jitter = rng.randf_range(-0.1, 0.1)
        var delay_jitter = rng.randf_range(-0.2, 0.2)

        rounds.append({
            "index": i,
            "direction": direction,
            "move_duration": base_speeds[i] + speed_jitter,
            "pre_delay": base_delays[i] + delay_jitter,
            "is_feint": (i == 4)  # R5 のみフェイク予告
        })

    return rounds
```

### デイリー共通化の効果

- 全ユーザーが同じ 7 ラウンドの決闘を体験 → Wordle 方式で勝率比較が公平
- X シェア URL から入ると同じパターンが再生 → 「俺も同じ決闘やったけど 3 勝しかできなかった」が成立

---

## 9. フライング・ミス処理

### 9-1. フライング（予告前 or ライン通過前のタップ）

```gdscript
func on_tap():
    if game_phase == "pre_announce":
        # 予告フェーズ前のタップ: 無視（誤タップ対策）
        return

    if game_phase == "announce":
        # 予告中のタップ: フライング判定
        record_round(delta_ms = 999, is_flying = true)
        advance_to_next_round()
        return

    if game_phase == "moving":
        var time_to_line = calculate_time_to_line()
        if time_to_line > 0:
            # ラインに到達する前のタップ: フライング判定
            record_round(delta_ms = 999, is_flying = true)
        else:
            # 正常判定
            record_round(delta_ms = abs(time_to_line), is_flying = false)
        advance_to_next_round()
```

### 9-2. タイムアウト（一切タップしない）

ターゲットが GHOST LINE を通過してから **1000ms** 経過してもタップがない場合、MISS として次ラウンドへ。

```gdscript
func on_line_passed():
    miss_timer.start(1.0)  # 1秒カウントダウン

func _on_miss_timer_timeout():
    record_round(delta_ms = 1000, is_miss = true)
    advance_to_next_round()
```

### 9-3. スコア影響

FLYING/MISS は Δt = 999〜1000ms として記録。中央 5 発選定時に **最遅側として自動的に除外される** 可能性が高い。ただし複数回フライングすると中央 5 発に入ってしまう → 結果的にスコアが下がる。

この設計により「フライングしても即ゲームオーバーにならない」一方、「毎回フライングしたらスコア大幅減」という自然な抑制が効く。

---

## 10. 実装アーキテクチャ（Godot 4 / GDScript）

### 10-1. シーン構成

```
ghost_7ban_shobu.tscn (Node2D)
├── GameLogic (Node)
│   └── script: ghost_7ban_shobu.gd
├── UI (CanvasLayer)
│   ├── RoundIndicator (Label)
│   ├── ScoreDisplay (VBoxContainer)
│   │   ├── PlayerWins (Label)
│   │   └── GhostWins (Label)
│   ├── Timer (Label)
│   └── TapArea (Control)
│       └── _input: on_tap()
├── Playfield (Node2D)
│   ├── GhostLine (Line2D) -- 画面中央横断ライン
│   ├── TargetSpawner (Node2D)
│   │   └── target.tscn (動的生成)
│   └── DirectionArrow (Sprite2D) -- 予告中のみ表示
├── GhostCharacter (ghost_character.tscn インスタンス)
└── ResultPopup (ghost_round_result.tscn)
```

### 10-2. 主要スクリプト: ghost_7ban_shobu.gd

```gdscript
extends Node
class_name Ghost7BanShobu

# 定数
const TOTAL_ROUNDS = 7
const TIMEOUT_AFTER_LINE_MS = 1000
const PERFECT_THRESHOLD_MS = 50

# 状態
var current_round: int = 0
var game_phase: String = "waiting"  # waiting, pre_announce, announce, moving, judged, finished
var player_deltas: Array = []
var ghost_deltas: Array = []  # 事前にロード
var player_wins: int = 0
var line_pass_time_ms: int = 0
var rounds_config: Array = []  # デイリーシードから生成

# 参照
@onready var ghost_character = $GhostCharacter
@onready var target_spawner = $Playfield/TargetSpawner
@onready var ghost_line = $Playfield/GhostLine

func _ready():
    rounds_config = generate_daily_rounds(DailySeed.get_today_seed())
    ghost_deltas = GhostData.load_round_medians("ghost_7ban_shobu")
    ghost_character.set_mode("duelist")
    ghost_character.set_dialogue("今日は本気でいくよ。7 番勝負、受けて立つ")
    start_round(0)

func start_round(index: int):
    current_round = index
    game_phase = "pre_announce"
    var config = rounds_config[index]
    show_announcement(config.direction, config.pre_delay)
    await get_tree().create_timer(config.pre_delay).timeout
    spawn_and_move_target(config.direction, config.move_duration)

func spawn_and_move_target(direction: String, move_duration: float):
    game_phase = "moving"
    var target = target_spawner.spawn(direction)
    var start_time_ms = Time.get_ticks_msec()

    # ラインに到達する予定時刻を計算
    var line_pass_time_offset = move_duration * 1000 / 2  # 中央到達
    line_pass_time_ms = start_time_ms + line_pass_time_offset

    # Tween で移動
    var tween = create_tween()
    tween.tween_property(target, "position", ghost_line.position, move_duration)
    tween.tween_callback(on_target_reach_end.bind(target))

func on_tap():
    if game_phase != "moving":
        return
    var tap_time_ms = Time.get_ticks_msec()
    var delta_ms = tap_time_ms - line_pass_time_ms  # 符号付き（マイナス = 早すぎ）

    if delta_ms < 0:
        # ライン通過前タップ = フライング
        record_round(delta_ms = 999, is_flying = true)
    else:
        record_round(delta_ms = delta_ms, is_flying = false)

    advance_to_next_round()

func record_round(delta_ms: int, is_flying: bool):
    game_phase = "judged"
    player_deltas.append(delta_ms)

    # ゴーストとの勝敗判定
    var ghost_delta = ghost_deltas[current_round] if ghost_deltas.size() > current_round else 273
    var player_win = delta_ms < ghost_delta

    if player_win:
        player_wins += 1
        ghost_character.set_dialogue("やられた〜！")
    else:
        ghost_character.set_dialogue("これは取らせてもらう")

    # ラウンド結果ポップアップ表示
    show_round_result(delta_ms, ghost_delta, player_win)

func advance_to_next_round():
    await get_tree().create_timer(0.3).timeout
    if current_round + 1 < TOTAL_ROUNDS:
        start_round(current_round + 1)
    else:
        finish_game()

func finish_game():
    game_phase = "finished"
    var score = calculate_total_score()
    GhostData.save_play("ghost_7ban_shobu", player_deltas, player_wins)

    ghost_character.set_mode("companion")
    if player_wins >= 4:
        ghost_character.set_dialogue("今日のきみ、鋭いね。完敗")
    elif player_wins == TOTAL_ROUNDS / 2:
        ghost_character.set_dialogue("互角だったね。いい勝負")
    else:
        ghost_character.set_dialogue("惜しかった！また明日やろう")

    emit_signal("game_finished", score, player_wins)

func calculate_total_score() -> int:
    var sorted = player_deltas.duplicate()
    sorted.sort()
    var middle_5 = sorted.slice(1, 6)
    var avg_ms = middle_5.reduce(func(a, b): return a + b) / 5.0
    var reaction_score = int(1000.0 / avg_ms * 300)
    var duel_bonus = player_wins * 50
    return reaction_score + duel_bonus
```

### 10-3. 計測精度（ms）の注意点

- **`Time.get_ticks_msec()` はフレーム非依存** なのでこれを使う
- `_process(delta)` の delta からは計算しない（フレームレート揺れの影響）
- Web版（HTML5）ではブラウザの performance.now() がバックエンドで使われるため、同等の精度
- モニタのリフレッシュレート（60Hz = 16.67ms 単位）の影響は受けるが、中央 5 発平均でノイズが平準化される

---

## 11. MVP と v1.1 以降の境界

### v1.0 MVP（Week 1 実装）

| 項目 | 実装範囲 |
|---|---|
| コアゲーム | 7 ラウンド決闘、左右 2 方向のみ、速度カーブは固定 |
| 予告演出 | テキストと矢印のみ |
| 判定 | PERFECT / GREAT / GOOD / LATE / FLYING / MISS の 6 段階 |
| ゴースト | 初回 273ms 固定、2 回目以降は直近 5 回の中央値 |
| 生霊キャラクタ接続 | `set_mode("duelist"/"companion")` + `set_dialogue` のみ |
| デイリーシード | ✅ 対応 |
| スコア | 中央 5 発平均 + 勝敗ボーナス |
| 効果音 | 予告音・タップ音・PERFECT 音・結果音の 4 種 |

### v1.1 拡張

| 項目 | 拡張内容 |
|---|---|
| 方向 | 上下も追加（4 方向） |
| フェイク予告 | R5 で方向を直前に切り替え |
| 移動軌道 | 曲線軌道を導入（難度調整） |
| ゴースト表情 | 決闘中の真剣顔、負けた時の悔しがり等 |
| 特別演出 | R7 最終戦の召喚サークル風カウントダウン |
| ラウンド詳細表示 | 結果画面の 7 ラウンド詳細をアニメーション付きで |

### v1.2 以降（検討中）

- **一発勝負モード**: 1 ラウンドのみの超緊張版（X バズ用）
- **チャンピオンズラウンド**: 15 ラウンド（約 60 秒）、本気タイム狙いのガチ勢向け
- **マルチゴースト**: 過去 7 日間のゴーストを同時表示（週次決闘）

---

## 12. 計測の妥当性

### 12-1. なぜ中央 5 発平均か

| 方式 | 妥当性 | 備考 |
|---|---|---|
| 1 発のみ | 低 | 運・偶然の影響大 |
| 3 発平均 | 中 | 外れ値 1 つで崩れる |
| **中央 5 発平均（本採用）** | **高** | **外れ値（フライング・瞬き）を除外しつつ、標本数が統計的に有効** |
| 7 発全平均 | 中 | フライング 1 回で平均が大きく崩れる |
| 20 発平均（旧案） | 高 | 集中力の疲労で後半の精度が落ち、逆にノイズ増加 |

### 12-2. 既存ツールとの比較

| ツール | 試行回数 | 外れ値処理 | 本作との関係 |
|---|---|---|---|
| Human Benchmark | 5 trials 平均 | なし | 単純平均、試行数は同じ 5 |
| arealme.com（公式記録） | 5 attempts（標準モード）、10 or 100 attempts（記録モード） | 10 attempts モードでは「最遅 5 を除外して最速 5 の平均」等の工夫あり | 本作の中央 5 発採用と近い発想 |
| 反射神経検定 | 一発勝負 / ランダム出現 / 3 連続の 3 モード | — | モード設計の参考 |
| 学術研究（スポーツ選手） | 5 回 × 2 試行、最良試行の平均 | ベスト試行のみ採用 | 本作は外れ値除外で同等の安定性 |

→ **本作の「7 ラウンド中央 5 発平均」は業界標準（5 試行）と整合しつつ、外れ値耐性で一段上。**

### 12-3. 脳年齢への変換

GDD §6 の脳年齢アルゴリズムに入力される反射速度スコアは **中央 5 発平均 Δt そのもの**。

- 200ms 未満 = 若年（20 代相当）
- 200-300ms = 標準（30〜40 代）
- 300ms 以上 = シニア（50 代以上）

※ 実際の変換係数は MVP 実装後のテストプレイデータで調整。

---

## 13. UX 細部

### 13-1. 初回オンボーディング

```
画面 1: "ゴースト7番勝負"
       → "過去の自分と 7 ラウンドの決闘をしよう"
画面 2: [ターゲット移動のアニメ]
       → "ターゲットがラインに来た瞬間にタップ"
画面 3: [練習ラウンド 1 回]
       → "練習成功！ 本番は 7 ラウンドだよ"
画面 4: [カウントダウン] → "3...2...1... スタート！"
```

### 13-2. 2 回目以降

- [スキップ] ボタンで即スタート（GDD §5 の説明画面仕様に準拠）
- カウントダウンのみ表示して開始

### 13-3. 音響設計

| 音 | タイミング | 長さ | 備考 |
|---|---|---|---|
| 予告音 | 予告フェーズ開始 | 0.2 秒 | ピッ |
| 移動音 | ターゲット移動中 | 継続 | フォォォ |
| タップ音 | プレイヤータップ | 0.1 秒 | パキッ |
| PERFECT 音 | PERFECT 判定 | 0.3 秒 | キーン |
| 勝利音 | ラウンド勝利 | 0.3 秒 | タン |
| 敗北音 | ラウンド敗北 | 0.3 秒 | ボ |
| 最終結果音 | 全 7 ラウンド終了 | 1.0 秒 | 勝越時: ファンファーレ / 負越時: しんみり |

BGM は静かめ（集中を妨げない）。GDD §9 アクセシビリティに従い個別オンオフ可能。

### 13-4. アクセシビリティ

- 色覚配慮: 勝敗表示を色だけでなく **○/× アイコン** で併記
- フォント: 反応時間の ms 表示は 24sp 以上
- 効果音のみでもプレイ可能（視覚情報が全て）
- 振動フィードバック（Android 版、設定でオン/オフ）

---

## 付録 A. 開発タスクリスト（Week 1 分）

| No | タスク | 工数目安 | 依存 |
|---|---|---|---|
| 1 | `ghost_7ban_shobu.tscn` 基本シーン作成 | 1h | — |
| 2 | `GhostLine` 描画 + `TargetSpawner` 実装 | 2h | 1 |
| 3 | Tween でターゲット移動 | 1h | 2 |
| 4 | `on_tap()` + Δt 計算ロジック | 2h | 3 |
| 5 | 7 ラウンドループ制御 | 2h | 4 |
| 6 | ラウンド結果ポップアップ | 1h | 5 |
| 7 | デイリーシード対応 (`generate_daily_rounds`) | 1h | 5 |
| 8 | ゴーストデータ読み書き (`GhostData` 連携) | 2h | 5 |
| 9 | スコア算出 (`calculate_total_score`) | 1h | 5 |
| 10 | `GhostCharacter` 連携（duelist/companion 切替） | 1h | §5e 実装済み前提 |
| 11 | 効果音実装 | 1h | 5 |
| 12 | 初回オンボーディング + カウントダウン | 2h | 10 |
| 13 | 最終結果画面 | 2h | 9 |
| 14 | Web/Android 両方で動作確認 | 2h | 13 |
| **合計** | | **約 21h** | = 約 3 日（90分/日 × 15 セッション） |

→ Week 1 の 90min/日 枠内で完了可能。残り 4 日は Godot 環境構築・フラッシュ暗算・ルール説明テンプレートに充当。

---

## 付録 B. 競合から取り込んだ設計判断サマリー

| 要素 | パクリ元 | 採用箇所 |
|---|---|---|
| 5 試行の平均で計測 | Human Benchmark | §5 中央 5 発平均 |
| 記録挑戦モードの存在 | arealme.com 10/100 attempts | v1.2 チャンピオンズラウンド案 |
| 複数モード展開 | 反射神経検定（一発/ランダム/3連続） | v1.2 一発勝負モード案 |
| 予告可能性 + リズム | Piano Tiles 2 | §2 予告→迎撃の全体構造 |
| PERFECT/GREAT/GOOD の判定段階 | 音ゲー全般 | §2-2 判定ルール |
| 減点型の多種ターゲット | 脳トレ覚醒 | **採用せず**（ストループと役割被りのため） |
| 端タップでミス判定の回避 | 脳トレ覚醒レビュー不満 | §3-1 判定エリアを画面下半分全域に |
| 後出しじゃんけんのスコア伸びにくさ | みんなの脳トレレビュー不満 | §1 純粋反応速度計測に回帰 |

---

## 付録 C. 次の設計議論候補

本ドキュメントで決めきれなかった、または議論の余地がある項目：

1. **R5 のフェイク予告の是非**: フェイクは難度を上げるが、計測妥当性を損なう可能性。v1.1 で A/B テスト候補
2. **タップ位置の活用**: 現在は位置を使わない。将来的に「画面右半分でタップしないと無効」等の応用あり得る（脳トレ覚醒のコピーになるため慎重に）
3. **振動フィードバックのデフォルト**: オンにするとバッテリー消費。どちらがデフォルトか要テスト
4. **ゴースト初期値 273ms の妥当性**: Human Benchmark 中央値だが、アプリの初回ユーザー層に合うかは要検証
5. **R7 最終戦の演出強度**: 召喚サークル的な演出はリソースコスト大。v1.0 MVP はシンプルな光エフェクトに留める

---

## 参照

- 親 GDD: `brain_training_gdd_v1.2.md` §4-4, §5b, §5e, §6, §10
- ゴースト生霊キャラクタ機能設計: `docs/functional-design.md` A-10
- UI パターン: `docs/design/patterns.md` §5
- デイリーシード実装: `brain_training_gdd_v1.2.md` §5c
- 開発スケジュール: `brain_training_gdd_v1.2.md` §10 Week 1
