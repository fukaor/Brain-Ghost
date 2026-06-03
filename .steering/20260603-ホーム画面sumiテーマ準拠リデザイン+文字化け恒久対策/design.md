# 設計書

## アーキテクチャ概要

**「算出はコントローラ・表示はコンポーネント」の分離**を採用する。

- `home_controller.gd` は現状のデータ算出ロジック（脳年齢/累積スコア/今日デルタ/通算戦績/ストリーク/レーダー値）をそのまま保持する。
- 表示は README チケットの8コンポーネントに分割し、各コンポーネントは `@export` プロパティ + setter + signal の公開APIのみを持つ表示専用ノードにする。
- コントローラは深いノードパス参照（現状）をやめ、コンポーネントの公開API経由でデータをバインドし、signal を受けて画面遷移する。

```
home.tscn (Control + WashiBackground + SafeArea/MainColumn)
  ├─ TopRow:  BrainAgeCard(component)        + SettingsButton(既存維持)
  ├─ HeroRow: MascotController/Mascot/Speech (既存維持)
  ├─ DailyScoreCard(component)
  ├─ GhostRecordStrip(component)             ← 戦績 + ストリーク(朱印スタンプ)
  ├─ SumiDivider(component)
  ├─ RadarCard: SumiRadarChart(component)    ← 既存 radar_chart.gd を昇格/整理
  ├─ DailyChallengeStrip(component)          + glow CTA(既存維持)
  └─ AllGamesLink (SumiButton SECONDARY or 既存 nav_link)

home_controller.gd
  - _apply_data(): 算出 → 各コンポーネントの setter / @export へ流し込み
  - signal 配線: DailyChallengeStrip.start_pressed / SumiRadarChart.train_pressed(weakest) / AllGames.pressed
```

## コンポーネント設計

共通規約（README 0-1 準拠）:
- ベースは Control 系。`@export` でデータ/テクスチャ注入可。signal はスクリプト冒頭で宣言。
- 座標(position/offset)ハードコード禁止。Container 構造で相対配置。
- 色は `SumiColors`（`scripts/constants/colors.gd`）定数。直リテラル禁止。
- テーマは `res://assets/themes/sumi_theme.tres`（※README の `assets/theme/` は誤記。project.godot 配線済みの `assets/themes/` を正とする）。
- 汚染パーツ（frame_ink_border/game_icon_*/btn_*/divider_*/hitodama/arrow_*/icon_lock/bar_fill_*）は texture 使用禁止。StyleBoxFlat / `_draw()` / Material Symbols / テキスト記号で代替。将来差し替え用に `@export var texture_*` を用意。

### 1. BrainAgeCard (2-1)
- PanelContainer(washi_card)。`@export brain_age:int`, `accuracy:float`。「脳年齢」キャプション/大数字/「歳」/乾筆アンダーライン(ColorRect or Line2D)/精度ProgressBar+ラベル。
- 参照: `references/ui_parts_home_nenrei.png`。

### 2. DailyScoreCard (2-2)
- PanelContainer。`@export score:int, score_diff:int, brain_age:int, wins:int, losses:int`。「3,230 pts」/「↑ +285」(WAKATAKE)/「脳年齢: 31歳」/勝○負×記号。差し替え用 `texture_frame`。
- 参照: `references/ui_parts_home_score.png`。

### 3. GhostRecordStrip (2-3)
- HBoxContainer。左=戦績(通算/N勝(SUMI_DARK)/N敗(SUMI_LIGHT))、右=ストリーク(朱印スタンプ7個 + 「N日連続！」)。
- スタンプは確認済みクリーンな `stamp_shuin.png` を当日点灯、過去は alpha 減衰、未プレイは alpha 最小（現 home の方式を踏襲）。`@export total_wins, total_losses, streak_days, streak_stamps:Array[bool]`。
- 参照: `references/daily_challenge_strip.png` 下段(戦績)・`ui_parts_sheet.png` 連勝。

### 4. SumiRadarChart (2-4)
- Control + `_draw()` のみ。既存 `scripts/ui/radar_chart.gd` を仕様(円相同心円/先細り軸/HITODAMA_FILL塗り/KINDEI最強軸/6軸ラベル/「鍛える →」)に整理して昇格。`@export values:Array[float]`。signal `train_pressed(axis:int)`（既存は同名signalを使用）。
- 参照: `references/ui_parts_home_graph.png`。

