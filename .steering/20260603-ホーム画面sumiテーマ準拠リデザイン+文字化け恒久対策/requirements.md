# 要求内容

## 概要

ホーム画面の「文字化け」と「デザイン不備」を解消する。文字化けはフォント未インポートが根本原因（調査で特定済み）。デザインは `docs/ideas/sumi-theme/README.md`(v2) の墨絵テーマ設計に準拠させ、稼働中の `scenes/main/home.tscn` を改修する。あわせて文字化けの再発を防ぐ恒久対策を devcontainer に組み込む。

## 背景

- ユーザー報告: 「ホーム画面構成が文字化けしているし、デザインがおかしい」。
- 調査結果（実機レンダリングで確認）:
  - **文字化けの真因 = フォント未インポート**。`.godot/` が root 所有で生成されていたため `godot` ユーザーがインポート結果を書けず、`assets/fonts/*.import` が `valid=false` でスタック。日本語が豆腐(□)、Material Symbols アイコンが生テキスト("settings"等)化していた。`.godot` 所有権修正＋`.import`削除→`godot --headless --import` で解消を確認済み（ローカル）。
  - **デザイン不備の一因 = パーツ汚染**。`assets/textures/` 配下のフレーム/ゲームアイコン/区切り線は `scripts_build/cut_sumi_sheets.py` の切り出し座標不良で、サンプルカード丸ごとや見出し文字が焼き込まれている。リファレンスシートは合成モックアップでありスプライトアトラスではないため、座標修正では原子パーツを取り出せない。
- 方針は `docs/ideas/sumi-theme/README.md`(v2) に確定済み: 汚染パーツは使わず Godot ネイティブ(StyleBoxFlat / `_draw()` / Theme / Material Symbols)で再現し、Phase 制・1チケット1コンポーネントで人間確認を挟む。

## 実装対象の機能

### 1. 文字化け恒久対策（インフラ）
- `.devcontainer/setup-claude.sh` に `.godot` 所有権修正 + `godot --headless --import` を追加し、クリーンコンテナでも文字化けが再発しないようにする。
- 検証ループ（`xvfb-run + --rendering-driver opengl3` での画面キャプチャ）が機能する状態を整える。

### 2. UIコンポーネント分割（README チケット 2-1〜2-8）
- 既存 home のインライン構築を、README に従い8つの単体コンポーネント(.tscn + .gd)に分割する。
- BrainAgeCard / DailyScoreCard / GhostRecordStrip / SumiRadarChart / DailyChallengeStrip / GameListCard / SumiDivider / SumiButton。
- 各コンポーネントは Control 系ベース、`@export` でデータ/テクスチャ注入可、signal はスクリプト冒頭で宣言、座標ハードコード禁止、`SumiColors` 定数使用、`sumi_theme.tres` 参照。

### 3. ホーム画面の再アセンブリ（README 3-1 を既存 home に適用）
- `scenes/main/home.tscn` を分割コンポーネントのインスタンスで再構成し、リファレンス(`ui_parts_home_*.png` 等)の見た目に近づける。
- 既存の固有要素(マスコット＋吹き出し / glow CTA / nav リンク)は維持する。
- `home_controller.gd` から各コンポーネントの `@export`/signal にデータ・遷移をバインドする。

## 受け入れ条件

### 文字化け恒久対策
- [ ] クリーンな `.godot` 状態から `godot --headless --import` でフォントが `valid` にインポートされる（`.godot/imported/` に各 fontdata が生成）。
- [ ] ホーム画面キャプチャで日本語が正しく表示され、設定/nav のアイコンが Material Symbols として表示される（豆腐・生テキストが無い）。
- [ ] `.devcontainer/setup-claude.sh` に所有権修正と import が追加され、手順がドキュメント化されている。

### UIコンポーネント分割
- [ ] 8コンポーネントが `scenes/ui/components/` に .tscn+.gd ペアで存在する。
- [ ] 各コンポーネントが単体でキャプチャ検証され、リファレンスの該当部と整合する。
- [ ] 汚染パーツ(frame_ink_border/game_icon_*/btn_*/divider_*/hitodama/arrow_*/icon_lock/bar_fill_*)を texture として使用していない。
- [ ] 色は `SumiColors` 定数経由、レイアウトは Container 構造（position/offset ハードコードなし）。

### ホーム画面再アセンブリ
- [ ] `scenes/main/home.tscn` が分割コンポーネントで再構成され、レンダリング結果がリファレンスに整合する。
- [ ] マスコット/glow CTA/nav リンクが維持され機能する。
- [ ] 既存の遷移(チャレンジ開始/全ゲーム一覧/設定)が動作する。

## 成功指標

- ホーム画面に文字化け・崩れが無く、墨絵テーマのリファレンスに視覚的に整合している。
- ホームのUI要素が再利用可能なコンポーネントに分割され、今後の画面でも流用できる。
- クリーンコンテナ構築時に文字化けが再発しない。

## スコープ外

以下はこのフェーズでは実装しません:

- ゲーム一覧画面(game_list)以外の画面リデザイン（リザルト/オンボーディング等は別タスク）。※GameListCard 単体は作成するが game_list 画面の完全アセンブリは状況により別途。
- 汚染パーツのクリーン再生成（新規アート制作）。将来 `@export` 差し替えポイント経由で対応。
- スコアリング/ゴーストロジック等のゲームロジック変更。

## 参照ドキュメント

- `docs/ideas/sumi-theme/README.md` (v2) - 墨絵テーマ実装指示書（本タスクの一次方針）
- `docs/ideas/brain_training_gdd.md` - GDD（設計の北極星）
- `docs/functional-design.md` / `docs/architecture.md` - 機能設計・技術仕様
- メモ: 文字化けの根本原因・検証ループ手順
