# 設計書

## アーキテクチャ概要

個別結果画面は MVC ライク構成: シーン (View) + Controller + GameManager (Model 経由のデータソース)。本リデザインで View を全面刷新し、Controller に grade/verdict/round-outcome/delta 算出ロジックを追加。データ流入経路は既存のまま (GameManager._current_play_log + _previous_score)。

```
[PlayLog]      [GhostData]        [DataStore]
   ↓                ↓                  ↓
GameManager._current_play_log + _previous_score
                                       ↓
                  IndividualResultController._load_from_game_manager()
                                       ↓
   ┌───────────┬───────────┬───────────┬───────────┐
   ↓           ↓           ↓           ↓           ↓
GradeHeadline Subtitle  RoundDots  VerdictTitle ScoreBlock + CompareCards + Speech
   (動的)       (静的Map)  (条件表示)   (動的)        (動的)        (動的)         (動的)
```

## コンポーネント設計

### 1. GradeHeadline

**責務**:
- log.game_type + wins + is_new_best から見出し文字列・サイズ・色を決定
- 両側の星装飾 (Material `auto_awesome`) も合わせて表示

**実装の要点**:
- `_compute_grade_headline(log: PlayLog) -> Dictionary` で `{text, font_size, font_color, decoration_visible}` を返す
- ghost_7ban_shobu の wins 取得は既存 `_count_wins_from_events()` 互換ロジックを controller 側にも持つ (GameManager 依存を最小化)
- font_size 変化は `add_theme_font_size_override` で実現

**マッピング** (要件 §1-1 参照):

```gdscript
# ghost_7ban_shobu
wins == 7 → "PERFECT WIN", 72px, gold, deco=true
wins in [5,6] → "GREAT WIN", 64px, gold, deco=true
wins == 4 → "WIN", 56px, gold, deco=true
wins <= 3 → "NICE TRY", 56px, cyan_dim, deco=false

# 他ゲーム
is_new_best → "NEW BEST", 64px, gold, deco=true
prev == 0 → "NICE START", 56px, gold, deco=true
score > prev → "IMPROVED", 56px, gold, deco=true
else → "NICE TRY", 56px, cyan_dim, deco=false
```

### 2. Subtitle

**責務**: ゲーム種別ラベル表示 (静的 Map)

**実装の要点**:
- `const GAME_SUBTITLE: Dictionary = { "ghost_7ban_shobu": "7ラウンド対決", ... }`
- 文字間隔は `LabelSettings.letter_spacing` を使うか、theme variation `subtitle_caps` を新設

### 3. RoundDots

**責務**: ghost_7ban_shobu の 7 ラウンド勝敗を 7 個のアイコンで可視化

**実装の要点**:
- ghost_7ban_shobu 以外は `visible = false` (シーンルートで `RoundDots` 全体を hide)
- アイコンは Material Symbols フォントで描画 (既存 MaterialSymbolsRounded.ttf 流用):
  - win: `circle` (filled), cyan
  - loss: `close` (×), gray
  - miss: `radio_button_unchecked` (空丸), gray dim
- 7 個の Label ノードを HBox に並べる (静的に 7 個用意、テキストだけ動的書換)
- `_compute_round_outcomes(log) -> Array[String]` で 7 要素配列を返す

**round_outcomes 算出ロジック**:

```gdscript
func _compute_round_outcomes(log: PlayLog) -> Array[String]:
    var deltas: Array[int] = []
    var wins: Array[int] = []
    for evt in log.events:
        if evt.event_type == "round_result":
            deltas.append(int(evt.value))
        elif evt.event_type == "round_win":
            wins.append(int(evt.value))
    var out: Array[String] = []
    for i in deltas.size():
        if deltas[i] >= 1000:
            out.append("miss")
        elif i < wins.size() and wins[i] == 1:
            out.append("win")
        else:
            out.append("loss")
    while out.size() < 7:
        out.append("miss")  # 不足分は安全側 (miss)
    return out
```

### 4. VerdictTitle

**責務**: 「勝ち越し！」等の装飾セリフタイトル

**実装の要点**:
- Label 1 つで完結: `text = "✧ %s ✧" % title`
- フォントは既存の `NotoSerifJP-Bold.otf` を 44px で使用
- `_compute_verdict_title(log) -> Dictionary` で `{text, color}` を返す

### 5. ScoreBlock (Score + DeltaBadge + BestPill)

**責務**: 主スコア + 前回比 delta + ベスト判定の表示

**実装の要点**:
- 既存 `ScoreCard` PanelContainer (premium_card) を流用
- 内部 VBox:
  - ScoreCaption「スコア」
  - ScoreRow HBox: [ScoreValue] [ScoreUnit] [DeltaBadge]
  - BestPill (旧 NewBestBadge を改修、PanelContainer + text "BEST" + gold pill style)
- DeltaBadge は controller 側で `visible = (log.score - prev > 0)` 制御
- ScoreValue は 3 桁区切り表示: `String.num_int64(int(value)).insert(...)` または "%s" + 自前フォーマッタ

