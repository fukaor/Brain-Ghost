# 設計書

## 基本方針

**Stitchで作成した画面がUIの正**。レイアウトの「雰囲気」を寄せるのではなく、コンポーネントの種類・配置順序・階層構造をStitchスクリーンショットに忠実に再現する。

既存の .tscn 構造を Stitch に合わせて再構成する。テーマは既存の `default_theme.tres` の variation を活用し、不足分のみ追加する。

---

## 画面1: ルール説明画面

### Stitch コンポーネントツリー（上→下の配置順）

```
RuleExplain (Control)
├── PageBackground (TextureRect) — page_bg
├── SafeAreaMargin (MarginContainer)
│   └── MainColumn (VBoxContainer)
│       ├── HeaderRow (HBoxContainer)
│       │   ├── GameIcon (Label/icon) — ⚡ 黄色丸背景
│       │   ├── TitleVBox (VBoxContainer)
│       │   │   ├── TitleLabel — "反射タップ" (h1, 左寄せ)
│       │   │   └── SubtitleLabel — "🧠 脳力: 反応速度" (caption, 左寄せ)
│       │   ├── HeaderSpacer (Control, expand)
│       │   └── BackButton — ↩ 矢印 (右上)
│       │
│       ├── ExplanationText (Label, 中央寄せ, autowrap)
│       │   "次々に出てくる的を、\n素早くタップしてね！\n20回タップするまでの時間を測るよ。"
│       │
│       ├── GhostImage (TextureRect) — Seirei 画像 (吹き出しなし)
│       │
│       ├── HintCardsRow (HBoxContainer)
│       │   ├── TargetCard (PanelContainer / glass_bubble)
│       │   │   └── VBox
│       │   │       ├── TargetIcon — 青丸+タップ指アイコン
│       │   │       ├── TargetTitle — "TARGET"
│       │   │       └── TargetDesc — "的をタップ！"
│       │   └── FakeCard (PanelContainer / glass_bubble)
│       │       └── VBox
│       │           ├── FakeIcon — 紫✕アイコン
│       │           ├── FakeTitle — "FAKE"
│       │           └── FakeDesc — "✕は無視しよう"
│       │
│       ├── WarningRow (HBoxContainer, 中央寄せ)
│       │   └── WarningLabel — "⚠ フェイクをタップすると、タイムロスになるよ！"
│       │
│       └── StartButton (Button / cta_blue)
│           "脳トレ開始 ▶"
```

### 現在の実装との差分

| 項目 | 現在 | Stitch |
|------|------|--------|
| ヘッダー左 | BackButton (arrow_back) | GameIcon (⚡) + Title + Subtitle |
| ヘッダー右 | なし | BackButton (↩) |
| ルール説明 | GhostCharacter の吹き出し内テキスト | 独立した Label（吹き出しなし） |
| ゴースト表示 | GhostCharacter コンポーネント（吹き出し付き） | 素の TextureRect（吹き出しなし） |
| TARGET/FAKE カード | なし | glass_bubble × 2 枚 |
| 警告テキスト | なし | WarningLabel |
| CTA テキスト | "スタート" | "脳トレ開始 ▶" |
| SkipButton | hidden で存在 | なし (削除) |
| Subtitle | なし | "🧠 脳力: 反応速度" |

### コントローラ変更 (rule_explain_controller.gd)

- RULES dict にフィールド追加:
  - `ability_name`: "反応速度" / "計算力" 等
  - `explanation`: 吹き出しから独立したルール説明テキスト
  - `hints`: [{icon, title, desc}, ...] — TARGET/FAKE カード用
  - `warning`: 警告テキスト
- GhostCharacter コンポーネントの参照を削除 → TextureRect 参照に変更
- set_rule() で上記フィールドを各ラベルに反映

---

## 画面2: 反射タップ プレイ画面

### Stitch コンポーネントツリー（上→下の配置順）

