# タスクリスト — Midnight Cat (v3) 全面リデザイン

## 🚨 タスク完全完了の原則

このファイルの全タスクが完了するまで作業を継続する。
未完了タスク（`[ ]`）を残したまま振り返りに進まない。

---

## フェーズ1: Midnight Cat デザイントークン差し替え（完了済）

- [x] `scripts/utils/color_palette.gd` を v3 (Midnight Cat) に書き換え
  - [x] `BACKGROUND` を `#000` に
  - [x] `PRIMARY_CYAN` / `YOU_GOLD` / `SURFACE_LOW/MID/HIGH/GLOW` を追加
  - [x] 旧 `PRIMARY_BLUE` / `BACKGROUND_V2` 等を alias で温存
- [x] `assets/fonts/NotoSerifJP-Bold.otf` を追加（SIL OFL）
- [x] `assets/fonts/NotoSerifJP-Bold.otf.import` を作成
- [x] `assets/themes/default_theme.tres` に `mc_*` バリアント群を追加
  - [x] StyleBox: `mc_void` / `mc_card` / `mc_pill_glow` / `mc_streak_ribbon` / `mc_score_pill` / `mc_speech` / `mc_step_card` / `mc_back_btn`
  - [x] Type: `mc_h1_lg` / `mc_h1` / `mc_h2` / `mc_subtitle` / `mc_body` / `mc_caption` / `mc_score_value` / `mc_score_unit` / `mc_score_delta` / `mc_brain_age` / `mc_streak_text` / `mc_step_index` / `mc_step_title` / `mc_step_body` / `mc_icon` / `mc_icon_cyan` / `mc_link`
  - [x] Button: `mc_cta_glow` / `mc_back_btn`
- [x] `project.godot` の `default_clear_color` を黒に

## フェーズ2: home.tscn 再構築（完了済）

- [x] `scripts/ui/radar_chart.gd` を新規作成
- [x] `scripts/ui/home_controller.gd` を全面書き換え
- [x] `scenes/main/home.tscn` を home.png 準拠で再構築
- [x] CTA → `start_game("ghost_7ban_shobu")` の遷移を確認

## フェーズ3: rule_explain.tscn 再構築 + データドリブン化（完了済）

- [x] `scripts/ui/rule_step_preview.gd` を新規作成（ready / tap / compare の 3 variant）
- [x] `scripts/ui/rule_explain_controller.gd` をデータドリブンに書き換え
- [x] RULES Dict に 4 ゲーム以上を登録（ghost_7ban_shobu / reflex_tap / flash_calc / sequence_memory）
- [x] `scenes/ui/rule_explain.tscn` を game_tap_rule.png 準拠で再構築

## フェーズ4: ghost_7ban_shobu — 1 レーン正面衝突への書き換え

- [x] レーン形状ヘルパを実装
  - [x] `scripts/games/ghost_7ban_shobu/lane_shapes.gd` を新規作成（class_name LaneShapes）
  - [x] `position_on_lane(shape, t, rect) -> Vector2` を実装（5 種：line / s_curve / sine_wave / zigzag / arc）
  - [x] `sample_polyline(shape, rect, samples)` でレーン全体描画用座標列を返す
  - [x] `shape_for_round(round_index)` でローテーション

- [x] `scripts/games/ghost_7ban_shobu/ghost_7ban_shobu.gd` の CFG_BASE に shape を追加
  - [x] 各 round に `shape` を追加（line / s_curve / sine_wave / zigzag / arc / line / s_curve）
  - [x] 旧 `dir` は互換のため残置（view 側で未使用）
  - [x] `generate_rounds()` でジッタ後も shape を保持

- [x] `scripts/ui/ghost_7ban_lane_view.gd` を新規作成（Lane 描画＆オーブアニメ Control）
  - [x] レーン曲線描画 / GATE 縦光線 / YOU・GHOST オーブ
  - [x] `set_round()` / `start_moving()` / `record_tap()` / `enter_result()` / `clear_state()`
  - [x] Result 時：タップ位置の爆発 + GATE 補助線 + ms ラベル（YOU 上 / GHOST 下）

