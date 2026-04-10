# 要求内容 — モバイルアプリ UI/UX 基盤

## 概要

Brain Boost のモバイルアプリらしい見た目・操作感の基盤を、Godot 側で直接 `.tscn` + `theme.tres` として作り込む。ホーム画面 1 枚を実証対象とし、ここで確立したデザイン言語・テンプレート・検証ループを以降の全画面に展開する。

## 背景

- Claude.ai + Figma MCP でホーム画面を試作したが「アプリっぽくない」との結論。原因分析:
  - Figma MCP の出力は React+Tailwind 前提で、Godot に翻訳する過程でモバイル密度・親指ゾーン・Safe Area といった **モバイルアプリ固有の作法** が落ちてしまう
  - GDD 固有ルール（赤禁止、タップ only、`ColorPaletteUtil` 一対一対応）が Figma 側に制約として効かず、生 hex が散らばる
  - 何より「Claude.ai → 人が翻訳 → Godot」の翻訳レイヤーが手戻りを生んでいた
- Claude Code 側で直接 Godot の `.tscn` を組む方が、**最終成果物 = デザイン成果物** になり翻訳が消える
- 競合 7 アプリの UI リサーチは完了済み（`docs/design/references/competitor-research.md`）。これを参考画像の代替として活用する
- `citadel:design` と `citadel:live-preview` という既存スキルが「デザイン言語の明文化」と「スクショでの検証ループ」を既に備えており、新規スキル作成よりも先にこれらを試す方が低コスト
- 本タスクは **反射タップ実装と切り離す**。ロジック実装は UI 基盤が固まってから別ステアリングで進める

## 実装対象の機能

### 1. デザイン言語の明文化（manifest.md）

- `citadel:design` スキルで `docs/design/manifest.md` を生成
- 以下を明文化:
  - **ブランドトーン**: ライト基調、丸ゴシック太字、ミニマル、セルフチャレンジャー（朝通勤 2 分）に合う落ち着き
  - **カラートークン**: `ColorPaletteUtil` の既存定数と一対一対応（`POSITIVE_GREEN` / `POSITIVE_GOLD` / `NEUTRAL_GRAY` / `BG_LIGHT` / `ACCENT_BLUE`）
  - **タイポグラフィスケール**: Display (64pt) / H1 (32pt) / H2 (24pt) / Body (18pt) / Caption (14pt)。Noto Sans JP Bold または M PLUS Rounded 1c
  - **スペーシング**: 8pt グリッド（4 / 8 / 16 / 24 / 32 / 48 / 64）
  - **角丸**: 16px（カード） / 24px（CTA ボタン） / 9999px（ピル）
  - **Safe Area / 親指ゾーン**: 上 48px / 下 96px（ボトムナビ + 親指リーチ領域確保）
  - **最小タップ領域**: 44×44pt（iOS HIG 準拠、Android Material は 48dp だが厳しい方に合わせる）
  - **シャドウ**: 微シャドウのみ（`alpha 0.08`, `offset_y 2`, `blur 8`）。立体感を出しすぎない
  - **禁則**: 赤禁止、絶対配置禁止（Anchor + Container のみ）、生 hex 禁止

### 2. 共通テーマリソース（default_theme.tres）

- `assets/themes/default_theme.tres` を新規作成
- 最小セットとして以下の StyleBox / Font / Color を登録:
  - **Button** (`default`, `hover`, `pressed`, `disabled`): ゴールド CTA / ブルー セカンダリ / グレー無効
  - **Label** (`default`, `h1`, `h2`, `display`, `caption`)
  - **Panel** (`card`, `card_elevated`): 角丸 16px + 微シャドウ
- Font は Noto Sans JP Bold を同梱（`assets/fonts/` に配置）
- `project.godot` の `gui/theme/custom` に登録し全シーンで自動適用

### 3. ホーム画面実装（scenes/main/home.tscn）

- 現在プレースホルダ状態の `home.tscn` を本実装に置き換え
- FR-07 の受け入れ条件を満たす以下の要素を含む:
  - ヘッダ: 前回スコア + 脳年齢 / ストリーク表示 / ゴースト通算戦績
  - メイン: **[今日のチャレンジ]** 大型 CTA ボタン（画面幅 85%、高さ 88px 以上、ゴールド）
  - セカンダリ: **[全ゲーム一覧]** サブ CTA
  - フッタ: ボトムナビ 3 タブ（ホーム / カレンダー / 設定）のプレースホルダ
  - バナー広告領域（Android 版のみ表示想定、Web では空）
- レイアウトは **縦 720×1280 基準**、Container + Anchor で構成
- 参考モデル: **みんなの脳トレ**のホーム（中央大型 CTA）+ **毎日脳トレ**のカード縦並び + **PEAK** のカテゴリ色

### 4. ホームコントローラ（home_controller.gd）

- `scripts/ui/home_controller.gd` を最小実装
- ボタンシグナル接続のみ（遷移先は `print()` でのログ出しで OK、本格遷移は後続ステアリング）
- DataStore からダミー値を読み取り UI に反映（データなしでもクラッシュしない）

