# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: イベントスキーマ拡張 (round_win)

- [x] `scripts/games/ghost_7ban_shobu/ghost_7ban_shobu.gd` の `_commit_round_result()` に `round_win` イベント emit を追加
  - [x] win フラグを 1.0/0.0 で record_event
  - [x] 既存 `round_result` (delta) との順序を保ち、1:1 ペアになるよう確認

## フェーズ2: Controller のデータ計算メソッド追加

- [x] `_compute_grade_headline(log) -> Dictionary` を実装
  - [x] ghost_7ban_shobu: wins 数で PERFECT/GREAT/WIN/NICE TRY 分岐
  - [x] 他ゲーム: new_best/improved/start/nice_try 分岐
  - [x] 戻り値: `{text, font_size, font_color, deco_visible}`
- [x] `_compute_verdict_title(log) -> Dictionary` を実装
  - [x] ghost_7ban_shobu: wins ≥ 4 → 勝ち越し！/ <4 → あと一歩！
  - [x] 他ゲーム: 自己ベスト/成長してる/ナイスプレイ/良いスタート分岐
- [x] `_compute_round_outcomes(log) -> Array[String]` を実装
  - [x] round_result と round_win イベントを 1:1 ペアリング
  - [x] win/loss/miss を返す、不足分は "miss" で埋める
- [x] `_compute_delta_badge(log, previous_score) -> Dictionary` を実装
  - [x] delta > 0 → `{visible: true, text: "+%d"}`
  - [x] それ以外は `{visible: false}`
- [x] `_format_thousands(n) -> String` ヘルパ (3 桁区切り)
- [x] `_get_display_config` に `compare_mode` / `compare_caption_you` / `compare_caption_opponent` を追加
  - [x] reflex_tap: compare_mode="ghost"
  - [x] ghost_7ban_shobu: compare_mode="ghost"
  - [x] flash_calc / stroop / sequence_memory / card_match / number_search: compare_mode="self_best"

## フェーズ3: シーン書換 (個別結果画面の構造変更)

- [x] 旧ノード削除: ResultsHeader / StarLeft / StarRight / VictoryBadge / VictoryLabel / CompareSpacer / CompareSpacer2 / CompareBarRow / PlayerBarSegment / GhostBarSegment / StatsGrid / PerfectCard / PerfectVBox / PerfectCaption / PerfectValue / MissCard / MissVBox / MissCaption / MissValue
- [x] 新ノード追加: ヘッダ系
  - [x] HeaderBlock (VBox)
  - [x] GradeRow (HBox): StarLeftDeco + GradeHeadline Label + StarRightDeco
  - [x] Subtitle Label
  - [x] RoundDots (HBox, 7 個の Label)
- [x] 新ノード追加: VerdictTitle Label (装飾セリフ)
- [x] ScoreBlock 構造改修
  - [x] ScoreRow を [ScoreValue][ScoreUnit][DeltaBadge] に再構成
  - [x] DeltaBadge (PanelContainer + Label, pill 形)
  - [x] NewBestBadge を BestPill に置換 (gold pill)
  - [x] スコア下に BestPill を再配置
- [x] CompareCards 構造改修
  - [x] 旧 ComparisonCard 構造を削除
  - [x] HBox に YouCard + OpponentCard
  - [x] 各カード: PanelContainer (glass_bubble) + VBox(Avatar 72x72 / Caption / Value)
- [x] ボタン文言修正
  - [x] 「もう一度プレイ」→「もう一度」
  - [x] 「ホームに戻る」→「ホームへ戻る」

## フェーズ4: Controller と新ノードの接続

(フェーズ2の Controller 全面リライト時に統合実装)

- [x] `@onready` ノードパスを新構造に更新
  - [x] 旧パス削除: `_victory_badge`, `_victory_label`, `_player_bar`, `_ghost_bar`
  - [x] 新パス追加: `_grade_headline`, `_subtitle`, `_round_dots`, `_verdict_title`, `_delta_badge`, `_delta_text`, `_best_pill`, `_you_avatar`, `_you_caption`, `_you_value`, `_opponent_avatar`, `_opponent_caption`, `_opponent_value`
- [x] `set_result()` を新構造に合わせて書換
  - [x] grade_headline 適用 (text, font_size, color)
  - [x] subtitle 設定 (GAME_SUBTITLE map から)
  - [x] round_dots 表示 (ghost_7ban_shobu のみ、他は非表示)
  - [x] verdict_title 設定
  - [x] delta_badge 適用 (visible / text)
  - [x] best_pill 適用 (log.is_new_best)
  - [x] compare_cards 適用 (compare_mode 分岐: ghost or self_best)
  - [x] speech_text 更新 (grade 連動)
- [x] 削除: 旧 `_display_comparison`, `_judge_victory` (compare bar/victory badge は廃止)
- [x] `_update_ghost_dialogue` を grade 連動に書換 (`_apply_speech` に統合)

## フェーズ5: キャプチャ検証ツール

