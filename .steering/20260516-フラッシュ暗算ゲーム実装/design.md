# 設計

## 全体アーキテクチャ

```
[game_list]  →  [flash_calc_home]  →  [rule_explain_landscape]  →  [countdown_landscape]  →  [flash_calc_play]  →  [individual_result]
                ↑ティア選択 (新規)    ↑既存                      ↑既存                       ↑試合 (新規)         ↑既存
                └──────────────────────────────────────────────────────────────────────────────┘
                                              リプレイ
```

`flash_calc_home` は新規シーン（ティア選択画面）。GameManager に **tier_select** フェーズを追加して既存 4 段階フローに挿入する。

## 画面構成（縦横の決定）

| 画面 | 向き | 理由 |
|---|---|---|
| flash_calc_home | **横画面** | 8 ティアをグリッド表示するため横幅を活用 |
| rule_explain_landscape | 横 | 既存共通 |
| countdown_landscape | 横 | 既存共通 |
| flash_calc_play | **横画面** | 大きな数字フラッシュ + テンキー両立のため。仕様書 §3-3 に準拠 |
| individual_result | 縦 | 既存共通（リザルト画面は portrait） |

→ flash_calc 系全画面で OrientationHelper.enter_landscape()、result で enter_portrait() に戻す。

## ファイル構成

### 新規追加

```
scenes/games/flash_calc/
├── flash_calc_home.tscn       # ティア選択画面（折りたたみ式）
├── flash_calc_play.tscn       # 試合画面
├── tier_item.tscn              # ティア 1 件分のコンポーネント（再利用）
└── ghost_label_switch.tscn    # 「練習仲間→いつもの自分」演出オーバーレイ

scripts/games/flash_calc/
├── flash_calc.gd               # メインゲームロジック (BaseGame 継承、置換)
├── flash_calc_home.gd          # ティア選択 controller
├── flash_calc_play_view.gd     # 試合画面 view
├── tier_item.gd                # ティア item controller
├── tier_config.gd              # TIER_CONFIGS 静的定数
└── problem_generator.gd        # 数字列 + 答え生成（4 桁防止）

scripts/utils/
└── flash_calc_dialogues.gd     # 台詞リソース（DialogueManager 簡易版）

assets/games/flash_calc/
└── (必要なら効果音、紙吹雪等)
```

### 既存変更

```
scripts/games/flash_calc.gd            # 旧 → 廃棄、scripts/games/flash_calc/flash_calc.gd に置換
scenes/games/flash_calc.tscn           # 旧 → 廃棄、新規シーン群に分割
scripts/autoload/game_manager.gd       # tier_select フェーズ追加、_current_tier 追加、flash_calc 用 ScoreSystem hook 修正、session_end 契約撤去
scripts/autoload/data_store.gd         # 変更不要（FlashCalcGhostStore が独自保存）
project.godot                          # FlashCalcGhostStore Autoload 登録
```

### 新規 Autoload

```
scripts/autoload/flash_calc_ghost_store.gd   # tier-keyed ゴーストデータ専用ストア (※)
```

(※) 既存 `ghost_data.gd` は `round_deltas.size() == 7` 固定で flash_calc 非互換のため、別 Autoload で並走させる。将来的に共通 GhostStore に統合できるよう、API シグネチャは互換性を意識する。

## データモデル

### FlashCalcGhostStore (新規 Autoload)

`ghost_data.gd` は 7 ラウンド前提なので、本ゲーム用に **独立した Autoload** として用意:

```gdscript
# scripts/autoload/flash_calc_ghost_store.gd
class_name FlashCalcGhostStoreCls
extends Node

const TIER_INITIAL_DELTAS = {
    "T1": 12000, "T2": 11000, "T3": 9000, "T4": 7000,
    "T5": 5500, "T6": 4500, "T7": 3500, "T8": 2500,
}
const RECENT_PLAY_WINDOW = 5

## スキーマ:
## {
##   "schemaVersion": 1,
##   "tiers": {
##     "T1": {
##       "plays": [{"date": "2026-05-16", "response_ms": 4200, "won": true, "score": 1450}, ...] # 最大 5 件
##       "best_score": 1500,
##       "unlocked": true
##     },
##     "T2": {...},
##   }
## }

func save_play(tier: String, response_ms: int, won: bool, score: int) -> bool
func get_delta_for_tier(tier: String) -> int      # 中央値 or TIER_INITIAL_DELTAS[tier]
func get_play_count(tier: String) -> int
func get_recent_wins(tier: String) -> int          # 直近 5 回中の勝利数
func is_unlocked(tier: String) -> bool
func unlock(tier: String) -> void                  # 直近 5 回中 3 回以上勝利時にこれを呼ぶ
func get_best_score(tier: String) -> int
func get_appropriate_tier() -> String              # ホーム画面の「適正ティア」用
```