**3 桁区切り実装**:
```gdscript
static func _format_thousands(n: int) -> String:
    var s := str(n)
    var result := ""
    var count := 0
    for i in range(s.length() - 1, -1, -1):
        if count > 0 and count % 3 == 0:
            result = "," + result
        result = s[i] + result
        count += 1
    return result
```

### 6. CompareCards (YouCard + OpponentCard)

**責務**: ゲーム別の比較表示 (vs GHOST or vs 自己ベスト)

**実装の要点**:
- HBoxContainer + 2 PanelContainer (theme_type_variation = `glass_bubble`)
- 各カードに VBox: [Avatar] [Caption] [Value]
- Avatar は TextureRect 64x64 (catboy_electric / catboy_confident)
- controller が cfg dict をもとに caption と value を動的設定

**ゲーム別 cfg 拡張** (`_get_display_config` に追加):

```gdscript
"reflex_tap": {
    ...,
    "compare_mode": "ghost",  # YOU vs GHOST
    "compare_caption_you": "平均",
    "compare_caption_opponent": "平均",
    "opponent_avatar": "catboy_confident",
},
"flash_calc": {
    ...,
    "compare_mode": "self_best",  # YOU vs 自己ベスト
    "compare_caption_you": "スコア",
    "compare_caption_opponent": "自己ベスト",
    "opponent_avatar": "catboy_confident",
},
```

`compare_mode == "self_best"` のときは opponent_value を `DataStore.load_best(log.game_type).best_score` から取得 (前回スコアではなく自己ベスト)。

### 7. SpeechBubble (既存ロジック流用、文言は grade に合わせて調整)

**実装の要点**:
- 既存 `_update_ghost_dialogue` を grade 連動に拡張:

```gdscript
match grade:
    "PERFECT WIN":   "完璧！君は今日のヒーローだ！"
    "GREAT WIN":     "素晴らしい勝ち越しだよ！"
    "WIN":           "やったね！今日は君の方が一歩近づいた"
    "NEW BEST":      "すごい！自己ベスト更新だよ！"
    "IMPROVED":      "成長してる！この調子！"
    "NICE START":    "良いスタート！基準値ができたよ"
    "NICE TRY":      "今日は惜しかった。次は超えられるよ"
```

### 8. ボタン (ReplayButton + HomeButton)

**変更点**:
- ReplayText: 「もう一度プレイ」→ 「もう一度」(画像準拠)
- HomeText: 「ホームに戻る」→ 「ホームへ戻る」(画像準拠)
- アイコン・スタイルは既存維持

## データフロー

### ユースケース1: ghost_7ban_shobu 終了 → 個別結果表示 (wins=5 のケース)

```
1. Ghost7BanShobu._commit_round_result() がラウンド毎に呼ばれる
2. record_event("round_result", delta_ms)
3. record_event("round_win", 1.0 or 0.0)  ← 新規追加
4. (7 ラウンド後) Ghost7BanShobu.finalize_game() で session_end イベント記録
5. GameManager.on_game_finished_handler(log):
   - log.score = ScoreSystem.calculate_score(...)
   - log.is_new_best = DataStore.update_best_if_better(log)
   - _current_play_log = log
   - _safe_change_scene("res://scenes/ui/individual_result.tscn")
6. IndividualResultController._ready() → _load_from_game_manager()
7. set_result(log, _previous_score):
   - grade = _compute_grade_headline(log) → {text: "GREAT WIN", font_size: 64, color: gold, deco: true}
   - subtitle = GAME_SUBTITLE["ghost_7ban_shobu"] → "7ラウンド対決"
   - dots = _compute_round_outcomes(log) → ["win", "win", "loss", "win", "win", "win", "miss"]
   - verdict = _compute_verdict_title(log) → {text: "✧ 勝ち越し！ ✧", color: gold}
   - delta = log.score - _previous_score (e.g. 180)
   - score_block: value=log.score (3桁区切り), unit="pts", delta="↑+180", best=true if new_best
   - compare_cards (cfg.compare_mode == "ghost"): you_value=avg(player_deltas), opp_value=avg(ghost_medians)
   - speech_text = _gen_speech("GREAT WIN") → "素晴らしい勝ち越しだよ！"
```

### ユースケース2: flash_calc 終了 → 個別結果表示 (改善あり、ベスト更新なし)

```
1. FlashCalc が session_end emit
2. GameManager.on_game_finished_handler(log)
3. set_result(log, _previous_score=900):
   - grade = "IMPROVED" (score=1020 > prev=900, not new best)
   - subtitle = "フラッシュ暗算"
   - dots = HIDDEN
   - verdict = "成長してる！" gold
   - delta = +120 → "↑+120" 表示
   - best_pill = hidden
   - compare_cards (cfg.compare_mode == "self_best"):
     - you_value = 1020
     - opp_value = DataStore.load_best("flash_calc").best_score (e.g. 1200)
     - caption_opp = "自己ベスト"
```

## エラーハンドリング戦略

### round_result と round_win イベントの数が一致しない場合

ghost_7ban_shobu 以外のゲームでは round_result イベントは存在しないため、`_compute_round_outcomes` は空配列を返す → RoundDots は不可視のまま (シーンルートで visible=false がデフォルト)。