### 5. スクショ検証ループ

- `citadel:live-preview` または手動で `godot --headless` + スクリーンショット取得
- 参考 Top 5 画面（competitor-research.md）と並べてトーン比較
- ユーザーが目視で「アプリっぽい」と判断するまで反復

### 6. テンプレ化（次画面への展開資産）

- ホーム画面で確立した Container 階層・命名規則・Theme 使用パターンを `docs/design/patterns.md` に記録
- 新規画面を作るときの手順（ボイラープレート）を 1 ページにまとめる

## 受け入れ条件

### 1. デザイン言語（manifest.md）

- [ ] `docs/design/manifest.md` が存在する
- [ ] カラートークンが `ColorPaletteUtil` の定数と 1 対 1 対応している
- [ ] タイポグラフィスケール（5 段階）が明記されている
- [ ] 8pt グリッド・Safe Area・44pt 最小タップ領域が明記されている
- [ ] 禁則事項（赤禁止・絶対配置禁止・生 hex 禁止）が明記されている

### 2. 共通テーマ（default_theme.tres）

- [ ] `assets/themes/default_theme.tres` が存在する
- [ ] Button / Label / Panel の最小セットが登録されている
- [ ] `project.godot` に登録され、シーン起動時に自動適用される
- [ ] Noto Sans JP（または代替の丸ゴシック太字）が同梱されている

### 3. ホーム画面（home.tscn）

- [ ] FR-07 の受け入れ条件を全て満たす（前回スコア・脳年齢・ストリーク・ゴースト戦績・CTA 2 つ）
- [ ] 縦 720×1280 で崩れない
- [ ] すべての色が `ColorPaletteUtil` 参照（生 hex 0 件）
- [ ] すべてのタップ対象が 44×44pt 以上
- [ ] Container + Anchor のみでレイアウト（絶対配置 offset ハードコード 0 件）
- [ ] `godot --headless --quit` がエラーなく終了
- [ ] GUT ユニットテスト（既存 45 件）がリグレッションなく通る

### 4. 検証

- [ ] スクリーンショット取得スクリプト or 手順が確立
- [ ] ユーザーがスクショを見て「モバイルアプリっぽい」と承認
- [ ] 競合 Top 5 画面と並べたトーン比較が `docs/design/references/` 配下に記録されている

### 5. テンプレ化

- [ ] `docs/design/patterns.md` が存在する
- [ ] ホーム画面で使った Container 階層・命名規則・Theme 使用法が記載されている
- [ ] 次の画面（反射タップ / 結果画面 等）を作るときの手順が 1 ページで追える

## 成功指標

**定量**:
- 生 hex 0 件（grep `Color\(0\.` や `#[0-9a-fA-F]{6}` で 0 ヒット、`ColorPaletteUtil` 内を除く）
- 絶対配置 offset の直接ハードコード 0 件（`offset_left =`, `offset_top =` の直書き 0 件、Anchor/Margin 経由のみ）
- GUT 45/45 パス（リグレッションなし）
- `godot --headless --quit` exit=0

**定性**:
- ユーザーが「アプリっぽい」と一言で認めるスクショが撮れる
- 次画面（反射タップ / 結果画面）の実装者が `docs/design/patterns.md` 1 ファイル見るだけで同じトーンを再現できる

## スコープ外

以下はこのフェーズでは実装しない:

- **反射タップゲーム本体の実装**（次ステアリング `20260412-reflex-tap-implementation` で実施）
- **他の画面**（オンボーディング・ルール説明・個別結果・総合結果・シェア画面・設定・カレンダー画面）
- **アニメーション・トランジション**（ホーム画面に入る演出は最小。入念なモーションは別ステアリング）
- **本物のデータ連動**（DataStore の実データ読み込み。ダミー値で見た目を固めることを優先）
- **Android 実機確認**（Web での headless スクショのみで判断。実機確認はストア提出準備ステアリングで）
- **バナー広告の実装**（枠だけ作る。`AdService` 実装は別ステアリング）
- **ボトムナビの実遷移**（枠と見た目のみ。遷移ロジックは後続）
- **ダークモード**（GDD §v1.1 以降の拡張）

## 参照ドキュメント

- `docs/ideas/brain_training_gdd.md` — GDD（設計の北極星）
- `docs/product-requirements.md` — FR-07（2回目以降の日常フロー / ホーム画面の受け入れ条件）、FR-09（ストリーク）、FR-12（広告）
- `docs/functional-design.md` — A-05（日付シード）、UC-02（デイリーチャレンジフロー）
- `docs/architecture.md` — UI レイヤー / プラットフォーム分岐
- `docs/repository-structure.md` — `scenes/main/`, `assets/themes/` の配置規則
- `docs/development-guidelines.md` — 色の使用ルール、`ColorPaletteUtil` 規約
- `docs/design/references/competitor-research.md` — 競合 7 アプリ UI リサーチ（本タスクの参考資料）
- `scripts/utils/color_palette.gd` — 色定数の実装