```
ReflexTap (Control)
├── PageBackground (TextureRect) — page_bg_v2 ★変更
├── SafeAreaMargin (MarginContainer)
│   └── MainColumn (VBoxContainer)
│       ├── TopHudRow (HBoxContainer)
│       │   ├── AvgColumn (VBoxContainer)
│       │   │   ├── AvgCaption (Label) — "CURRENT AVG" (caption, グレー)
│       │   │   └── AvgValue (Label) — "0.45s" (display, 大きく太字)
│       │   ├── ProgressColumn (VBoxContainer)
│       │   │   ├── ProgressCaption (Label) — "PROGRESS" (caption, グレー)
│       │   │   └── ProgressValue (Label) — "7 / 20" (display, 大きく太字)
│       │   ├── HudSpacer (Control, expand)
│       │   └── ProgressRing (VBoxContainer or Control)
│       │       └── ProgressPercent (Label) — "35%" (円弧枠 + パーセント)
│       │
│       ├── GameArea (Control, expand, clip_contents)
│       │   └── [動的にターゲット Button を生成]
│       │
│       └── GhostBattleBar (PanelContainer)
│           └── BattleVBox (VBoxContainer)
│               ├── BattleHeaderRow (HBoxContainer)
│               │   ├── BattleIcon (Label/icon) — ⚔ swords
│               │   ├── BattleTitle (Label) — "ゴーストバトル"
│               │   ├── BattleSpacer (Control, expand)
│               │   └── LiveSyncBadge (PanelContainer / pill)
│               │       └── LiveSyncLabel — "LIVE SYNC"
│               └── ScoreRow (HBoxContainer)
│                   ├── PlayerLabel — "自分"
│                   ├── PlayerBar (PanelContainer, expand, 青)
│                   ├── PlayerScore — "420"
│                   ├── GhostLabel — "ゴースト"
│                   └── GhostScore — "385"
```

### 現在の実装との差分

| 項目 | 現在 | Stitch |
|------|------|--------|
| HUD構成 | PanelContainer ×3 (pill_chip) | テキストのみ 2列 + 円形プログレス |
| HUD内容 | Progress/Elapsed/Speed | CURRENT AVG / PROGRESS / % |
| 背景 | page_bg | page_bg_v2 |
| ゴーストバトルバー | なし | 画面下部に常時表示 |
| 速度表示 | "— ms" (最終タップのms) | "0.45s" (累積平均秒) |

### コントローラ変更 (reflex_tap_view.gd)

- @onready 参照を全て新ノード名に変更
- _process() の HUD 更新:
  - AvgValue: 累積平均反応時間を秒単位で表示 ("0.45s")
  - ProgressValue: "7 / 20" 形式
  - ProgressPercent: tapped / total * 100 → "35%"
- ゴーストバトルバーのスコアはプレースホルダー（ゴーストシステム未実装）
  - PlayerScore: 現在スコアをリアルタイム計算
  - GhostScore: 固定値（例: 385）

---

## 画面3: 結果画面

### Stitch コンポーネントツリー（上→下の配置順）

