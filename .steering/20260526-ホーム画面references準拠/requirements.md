# 要求内容 — ホーム画面 references 準拠リデザイン

## 概要

ホーム画面 (`scenes/main/home.tscn`) を `docs/ideas/sumi-theme/references/` 配下の 5 枚のリファレンス画像に**視覚的に準拠**させる。
現状実装は構造のみが新テーマ化されているが、各ブロックの**ディテール (装飾 / 余計な要素 / アスペクト / グリッド形状)** がリファレンスと乖離している。

## 背景

直前のフェーズで `home.tscn` を `mc_*` (Midnight Cat) テーマから sumi バリエーションに移行したが、移行はあくまで**バリエーション参照の置換**であり、コンポーネントの構造はリファレンス画像を直接見て設計したものではない。実機デプロイ後の確認でユーザから「全体的にレイアウトがぶっこわれてる」とフィードバックがあり、リファレンス画像と並べると以下の乖離が明確:

- 脳年齢カード: リファレンスは「単純な大きな数字 + 墨筆アンダーライン + 墨飛沫」だが、現状は PanelContainer + 精度ヒント + ProgressBar まで詰め込まれている
- スコアカード: リファレンスは「○○× 戦績マーク + 黒猫シルエット装飾」を含むが、現状実装はテキスト 4 行のみ
- 戦績/連勝行: リファレンス 1A (横並び戦績 + 黒猫) / 2A (曜日付きハンコ) と現状 (横並びだけ + 曜日無し) でディテール差
- レーダー: リファレンスは**同心六角形グリッド + 最上頂点に人魂**だが、現状は**同心円グリッド + 人魂無し**
- 今日のチャレンジ: リファレンスは**巻物背景 + 3 ゲームカード (名前付き) + "始める" ボタン**だが、現状は**プレーン HBox + 3 アイコン + "今日のチャレンジ" ボタン**

## 実装対象の機能

### 1. 脳年齢ブロック簡素化

- 既存の `BrainAgeBlock` から **AccuracyHint / Progress (ProgressBar) を削除**
- レイアウト: VBox(Caption "脳年齢" + Value "31" 大 + Underline)
- 墨飛沫装飾 1〜2 個を周辺に配置（`decorations/ink_splatter_*.png` が無い場合は `divider_thin.png` / `arrow_up_brush.png` 等を流用 or skip）
- `washi_card` PanelContainer 枠は外す（リファレンスは枠なしで透過の上に直接乗っている）

### 2. DailyScoreCard リファレンス準拠

- 構造: NinePatchRect (frame_ink_border.png) を**唯一のフレーム**として使用 (PanelContainer の washi_card との二重枠は廃止)
- 内容を 2 段構成に再設計:
  - 1 段目: `3,230` `pts` + `↑+285` (text_win 緑、上昇矢印 brush) + 右側に **黒猫シルエット** (`sumineko_normal.png` を小さく配置 or 専用素材があれば差し替え)
  - 2 段目: メタ情報 (例: `脳年齢: 31歳`) + **○○× 戦績マーク** (`mark_win.png` × 2 / `mark_lose.png` × 1 程度)

### 3. StatsAndStreakRow 1A + 2A バリエーション準拠

- StatsBlock: 「通算 15勝 8敗」を 1 行で表示 + 黒猫シルエット小 (リファレンス 1A 準拠)
- StreakBlock: 7 個の `stamp_shuin.png` 上部に**曜日ラベル (月火水木金土日)** を配置、下部に "5日連続！" (リファレンス 2A 準拠)
- スタンプサイズはリファレンスの相対比率に合わせて拡大 (現状 22x28 → 適切な可視サイズへ)

### 4. RadarChart 六角形グリッド + 人魂

- グリッドを**同心円から同心六角形へ変更** (3 リング)
- 最上頂点 (計算力, index 0) に**人魂** (`hitodama.png` 小) を配置
- データ多角形塗りはリファレンスの淡水色を維持 (HITODAMA_FILL)
- 最強軸頂点の KINDEI 丸はそのまま残す

### 5. DailyChallengeStrip リファレンス準拠 (始める)