DataStore.save / load_dict を利用して内部的に永続化（既存と同じパターン）。

### GameBest

既存 `game_best.gd` は変更しない。flash_calc は別ストア (FlashCalcGhostStore) に統一する。
ただし `individual_result_controller._load_self_best` は GameBest.best_score を読むので、ベスト更新時に GameBest にも tier 横断のベストを書き込む（簡易互換）。

### PlayLog event

PlayLog 自体は変更しない（`event_type: String, value: float` のみ）。flash_calc は以下 4 イベントを emit:

| event_type | value | 意味 |
|---|---|---|
| `tier` | int 1..8 (T1=1, T8=8) | プレイしたティア（最初に 1 回） |
| `flash_completed` | duration_ms | 数字フラッシュの実時間 |
| `answer_submitted` | response_time_ms | フラッシュ最終枚から入力確定までの時間 |
| `match_result` | 1=win, 0=lose | 勝敗フラグ |

個別結果画面で tier を表示したい場合は `_compute_subtitle` で event_type="tier" を探す。

## GameManager 改修

### 新規定数

```gdscript
const TIER_SELECT_SCENES: Dictionary = {
    "flash_calc": "res://scenes/games/flash_calc/flash_calc_home.tscn",
}

# LANDSCAPE_GAMES に flash_calc を追加
const LANDSCAPE_GAMES: Array = ["ghost_7ban_shobu", "flash_calc"]

# GAME_SCENES の flash_calc を play 専用シーンに切替
const GAME_SCENES: Dictionary = {
    ...
    "flash_calc": "res://scenes/games/flash_calc/flash_calc_play.tscn",
    ...
}
```

### 新規状態

```gdscript
var _current_tier: String = ""   # flash_calc 等ティア対応ゲーム用
```

### 新規フロー

```gdscript
func start_game(game_type: String) -> void:
    _current_game_type = game_type
    _current_tier = ""
    _previous_score = DataStore.load_best(game_type).best_score

    if game_type in TIER_SELECT_SCENES:
        _safe_change_scene(TIER_SELECT_SCENES[game_type])
    else:
        _safe_change_scene(RULE_EXPLAIN_SCENES[_orientation_key(game_type)])


func on_tier_selected(tier: String) -> void:
    _current_tier = tier
    _safe_change_scene(RULE_EXPLAIN_SCENES[_orientation_key(_current_game_type)])
```

### 既存 hook の整理

- `_build_play_data_for(log)` の `"flash_calc":` ブロック: v1.3 では score は flash_calc.gd 内で算出済みなので、`{"precomputed_score": log.score}` を返すか、ScoreSystem 側で no-op 化
- `_extract_remaining_sec` (`session_end` event): 旧契約のため v1.3 では未使用、`session_end` 受信時は無視する

## ゲーム状態マシン

```
[idle]
  └ start_game(tier)
[pre_announce]  -- 1.5s --
  └→ [flashing]  -- 段階的カーブ --
       └ 最終枚表示と同時に
       [input + ghost_cd]  -- 最大 t_max 秒 --
          ├ 入力確定 → [judging]
          └ CD ゼロ → [time_lose]
       [judging]
          ├ 正解+早い → [win]
          ├ 同タイ → [draw]
          ├ 不正解 → [wrong]
          └ 遅い → [time_lose]
       [result_animation]  -- 8s --
          └→ [tier_unlock?]  ← 条件達成時のみ
                └→ [individual_result]
                  → home_again or replay
```

実装は `flash_calc.gd` 内に enum + 1 つの switch 文。または State パターン（過剰なら不要）。

## 数字フラッシュ実装

### 速度カーブ（仕様 §4-2）

| フェーズ | T1-T3 | T4-T5 | T6-T7 | T8 |
|---|---|---|---|---|
| ウォームアップ (最初30%) | 0.6s | 0.5s | 0.6s | 0.4s |
| 本番 (中盤40%) | 0.4s | 0.35s | 0.4s | 0.3s |
| 追い込み (最後30%) | 0.30s | 0.25s | 0.27s | 0.20s |