```
IndividualResult (Control)
├── PageBackground (TextureRect) — page_bg
├── GhostMascotBg (TextureRect) — Seirei 大きめ背景 (薄い)
├── SafeAreaMargin (MarginContainer)
│   └── MainColumn (VBoxContainer)
│       ├── GhostRow (HBoxContainer)
│       │   ├── GhostChibi (TextureRect) — Seirei ちび画像 (小)
│       │   └── SpeechBubble (PanelContainer / glass_bubble + speech_bubble script)
│       │       └── SpeechText (Label) — "すごい！昨日より反応が速くなってるよ！"
│       │
│       ├── ResultsLabel (HBoxContainer, 中央寄せ)
│       │   ├── ResultsDot (Label) — "●" (青丸)
│       │   └── ResultsText (Label) — "RESULTS"
│       │
│       ├── ScoreSection (VBoxContainer, 中央寄せ)
│       │   ├── ScoreRow (HBoxContainer, 中央寄せ)
│       │   │   ├── ScoreValue (Label) — "0.42" (超大型)
│       │   │   ├── ScoreUnit (Label) — "s" (大型、baseline揃え)
│       │   │   └── NewBestBadge (Label/PanelContainer) — "NEW BEST!" (黄色、斜め)
│       │   └── ScoreCaption (Label) — "平均反応時間" (caption, グレー)
│       │
│       ├── ComparisonCard (PanelContainer / hero_card)
│       │   └── ComparisonHBox (HBoxContainer)
│       │       ├── YouSection (VBoxContainer)
│       │       │   ├── YouCaption (Label) — "YOU" (caption)
│       │       │   └── YouValue (Label) — "0.42s" (display)
│       │       ├── VictoryBadge (PanelContainer / pill) — "VICTORY" (黄色)
│       │       └── GhostSection (VBoxContainer)
│       │           ├── GhostCaption (Label) — "GHOST" (caption)
│       │           └── GhostValue (Label) — "0.45s" (display)
│       │
│       ├── StatsCard (PanelContainer / hero_card)
│       │   └── StatsHBox (HBoxContainer)
│       │       ├── PerfectSection (VBoxContainer)
│       │       │   ├── PerfectCaption (Label) — "パーフェクト" (caption)
│       │       │   └── PerfectValue (Label) — "18回" (display)
│       │       ├── StatsDivider (VSeparator or Control)
│       │       └── MissSection (VBoxContainer)
│       │           ├── MissCaption (Label) — "ミス" (caption)
│       │           └── MissValue (Label) — "2回" (display)
│       │
│       ├── ReplayButton (Button / cta_blue)
│       │   "もう一度プレイ 🔄"
│       │
│       └── HomeLinkRow (HBoxContainer, 中央寄せ)
│           ├── HomeIcon (Label/icon) — 🏠
│           └── HomeLink (Button / flat) — "ホームに戻る"
```

### 現在の実装との差分

| 項目 | 現在 | Stitch |
|------|------|--------|
| ゴースト位置 | 中央下部（GhostCharacter コンポーネント） | 上部左寄り（ちびキャラ + 吹き出し） |
| タイトル | "結果" (h1) | "● RESULTS" (小さめ) |
| メイン表示 | スコア数値 (score) | 平均反応時間 "0.42s" |
| NEW BEST | HBox（icon + "ベスト更新！"） | 黄色バッジ "NEW BEST!" (スコア横) |
| 前回比 | "前回比 +XX" (DiffLabel) | なし（YOU vs GHOST に置換） |
| YOU vs GHOST | なし | 比較カード |
| 統計 | なし | パーフェクト/ミス回数 |
| ボタン構成 | ReplayButton + HomeButton (横並び) | ReplayButton (CTA) + HomeLink (テキスト) |
| 背景ゴースト | なし | Seirei 背景画像 (薄い) |

### コントローラ変更 (individual_result_controller.gd)

- @onready 参照を全面書き換え（ノード構造が大幅に変わるため）
- set_result() の表示ロジック:
  - ScoreValue: `"%.2f" % (avg_ms / 1000.0)` で秒表示
  - NewBestBadge: log.is_new_best で visible 切替
  - YouValue: 自分の平均反応時間
  - GhostValue: プレースホルダー "0.45s"
  - VictoryBadge: YOU < GHOST (時間が短い方が勝ち) で VICTORY / DEFEAT
  - PerfectValue / MissValue: PlayLog.events から target_tapped / fake_tapped をカウント
- GhostCharacter コンポーネント参照を削除 → GhostChibi (TextureRect) + SpeechBubble に変更
- _update_ghost_dialogue() のセリフをStitch準拠に更新

---

## 画面4: ホーム画面

### Stitch vs 現在の差分

ホーム画面は現在の実装がStitchにほぼ準拠済み。差分は以下のみ:

| 項目 | 現在 | Stitch |
|------|------|--------|
| CTA テキスト | "今日の脳トレを開始する" | "👻 今日の脳トレを開始する" (ゴーストアイコン付き) |

### 変更内容
- StartButton の内部構造を変更: 単純な text → HBox(icon + text) に変更するか、text に Material Symbols の ghost 文字を prefix

---

## 実装の順序

1. ルール説明画面 (.tscn を Stitch 準拠で再構成 → .gd を対応)
2. 反射タップ プレイ画面 (.tscn を Stitch 準拠で再構成 → .gd を対応)
3. 結果画面 (.tscn を Stitch 準拠で再構成 → .gd を対応)
4. ホーム画面 (CTA の微調整のみ)