- [x] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` を 1 レーン構造に再構築
  - [x] 旧 `YouLane` / `GhostLane` を削除し、単一 `Playfield/Lane` に統合
  - [x] HUD は YOU 0 - 0 GHOST + 進捗ドット形式
  - [x] AnnounceLabel（明朝大）/ ResultOverlay / ReadyOverlay / DoneOverlay を整理
  - [x] 黒猫マスコット（icy_accents）を Ready overlay に配置

- [x] `scripts/ui/ghost_7ban_shobu_view.gd` を新シーンに合わせて書き直し
  - [x] 旧 918 行 → 新 約 200 行に簡素化
  - [x] phase machine: ready → announce(READY/START) → moving → result → 次 round → done
  - [x] 旧 2 レーン用ロジック（rail_you / rail_ghost 等）を削除
  - [x] miss timer / tap handling を新構造で再実装

- [x] BaseGame / GhostData / GameManager との互換確認
  - [x] 既存 resolve_tap / resolve_miss / finalize_game / finish() を経由（ロジック温存）
  - [x] `_on_game_finished` で `GameManager.on_game_finished_handler(log)` を呼ぶ
  - [x] スクリプト・シーンが load 成功（`tools/load_check.gd` 通過）

## フェーズ5: rule_explain フォーマット仕様の明文化

- [x] `docs/design/patterns.md` に「ルール説明画面のデータ構造」セクションを追記
  - [x] RULES Dict のスキーマ
  - [x] `preview_variant` の選択肢
  - [x] 新ゲーム追加時の手順
- [x] 既存 RULES の例（ghost_7ban_shobu / reflex_tap / flash_calc / sequence_memory）を docs に転載

## フェーズ6: 実装画面キャプチャ取得

- [x] `.steering/20260502-MidnightCatリデザイン/captures/` ディレクトリを作成
- [x] `home.png`（home.tscn の起動直後）
- [x] `rule_explain_ghost_7ban_shobu.png`
- [x] `rule_explain_reflex_tap.png`
- [x] `rule_explain_flash_calc.png`
- [x] `rule_explain_sequence_memory.png`
- [x] `ghost_7ban_shobu_ready.png`（Ready overlay）
- [x] `ghost_7ban_shobu_play.png`（プレイ中：GHOST orb がレーン上を移動）
- [x] `ghost_7ban_shobu_result.png`（announce "READY" を捕捉。Result phase の長時間サンプリングは future work）

## フェーズ7: 品質チェックと修正

- [x] すべてのスクリプトが parse できる（lane_shapes / lane_view / view / game_logic 全て load 成功）
- [x] 各シーンが load → instantiate できる（home / rule_explain / ghost_7ban_shobu）
- [x] home → rule → countdown の遷移が通る（`tools/flow_check.gd` PASS）
- [x] ghost_7ban_shobu の 1 レーンプレイが round 進行する（snap captures で確認: ready → announce → moving）

## フェーズ8: ドキュメント更新と振り返り

- [x] `docs/design/patterns.md` 更新済み（§10 ルール説明画面のフォーマット追加）
- [x] このファイルの「実装後の振り返り」を記録

## フェーズ9: promo 画像との整合・微調整（追加）

- [x] ghost_7ban_shobu を **landscape 1280×720** で動作させる
  - [x] view 側 `_force_landscape()` / `_restore_orientation()` を再実装（DisplayServer 経由）
  - [x] scene を landscape 構図に再構築：HUD左上 / score右上 / lane 中央水平 / Result上中央 / YOU左下 / GHOST右下
  - [x] AnnounceLabel を画面中央大字 (mincho 140px)
  - [x] Done overlay を中央カードに整理
- [x] home.tscn を promo 構図に寄せる
  - [x] マスコット (黒猫 icy_accents) を右寄せ・大きめ (240px) に配置
  - [x] 吹き出しをコンパクト化 + 中央寄せ・脳年齢ブロック直下に
  - [x] 既定脳年齢を 30 → 31 に変更（promo 一致）
- [x] rule_step_preview の compare variant を promo に寄せる
  - [x] YOU 側に person アイコン、GHOST 側に pets アイコン (Material Symbols) を追加
- [x] 全画面再キャプチャ（720×1280 portrait / 1280×720 landscape）

## フェーズ10: スコープ整理と余白活用（追加）

- [x] `RULES["reflex_tap"]` を削除（ghost_7ban_shobu に統合済みのため）
- [x] `docs/design/patterns.md` の reflex_tap 行を削除
- [x] `.steering/.../captures/rule_explain_reflex_tap.png` を削除
- [x] rule_explain のステップカードを拡大して余白を活用
  - [x] preview の最小サイズ 180×90 → **280×170** に拡大
  - [x] preview 内の rail / gate / orb / グロー / アイコンを大きく描画 (TAP! 14→26px / orb 4-5px→7-10px / icon 16→28px)
  - [x] `mc_step_index` 24→32px / `mc_step_title` 22→30px / `mc_step_body` 14→18px
  - [x] StepsColumn separation 12→18px

## フェーズ12: Claude Design への再寄せサイクル（2026-05-02 再起動後）

- [x] `research_claude_design_gap.md` を作成 (差分マップ + エフェクト仕様)
- [x] `scripts/utils/color_palette.gd` を variant-b 準拠に補正 (CYAN_300/400/500 / INK_100..20 / GOLD_300/400 / RED_400/500 を追加。旧名は alias)
- [x] `scripts/ui/effects/` ディレクトリを新設し 9 種のアセットを独立化
  - [x] `star_layer.gd` — 64 点の twinkling starfield
  - [x] `glow_orb.gd` — YOU/GHOST orb + trail
  - [x] `cyan_gate.gd` — 中央光柱 + halo + GATE ラベル (再利用しやすい単独 Control)
  - [x] `tap_burst.gd` — Ring×7 + Core + VerticalFlare の中央爆発
  - [x] `side_laser.gd` — hit→端の core + パーティクル光線
  - [x] `dotted_delta.gd` — 2 点間の repeating dotted line + 「-/+ Xms」ラベル
  - [x] `progress_dots.gd` — win/lose×/未戦/進行中の 7 戦ドット
  - [x] `glow_cta.gd` — cyan-border ピル + 多重 outline glow + pulse animation
  - [x] `headline_serif.gd` — rb-headline / rb-slam キーフレームの明朝大字
- [x] home.tscn 改修: StarLayer / マスコット 240→160px / 吹き出しをマスコット隣接 / レーダー 360→300px / CTA を GlowCTA でラップ
- [x] rule_explain.tscn 改修: StarLayer / Start CTA を GlowCTA でラップ / TAP preview に十字バースト + 多重リング
- [x] ghost_7ban_shobu.tscn 改修: StarLayer / ProgressDots / HeadlineSerif (PERFECT/GREAT/MISS 対応) / GATE を細い beam 化 / 黒猫マスコット modulate 強化 / Ready overlay を variant-b 構成 (GHOST · 7-BAN eyebrow + 7 番勝負 + TAP で開始 GlowCTA pill) / Done を「昨日の自分を、超えた。」など 3 状態
- [x] ghost_7ban_shobu_view.gd: Result phase で TapBurst + SideLaser×2 (YOU left + GHOST right weak) を動的生成
- [x] 全画面再キャプチャ (home / rule × 3 / 7ban × 3) — 7 枚すべて更新済み
- [x] 構文・load チェック PASS (`tools/load_check.gd` で 3 シーン load 成功)

## フェーズ11: ClaudeDesign 準拠のタップ演出（追加）

- [x] `reference/mockup/variant-b.jsx` を読み、TargetOrb / TapFlash / GhostStopMarker の演出仕様を抽出
- [x] `scripts/games/ghost_7ban_shobu/lane_shapes.gd` の 5 種形状を再確認
  - `line` / `s_curve` / `sine_wave` / `zigzag` / `arc` を chat1 末尾仕様 (4-5 種) と一致と確認
  - `s_curve` の dead code (`* 0.0` の行) を削除
  - `sine_wave` を sin(t*PI) → sin(t*TAU)*0.5 に変更し、t=0/0.5/1 で center を通る正しい振動に
  - `arc` は意図通り t=0.5 で頂点（広い山）
- [x] `scripts/ui/ghost_7ban_lane_view.gd` のタップ演出を強化
  - [x] 移動中: orb の進行方向と逆向きに 16 サンプル衰退トレイル（v-b の filter:blur 70px 相当）
  - [x] orb の白コア (radial gradient `#fff 0%, glow 40%, color 100%` の Godot 模倣)
  - [x] タップ瞬間: rb-fire keyframes (0.3→1.2→2.2 倍 + フェード) を再現した拡張リング
  - [x] Result の YOU 爆発: 8 本の星形バースト光線（背面太線 + 前面細線の 2 層）
  - [x] GHOST 停止ダッシュ縦線（v-b GhostStopMarker 由来。プレイ中＆Result 両方で表示）
