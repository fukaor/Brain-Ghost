# 要求内容

## 概要

個別結果画面 `scenes/ui/individual_result.tscn` を Midnight Cat v3 に統一する。controller ロジックは触らず、シーンファイル内の見た目 (キャラ・背景・色・フォント) のみを差し替える。

## 背景

- ホーム / rule_explain / countdown / ghost_7ban_shobu は Midnight Cat v3 (黒 + Nebula + StarLayer + シアン/ゴールド) で統一済み
- 個別結果画面だけ古い世界観 (水色グラデ + ghost_seirei + 青/緑/赤) で取り残されている
- ユーザ報告: 「結果のリザルト画面について、古いキャラや UI/UX が利用されていたので最新のものに合わせて作り直してほしい」

## 実装対象の機能

### 1. キャラの置換

- `assets/characters/ghost_seirei.png` → `assets/characters/catboy_electric.png`
- `GhostChibi` ノードのテクスチャ参照のみ変更 (サイズ・位置は維持)

### 2. 背景の Midnight Cat 化

`PageBackground` (水色グラデ) を撤去し、rule_explain / countdown と同じ 3 層構成:

- `VoidBg` (ColorRect, 黒)
- `NebulaBg` (TextureRect + 濃紺グラデ `Color(0.04,0.08,0.16)` 〜 `Color(0,0,0)`)
- `StarLayer` (Control + star_layer.gd)

### 3. 文字色の Midnight Cat 統一

| 要素 | 旧色 | 新色 |
|---|---|---|
| ResultsLabel "RESULTS" | `Color(0, 0.484, 1)` 青 | `Color(0.7, 0.93, 1.0)` シアン |
| ScoreValue 巨大数字 | `Color(0.059, 0.09, 0.165)` 濃紺 | `Color(0.95, 0.97, 1.0)` Midnight Cat 白 |
| ScoreUnit | 同上 | 同上 |
| ScoreCaption | `Color(0.314, 0.353, 0.506, 0.6)` グレー青 | `Color(0.78, 0.824, 0.91, 0.7)` Midnight Cat dim |
| NewBestLabel | `Color(0.267, 0.192, 0)` ブラウン | `Color(1.0, 0.914, 0.659)` Midnight Cat ゴールド |
| YouCaption / YouValue | 青系 | シアン (`Color(0.7, 0.93, 1.0)`) |
| GhostCaption / GhostValue | グレー | Midnight Cat dim (`Color(0.78, 0.824, 0.91, 0.7)` / `Color(0.78, 0.824, 0.91, 1)`) |
| VictoryLabel "VICTORY" | `Color(0, 0.353, 0.216)` 緑 | `Color(1.0, 0.914, 0.659)` ゴールド |
| PerfectCaption | グレー青 | Midnight Cat dim |
| PerfectValue | 濃紺 | Midnight Cat 白 |
| MissCaption | グレー青 | Midnight Cat dim |
| **MissValue** | **`Color(0.702, 0.106, 0.145)` 赤** | **`Color(0.533, 0.588, 0.690)` グレー** (GDD ネガティブ色禁止) |
| SpeechText | 濃紺 | Midnight Cat シアン |
| HomeIcon / HomeText | 青 | シアン |

### 4. 機能維持

- `individual_result_controller.gd` は変更しない
- ノード命名は完全維持 (controller の `@onready var` パスが壊れないように)
- `theme_type_variation` (premium_card / glass_bubble / new_best_badge / victory_badge / stat_card / cta_blue / home_button) は維持 (テーマ定義側のスタイルが Midnight Cat 化していないものは別フェーズ判断)

## 受け入れ条件

- [ ] `grep -r "ghost_seirei" scenes/ui/individual_result.tscn` で 0 件
- [ ] `Gradient_resultbg` / `GradientTexture2D_resultbg` / `PageBackground` ノードが削除されている
- [ ] `VoidBg` / `NebulaBg` / `StarLayer` が rule_explain.tscn と同じ SubResource 構成で存在
- [ ] `MissValue` の `font_color` が `Color(0.533, 0.588, 0.690, 1)` (グレー)
- [ ] `VictoryLabel` の `font_color` が `Color(1.0, 0.914, 0.659, 1)` (ゴールド)
- [ ] `ScoreValue` 等の文字色が Midnight Cat 白系 (`Color(0.95, 0.97, 1.0)`)
- [ ] ノード命名が無変更 (`@onready var` パスの破綻なし)
- [ ] ゲーム終了 → 個別結果画面遷移時に visual エラーが出ない
- [ ] 実機 (moto g 66j) でホーム / rule_explain / countdown / 個別結果画面のトーンが一貫している

## 成功指標

- ユーザが「結果画面だけ世界観が浮いている」と感じない
- 縦画面動線 (reflex_tap → reflex_tap 結果) と横画面動線 (ghost_7ban_shobu → 縦復帰結果) の両方で個別結果が一貫して Midnight Cat

## スコープ外

- 総合結果画面 (`scenes/ui/overall_result.tscn`) のリデザイン (存在確認次第別フェーズ)
- 個別結果画面の横画面対応
- `individual_result_controller.gd` のロジック追加
- `default_theme.tres` の theme_type_variation 自体のリデザイン (theme 側の `premium_card` 等のスタイルが古ければ別フェーズ)

## 参照ドキュメント

- `scenes/ui/rule_explain.tscn` - Midnight Cat 縦版 reference
- `scenes/ui/countdown.tscn` - 最近リデザイン済みの reference
- `assets/themes/default_theme.tres` - theme_type_variation 定義
- GDD §6 「負け色=グレー、勝ち=金/緑」
- memory: catboy_electric を正、ghost_seirei 廃止
