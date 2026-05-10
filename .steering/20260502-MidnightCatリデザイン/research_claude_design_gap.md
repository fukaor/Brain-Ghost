# Claude Design 差分マップと改修方針

作成: 2026-05-02 (再起動後の再調査)
対象: home / rule_explain / ghost_7ban_shobu の3画面
基準: `docs/design/promotion/*.png`(理想) ←→ `.steering/20260502-MidnightCatリデザイン/captures/*.png`(現状)
参照: `docs/design/claude_design/brain-ghost/project/mocks/reflex/variant-b.jsx` (mocks)

---

## 1. 共通トークン (variant-b / variant-a で一致確認)

```gdscript
# scripts/utils/color_palette.gd 拡張案
const BG_VOID    = Color("#000000")
const BG_DEEP    = Color("#060912")
const BG_PANEL   = Color("#0B1220")
const BG_ELEV    = Color("#111827")
const INK_100    = Color("#F4F7FF")
const INK_80     = Color("#C7D2E8")
const INK_60     = Color("#8896B0")
const INK_40     = Color("#4A5570")
const INK_20     = Color("#232B3F")
const CYAN_300   = Color("#B8E0FF")
const CYAN_400   = Color("#6FB4FF")
const CYAN_500   = Color("#3D8BE8")
const CYAN_GLOW  = Color(0.435, 0.706, 1.0, 0.55)
const GOLD_300   = Color("#FFE9A8")
const GOLD_400   = Color("#F5C76A")
const GOLD_GLOW  = Color(0.961, 0.78, 0.416, 0.6)
const RED_400    = Color("#E55A5A")
const RED_500    = Color("#C73B3B")
const RED_GLOW   = Color(0.906, 0.353, 0.353, 0.5)
```

色値が現行 `color_palette.gd` と微妙に違う (例: `PRIMARY_CYAN` は `#7DD3FC` だが mocks は `#6FB4FF`)。**正は variant-b**。

---

## 2. home.tscn 差分

| 項目 | promo (理想) | 現状 (Godot) | 差分 |
|---|---|---|---|
| 全体トーン | iPhone モック内に「**毎日2分、昨日の自分に挑め。**」明朝コピー外側 | コピーなし | ヘッダコピーが欠落 (画面外でも下部に配置すべきか要検討) |
| 脳年齢ブロック | 左上、コンパクト | 左上にあるが大きすぎる | フォント縮小・位置調整 |
| マスコット | 右上、**小さめ・吹き出し付き** (アイコン高 ≒ 110px) | 右側、**240px と大きすぎる**、吹き出し離れている | サイズ 240→160px、吹き出しをマスコット隣接バブルに変更 |
| 吹き出し位置 | マスコット脇 (右上) に隣接 | 中央に独立カード | マスコット隣接配置に |
| 吹き出しスタイル | パネル `#0B1220` + cyan500 1px border + 三角矢印 | mc_speech (角丸枠のみ) | 三角矢印追加 + border 強化 |
| 3,230pts ピル | 細長 + 通算ピル並列 | OK | promo に近い、サイズだけ要確認 |
| 「今日のチャレンジ」CTA | **太い** ピル、cyan強グロー、明朝太字 | OK だが グロー弱め | グロー強化 (`rb-glow` 風アニメ) |
| 5日連続リボン | ゴールド ストライプ風 + 炎アイコン | gold ピル | OK |
| レーダーチャート | 中央配置、**やや小さめ**、白点グロー | やや大きい、グロー弱い | サイズ -15%、頂点白点 + glow 追加 |
| 全ゲーム一覧リンク | 下端、明朝小字 | OK | OK |
| 背景 starfield | **8 点 radial-gradient 星空** | なし | StarLayer 追加 |
| ヘッダタイトル | 「毎日2分、昨日の自分に挑め。」(promo は外側だが Godot では画面内最上部に置きたい) | なし | 追加候補 (要判断) |

---

## 3. rule_explain.tscn 差分 (ghost_7ban_shobu 例)