ghost_7ban_shobu でも records が 7 件未満の場合 (異常終了等) は不足分を "miss" で埋める (要件 §3-1 参照)。

### _previous_score が未設定 (初回)

`_previous_score == 0` のときは:
- DeltaBadge は非表示
- grade は "NICE START" (gold, ポジティブ)
- verdict は "良いスタート！"

### log.game_type が GAME_SUBTITLE に無い

未知の game_type は subtitle に game_type 自体を表示 (フォールバック)。push_warning を出す。

## テスト戦略

### 手動テスト (キャプチャ確認)

`tools/capture_individual_result.gd` で 4 ケースをキャプチャ:

1. ghost_7ban_shobu wins=7 (PERFECT WIN)
2. ghost_7ban_shobu wins=2 (NICE TRY)
3. reflex_tap new_best (NEW BEST + ghost compare)
4. flash_calc improved (IMPROVED + self_best compare)

それぞれの PNG を `.steering/.../captures/` に保存し、image diff で承認。

### スモークテスト (実機 / Godot エディタ)

各ゲームを 1 回プレイし、結果画面で以下を確認:
- ヘッドラインが想定通り
- ラウンドドット (ghost_7ban_shobu のみ) が 7 個表示
- 「もう一度」ボタンで同ゲーム再開
- 「ホームへ戻る」でホーム遷移

## 依存ライブラリ

新規依存なし。既存の MaterialSymbolsRounded.ttf, NotoSerifJP-Bold.otf, default_theme.tres を流用。

## ディレクトリ構造

```
scenes/ui/individual_result.tscn                    # 全面改修
scripts/ui/individual_result_controller.gd          # メソッド追加
scripts/games/ghost_7ban_shobu/ghost_7ban_shobu.gd  # round_win イベント追加
tools/capture_individual_result.gd                  # 新規 (キャプチャツール)
.steering/20260515-個別結果画面リザルトイメージ準拠リデザイン/
├── requirements.md
├── design.md
├── tasklist.md
└── captures/                                       # 検証PNG
    ├── ghost_perfect_win.png
    ├── ghost_nice_try.png
    ├── reflex_new_best.png
    └── flash_improved.png
```

## 実装の順序

1. **イベントスキーマ拡張**: ghost_7ban_shobu.gd に `round_win` PlayEvent emit を追加 (既存 ghost_7ban_shobu のプレイで動作確認)
2. **コントローラのデータ計算メソッドを追加**: `_compute_grade_headline` 等 4 メソッドを実装し、ダミーデータでユニット確認 (UI 接続前)
3. **シーンを段階的に書き換え**: 旧 ResultsHeader → GradeHeadline 置換、旧 ComparisonCard → CompareCards 置換、旧 StatsGrid 削除、新規 RoundDots/VerdictTitle/DeltaBadge/BestPill 追加
4. **コントローラと新ノードを接続**: `@onready` 参照を更新、`set_result` で各セクションを駆動
5. **キャプチャツール作成**: 4 ケース PNG 生成
6. **実機 / エディタで動作確認**: 各ゲームを実プレイ → 結果画面確認

## セキュリティ考慮事項

該当なし (UI 改修のみ、外部入力なし)。

## パフォーマンス考慮事項

- Material Symbols フォントの読み込みは既存。RoundDots は最大 7 ラベル → 描画コスト無視可能
- _compute_* メソッドは O(N) (N=イベント数)、PlayLog の events は最大 100 程度想定 → 問題なし
- 3 桁区切りは O(桁数) で軽量

## 将来の拡張性

- ヘッドラインに紙吹雪パーティクル (PERFECT WIN のみ) を追加するときは GradeHeadline の周囲に CPUParticles2D を配置できるよう、ヘッドライン親ノードを VBox ではなく Control にしておく
- レーダーチャート (精度100%時のみ表示) を BestPill の下に追加する余地を確保
- シェアボタン (Web 版限定) を ReplayButton 横に追加する余地を確保 (ButtonRow を HBox にしておく)

## デザイントークン (rule_explain / countdown と統一)

| トークン | 用途 | 色 |
|---|---|---|
| `gold` | ヘッドライン勝ち、BESTピル、verdict gold | `Color(1.0, 0.914, 0.659)` |
| `cyan300` | DeltaBadge 正、win 色 | `Color(0.435, 0.706, 1.0)` |
| `cyan100` | YouValue (ghost_mode) | `Color(0.7, 0.93, 1.0)` |
| `ink95` | ScoreValue 主数字 | `Color(0.95, 0.97, 1.0)` |
| `ink80` | OpponentValue, dim 文字 | `Color(0.78, 0.824, 0.91)` |
| `ink60` | 装飾サブテキスト | `Color(0.78, 0.824, 0.91, 0.7)` |
| `gray_dim` | round dot loss/miss × | `Color(0.6, 0.65, 0.75)` |
| `void_bg` | VoidBg | `Color(0, 0, 0)` |
| `nebula_a` | NebulaBg start | `Color(0.04, 0.08, 0.16)` |
| `nebula_b` | NebulaBg mid | `Color(0.01, 0.02, 0.04)` |
