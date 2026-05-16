# 要求内容

## 概要

個別結果画面（`scenes/ui/individual_result.tscn` + `scripts/ui/individual_result_controller.gd`）について、ユーザレビューで判明した次の 2 点を修正する:

1. **YOU/GHOST が判別不能**: 比較カードに SD キャラ（catboy_electric vs catboy_confident）を並べているが、サイズが小さく色味も似ているため、どちらが自分でどちらがゴーストか分からない。各カードに「YOU」「GHOST」（あるいは self_best モードでは「YOU」「BEST」）の明示テキストを最上段に追加する。
2. **ボタンが他画面と統一されていない**: 「もう一度」「ホームへ戻る」が古い `cta_blue`（青グラデーション）と `home_button`（白ピル）テーマを使っており、Midnight Cat 暗色背景から浮いている。`rule_explain.tscn` のスタートボタン（`mc_cta_glow` + GlowCTA）と統一する。

## 背景

- 直前ステアリング `20260515-個別結果画面リザルトイメージ準拠リデザイン` でレイアウトは完成したが、ボタン部分は「リザルトイメージ画像」準拠でデザインされており、`mc_cta_glow` ベースの新 CTA デザインに切り替えるべき箇所が残っていた
- `cta_blue` / `home_button` テーマは個別結果画面でしか使われておらず、メンテナンス上も削除候補
- SD キャラの色対比だけでは「自分 vs ゴースト」を瞬時に判別できないことが UX レビューで判明。Lumosity / Peak の比較 UI でも「YOU / BEST」のような明示ラベルが定石

## 実装対象

### 1. CompareCards に YOU / GHOST / BEST ヘッダラベル追加

各 PanelContainer の VBox 先頭に Label を挿入:

| compare_mode | YouCard | OpponentCard |
|---|---|---|
| ghost | "YOU" (cyan, bold) | "GHOST" (gray dim, bold) |
| self_best | "YOU" (cyan, bold) | "BEST" (gold, bold) |

スタイル:
- font: NotoSerifJP-Bold (`6_mcserif`) または theme default
- font_size: 28px
- letter_spacing: やや広め
- horizontal_alignment: center
- YOU 色: `COLOR_CYAN300` `Color(0.435, 0.706, 1.0)`
- GHOST 色: `COLOR_GRAY_DIM` `Color(0.6, 0.65, 0.75)`
- BEST 色: `COLOR_GOLD` `Color(1.0, 0.914, 0.659)`

既存の "平均"/"スコア" キャプションは sub-label として残し font_size を小さくする (20px)。

### 2. YouCard / OpponentCard のボーダー色差別化

カード単位でも自分とゴーストを区別:

- **YouCard**: border_color `Color(0.435, 0.706, 1.0, 0.55)` (cyan, やや強め)
- **OpponentCard (ghost)**: border_color `Color(0.6, 0.65, 0.75, 0.4)` (gray dim)
- **OpponentCard (self_best)**: border_color `Color(1.0, 0.914, 0.659, 0.55)` (gold)

self_best モードのカラー差はコントローラ側で動的にオーバーライドする。

### 3. ReplayButton を mc_cta_glow + GlowCTA に置換

`scenes/main/home.tscn` の CTAButton / `scenes/ui/rule_explain.tscn` の StartButton と同じパターン:

```
[node name="ReplayCTAWrap" type="Control"]
  [node name="GlowFx" type="Control" script="glow_cta.gd"]
  [node name="ReplayButton" type="Button"
   theme_type_variation = &"mc_cta_glow"
   theme_override_styles/normal = StyleBoxEmpty
   ...
   text = "もう一度  ↻"]
```

- icon は Material Symbols `replay` から Unicode `↻` または `▶` に切替（home.tscn の `›` パターンに合わせて）
- height: 88px (home の CTA と統一)

### 4. HomeButton を地味なテキストリンクに置換

`scenes/main/home.tscn` の AllGamesLink パターン（StyleBoxEmpty + 地味な cyan dim テキスト）:

```
[node name="HomeButton" type="Button"
 theme_override_styles/normal = StyleBoxEmpty_clean
 theme_override_styles/hover = StyleBoxEmpty_clean
 theme_override_styles/pressed = StyleBoxEmpty_clean
 theme_override_colors/font_color = Color(0.682, 0.722, 0.812, 1)
 theme_override_font_sizes/font_size = 18
 text = "‹  ホームへ戻る"]
```

- アイコン文字は Unicode `‹` をテキスト先頭に組み込む（home の AllGamesLink が末尾 `›` を使っているのに対し、戻るは先頭 `‹`）
- セパレーション 8px

### 5. Controller 更新

- `_apply_compare_cards()` に YOU/GHOST/BEST ヘッダラベルとボーダー色を反映するロジックを追加
- 新ノード参照 `_you_header`, `_opponent_header` を `@onready` で追加
- ボタンノードパス変更 (ReplayButton → ReplayCTAWrap/ReplayButton) に追従

## 受け入れ条件

- [ ] CompareCards の YouCard に「YOU」、OpponentCard に「GHOST」または「BEST」ラベルが表示される
- [ ] ghost_7ban_shobu / reflex_tap (compare_mode=ghost) で OpponentCard に「GHOST」
- [ ] flash_calc 等 (compare_mode=self_best) で OpponentCard に「BEST」
- [ ] YouCard ボーダーが cyan, OpponentCard ボーダーが ghost モードで gray / self_best モードで gold
- [ ] ReplayButton が `mc_cta_glow` + GlowCTA で home/rule_explain と同じ見た目
- [ ] HomeButton が StyleBoxEmpty ベースの地味なテキストリンク
- [ ] `grep "cta_blue\|home_button" scenes/ui/individual_result.tscn` が 0 件
- [ ] 4 ケース キャプチャ（perfect_win / nice_try / new_best / improved）取り直しで自分とゴーストの判別が明確
- [ ] Godot で parse / 実行時エラーなし

## スコープ外

- 総合結果画面のボタン統一（別ステアリング）
- `default_theme.tres` から `cta_blue` / `home_button` テーマ定義の削除（個別結果から参照が消えるだけで定義は残す）
- アバター画像の刷新

## 参照

- 直前ステアリング: `.steering/20260515-個別結果画面リザルトイメージ準拠リデザイン/`
- mc_cta_glow 利用例: `scenes/main/home.tscn`, `scenes/ui/rule_explain.tscn`
- AllGamesLink パターン: `scenes/main/home.tscn:328`