| 項目 | promo | 現状 | 差分 |
|---|---|---|---|
| ヘッダ | 「📖 ルール説明」ピル小 (中央) | OK | OK |
| 大見出し | 明朝、「ゴースト7番勝負」 | OK | OK |
| サブタイトル | 「鍛える能力：反射速度」cyan | OK | OK |
| ステップカード×3 | 各カードに **第3戦/7** バッジ + 進捗ドット (cyan/gold/grey) | カード内右上にドットあるが promo では cyan/gold/grey が「現在の勝敗状態」を示している | カード演出不足 (TAP! の十字バースト/グロー) |
| プレビュー1: 構える | 線 + YOU(ゴールド) + GATE縦線 + GHOST(シアン) | OK | OK |
| プレビュー2: タップ | 中央オーブ + **十字バースト + 多重リング** + TAP! ラベル | 中央オーブのみ、リング1層、TAP! 小さい | リング多層化 + 十字バーストライン (上下左右の光線) 追加 |
| プレビュー3: 比較 | 87ms ゴールド + 142ms シアン + 人/猫アイコン | OK | OK |
| スタートCTA | **太い** 丸ボタン、強グロー、明朝大字 | 細い | パディング増 + グロー強化 (cb-glow アニメ) |
| 背景 starfield | あり (薄い) | なし | StarLayer 追加 |

---

## 4. ghost_7ban_shobu (本体ゲーム) 差分

### Play 画面

| 項目 | promo | 現状 | 差分 |
|---|---|---|---|
| HUD 左上 | 「第N戦/7」 + 進捗ドット (赤×が miss、cyan が win) | 「第1戦/7」 + 黄色□と灰色□ | ドットを **win=cyan円glow / lose=red× / 未戦=空丸枠 / 進行中=白枠**に |
| HUD 右上 | YOU N - N GHOST (小さめ、cyan/ink) | OK | OK |
| GATE 中央光線 | **細い** 2px 縦線 + halo 楕円 + GATE ラベル文字 | 太い円柱状 | 細く 2px に変更、ラベル「GATE」追加 |
| レーン | 4層 (外22px 0.15 / 中10px 0.25 / 点線2px 0.6 dashed / コア1px 0.85) | 単純なライン | 4層レンダに変更 |
| YOU orb | 32px、core white → aura cyan、横ぼかしtrail (進行方向逆 64x8px blur) | OK (実装済み) | OK |
| GHOST orb | 28px、core ink80 → aura cyan弱 | 同色 (cyan) | サイズと色を区別 |
| LANE 名/反応時間 | 上部に「LANE · 直線」「GHOST反応 152ms」 | なし | 追加 |
| 背景 starfield | あり | なし | StarLayer 追加 |
| HISTORY タイル | 画面下部 7 列、各戦の delta/勝敗を表示 | なし | 追加 |

### Result 画面

| 項目 | promo | 現状 | 差分 |
|---|---|---|---|
| ヘッドライン | **PERFECT/GREAT/GOOD/LATE/MISS** 52px 明朝、状況色 (gold/cyan/ink) | 「MISS」のみ | grade 全種対応 + アニメ rb-headline |
| WIN/LOSE 副題 | 13px serif letter-spacing 0.6em | なし | 追加 |
| GATE 縦光線 | 1px 全高、ゴールド薄 | 太い | 細線化 |
| YOU タップ点 → GATE 点線 | 3px-3px の repeating 点線 + 中央に「-Xms」「+Xms」ラベル | なし | 追加 |
| GHOST → GATE 点線 | 同様 (薄め ink60) + 「-/+ Xms」 | なし | 追加 |
| YOU レーザー | hit→画面端、core グラデ + 140 パーティクル散布 | なし | 追加 (SideLaser) |
| GHOST レーザー | hit→画面端、弱め (70 パーティクル) | なし | 追加 |
| VerticalFlare | hit 点から上下に縦光線 | なし | 追加 |
| Ring 7層 | 24/38/56/78/102/130/162px 同心円 (cubic-bezier アニメ) | あり (簡易版) | 7 層化 |
| Core | 中央 10px 白点 + glow | あり | OK |
| YOU silhouette 左下 | 50x74px 人型シルエット | アイコンのみ | 人型 SVG パス相当に |
| GHOST 右下 | catboy_electric.png 76x76 + glow | アイコン (人マーク) | 黒猫マスコットPNGに |
| ms 表示 | YOU 上 (hit-86px) / GHOST 下 (ghost+60px) | OK | 位置微調整 |
| 「TAP で 次の戦」 | 下部小字 | なし | 追加 |

