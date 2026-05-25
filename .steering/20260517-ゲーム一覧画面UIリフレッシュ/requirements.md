# 要求内容

## 概要

`scenes/ui/game_list.tscn` （脳トレ一覧 / カルーセル画面）が旧 "Animated Intellectual" の白＋スカイブルーのデザイン言語のまま取り残されているため、ホーム / rule_explain / countdown / individual_result と同じ **Midnight Cat (v3) デザインシステム** に揃える。

## 背景

- 2026-05-02 の Midnight Cat リデザインで主要画面はすべて黒背景 + シアン発光 + 明朝 (NotoSerifJP-Bold) に移行済み。
- 2026-05-12〜05-16 にかけて countdown / individual_result / ゴースト7番勝負 / rule_explain も MidnightCat 化済み。
- ところが「全ゲーム一覧」だけは旧パレット（白カード + 水色グラデ + 青ボタン）が残っており、ホームから遷移すると**一目で別アプリ**のように見える。
- ユーザフィードバックでも「白すぎてホームと統一感がない」「文字が小さい（最低サイズ規約 2026-05-16 未適用）」と指摘されている。

## 実装対象

### 1. 背景・全体トーンの Midnight Cat 化

- 白 → 漆黒 `BG_VOID` (#000) + 中央放射 nebula グラデ
- StarLayer（`effects/star_layer.gd`）を最下層に重ねる（home / countdown / individual_result と同じ星空エフェクト）

### 2. ヘッダー / サブタイトル

- 旧「白半透明 + 角丸 32」のヘッダーガラスを廃止
- 代わりに **明朝大見出し** 「脳トレ」を `mc_h1` で配置（ホーム / individual_result と同じ日本語トーンに統一）
- その下に補助文「今日のメニューを選ぼう」を 20px (font_size=20 override 必須、mc_subtitle 既定 18px は不採用) で 1 行
- ボトムナビに「ホーム」ボタンが既にあるため、ヘッダーに追加の戻るチップは設けない（機能重複回避）

### 3. カードカルーセル（3D パースペクティブ）

レイアウト構造（中央＋隣接＋遠方の水平ストリップ）と操作（スワイプ・矢印キー・ドット）は **そのまま温存**。見た目だけ差し替える:

| 旧（Animated Intellectual） | 新（Midnight Cat） |
|---|---|
| `bg_color = Color(1,1,1,0.98)` (白カード) | `bg_color = Color(0.04, 0.08, 0.16, 0.55)` (暗グラスパネル) |
| `border_color = Color(1,1,1,1)` | `border_color = CYAN_400 α=0.45 (0.435, 0.706, 1, 0.45)` border_width=1 |
| corner_radius=53 | corner_radius=28（rule_explain step_card と統一） |
| アイコン円: 青 10% 塗り + 青文字 | アイコン円: シアン縁取り (border) + シアン発光文字 |
| カテゴリラベル: 青 18px | カテゴリラベル: シアン `CYAN_400` 22px (font_size override 必須) |
| ゲーム名: 濃紺 36px (Bold) | ゲーム名: **明朝 (mc_h2 / NotoSerifJP-Bold)** 36px インク色 INK_100 (font_size=36 override 必須、mc_h2 既定は 32px) |
| 説明文: グレー 24px | 説明文: `mc_body` INK_80 24px (font_size=24 override 必須、mc_body 既定は 17px) |
| MetricPanel: 薄紫塗り | MetricPanel: 暗グラス + 細シアン枠（individual_result の SBF_premium_dark 系流用） |
| MetricCaption: 18px グレー → "High Score" | INK_60 20px (font_size override 必須、mc_caption 既定 14px は不採用) |
| MetricValue: 青 36px | **金色 GOLD_400** 40px（ハイスコア＝アチーブメント表現を強化） |
| スタートボタン: 青ピル | **シアン発光ピル** `mc_cta_glow` 流用、font_size=28 / custom_minimum_size.y=64 で個別 override |
| COMING SOON タグ: 暗紫 70% | 暗グラスチップ + シアン半透明文字 20px |

### 4. ドットインジケータ

- 旧: 青塗り `Color(0, 0.484, 1, 1)` の Pill
- 新: アクティブ＝シアン発光丸（CYAN_400, 幅 36px）/ 非アクティブ＝INK_40 の小さな丸（11x11）
- 透明度は modulate ではなく color で

### 5. ボトムナビゲーションバー

- 旧: 白パネル + 青アクティブピル + 濃紺グレー文字
- 新: 暗グラス (SBF_nav_dark) + シアン発光アクティブピル + INK_60 非アクティブ文字
- アイコンは Material Symbols のまま、サイズは 2026-05-16 規約に従い **40〜44px**
- ラベル文字は **22〜24px**（直前まで 22px 規約だが game_list は 18-22 が混在）
- アクティブ ＝ 「脳トレ」（=この画面）— `psychology` アイコン

### 6. 最低サイズ規約 (2026-05-16 改訂) の遵守

| 用途 | 旧値 | **新値** |
|---|---|---|
| 本文・カード説明 | 24px | **24-26px** |
| カテゴリラベル | 18px | **20-22px** |
| ゲーム名 (h2) | 36px | 36-40px |
| ハイスコア値 | 36px | 40px |
| MetricCaption | 18px | **20px** |
| ナビラベル | 18-22px | **22-24px** |
| ナビアイコン | 40px | 40-44px |
| ボタン文字 | 20px | **28-32px** |
| タップ要素最小高 | 48px | **56-64px** |

## 受け入れ条件

### 視覚

- [ ] `scenes/ui/game_list.tscn` の背景が `Color(0,0,0,1)` ベース + nebula gradient (rule_explain / home と同じ Gradient_nebula と GradientTexture2D_nebula)
- [ ] `StarLayer` (`scripts/ui/effects/star_layer.gd`) がルート直下に配置されている
- [ ] カードに `theme_type_variation = &"mc_card"` または独自の暗グラス StyleBoxFlat が適用されている（白塗り `Color(1,1,1,*)` が無い）
- [ ] ゲーム名ラベルが NotoSerifJP-Bold（`mc_h2` / `mc_h1` 系）で描画
- [ ] スタートボタンが `mc_cta_glow` 相当のシアン発光ピル
- [ ] ボトムナビが暗グラス背景 + シアンアクティブピル

### 規約遵守

- [ ] `grep -E "font_size = (1[0-9]\b|2[0-3]\b)" scenes/ui/game_list.tscn` が 0 件
- [ ] Godot Editor のインスペクタで各ラベルを目視確認し、`mc_subtitle` / `mc_body` / `mc_caption` の既定 font_size (18 / 17 / 14) のまま放置されたラベルが無い（規約違反は grep だけでは検出不能）
- [ ] タップ可能要素（CardPlayButton / NavTrainButton / NavHomeButton / NavAnalyticsButton / NavAwardButton / NavSettingsButton）の `custom_minimum_size.y >= 56`
- [ ] 赤系の使用なし
- [ ] ハードコード Color 値はパネル StyleBox 内のみで、コントローラ GDScript には無い

### 機能

- [ ] カルーセル操作（左右スワイプ・矢印キー・カードタップ）が動作（ドットは視覚インジケーター専用、タップ非対応のまま）
- [ ] 中央カードのみ「スタート」ボタン or 「COMING SOON」表示
- [ ] スタート押下で対応ゲーム (reflex_tap / flash_calc / sequence_memory) が起動
- [ ] ボトムナビ「ホーム」で `home.tscn` に戻れる
- [ ] DataStore のベストスコアが各カードに表示される（未プレイは `--`）

### 動作確認

- [ ] Godot Editor で `scenes/ui/game_list.tscn` を実行してエラーなし
- [ ] Web エクスポートしてカードカルーセルが想定どおり動く
- [ ] スクリーンショットを撮り、home / individual_result と並べて**1 つのデザインシステム**として通用するか目視確認

## スコープ外

- カルーセル機構の根本変更（操作感の改善は別ステアリングで）
- 新ゲームカードの追加（GAME_CARDS データはそのまま）
- ボトムナビの他画面遷移実装（分析 / アワード / 設定）は依然 TODO のまま据え置き
- ゲーム本体側の UI 変更

## 参照ドキュメント

- `.steering/20260502-MidnightCatリデザイン/design.md` — Midnight Cat デザインシステムの定義
- `.steering/20260512-個別結果画面MidnightCat化/` — 後発リデザインの先例
- `.steering/20260516-フォント追加拡大とマスコット枠削除と縦画面固定/requirements.md` — 最低サイズ規約
- `assets/themes/default_theme.tres` — `mc_*` バリアント定義
- `scripts/utils/color_palette.gd` — Midnight Cat パレット定数
- `scenes/main/home.tscn` / `scenes/ui/individual_result.tscn` — 既存リファレンス画面