実装: 数字配列を生成後、各 index の表示 interval を配列に展開。Timer/await ループで Label.text を更新。

### 桁数モード

- `1digit`: 1〜9 のみ
- `2digit`: 10〜99
- `mixed`: 67% 1digit + 33% 2digit、出現順序はランダム

### 4 桁防止

問題生成時に累積和を計算し、最大値 / 最小値が ±999 を超えそうな場合は要素を再生成。

```gdscript
func generate_problem(seed_value: int, tier: String) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    while true:
        var numbers := _gen_numbers(rng, tier)
        var sum := numbers.reduce(func(a, b): return a + b, 0)
        if sum >= 0 and sum <= 999:
            return {"numbers": numbers, "answer": sum, ...}
```

## ゴースト CD バー

既存 `ghost_battle_bar.tscn` は 7 番勝負用なので、本作には **新規 ghost_cd_bar.tscn** を作る（ProgressBar ベース）:

- Tween で減少アニメーション（max_value=ghost_delta_ms, value 0 まで）
- 色グラデーション: cyan → orange → red（赤禁止 → orange/gray dim に置換、UX §3.1）
  - 採用色: cyan (満) → orange dim (中盤) → gray dim (終盤)
- ゼロで `ghost_zero` signal emit

## テンキー UI

仕様 §13-5 準拠の電卓配置:

```
[7] [8] [9]
[4] [5] [6]
[1] [2] [3]
[⌫] [0] [✓]
```

- 各ボタン 64x64 以上、文字 36 以上
- ⌫ = backspace (削除)
- ✓ = 確定 (Submit)
- 答えが最大桁に達したら自動確定（ティアごとに 2/3 桁を切替）

実装: GridContainer + 12 個の Button、`button_pressed(digit/back/submit)` signal。

## 解放演出 / 切替演出

両方とも全画面オーバーレイ（CanvasLayer）。簡易版で OK:

- TierUnlockAnnouncement: 「T(N) 解放！」テキスト + 5s で自動遷移
- GhostLabelSwitchAnnouncement: 「いつもの自分が来た」テキスト + 4s

## ホーム画面（ティア選択）

仕様 §3-1（折りたたみ式）:

```
┌─────────────────────────┐
│ 🥋 フラッシュ暗算 一本勝負│
│                         │
│ 適正ティア: T3          │
│                         │
│ ┌─T2: 勝率 80% (4/5)── │   ← 適正 ±1 のみデフォルト表示
│ ├─T3: 勝率 60% (★)─── │   ← 適正
│ └─T4: 勝率 0%─────────│
│ [▼ 全ティア表示]         │   ← トグルボタン
│                         │
│ [▶ プレイ]               │
└─────────────────────────┘
```

`tier_item.tscn` は 1 ティア分の表示パーツ（左:状態 / 中:ティア名 / 右:ベストスコア）。

## スコア算出

仕様 §6（推定）:
```
base_score = max(0, (ghost_delta_ms - response_time_ms))  # 早ければ +
victory_bonus = 500 if win else 0
score = round((base_score + victory_bonus) * tier_score_mult)
```

不正解時は score=0、TIME_LOSE 時も score=0（後段で要確認）。

## 個別結果画面との統合

`individual_result_controller.gd` の `_get_display_config` に既に `flash_calc` エントリ存在（`compare_mode="self_best"`）。実装後にティア情報も表示したい場合はサブタイトルに「T3」を追記する拡張を検討。MVP では既存のまま流用。

## ロールバック方針

旧 `flash_calc.gd` + `flash_calc.tscn` は削除前に `archive/flash_calc_v1/` にバックアップ（git で復元可能なので不要かも）。

## リスクと対策

| リスク | 対策 |
|---|---|
| 仕様書の規模（1255行）に対し実装が膨らむ | MVP に絞る。タスクリストでフェーズ管理 |
| ティア解放ロジックのバグ | last_5_plays の長さチェックを 1 箇所に集約 |
| 横画面切替で他画面に影響 | individual_result 入る前に enter_portrait() 呼び出し |
| テンキーが小さくて押しづらい | ボタン最低 64x64、12 個の grid 配置で十分な領域確保 |
| Tween / Timer の競合 | 状態マシン enum で排他制御 |