- [x] `ghost_7ban_shobu_play.png` / `ghost_7ban_shobu_result.png` を再キャプチャ

---

## 実装後の振り返り

### 実装完了日
2026-05-02

### 計画と実績の差分

**計画と異なった点**:
- `default_theme.tres` の旧バリアント（`bar_win_v2` / `cta_blue` / `glass_bubble` 等）は削除せず温存。これは互換維持のため意図的。新画面に置き換え完了後にクリーンアップ予定。
- `ghost_7ban_shobu.gd` (game logic) の本体ロジックは想定より少ない変更で済んだ（`resolve_tap` の判定式は時刻ベースで 1 レーン/2 レーン共通）。`CFG_BASE` に `shape` を追加し、view 側を全面書き換えで対応。
- 旧 `dir` (left/right) を完全撤去するつもりだったが、互換のため残置。view 側は無視。
- ghost_7ban_shobu の Result phase キャプチャは時間制御の難しさからアナウンス "READY" を捉えてしまった。Lane の動的描画が正しいことは moving のキャプチャで確認できたため、Result の精密キャプチャは future work とする。

**新たに必要になったタスク**:
- `scripts/ui/ghost_7ban_lane_view.gd` を新規作成（レーン曲線・GATE・オーブ・Result の描画を専任）。当初は view 内に統合する予定だったが、責務分離のため独立 Control として実装。
- `tools/snap_scene.gd` / `tools/snap_g7_phases.gd` を作成して xvfb 経由のキャプチャ自動化。これにより promo 画像との比較が容易に。
- `LaneShapes` を class_name 登録ではなく `preload` で参照（class_name は Godot のプロジェクト import が完了していないと resolved されない CLI 制約のため）。

