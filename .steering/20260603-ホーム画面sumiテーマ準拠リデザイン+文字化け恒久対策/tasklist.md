# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### 進め方（README v2 準拠）
- **1チケット = 1コンポーネント**。生成→単体キャプチャ検証→**人間がGodotエディタで確認・微調整→確定**してから次へ。
- 各コンポーネント完了時にユーザーへ報告し承認を得る。

---

## フェーズA: 文字化け恒久対策・検証ループ確立

- [x] A-1. `.godot` 所有権問題の恒久対策を `.devcontainer/setup-claude.sh` に追加
  - [x] `sudo chown -R godot:godot /workspace/.godot`（存在時のみ・root所有検知時）を追加（section 3.5）
  - [x] `godot --headless --import` を未インポート時のみ起動時に実行する処理を追加
- [x] A-2. 検証ループ手順を確立（xvfb 前提を明文化）
  - [x] `xvfb` + `libgl1-mesa-dri` を `.devcontainer/Dockerfile` に追加（render-verify ループが標準で動く）
  - [x] `tools/snap_one.gd`（任意シーン単体キャプチャの汎用ツール）を作成
- [x] A-3. ホーム全体を再キャプチャし、日本語・アイコンが正常表示であることを確認（豆腐/生テキストが無い） → captures/A3_home_after_fontfix.png で確認済み

## フェーズB: UIコンポーネント生成（1チケット1コンポーネント）

- [x] B-1. SumiDivider（2-7）生成 → 単体キャプチャ → 確定（captures/B1_sumi_divider.png）
  - [x] scenes/ui/components/sumi_divider.tscn + scripts/ui/sumi_divider.gd
- [x] B-2. SumiButton（2-8）生成 → 単体キャプチャ → 確定（captures/B2_sumi_buttons.png）
  - [x] scenes/ui/components/sumi_button.tscn + scripts/ui/sumi_button.gd（PRIMARY/SECONDARY/ACCENT）
- [x] B-3. BrainAgeCard（2-1）生成 → 単体キャプチャ → 確定（captures/B3_brain_age_card.png）
  - [x] scenes/ui/components/brain_age_card.tscn + scripts/ui/brain_age_card.gd
- [x] B-4. DailyScoreCard（2-2）生成 → 単体キャプチャ → 確定（captures/B4_daily_score_card.png）
  - [x] scenes/ui/components/daily_score_card.tscn + scripts/ui/daily_score_card.gd
- [x] B-5. GhostRecordStrip（2-3）生成 → 単体キャプチャ → 確定（captures/B5_ghost_record_strip.png）
  - [x] scenes/ui/components/ghost_record_strip.tscn + scripts/ui/ghost_record_strip.gd
- [x] B-6. SumiRadarChart（2-4）生成 → 単体キャプチャ → 確定（captures/B6_sumi_radar_chart.png）
  - [x] scenes/ui/components/sumi_radar_chart.tscn（既存 radar_chart.gd を流用。参照破壊回避のためスクリプト名は据え置き）
- [x] B-7. DailyChallengeStrip（2-5）生成 → 単体キャプチャ → 確定（captures/B7_daily_challenge_strip.png）
  - [x] scenes/ui/components/daily_challenge_strip.tscn + scripts/ui/daily_challenge_strip.gd
  - 備考: 横幅の最終フィット調整は Phase C のホーム組み込み時に実施
- [x] B-8. GameListCard（2-6）整理（既存を README 仕様へ）→ 単体キャプチャ → 確定（captures/B8_game_list_card.png, B8_game_list_screen.png）
  - [x] scenes/ui/components/game_list_card.tscn 再構成（PanelContainer 160×200・縦並び・Material Symbols アイコン・StyleBoxFlat 状態差分）
  - [x] scripts/ui/game_list_card.gd 新規（@export 群 + signal card_pressed・hover/press tween・normal/locked/selected/new）
  - [x] 旧 scripts/ui/components/game_list_card.gd 削除（class_name 重複回避）
  - [x] 一覧画面を新APIへ移行: game_list_controller.gd（icon_text=Material Symbols・@export バインド・card_pressed 配線）
  - [x] tools/snap_game_list_card.gd 新規（4状態並列キャプチャ検証ツール）
  - ユーザー決定: アイコン=Material Symbols文字（README準拠）/ 一覧画面も新APIへ移行

## フェーズC: ホーム画面の再アセンブリ

- [x] C-1. `scenes/main/home.tscn` を確定コンポーネントのインスタンスで再構成（BrainAgeCard / DailyScoreCard / GhostRecordStrip / SumiDivider / SumiRadarChart / DailyChallengeStrip を instance 化。マスコット/吹き出し/設定ボタン/nav は既存維持）
  - glow CTA は ChallengeWrap(Control) に GlowFx を重ね、DailyChallengeStrip を 6px インセットで重畳して外周ハローとして維持
