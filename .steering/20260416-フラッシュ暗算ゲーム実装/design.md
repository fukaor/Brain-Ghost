# 設計書

## アーキテクチャ概要

反射タップと同じ3層構成を踏襲:
- `scripts/games/flash_calc.gd` — ロジック（BaseGame継承、問題生成・正誤判定・スコア計算）
- `scripts/ui/flash_calc_view.gd` — ビュー（テンキー操作・タイマー表示・問題表示）
- `scenes/games/flash_calc.tscn` — シーン（Stitch準拠レイアウト）

```
FlashCalcView (flash_calc.tscn)
  ├── FlashCalc (ロジック、Node として add_child)
  ├── 計算表示 (Label: "23 - 12")
  ├── 回答表示 (Label: "???")
  ├── タイマー (Label: 残り秒 + CircularProgress的な表示)
  ├── GhostBattleBar (共有シーン)
  └── Keypad (3x4 GridContainer)
```

## コンポーネント設計

### 1. FlashCalc (flash_calc.gd)

**定数**:
- TIME_LIMIT_SEC = 30
- NUM_MIN_INITIAL = 1, NUM_MAX_INITIAL = 50（＋の場合）
- SUBTRACTION_CHANCE = 0.3（30%の確率で引き算）

**状態**:
- _correct_count: int
- _wrong_count: int
- _current_num1: int
- _current_num2: int
- _current_operator: String ("+" or "-")
- _current_answer: int

**Public API**:
```gdscript
func generate_next_problem() -> Dictionary  # {num1, num2, operator, answer}
func check_answer(user_answer: int) -> bool  # 正誤判定 + イベント記録
func get_correct_count() -> int
func get_wrong_count() -> int
func get_remaining_sec() -> int
```

**問題生成ルール（決定論、rng使用）**:
- num1 = rng.randi_range(1, 50)
- 引き算判定: rng.randf() < SUBTRACTION_CHANCE
- 加算: num2 = rng.randi_range(1, 50), answer = num1 + num2
- 減算: num2 = rng.randi_range(1, num1), answer = num1 - num2（負にならない）

### 2. FlashCalcView (flash_calc_view.gd)

**責務**:
- タイマー管理（30秒カウントダウン、_process で毎フレーム更新）
- テンキー入力 → _input_buffer に蓄積 → 回答表示更新
- 確定ボタン → FlashCalc.check_answer() → 正誤フィードバック → 次の問題
- バックスペース → _input_buffer 末尾削除
- ゴーストバトルバー更新（正解数リアルタイム反映）

**テンキーフロー**:
```
数字キー押下 → _input_buffer += str(digit) → AnswerLabel.text = _input_buffer
確定 → parse int → check_answer → 正誤アニメ → generate_next → _input_buffer = ""
BS → _input_buffer = _input_buffer.substr(0, -1) → AnswerLabel更新
```

### 3. flash_calc.tscn レイアウト

```
Control (root, FlashCalcView script)
├── PageBackground (放射グラデーション)
├── TimerRing (右上、円形プログレス)
│   ├── TimerBg (TextureProgressBar or Label + 円描画)
│   └── TimerLabel (残り秒数)
├── SafeAreaMargin
│   └── MainColumn (VBoxContainer)
│       ├── CalcDisplay (CenterContainer)
│       │   └── CalcRow (HBoxContainer: Num1 + Operator + Num2)
│       ├── AnswerDisplay (CenterContainer)
│       │   └── AnswerLabel
│       ├── GhostBattleBar (共有シーンインスタンス)
│       └── KeypadCard (PanelContainer, glass_bubble)
│           └── KeypadGrid (GridContainer 3列)
│               ├── 1-9 (Button)
│               ├── BS (Button, backspace)
│               ├── 0 (Button)
│               └── OK (Button, confirm)
├── GameTimer (Timer, 30秒)
```

## Stitch HTML → Godot サイズ換算

| HTML要素 | HTML px | Godot px | 備考 |
|--|--|--|--|
| 計算数字 | 280px | 140px | font-black, 視認性重視で大きめ維持 |
| 演算子 | 280px | 140px | +は青、-は赤 |
| 回答 "???" | 9rem(144px) | 72px | |
| タイマー数字 | 4rem(64px) | 40px | |
| テンキー数字 | 4rem(64px) | 36px | |
| ゴーストバトル | — | — | 共有シーンそのまま |

## テーマに追加するvariation

| variation名 | base_type | 用途 |
|--|--|--|
| `keypad_button` | Button | テンキー通常ボタン（白背景、底シャドウ） |
| `keypad_confirm` | Button | テンキー確定ボタン（青背景） |
| `keypad_card` | PanelContainer | テンキーカード枠（glass-card） |

## ファイル構成

```
scripts/games/flash_calc.gd          # 新規 — ロジック
scripts/ui/flash_calc_view.gd        # 新規 — ビュー
scenes/games/flash_calc.tscn         # 新規 — シーン
assets/themes/default_theme.tres     # keypad系variation追加
```

## 実装の順序

1. テーマにキーパッドスタイル追加
2. flash_calc.gd（ロジック）作成
3. flash_calc.tscn + flash_calc_view.gd（シーン+ビュー）作成
4. GameManagerのflash_calc対応（_build_play_data_for）確認
5. Xvfbキャプチャ・Stitch比較