- [x] `tools/capture_individual_result.gd` 新規作成
  - [x] 環境変数 CAPTURE_CASE で case を選択 (perfect_win / nice_try / new_best / improved)
  - [x] ダミー PlayLog をビルド (events 付き) — controller の _build_dummy_log に移譲
  - [x] _previous_score をモック (ケース別に設定)
  - [x] WAIT_FRAMES 後に scene capture → PNG 保存 (xvfb-run 経由)
- [x] 4 ケース PNG を `.steering/20260515-個別結果画面リザルトイメージ準拠リデザイン/captures/` に出力
  - [x] individual_perfect_win.png
  - [x] individual_nice_try.png
  - [x] individual_new_best.png
  - [x] individual_improved.png
- [x] Midnight Cat 暗色テーマ適用のため inline StyleBoxFlat (SBF_premium_dark / SBF_glass_dark / SBF_pill_cyan / SBF_pill_gold) を追加
- [x] round dots を Material Symbols から Unicode (●/✕/○) に変更 (fill axis 対応回避)

## フェーズ6: 品質チェックと修正

- [x] `grep -E "ResultsHeader|VictoryBadge|VictoryLabel|PerfectCard|MissCard|CompareBarRow|PlayerBarSegment|GhostBarSegment" scenes/ui/individual_result.tscn` が 0 件
- [x] `grep -E "DEFEAT|LOSE|失敗|負け" scripts/ui/individual_result_controller.gd scenes/ui/individual_result.tscn` が 0 件
- [x] 赤系の色値 (`Color(0\.[6-9]\d*, 0\.[01]\d*, 0\.[01]\d*` 等) が無い (ヘッドラインの装飾も含めて)
- [x] Godot で project 起動して parse / 実行時エラーがないことを確認 (godot --quit でクリーン起動)
- [x] キャプチャ画像と `docs/design/promotion/game_tap_result.png` を見比べて遜色ないことを確認 (4 ケースとも MidnightCat 暗色 + 必要要素揃って表示)

## フェーズ7: ドキュメント更新

- [x] 実装後の振り返り（このファイルの下部に記録）

---

## 実装後の振り返り

### 実装完了日
2026-05-15

### 計画と実績の差分

**計画と異なった点**:
- `default_theme.tres` の `premium_card` / `glass_bubble` / `new_best_badge` が古い明色テーマのまま (前ステアリングの out-of-scope) だったため、シーン内に inline StyleBoxFlat (SBF_premium_dark / SBF_glass_dark / SBF_pill_cyan / SBF_pill_gold) を 4 つ追加して `theme_override_styles/panel` でオーバーライド。design.md では theme variation の利用を想定していたが、Midnight Cat 化のためインライン上書きに切替。
- ラウンドドットのアイコンは当初 Material Symbols `circle` を想定したが、Material Symbols Rounded の variable font axis (fill=1) が未設定のため outline で描画されていた。Unicode 文字 `●` / `✕` / `○` (NotoSansJP 標準フォントで描画) に切替。

**新たに必要になったタスク**:
- Midnight Cat 用 StyleBoxFlat の inline 定義 (SBF_premium_dark / SBF_glass_dark / SBF_pill_cyan / SBF_pill_gold)
- xvfb-run 経由でのキャプチャ実行 (headless では SubViewport テクスチャが null になる問題)
- _build_dummy_log 4 ケース実装 (controller 内に集約)

### 学んだこと

**技術的な学び**:
- Godot 4.6 headless 実行では SubViewport のテクスチャが取得できない (dummy renderer)。Xvfb 経由で実 OpenGL レンダラを立ち上げる必要がある (`xvfb-run -a godot --path ... --script ...`)
- Material Symbols Rounded の filled icon を使うには variable font axis fill=1 を設定する必要があり、フォントロード単純設定では outline 表示になる。多目的なシンボルは Unicode で代替したほうが軽量
- `theme_override_styles/panel = SubResource(...)` で PanelContainer のテーマを局所的に書換可能。theme_type_variation を上書き
- PlayEvent のスキーマ拡張 (round_win 追加) は破壊的変更ではなく、未対応の game_type では空配列を返すだけで後方互換

**プロセス上の改善点**:
- `brain-training-ux` skill の調査結果を requirements.md に明示記録したことで、要件レビュー段階での判断根拠が後から追跡可能になった
- キャプチャ検証 (4 ケース) を実装フェーズ内に組み込むことで、視覚的回帰を即座に検知できた

### 次回への改善提案
- `default_theme.tres` 自体に Midnight Cat 用の `premium_dark` / `glass_dark` / `pill_cyan` / `pill_gold` variation を追加すれば、今後の画面はインライン上書き不要になる (別ステアリングとして検討)
- Material Symbols filled icon を一律使えるよう、フォントロード時の `variation_coordinates` 設定を共通化したい
- xvfb 依存のキャプチャ手順を `docs/development-guidelines.md` または `tools/README.md` にメモする
