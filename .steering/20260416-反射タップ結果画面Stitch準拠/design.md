# 設計書

## アーキテクチャ概要

既存パターン（ルール説明画面・カウントダウン画面）と同じ構成を踏襲:
- `.tscn` でレイアウト定義
- `_controller.gd` でデータバインドと画面遷移
- テーマ variation でスタイル統一

```
GameManager.on_game_finished_handler(log)
  → individual_result.tscn に遷移
    → IndividualResultController が PlayLog を受け取る
    → UI にデータバインド
    → ユーザーが "もう一度プレイ" or "ホームに戻る" を選択
```

## コンポーネント設計

### 1. individual_result.tscn（シーン）

**レイアウト構造** (上→下):
```
Control (root)
├── PageBackground (TextureRect, 放射グラデーション)
├── SafeAreaMargin (MarginContainer)
│   └── MainColumn (VBoxContainer)
│       ├── CharacterRow (HBoxContainer)
│       │   ├── ChibiTexture (TextureRect, ghost_seirei.png)
│       │   └── SpeechBubble (PanelContainer, glass_bubble)
│       ├── ScoreCard (PanelContainer, premium_card)
│       │   ├── ResultsHeader (HBoxContainer: stars + RESULTS + stars)
│       │   ├── ScoreDisplay (Label, 特大スコア)
│       │   ├── NewBestBadge (PanelContainer, 条件付き表示)
│       │   └── ScoreCaption (Label, "平均反応時間")
│       ├── GhostBattleCard (PanelContainer, glass_bubble)
│       │   ├── ScoreComparison (HBoxContainer: YOU / VICTORY / GHOST)
│       │   └── ComparisonBar (HBoxContainer: 青バー + 灰バー)
│       ├── StatsGrid (HBoxContainer)
│       │   ├── PerfectCard (PanelContainer)
│       │   └── MissCard (PanelContainer)
│       └── ButtonColumn (VBoxContainer)
│           ├── ReplayButton (Button, cta_blue)
│           └── HomeButton (Button, secondary)
```

### 2. individual_result_controller.gd（コントローラ）

**責務**:
- PlayLog + ゴースト判定結果を受け取ってUIにバインド
- 勝敗に応じた吹き出しテキスト・VICTORYバッジ切替
- NEW BEST判定と表示
- ボタン押下時の画面遷移

**公開API**:
```gdscript
func setup(log: PlayLog, ghost_result: Dictionary) -> void
```

**ghost_result Dictionaryの想定**:
```gdscript
{
  "player_score": float,  # 今回のスコア（例: 0.42）
  "ghost_score": float,   # ゴーストスコア（例: 0.45）
  "is_victory": bool,
  "is_new_best": bool,
  "perfect_count": int,
  "miss_count": int,
}
```

## Stitch HTML → Godot サイズ換算

HTML(1080x1920) → Godot(720x1280) = ×2/3。ただし視認性を考慮して最低12px。

| HTML要素 | HTML px | Godot px | 備考 |
|--|--|--|--|
| スコア本体 | 180px | 120px | score-text |
| スコア単位 "s" | 72px(text-7xl) | 48px | |
| "RESULTS" | 24px(text-2xl) | 16px | tracking-widest |
| "平均反応時間" | 30px(text-3xl) | 20px | |
| YOU/GHOST ラベル | 20px(text-xl) | 14px | |
| YOU/GHOST スコア | 48px(text-5xl) | 32px | |
| VICTORY バッジ | 20px(text-xl) | 14px | |
| 統計ラベル | 18px(text-lg) | 12px | |
| 統計値 | 60px(text-6xl) | 40px | |
| CTA "もう一度プレイ" | 36px(text-4xl) | 24px | |
| "ホームに戻る" | 24px(text-2xl) | 16px | |
| 吹き出しテキスト | 28px | 19px | |

## テーマに追加するvariation

| variation名 | base_type | 用途 |
|--|--|--|
| `premium_card` | PanelContainer | メインスコアカード（白グラデ、大シャドウ） |
| `stat_card` | PanelContainer | 統計カード（白半透明、角丸） |
| `victory_badge` | PanelContainer | VICTORYバッジ（緑背景） |
| `defeat_badge` | PanelContainer | DEFEATバッジ（グレー背景） |

## ディレクトリ構造

```
scenes/ui/individual_result.tscn    # 新規
scripts/ui/individual_result_controller.gd  # 新規
assets/themes/default_theme.tres    # 4 variation追加
```

## 実装の順序

1. テーマにスタイル追加 (premium_card, stat_card, victory/defeat_badge)
2. tscnレイアウト構築（5セクション）
3. コントローラスクリプト実装
4. Xvfbキャプチャ・Stitch比較