### Ready / Done 画面

| 項目 | promo (Ready) | 現状 | 差分 |
|---|---|---|---|
| Ready 左テキスト | "GHOST · 7-BAN" 小cyan / "7 番勝負" 64px serif / 「昨日の自分が、いま光の向こうから挑んでくる。」/ TAP で開始 ボタン | あり | 構成OK、テキストタイポを揃える |
| Ready マスコット | catboy_confident.png 200px 右下 + bob アニメ + 吹き出し「おかえり、今日もやる？」 | あり | OK |
| Done | "決着" / wins-gwins 110px / 「昨日の自分を、超えた。」「互角。」「もう一歩。」 | あり | OK |

---

## 5. 共通エフェクトの再利用化

`scripts/ui/effects/` 配下に独立コンポーネント化する候補:

| アセット | 役割 | 主な利用先 |
|---|---|---|
| `star_layer.gd` (Control) | 8 点星空背景 | 全画面 |
| `aura_layer.gd` (Control) | 上部楕円グロー | 全画面 |
| `glow_orb.gd` (Control) | YOU/GHOST オーブ + trail | ghost_7ban_shobu / rule_explain (preview) |
| `tap_burst.gd` (Control) | tap時の Ring×N + Core + Cross flare | ghost_7ban_shobu / 反射タップ系 |
| `side_laser.gd` (Control) | hit→端のパーティクル含む光線 | ghost_7ban_shobu Result |
| `vertical_flare.gd` (Control) | hit 点上下の縦光線 | ghost_7ban_shobu Result |
| `cyan_gate.gd` (Control) | GATE 縦光線 + halo + ラベル | ghost_7ban_shobu |
| `dotted_delta.gd` (Control) | 2点間の repeating dotted line + ラベル | ghost_7ban_shobu Result |
| `progress_dots.gd` (Control) | win/lose/empty/cur 進捗ドット | ghost_7ban_shobu HUD |
| `glow_cta.gd` (Control) | cyan border ピル + glow pulse アニメ | home / rule_explain / ready / done |
| `headline_serif.gd` (Control) | rb-slam + glow ヘッドライン | result / countdown |

---

## 6. 改修方針 (実装順)

1. **エフェクトアセット切り出し** (`scripts/ui/effects/*.gd` + `.tscn`)
   - 上記コンポーネントを単独で動く形に切り出し、テストシーンで確認可能に
2. **color_palette.gd の値を variant-b 準拠に補正** (`CYAN_300/400/500` `INK_100/80/60/40/20` `GOLD_300/400` を追加 / 既存名は alias)
3. **home.tscn 改修** (StarLayer / マスコット縮小 + 吹き出し移動 / レーダー縮小 / CTA グロー強化)
4. **rule_explain.tscn 改修** (StarLayer / preview の TapBurst リング多層化 / CTA 太く)
5. **ghost_7ban_shobu 改修** (StarLayer / レーン4層 / 細GATE / Result の SideLaser+VerticalFlare+Ring×7+Headline+Dotted-delta / progress_dots / HISTORY タイル / catboy 黒猫 PNG 配置 )
6. **再キャプチャ → promo 並列比較**

## 7. 残課題 (今回スコープ外、次イテレーション)

- flash_calc の Midnight Cat 移行 (variant-a 準拠)
- countdown / individual_result / overall_result の Midnight Cat 移行
- HISTORY タイルのレスポンシブ縮小 (七戦中の表示密度)
