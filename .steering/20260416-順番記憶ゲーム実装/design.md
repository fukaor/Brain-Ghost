# 設計書

## アーキテクチャ概要

反射タップ・フラッシュ暗算と同じ3層構成:
- `scripts/games/sequence_memory.gd` — ロジック（BaseGame継承、シーケンス生成・正誤判定）
- `scripts/ui/sequence_memory_view.gd` — ビュー（グリッド表示・アニメーション・タイマー）
- `scenes/games/sequence_memory.tscn` — シーン（Stitch準拠レイアウト）

## コンポーネント設計

### 1. SequenceMemory (sequence_memory.gd)

**定数**:
- GRID_SIZE = 9 (3x3)
- INITIAL_LEVEL = 3（最初に光るパネル数）
- SHOW_INTERVAL_SEC = 0.6（各パネルの表示時間）
- SHOW_PAUSE_SEC = 0.3（パネル間の暗転時間）

**状態**:
- _current_level: int（現在何個光らせるか）
- _sequence: Array[int]（光る順番のパネルインデックス 0-8）
- _user_input_index: int（ユーザーが何番目まで入力したか）
- _max_reached_level: int（到達最大レベル）
- _phase: String（"showing" / "input" / "finished"）

**Public API**:
```gdscript
func get_current_level() -> int
func get_max_reached_level() -> int
func get_sequence() -> Array[int]       # 表示フェーズ用
func get_phase() -> String
func check_panel_tap(panel_index: int) -> String  # "correct" / "level_clear" / "wrong"
func advance_to_next_level() -> void    # 次のラウンドへ
```

**シーケンス生成（決定論、rng使用）**:
- _sequence を _current_level 個分生成
- 重複なし: rng で 0-8 からシャッフル的に選択

### 2. SequenceMemoryView (sequence_memory_view.gd)

**責務**:
- 表示フェーズ: _sequence に従ってパネルを順番にハイライト（Tween）
- 入力フェーズ: パネルタップ → SequenceMemory.check_panel_tap()
- 正解アニメ → 次ラウンド / 不正解 → ゲーム終了
- ラウンド表示・タイマー更新
- ゴーストバトルバー（到達レベル表示）

**フェーズ管理**:
```
ROUND開始 → 表示フェーズ（パネル順番ハイライト）→ 入力フェーズ（ユーザータップ）
  → 全正解 → advance_to_next_level → ROUND開始に戻る
  → 不正解 → finish
```

### 3. sequence_memory.tscn レイアウト

```
Control (root, SequenceMemoryView script)
├── PageBackground (放射グラデーション)
├── TimerRing (右上)
├── SafeAreaMargin
│   └── MainColumn (VBoxContainer)
│       ├── RoundBadge (Label: "ROUND 05")
│       ├── InstructionLabel (Label: "順にタップしてください")
│       ├── MemoryGrid (GridContainer 3列, 9パネル)
│       │   └── Panel0..Panel8 (Button, memory_panel theme)
│       （※ クリア系ゲームのためプレイ中ゴーストバトルバー非表示: GDD §5c）
```

## テーマに追加するvariation

| variation名 | base_type | 用途 |
|--|--|--|
| `memory_panel` | Button | 通常パネル（白背景、底シャドウ、角丸、1:1） |
| `memory_panel_active` | Button | アクティブパネル（青背景、青グロー） |

## Stitch HTML → Godot サイズ換算

| HTML要素 | HTML px | Godot px |
|--|--|--|
| "ROUND 05" | 20px(text-xl) | 14px |
| 指示テキスト | 72px(text-7xl) | 36px |
| パネル内番号 | 120px | 60px |
| パネル底シャドウ | 12px | 8px |
| グリッド gap | 10(gap-10=40px) | 8px |

## ファイル構成

```
scripts/games/sequence_memory.gd          # 新規
scripts/ui/sequence_memory_view.gd        # 新規
scenes/games/sequence_memory.tscn         # 新規
assets/themes/default_theme.tres          # memory_panel追加
```

## 実装の順序

1. テーマにメモリーパネルスタイル追加
2. sequence_memory.gd（ロジック）作成
3. sequence_memory.tscn + sequence_memory_view.gd（シーン+ビュー）作成
4. GameManagerのsequence_memory対応確認
5. Xvfbキャプチャ・Stitch比較