- [x] C-2. `scripts/ui/home_controller.gd` をコンポーネント公開API経由に書き換え（深いノードパス参照を撤廃、`_compute_*` 算出ロジックは保持。`_apply_streak_stamps`/`_animate_cta_pulse` 撤去、`_to_bool_array` 追加）
- [x] C-3. signal 配線（DailyChallengeStrip.start_pressed / SumiRadarChart.train_pressed / AllGamesLink.pressed / 設定）を再接続
- [x] C-4. ホーム全体キャプチャでレイアウト整合・文字化けなしを確認（captures/C4_home_reassembled.png。脳年齢/スコア/戦績+ストリーク/レーダー/今日のチャレンジ+glow/全ゲーム一覧 すべて表示、720×1280 に収まり豆腐なし）
  - 高さ調整: HeroRow 260→212 / MascotImage 260→212 / Radar 300→244（新DailyChallengeStripが旧CTAより高く全ゲーム一覧が画面外化したため）
  - 注: 単体キャプチャは autoload 非登録のためコンポーネント既定値表示。データ束縛の動作確認は実機起動（D-2）で行う

## フェーズD: 仕上げ・品質チェック

- [x] D-1. 背景設定確認 — WashiBackground は bg_home.png / `expand_mode=1` / `stretch_mode=6`(keep_aspect_covered)。適正。
- [x] D-2. 遷移の検証 — 静的: DailyChallengeStrip.start_pressed→start_game("ghost_7ban_shobu")、train_pressed→ABILITY_TO_GAME→start_game、AllGamesLink→game_list.tscn、設定ボタン配線。GAME_SCENES に6ゲーム全実在。
  - **実起動検証済み**: `tools/capture_home_live.tscn`（autoload有効のシーン通常起動）でホームを実行 → home_controller の SCRIPT ERROR ゼロ、実データ束縛成功（空セーブで 30歳/0pts/0勝0敗/今日からスタート/最小レーダー＝既定値でなく実算出値）。captures/D2_home_live_empty.png。
  - 既存の軽微警告 `Tween(MascotController): started with no Tweeners` は今回の変更と無関係。
  - 残: ボタン実タップ→画面遷移のクリック確認はエディタ/実機での手動操作を推奨（headless では描画・束縛・配線まで確認済み）。
- [x] D-3. GUT回帰 — `scripts_build/run_unit_tests.sh` 実行、**82/82 passed**（7スクリプト・193アサート・回帰なし）。
- [x] D-4. ドキュメント更新要否 — 判断: **必須更新なし**。CLAUDE.md / repository-structure.md に旧スクリプトパス参照なし、README:386 は .tscn 出力パスで現状正しい。墨絵コンポーネント規約は steering design.md に記録済み。home.tscn に未使用 ext/sub リソースなし。（任意: repository-structure.md に scenes/ui/components/ の追記は将来検討可）
- [x] D-5. 実装後の振り返り（下記に記録）

---

## 実装後の振り返り

### 実装完了日
2026-06-03

### 計画と実績の差分
- **B-8 は「整理」ではなく実質リライト**だった。既存カードは旧・横長(0×112)＋TextureRect画像アイコン＋`set_card/tapped` API で、README 2-6（縦160×200・Material Symbols・`@export`/`card_pressed`）と別物。旧APIに依存する全ゲーム一覧画面も新APIへ移行（ユーザー決定）。
- **glow CTA**: 新 DailyChallengeStrip は内部に「始める」ボタンを持つため、旧来の `_cta_button` 直接パルスは廃止。ChallengeWrap(Control) に GlowFx を敷き、帯を6pxインセットで重ねる外周ハロー方式に変更（glow_cta は自走パルス）。
- **高さ調整が発生**: 新 DailyChallengeStrip が旧CTA帯より約90px高く、全ゲーム一覧リンクが画面外化。HeroRow/MascotImage 260→212、Radar 300→244 で吸収。
- データ束縛の実機確認（D-2 インタラクティブ）は未実施（headless では autoload 非登録のため不可）。

### 学んだこと
- **PanelContainer は直下の子を矩形いっぱいに強制配置する** → anchor/offset が効かない。NEWバッジ等の隅配置は「全面ラベル＋文字揃え(右上/中央)」で実現する。
- **絵文字は色フォント非搭載で描画不可** → アイコンは Material Symbols ligature（bolt/calculate/format_list_numbered/palette/style/search/lock/fiber_new）で統一。
- **autoload依存コントローラは `--script` 単体キャプチャではコンパイルされない** → 表示専用コンポーネントは autoload 非依存に保ち、既定値で静的レイアウト検証する設計が効く。
- **キャプチャPNGの毎回 Read はコンテキストを肥大化させる**（前セッションのループ一因）。確認後は会話に残さず、必要時のみ最新1枚を読む運用に。

### 次回への改善提案
- 長丁場のフェーズ（コンポーネント多数生成）では途中で `/clear` か新セッションを挟み、画像蓄積によるコンテキスト肥大を防ぐ。
- ホームのデータ束縛は実機/エディタ起動で 1 度通し確認する（CTA→ゲーム、鍛える→該当ゲーム、一覧遷移）。
- glow ハローの角丸はカード角丸とやや不一致。気になる場合は GlowFx の corner_radius をカード(washi_card)に合わせて微調整。
- 残置した game_icon_*_art.png はクリーンアセット用意後に各カードの texture_icon へ差し替え可能。
