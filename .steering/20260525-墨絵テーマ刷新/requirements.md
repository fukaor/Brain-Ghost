# 要求内容

## 概要

ブレインゴーストの視覚テーマを現状の Midnight Cat（漆黒 + シアン発光）から **墨絵調（和紙クリーム + 墨 + 鬼火青）** に全面刷新する。新規 SD 黒猫キャラと和紙背景アセットを最大限活かす配色とテクスチャ運用に統一する。アプリ名「ブレインゴースト」は変更しない。

## 背景

- 現状の黒基調は**視認性が低い**（暗背景上の暗テキスト・暗ボタンが混在）
- マスコット = 墨絵調黒猫（ユーザ提供アセット 6 ポーズ）、ゴースト = ユーザの生霊（青鬼火 / 墨の滲み）という設定が**墨絵と概念的に完全一致**
- 競合（Lumosity / Peak / Elevate）が無機質寄りである一方、本作は**和の意匠 × ゴースト**で差別化を一段強化できる
- 「色をまったく別にしたいわけではない」というユーザ意向に対し、**墨と青鬼火の二色体系**は既存のシアン軸を継承しつつ和に寄せる解として最適

## 実装対象の機能

### 1. アセット移植と命名規約統一

- `docs/ideas/character/` の 6 ポーズと `docs/ideas/background/` の 7 背景を `assets/characters/` および `assets/backgrounds/` に正式移植
- キャラ命名: `sumineko_<state>.png`（プレフィクス `sumineko` で統一）
- 背景命名: `washi_<screen>.png`（プレフィクス `washi`）
- 旧 Catboy 系 4 ファイル（catboy_electric / confident / energetic / ghost_seirei）はアセット残置のままランタイム参照ゼロ化

### 2. カラーパレット v4「Sumi Ghost」への置換

- `scripts/utils/color_palette.gd` を Midnight Cat（v3）から Sumi Ghost（v4）へ全面書き換え
- 旧定数（CYAN_300 / BG_PANEL 等）は alias を残して段階移行
- 新定数群: 和紙系 3 階層 / 墨系 4 階層 / 鬼火青系 2 階層 / 金（古色）/ 翠（成功）/ ゴースト滲み

### 3. Theme リソース全面リフォーム

- `assets/themes/default_theme.tres`（約 1500 行 / 182 色参照）を新パレットで再構築
- StyleBox / 文字色 / アイコン色 / ボタン状態色をすべて新値に
- 既存テーマバリエーション名は維持（後方互換）

### 4. シーン背景の和紙テクスチャ化

- 全画面共通テクスチャ `washi_base.png` をベース層に
- 画面固有の背景画像（home / play / result_win / result_lose / tutorial）を該当シーンに配置
- 既存の星粒子レイヤ / ネビュラグラデ / 漆黒背景は除去または非表示
- 全 6 画面: `launch.tscn` / `home.tscn` / `game_list.tscn` / `rule_explain.tscn`（縦・横）/ `countdown.tscn`（縦・横）/ `individual_result.tscn`
- ゲームシーン 6 種: 和紙背景共通テクスチャを敷く

### 5. ハードコード色定数の置換

- `scripts/ui/rule_step_preview.gd` 内の Color() 直書き（COLOR_RAIL / COLOR_GLOW_CYAN / COLOR_PANEL_OFF など）を新パレットに準拠
- `scripts/ui/components/card.gd` の COLOR_BACK_BG / COLOR_FRONT_BG / COLOR_MATCH_FLASH_BG 系を新パレットに準拠
- `scripts/ui/individual_result_controller.gd` の COLOR_GOLD / COLOR_CYAN300 等を新パレットに準拠
- `scripts/ui/effects/star_layer.gd` は墨はね粒子に置換（または無効化）
- `scripts/ui/effects/glow_cta.gd` は鬼火光に色相シフト
- `scripts/ui/launch_controller.gd` の演出色を墨絵パレットに

### 6. ルール説明プレビュー variant の色再調整

- 9 種すべての `_draw()` 内の色定数（COLOR_RAIL / COLOR_GATE / COLOR_GLOW_GOLD / COLOR_PANEL_OFF 等）を新パレットに置換
- ストロークの色は中墨 / 淡墨、ハイライトは鬼火青 / 金（古色）

### 7. マスコット画像参照の置換

- `home.tscn` / `countdown.tscn` / `countdown_landscape.tscn` / `individual_result.tscn` / `ghost_7ban_shobu.tscn` の 5 シーンで参照テクスチャを新キャラに差し替え
- 現状はベースポーズ `sumineko_normal.png`（または用途に応じて `sumineko_fight.png` 等）を使用
- AnimatedSprite2D 化は別ステアリング（マスコット強化ステアリング）で実施