### 5. DailyChallengeStrip (2-5)
- PanelContainer or HBox。「今日のチャレンジ」+ 3ゲーム枠(Material Symbols/emoji + 名前) + 「始める」アクセントボタン。`@export challenge_games:Array`。signal `start_pressed()`。既存 glow CTA は home 側で重畳維持。
- 参照: `references/ui_parts_home_daily.png` / `daily_challenge_strip.png`。

### 6. GameListCard (2-6)
- 既存 `scenes/ui/components/game_list_card.tscn` を README 仕様に合わせて整理（Material Symbols アイコン化・normal/locked/selected・hover/press tween・`@export` 群・signal `card_pressed(game_id)`）。
- 参照: `references/game_cards.png` / `card_states.png`。

### 7. SumiDivider (2-7)
- ColorRect ベース。`@export thickness, divider_color, divider_alpha, texture_override`。

### 8. SumiButton (2-8)
- Button ベース。`@export enum {PRIMARY, SECONDARY, ACCENT}` + `label_text` + `texture_bg`。hover alpha / pressed scale tween。テーマの btn_* variation と整合。

## データフロー

### ホーム表示
```
1. home_controller._ready() → _wire_signals() / _apply_data()
2. _apply_data(): DataStore/GhostData から算出（既存ロジック流用）
3. 算出結果を各コンポーネントの setter/@export へ set
4. ユーザー操作: CTA→start_pressed→GameManager.start_game("ghost_7ban_shobu")
   レーダー鍛える→train_pressed(weakest)→ABILITY_TO_GAME 経由 start_game
   全ゲーム→change_scene_to_file("res://scenes/ui/game_list.tscn")
```

## エラーハンドリング戦略
- autoload(DataStore/GameManager) は `get_node_or_null` でガードする既存方針を踏襲（`--script` 単体キャプチャでも落ちないように、コンポーネント側は autoload 非依存にする）。
- コンポーネントは表示専用でデータ取得しない（依存をコントローラに集約）。

## テスト戦略
### 検証（GUTユニットではなく描画キャプチャ主体）
- 各コンポーネント単体を SubViewport にロードしてキャプチャ → リファレンスと目視比較（`xvfb-run -a godot --rendering-driver opengl3 --path . --script <snap>.gd`）。
- ホーム全体キャプチャ：文字化け(豆腐/生テキスト)が無いこと、レイアウトがリファレンス整合。
- 既存 GUT テストがあれば回帰確認（`scripts_build/run_unit_tests.sh`）。

## ディレクトリ構造
```
scenes/ui/components/
  brain_age_card.tscn / daily_score_card.tscn / ghost_record_strip.tscn
  sumi_radar_chart.tscn / daily_challenge_strip.tscn / game_list_card.tscn(整理)
  sumi_divider.tscn / sumi_button.tscn
scripts/ui/
  brain_age_card.gd / daily_score_card.gd / ghost_record_strip.gd
  sumi_radar_chart.gd / daily_challenge_strip.gd / game_list_card.gd(整理)
  sumi_divider.gd / sumi_button.gd
  home_controller.gd (コンポーネントAPI経由に書き換え)
scenes/main/home.tscn (コンポーネントインスタンスで再構成)
.devcontainer/setup-claude.sh (chown .godot + headless import 追加)
tools/snap_components.gd (新規: コンポーネント単体キャプチャ補助)
```

## 実装の順序
1. Phase A: 文字化け恒久対策（devcontainer + 検証ループ確立） ← 先に土台を固める
2. Phase B: コンポーネント8つを 1チケットずつ生成 → 単体キャプチャ検証 → 人間確認
3. Phase C: home.tscn 再アセンブリ + home_controller.gd 書き換え → ホーム全体キャプチャ検証
4. Phase D: 仕上げ（背景確認・回帰・振り返り）

## パフォーマンス考慮事項
- `_draw()` レーダーは _process で毎フレーム再描画しない（値変更時のみ `queue_redraw()`）。
- スタンプ等の TextureRect は既存クリーンパーツのみ。新規画像追加は最小化。

## 将来の拡張性
- 各コンポーネントの `@export var texture_*` により、クリーンパーツが用意でき次第エディタからドラッグ差し替え可能（README Appendix の差し替えフローに準拠）。