- レイアウト: 縦 VBox に変更
  - タイトル行: "今日のチャレンジ" (h2) + 人魂アイコン
  - 3 ゲームカード行: HBox 3 個、各カードに**アイコン (横長) + ゲーム名ラベル**を縦並びで表示
  - 始めるボタン: `btn_accent` バリエーション、テキスト「始める」 (現「今日のチャレンジ ›」から変更)
- 巻物背景 (scroll bg) はアセット未存在のため**省略**し、`washi_card` PanelContainer で代替
- ゲームアイコンのアスペクト比は実 PNG (678×292) に合わせる

## 受け入れ条件

### 脳年齢ブロック
- [ ] ProgressBar / AccuracyHint が削除されている
- [ ] 「脳年齢」 caption + 大きな数値 + 墨筆アンダーラインの 3 要素のみで構成
- [ ] PanelContainer (washi_card) 枠が無く、bg_home の上に直接表示

### DailyScoreCard
- [ ] NinePatchRect frame_ink_border が唯一の枠 (PanelContainer 重ねが廃止)
- [ ] `↑+285` がリファレンス通り緑色 (text_win) + 上昇矢印
- [ ] 右上に黒猫シルエット (`sumineko_normal.png` 小サイズ) が配置されている
- [ ] ○○× 戦績マークが下段に表示される

### StatsAndStreakRow
- [ ] StatsBlock に「通算 X勝 Y敗」+ 黒猫シルエットが表示される
- [ ] StreakBlock の 7 スタンプ上部に「月火水木金土日」ラベルがある
- [ ] スタンプが画面上で視認可能なサイズで描画されている

### RadarChart
- [ ] グリッドが六角形 (3 リング) で描画される
- [ ] 計算力 (top) 頂点付近に 人魂 が表示される
- [ ] 6 軸ラベル + データ多角形が引き続き正しく描画される

### DailyChallengeStrip
- [ ] タイトル「今日のチャレンジ」+ 人魂が表示される
- [ ] 3 ゲームアイコンの下にゲーム名が表示される
- [ ] CTA ボタンのテキストが「始める」になっている
- [ ] 全体が `washi_card` の上に乗っている (背景の和紙感が出る)

### 共通
- [ ] `godot --headless --check-only` exit 0
- [ ] `godot --headless --import` exit 0
- [ ] SceneTree から `home.tscn` を `instantiate()` 成功
- [ ] Android 実機にデプロイし、スクショで視覚一致を確認 (リファレンス画像との同一画面並置比較)

## 成功指標

- リファレンス 5 枚と現状実装の**コンポーネント別比較**で、構造・装飾・色・テキストが意図と一致していること (Phase 8 で **必ずユーザ目視レビュー** を実施)
- 「ぶっこわれてる」フィードバックの再発無し
- ヘッドレスパース + APK ビルド (timeout 600s 内) が成功

## スコープ外

以下はこのフェーズでは実装しません:

- 巻物 (scroll) 背景素材の追加生成 (素材を新規生成せず、`washi_card` で代替)
- 「正」 calligraphy (2B バリエーション) — ハンコ (2A) 一本に絞る
- 「直近 10戦 ○○○○○×××」 (1B バリエーション) — 「通算 15勝 8敗」 (1A) 一本に絞る
- マスコットの表情切替や精度連動グロー (既存 MascotController の挙動は維持しつつ、改修対象外)
- 縦画面・横画面の両対応 (縦のみ。`home.tscn` のみ対象、`home_landscape.tscn` は無)
- game_list / individual_result / その他画面のリファレンス準拠 (別ステアリングで対応)

## 参照ドキュメント

- `docs/product-requirements.md` - プロダクト要求定義書
- `docs/functional-design.md` - 機能設計書
- `docs/ideas/sumi-theme/README.md` - 墨絵テーマ実装指示書 (原典)
- `docs/ideas/sumi-theme/references/ui_parts_home_nenrei.png` - 脳年齢
- `docs/ideas/sumi-theme/references/ui_parts_home_score.png` - スコアカード
- `docs/ideas/sumi-theme/references/ui_parts_home_graph.png` - レーダー
- `docs/ideas/sumi-theme/references/ui_parts_home_daily.png` - 戦績 + 連勝
- `docs/ideas/sumi-theme/references/daily_challenge_strip.png` - 今日のチャレンジ
- `.steering/20260526-墨絵テーマ実装指示書反映/` - 直前のステアリング (構造実装は完了済)
