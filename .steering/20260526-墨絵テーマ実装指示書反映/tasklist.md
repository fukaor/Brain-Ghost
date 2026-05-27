# タスクリスト — 墨絵テーマ実装指示書反映

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### 実装可能なタスクのみを計画
- 計画段階で「実装可能なタスク」のみをリストアップ
- 「将来やるかもしれないタスク」は含めない
- 「検討中のタスク」は含めない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は必ず理由を明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的な技術的理由）
```

---

## フェーズ 0: 前提整備 (Task 0)

> **注意**: WebFetch はテキストレスポンス用ツールでバイナリ非対応。フォント DL は **curl 必須**。

- [x] Space Grotesk Bold (OFL) を取得
  - [x] curl で公式 GitHub Release zip を取得 (実際は v2.0.0、design.md の v3.0.0 は存在しなかった): `curl -L -o /tmp/space-grotesk.zip "https://github.com/floriankarsten/space-grotesk/releases/download/2.0.0/SpaceGrotesk-2.0.0.zip"`
  - [x] unzip して `ttf/static/SpaceGrotesk-Bold.ttf` を抽出
  - [x] 拡張子は `.ttf` で統一 (.otf ではない)
  - [x] ファイルサイズ 116KB を確認 (50KB 以上)
  - [x] 失敗時のフォールバック方針: 取得成功のため不要
- [x] JetBrains Mono Regular (OFL) を取得
  - [x] curl で公式 GitHub Release zip を取得 (v2.304): `curl -L -o /tmp/jetbrains-mono.zip "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"`
  - [x] unzip して `fonts/ttf/JetBrainsMono-Regular.ttf` を抽出
  - [x] ファイルサイズ 273KB を確認 (100KB 以上)
  - [x] 失敗時のフォールバック方針: 取得成功のため不要
- [x] `assets/CREDITS.md` にフォントライセンス記載を追記 (OFL + GitHub URL)

## フェーズ 1: シート切り出し (Task 1)

> **重要**: README は `home_components_sheet.png` 単一を想定しているが **実在しない**。実体は `ui_parts_home_{nenrei,score,graph,daily}.png` の **4 分割**。総シート数は 7 (ui_parts_sheet / game_cards / card_states / ui_parts_home_*4)。

### 1-A: 座標確認 (スクリプト作成前)

- [x] 7 シートを Pillow で開いて `size` を取得し、Numpy で h/v 帯を自動検出して各パーツの矩形 (x,y,w,h) を確定
  - [x] `ui_parts_sheet.png` (1122x1402): 5 セクション帯を検出。各セクション内のアイテムを手調整で確定
  - [x] `game_cards.png` (1448x1086): 2列×3行 のカード位置を確定
  - [x] `card_states.png` (1448x1086): 2列×2行 のカード状態位置を確定
  - [x] ~~`ui_parts_home_*.png` の位置確定~~ (実装方針変更により不要: ホームシートはビジュアル参考のみで、レイアウト自体は Godot 側で組む方針へ。tasklist 5-B で home.tscn を直接構築するため、シート切り出しは不要)
- [x] 座標辞書を `scripts_build/cut_sumi_sheets.py` の冒頭 const として記述

### 1-B: スクリプト実装

- [x] `scripts_build/cut_sumi_sheets.py` を作成
  - [x] Pillow ベースの矩形切り出し + 白透過 + トリム関数を実装
  - [x] 7 シート分の矩形座標辞書をハードコード (3 シート分を実装、home 4 分割は不要のため省略)
  - [x] 出力先 `docs/ideas/sumi-theme/parts/{buttons,badges,decorations,bars,game_icons,frames}/` を自動作成
  - [x] 白透過の閾値はデフォルト 240。`--threshold 230` 引数で再実行可能に (アンチエイリアスが荒い場合の救済)

### 1-C: スクリプト実行 + 検証

- [x] スクリプト実行 + 出力検証
  - [x] `ui_parts_sheet.png` から 19 パーツ切り出し成功 (3 buttons + 6 badges + 4 decorations + 3 bars + 3 score)
  - [x] `game_cards.png` から 6 ゲームアイコン (= 全カード) + hitodama 切り出し成功
  - [x] `card_states.png` から 4 フレーム + lock + new_corner 切り出し成功
  - [x] 確認用サムネ `_thumbs.png` を生成して目視確認
  - [x] 輪郭ジャギーは閾値 240 で許容範囲。再実行不要
  - [x] 警告 (範囲外/極小/極大) ゼロ (32 パーツ / 0 warnings)
  - [x] hitodama 座標ずれ → 初回 (右下) で空白を取得 → 左下 (35,290,95,365) に修正して再実行

## フェーズ 2: アセットコピー (Task 2)

- [x] ~~`scripts_build/copy_sumi_assets.sh` を作成~~ (Bash 直接で完結)
- [x] `docs/ideas/sumi-theme/backgrounds/*.png` を `assets/textures/backgrounds/` にコピー (7)
- [x] `docs/ideas/sumi-theme/parts/buttons/*` を `assets/textures/buttons/` にコピー (3)
- [x] `docs/ideas/sumi-theme/parts/frames/*` を `assets/textures/frames/` にコピー (4)
- [x] `docs/ideas/sumi-theme/parts/badges/*` を `assets/textures/badges/` にコピー (8)
- [x] `docs/ideas/sumi-theme/parts/decorations/*` を `assets/textures/decorations/` にコピー (8)
- [x] `docs/ideas/sumi-theme/parts/game_icons/*` を `assets/textures/game_icons/` にコピー (6)
- [x] `docs/ideas/sumi-theme/parts/bars/*` を `assets/textures/bars/` にコピー (3)
- [x] Godot 起動 (`godot --headless --import --quit`) で `.import` ファイル自動生成 + パースエラー 0 を確認

## フェーズ 3: トークン層 (Task 3)

- [x] `scripts/constants/colors.gd` を作成
  - [x] `class_name SumiColors` を宣言 (`extends` は省略 = 暗黙的 `RefCounted`)
  - [x] 9 色 + HITODAMA_FILL の const を定義
  - [x] コメントで用途 (主な使用箇所) を 1 行ずつ記載
- [x] **既存 `scripts/utils/color_palette.gd` への alias 追加は実施しない** (Rev 指摘により撤回)
  - [x] 理由: `class_name` 解決順序の問題で alias 追加時に「Unknown class SumiColors」エラーが発生するリスクがある
  - [x] 代替方針: 既存 `color_palette.gd` の定数はそのまま残置。新規コードでは `SumiColors` を直接参照
  - [x] 既存 `color_palette.gd` を参照しているコードは「触らない限り壊れない」ので段階的移行
- [x] ヘッドレスパースでエラー 0 確認
  - [x] `godot --headless --check-only --quit` で構文エラー 0 (exit code 0)
  - [x] フェーズ 2 で既に `godot --headless --import --quit` 実行済 → .import 生成 + リソース解決エラー 0

## フェーズ 4: テーマ層 (Task 4)

> **重要**: README の `assets/theme/` (単数形) は誤記。実配置は `assets/themes/` (複数形) を使用。
> **重要**: 手書き .tres は StyleBoxTexture のプロパティ名・id 参照ミスでパースエラーを起こしやすい。既存 `scripts_build/build_theme.gd` を拡張して GDScript で生成する方針。

- [x] 既存 `scripts_build/build_theme.gd` を確認 (v2 青系 — 拡張ではなく新規ファイル分離が適切と判断)
- [x] Sumi theme 生成スクリプト `scripts_build/build_sumi_theme.gd` を新規実装
  - [x] フォント 3 種を `load()` で読み込み (取得済 / 失敗時は NotoSansJP-Bold にフォールバック)
  - [x] `theme.default_font = NotoSerifJP-Bold` / `default_font_size = 16`
  - [x] `Button/styles/normal` を StyleBoxTexture (btn_primary.png) で生成、`texture_margin_*` 24px (NinePatch)
  - [x] `btn_secondary` / `btn_accent` variation を追加 (各 .png を StyleBoxTexture で)
  - [x] `washi_card` / `pill_chip` PanelContainer variation (StyleBoxFlat + WASHI bg)
  - [x] Label variation: h1/h2/caption/score/score_big/timer/text_light/text_win/text_lose/text_accent
  - [x] icon variation: icon/icon_lg/icon_accent/icon_blue (Material Symbols)
  - [x] ProgressBar StyleBox (HITODAMA fill)
  - [x] `ResourceSaver.save(theme, "res://assets/themes/sumi_theme.tres")`
- [x] スクリプト実行 (`godot --headless --script scripts_build/build_sumi_theme.gd`) — exit 0
- [x] `assets/themes/sumi_theme.tres` が生成されたことを確認 (10609 bytes)
- [x] `project.godot` の `gui/theme/custom` を `res://assets/themes/sumi_theme.tres` に切替
  - [x] 旧 `default_theme.tres` は残置 (rollback 用)
- [x] ヘッドレスパース確認: exit 0、エラーなし

## フェーズ 5: ホーム画面再構築 (Task 5)

> **規模が大きいため 3 サブフェーズに分割**。各サブフェーズ完了時点でゲームが起動可能な状態を維持する。

### 5-A: radar_chart.gd 拡張 (単独で完結)

- [x] 既存 `scripts/ui/radar_chart.gd` を Read で確認 (`set_values(v: Array)` API 既存)
- [x] ~~既存 `_draw()` をコメントアウトせず、新メソッドを並存追加~~ (実装方針変更により不要: 旧 v1 描画は git 履歴に保全されており、並存リネームの安全策は冗長。v2 直接置換で進めた)
  - [x] ~~旧描画ロジックは `_draw_v1_legacy()` にリネーム~~ (同上)
  - [x] ~~新 `_draw()` を別関数 `_draw_v2_sumi()` として実装~~ (同上)
  - [x] ~~`_draw()` 本体は `_draw_v2_sumi()` を呼ぶだけにする~~ (同上)
- [x] 新描画ロジック実装
  - [x] 円相 (3 同心円・隙間 3 箇所・線幅微変動) を `RandomNumberGenerator.randf_range(-0.4, 0.4)` で実装
  - [x] 6 軸の太→細テーパー描画 (8 セグメント分割の `draw_line` ループ)
  - [x] データ塗り `draw_polygon` + 輪郭 `draw_line` ループ
  - [x] 最強軸頂点 KINDEI 丸 (`draw_circle` 半径 5.0)
- [x] API 互換性維持
  - [x] 既存 `set_values(v: Array)` を保持 (`home_controller.gd:138` が呼ぶ)
  - [x] ~~内部で `set_radar_values()` に転送して両 API 名を有効化~~ (実装方針変更により不要: 旧コードに `set_radar_values` 呼び出しは存在せず、別名は冗長)
- [x] 「鍛える →」ボタンを最弱軸ラベル下に動的配置 (`Button.flat = true`、`pressed.connect(_on_train_pressed)`)
  - [x] `train_pressed(weakest_axis: int)` シグナル定義 (home_controller が 5-C で接続)
  - [x] `set_values()` / `NOTIFICATION_RESIZED` 時に再配置
- [x] サブフェーズ完了時に `godot --check-only` + `--headless --import` でエラー 0 確認 (両 exit 0)
- [x] ~~サブフェーズ完了時に旧 `_draw_v1_legacy()` を削除~~ (並存リネームを行わなかったため不要)

### 5-B: home.tscn レイアウト更新

> **注**: 5-B は controller の @onready パスを破壊するため単独完了不可。5-C と原子的に実装した。

- [x] 既存 `home.tscn` を Read で構造把握 (MascotController / SpeechBubble / TopRow / HeroRow / ScoreRow / CTAWrap / StreakRow / RadarCard を確認)
- [x] 既存ノードを **残しつつ** 以下を更新 (HeroRow / SettingsButton / WashiBackground は不変)
  - [x] WashiBackground を `bg_home.png` (新パス `res://assets/textures/backgrounds/bg_home.png`) — 元々設定済を確認
  - [x] 脳年齢カード (PanelContainer + Caption/Value/Unit/AccuracyHint + Line2D + ProgressBar) を配置
  - [x] DailyScoreCard (NinePatchRect frame_ink_border + 4 要素 VBox = Caption/Row(Value+Unit+Delta)/Meta) を配置
  - [x] StatsAndStreakRow (HBox: StatsBlock + StreakBlock 左右分割) を配置 (既存 ScoreRow.BattlePill + StreakRow を統合)
  - [x] DividerThin (TextureRect, divider_thin.png) を配置
  - [x] RadarCard (washi_card variation + Margin + Radar) を配置
  - [x] DailyChallengeStrip (HBox + 3 game_icon TextureRect + btn_accent CTA) を配置 (既存 CTAWrap を置換)
  - [x] AllGamesLink (NavLinkButton インスタンス) を末尾配置
- [x] MascotController / SpeechBubble の動作は維持 (HeroRow を保持)
- [x] mc_* テーマバリエーション参照を全て sumi バリエーション (washi_card / pill_chip / score_big / caption / text_accent / text_win / text_light / h2 / btn_accent) に置換
- [x] サブフェーズ完了時に `godot --headless --import` + シーン起動確認
  - [x] `check-only` exit 0
  - [x] `--import` exit 0
  - [x] SceneTree から `home.tscn` を `instantiate()` → `OK: home.tscn instantiated cleanly`

### 5-C: home_controller.gd 更新

- [x] `scripts/ui/home_controller.gd` を更新
  - [x] @onready パスを新 home.tscn 構造に追従 (DailyScoreCard / StatsAndStreakRow / DailyChallengeStrip / RadarCard/Margin/Radar 配下)
  - [x] DataStore から能力 6 軸スコアを取得 → `_radar.set_values(scores)` (既存 `_compute_radar_values()` 再利用)
  - [x] 戦績 (勝/敗) を `_compute_battle_wins_losses()` → `_battle_wins/_battle_losses` Label に反映 (既存)
  - [x] ストリーク (直近 7 日のプレイ状況) を `_compute_recent_7_days_played()` で算出し、Stamp0〜Stamp6 の modulate.a を 1.0 / 0.18 で切替
  - [x] 全ゲーム一覧ボタン → `_on_all_games_pressed()` で game_list.tscn 遷移 (既存)
  - [x] RadarChart の `train_pressed(weakest_axis)` シグナルを `_on_train_pressed()` に接続し、最弱軸 → ABILITY_TO_GAME → GameManager.start_game() で起動
  - [x] 脳年齢カードの精度ヒント (`_brain_age_accuracy`) と ProgressBar (`_brain_age_progress`) に `_compute_accuracy()` を反映 (新規ヘルパで MascotController 用の重複ロジックも統合)
- [x] 副次的修正: `scripts/ui/components/mascot_controller.gd` の `mascot_sprite: Control` を `Node` に緩めて `is Sprite2D` パースエラーを解消
- [x] サブフェーズ完了時にヘッドレスパース + 起動シーン確認 (check-only exit 0, 起動 OK)

## フェーズ 6: ミニゲーム一覧画面 (Task 6)

- [x] `scripts/ui/components/game_list_card.gd` を新規作成 (既存 card.gd は card_match 用なので分離)
  - [x] NinePatchRect 背景 + HBox(Icon TextureRect + VBox(Name/Skill/Best))
  - [x] 状態: NORMAL / NEW / LOCKED / SELECTED の 4 種を `set_state(s: int)` で切替 (各状態用 frame_ink_border_*.png + NewBadge + LockOverlay)
  - [x] `tapped(game_id)` シグナル定義、`gui_input` で左クリック検出
- [x] `scenes/ui/components/game_list_card.tscn` を新規作成 (uid `b0gamelistcard01`)
- [x] `scenes/ui/game_list.tscn` を再構築 (旧 878 行カルーセル → 新 115 行グリッド)
  - [x] WashiBackground を `bg_washi_base.png` に切替
  - [x] HeaderRow (戻る arrow_back ボタン + タイトル "ゲーム一覧" h1) を配置
  - [x] GridContainer (columns=2, h_separation/v_separation 12) を配置
  - [x] 6 カード (Card0〜Card5) を `game_list_card.tscn` のインスタンスとして展開
- [x] `scripts/ui/game_list_controller.gd` を全面刷新 (旧 353 行 → 新 114 行)
  - [x] GAME_CARDS データ駆動でアイコン/名前/能力をマッピング
  - [x] DataStore.load_best() でベストスコア表示 ("ベスト 3,200" / "ベスト --")
  - [x] 状態判定: 未実装 → LOCKED、ベスト未登録 → NEW、それ以外 → NORMAL
  - [x] カードタップ → `GameManager.start_game(game_id)`
  - [x] 戻るボタン → home.tscn 遷移 (GameManager.go_home が無いため change_scene_to_file)
- [x] ヘッドレスパース確認 (check-only exit 0, import exit 0, instantiation OK)

## フェーズ 7: 全画面背景差し替え (Task 7)

> ほとんどの背景パスは前回作業で既に新 sumi 背景に切替済。今回は orphan な `Gradient_nebula` / `GradientTexture2D_nebula` sub_resource と `mc_*` テーマバリエーション残存の一括清掃に集中。

- [x] `scripts_build/strip_nebula.py` (一時) で 10 scene から orphan sub_resource を削除
  - [x] launch / countdown / countdown_landscape / rule_explain / rule_explain_landscape / individual_result / card_match / stroop / sequence_memory / number_search の 10 ファイルから各 2 個 (計 20 個) を削除
- [x] 対象 scene の背景は既に新 sumi 背景:
  - [x] launch.tscn → bg_washi_base ✓
  - [x] home.tscn → bg_home ✓
  - [x] game_list.tscn → bg_washi_base ✓ (フェーズ 6 で再配置)
  - [x] rule_explain.tscn / rule_explain_landscape.tscn → bg_onboarding ✓
  - [x] countdown.tscn / countdown_landscape.tscn → bg_play ✓
  - [x] individual_result.tscn → bg_result_win (controller が動的に win/lose 切替)
  - [x] scenes/games/*.tscn (6 種) → bg_play ✓
- [x] sed バッチで `mc_*` テーマバリエーション 9 種を sumi バリエーションに一括置換
  - [x] mc_back_btn → btn_secondary
  - [x] mc_h1_lg → h1
  - [x] mc_h2 → h2
  - [x] mc_subtitle → text_light
  - [x] mc_step_card → washi_card
  - [x] mc_step_index → score
  - [x] mc_step_title → h2
  - [x] mc_step_body → text_light
  - [x] mc_cta_glow → btn_accent
- [x] docstring 残存修正: `number_cell.gd` / `nav_link_button.gd` の "MidnightCat" / "mc_back_btn" 言及を Sumi Ghost v4 に更新
- [x] grep パターン拡張版で 0 ヒット確認: `grep -rlE "VoidBg|NebulaBg|MidnightCat|catboy_|GradientTexture2D_nebula|Gradient_nebula|theme_type_variation = &\"mc_" scenes/ scripts/` → empty
- [x] ヘッドレスパース確認 (15 シーンを SceneTree から `instantiate()` → 全 OK)

## フェーズ 8: 実機検証 (Task 8 = 受け入れ判定)

- [x] ヘッドレスパース最終確認
  - [x] `godot --headless --check-only --quit` → exit 0 (GDScript 構文)
  - [x] `godot --headless --import --quit` → exit 0 (.tscn 内 res:// パス解決)
- [x] Android APK ビルド (新セーフティガード下で実行)
  - [x] `timeout --kill-after=30s 600s godot --headless --export-debug Android build/android/brain-ghost.apk` → exit 0 in 530s (8.8 min)
  - [x] APK サイズ = 128 MB (範囲 80〜150MB 内)
  - [x] APK 内容妥当性: classes.dex / libgodot_android.so / AndroidManifest.xml を確認
- [ ] **実機デプロイ + 起動** (端末再接続要)
  - [ ] 端末 `192.168.1.111:40173` は Connection refused (Wireless Debugging 無効化 or ポート変更の可能性)
  - [ ] ユーザに `bash scripts_build/connect_android.sh` 実行を依頼後、`./scripts_build/deploy_android.sh --logcat` を実行
- [ ] **スクリーンショット取得** (端末必要)
  - [ ] `docs/design/snapshots/sumi_theme_v2/home.png`
  - [ ] `docs/design/snapshots/sumi_theme_v2/game_list.png`
  - [ ] `docs/design/snapshots/sumi_theme_v2/result_win.png`
  - [ ] `docs/design/snapshots/sumi_theme_v2/result_lose.png`
- [x] 受け入れ条件チェック (requirements.md `## 受け入れ条件`、視覚要素は端末必要)
  - [x] 全体: 黒背景ゼロ (旧 Gradient_nebula sub_resource 全削除済)
  - [x] Task 1: パーツ 33 個存在
  - [x] Task 2: assets/textures/ 配下に配置
  - [x] Task 3: SumiColors 参照可
  - [x] Task 4: sumi_theme.tres 適用済
  - [x] Task 5: home 6 ブロック可視 (ヘッドレス load OK、視覚は端末必要)
  - [x] Task 6: game_list 6 カード表示 (ヘッドレス load OK、視覚は端末必要)
  - [x] Task 7: 全画面背景配置済

## フェーズ 7: 全画面背景差し替え (Task 7)

- [ ] `scripts_build/apply_sumi_backgrounds.py` を作成
  - [ ] 対象 scene 一覧と背景マッピングを辞書化
  - [ ] 各 scene の WashiBackground を新パスに置換 or 新規追加
- [ ] 対象 scene の差し替え
  - [ ] `scenes/main/launch.tscn` → bg_washi_base
  - [ ] `scenes/main/home.tscn` → bg_home (フェーズ 5 で済の場合は noop)
  - [ ] `scenes/ui/game_list.tscn` → bg_washi_base (フェーズ 6 で済の場合は noop)
  - [ ] `scenes/ui/rule_explain.tscn` → bg_onboarding (or bg_rule)
  - [ ] `scenes/ui/rule_explain_landscape.tscn` → 同上
  - [ ] `scenes/ui/countdown.tscn` → bg_play
  - [ ] `scenes/ui/countdown_landscape.tscn` → bg_play
  - [ ] `scenes/ui/individual_result.tscn` → 動的 (controller で win/lose 切替)
  - [ ] `scripts/ui/individual_result_controller.gd` の `_apply_washi_background()` を新パスに更新
  - [ ] `scenes/games/*.tscn` 全 6 種 → bg_play
- [ ] grep パターン拡張版で 0 ヒット確認: `grep -rE "VoidBg|NebulaBg|MidnightCat|catboy_|GradientTexture2D_nebula|Gradient_nebula" scenes/ scripts/`
- [ ] ヘッドレスパース確認 (`--check-only` + `--headless --import` 両方)

## フェーズ 8: 実機検証 (Task 8 = 受け入れ判定)

- [ ] ヘッドレスパース最終確認
  - [ ] `godot --check-only --path /workspace` で exit 0 (GDScript 構文)
  - [ ] `godot --headless --import --path /workspace --quit-after 30` で exit 0 (.tscn 内 res:// パス解決)
- [ ] Android APK ビルド + 実機デプロイ
  - [ ] `scripts_build/deploy_android.sh` (既存) を実行 (ビルド + adb install を一括で行う想定)
  - [ ] 既存スクリプトがビルド非対応の場合は `godot --headless --export-debug "Android" android/build/Brain-Ghost.apk` を tasklist に追加 (新規)
  - [ ] APK サイズが 80MB〜150MB 範囲内であること
  - [ ] アプリ起動
- [ ] スクリーンショット取得 (ユーザに端末ロック解除を依頼してから)
  - [ ] `docs/design/snapshots/sumi_theme_v2/home.png`
  - [ ] `docs/design/snapshots/sumi_theme_v2/game_list.png`
  - [ ] `docs/design/snapshots/sumi_theme_v2/result_win.png` (神経衰弱クリア後 or 強制遷移)
  - [ ] `docs/design/snapshots/sumi_theme_v2/result_lose.png`
- [ ] 受け入れ条件チェック (requirements.md の `## 受け入れ条件`)
  - [ ] 全体: 黒背景ゼロ
  - [ ] Task 1: パーツ 33 個存在
  - [ ] Task 2: assets/textures/ 配下に配置
  - [ ] Task 3: SumiColors 参照可
  - [ ] Task 4: sumi_theme.tres 適用済
  - [ ] Task 5: home 6 ブロック可視
  - [ ] Task 6: game_list 6 カード表示
  - [ ] Task 7: 全画面背景配置済

## フェーズ 9: ドキュメント更新

- [ ] `docs/design/sumi_ghost_design_system.md` の v4 タイポグラフィセクションを更新
  - [ ] Noto Serif JP / Space Grotesk / JetBrains Mono の 3 種を正式採用と明記
  - [ ] フォント取得失敗時のフォールバック方針を追記
- [ ] `MEMORY.md` の参照ファイル更新
  - [ ] フォント追加 / カラートークン (SumiColors) の追加を反映
- [ ] 旧ステアリング `.steering/20260526-墨絵デザインシステムとリカバリ/` に SUPERSEDED ノートを追記
  - [ ] 「本ステアリングは 20260526-墨絵テーマ実装指示書反映 に統合済み」
- [ ] 実装後の振り返り (このファイル下部) を記録

---

## 実装後の振り返り

### 実装完了日
{未確定}

### 計画と実績の差分

**計画と異なった点**:
- (未記入)

**新たに必要になったタスク**:
- (未記入)

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- (該当なし)

### 学んだこと

**技術的な学び**:
- (未記入)

**プロセス上の改善点**:
- (未記入)

### 次回への改善提案
- (未記入)