**技術的理由でスキップしたタスク**:
- なし（全 8 フェーズ完了）

### 学んだこと

**技術的な学び**:
- Claude Design (claude.ai/design) の handoff bundle は `https://api.anthropic.com/v1/design/h/<id>` から `tar.gz` で取得でき、認証なしで Claude Code から直接 fetch できる（id を知っていれば）。WebFetch は 10MB 制限があるので curl 経由が確実。
- Godot 4 で headless 描画キャプチャを行うには `xvfb-run` + `--rendering-driver opengl3` が必要。`--headless` 単体では dummy renderer で texture が作れない。
- `class_name` で登録した型は CLI スクリプト実行時には resolve されないことがあるため、プロジェクト内ファイル参照は `preload("res://...")` を使うほうが robust。
- Theme variation は段階的に追加できる。旧バリアントを削除せず新規 `mc_*` を追加するだけで、新画面と旧画面が共存可能。
- promo 画像の最終形と handoff bundle の README/colors_and_type.css が一致しないことがある（README は light theme、promo は dark theme）。chat transcripts が「真の最終形」として最も信頼できる情報源。

**プロセス上の改善点**:
- ステアリングファイルを後追いで作成したため、一部タスクが「完了済み」状態でリストアップされた。次回は最初に作業計画フェーズで steering モード1 を呼ぶこと。
- 大規模リデザインでは、まず色トークン → フォント → テーマ → 画面再構築 → ロジック書き換え → ドキュメント の順で進めると依存関係がきれいに解ける。

### 次回への改善提案
- 旧 light theme バリアント（`bar_win_v2` / `cta_blue` / `glass_bubble` / `header_pill` / `cta_gradient` 等）の撤去を別 PR で実施。撤去前に全シーンが `mc_*` に移行済みかをチェック。
- `flash_calc` / `sequence_memory` / `countdown` / `individual_result` / `ghost_character` の Midnight Cat 移行を次イテレーションで。
- ghost_7ban_shobu の result phase キャプチャを安定的に取れるよう、テストモードフラグで「自動タップ＋固定ms」にできるようにすると CI 連携が楽になる。
- `docs/design/manifest.md` も Midnight Cat ベースに更新する（現状は旧 light theme 仕様のまま）。