### 8. リブランディング表記の整理

- ドキュメント / コメント内の「Midnight Cat」表記を「Sumi Ghost」または「墨ゴースト v4」に置換
- アプリ表示名 / パッケージ名は変更しない（ユーザ指示）
- MEMORY のマスコット情報を `sumineko` ID に更新

## 受け入れ条件

### アセット移植

- [ ] `assets/characters/sumineko_*.png` が 6 枚配置されている（normal / fight / running / double / touch / sleep）
- [ ] `assets/backgrounds/washi_*.png` が 7 枚配置されている（base / home / play / result_win / result_lose / tutorial / promo）
- [ ] 旧 `docs/ideas/character/` および `docs/ideas/background/` は残置（参考用、削除しない）
- [ ] `.import` ファイルが自動生成される

### カラーパレット v4

- [ ] `color_palette.gd` に v4 ブロックが定義され、旧 v3 定数は alias 化されている
- [ ] 新キー 13 種: WASHI_BASE / WASHI_PANEL / WASHI_SHADE / SUMI_INK / SUMI_MID / SUMI_LIGHT / SUMI_DIM / ONIBI_BLUE / ONIBI_GLOW / ONIBI_DEEP / GOLD_AGED / JADE_INK / GHOST_INK
- [ ] RED 系定数（RED_400 / RED_500 / RED_GLOW）は残置（particle 装飾限定として維持、ドックコメント更新済み）
- [ ] CLAUDE.md の禁止色ルール（赤）は引き続き遵守

### Theme リフォーム

- [ ] `default_theme.tres` の StyleBoxFlat / fonts / colors が新パレットに置換済み
- [ ] エディタで `default_theme.tres` を開きエラーが出ない
- [ ] 主要 theme_type_variation（mc_cta_glow / mc_cta_primary / glass_bubble / chip 系）は意味的に維持（名称は維持、色のみ変更）

### シーン背景

- [ ] 全 6 主要画面 + 6 ゲームシーンで黒背景が消え、和紙テクスチャに置き換わっている
- [ ] 星粒子 / ネビュラグラデは描画されない（コードから到達不能）
- [ ] スマホ実機（720x1280）で背景が破綻なく表示される

### ハードコード色置換

- [ ] `grep "Color(0.04, 0.08\|Color(0.067, 0.094\|Color(0.043, 0.071" scripts/` で結果ゼロ件（旧 Midnight 色定数の直書きを排除）
- [ ] 各 view / preview / controller の色は ColorPaletteUtil の定数経由 or 新値に統一

### ルール説明プレビュー

- [ ] 9 variant の描画が和紙地に**読み取れる**コントラストで表示される
- [ ] グロー金 / グロー鬼火青の対比が維持されている

### マスコット参照置換

- [ ] `grep "catboy_" scripts/ scenes/` で 0 件
- [ ] 5 シーンすべてで新キャラが表示される

### リブランド表記

- [ ] スクリプトコメント / ドキュメント本文の「Midnight Cat」表記を「Sumi Ghost」または「墨ゴースト」に整理（一部歴史的記載は残してよい）
- [ ] MEMORY の `project_mascot_catboy.md` を新キャラ ID（sumineko）に書き換え

## 成功指標

- ホーム画面のスクリーンショットを並べたとき「別アプリ」と感じられるレベルの転換
- テキスト本文がすべて可読（コントラスト比 AA 以上を目標）
- 実機で 6 ゲームを通しプレイしたとき、視覚的な違和感がない

## スコープ外（次回以降）

- マスコットの AnimatedSprite2D 化と AnimationTree ステートマシン（次ステアリング: マスコット強化版で扱う）
- juicy_button / 結果リアクション 3 段階 / 神経衰弱裏面 / 精度連動グロー（次ステアリング）
- 旧 catboy_*.png 物理削除（さらに次回）
- 筆描き風フォント導入（フォント探索が別タスク化されるため切る）
- B-2 ゴースト猫の対戦相手化、B-3 アンビエント音、B-4 ワードローブ
- 全 6 ゲームのゲーム内マスコット演出（神経衰弱裏面以外）

## 参照ドキュメント

- `docs/product-requirements.md` — PRD
- `docs/functional-design.md` — 機能設計
- `docs/architecture.md` — アーキテクチャ
- `docs/repository-structure.md` — リポジトリ構造
- `docs/development-guidelines.md` — 開発ガイドライン（色禁止ルール）
- `docs/ideas/brain_training_gdd.md` — GDD §6 赤禁止
- 2026-05-25 墨絵リサーチ（本セッション、Sumi-e / Wabi-sabi / Japan minimalism）
- ユーザ提供アセット: `docs/ideas/character/*.png` / `docs/ideas/background/*.png`
