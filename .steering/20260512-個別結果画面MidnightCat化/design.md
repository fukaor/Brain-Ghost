# 設計書

## アーキテクチャ概要

シーンファイル `individual_result.tscn` のみを編集する局所変更。controller (`individual_result_controller.gd`) は変更不要。背景階層と各 Label の color/font 設定を Midnight Cat v3 用に上書きする。

```
[before]                        [after]
IndividualResult                IndividualResult
├ PageBackground (水色グラデ)    ├ VoidBg (黒)
└ SafeAreaMargin                 ├ NebulaBg (濃紺)
   └ MainColumn                  ├ StarLayer
      └ GhostRow                 └ SafeAreaMargin
         ├ GhostChibi               └ MainColumn
         │  └ ghost_seirei             └ GhostRow
         └ SpeechBubble                   ├ GhostChibi
                                          │  └ catboy_electric ★
                                          └ SpeechBubble
```

## コンポーネント設計

### 1. 背景階層の差し替え

**現状**:
```
[node name="PageBackground" type="TextureRect" parent="."]
texture = SubResource("GradientTexture2D_resultbg")  ← 水色グラデ
```

**変更後**:
```
[node name="VoidBg" type="ColorRect" parent="."]
color = Color(0, 0, 0, 1)

[node name="NebulaBg" type="TextureRect" parent="."]
texture = SubResource("GradientTexture2D_nebula")  ← rule_explain と同じ

[node name="StarLayer" type="Control" parent="."]
script = ExtResource("star_layer.gd")
```

SubResource (`Gradient_nebula`, `GradientTexture2D_nebula`) は rule_explain.tscn からそのままコピー。

### 2. キャラ参照の差し替え

```
[ext_resource type="Texture2D" path="res://assets/characters/catboy_electric.png" id="3_ghost"]
```

`id="3_ghost"` のままにすることで、`GhostChibi.texture = ExtResource("3_ghost")` の参照を変更不要。

### 3. 文字色マップ

`Color(0.7, 0.93, 1.0)` を **MC_CYAN** と呼ぶ。
`Color(1.0, 0.914, 0.659)` を **MC_GOLD**。
`Color(0.95, 0.97, 1.0)` を **MC_WHITE**。
`Color(0.78, 0.824, 0.91)` を **MC_DIM**。
`Color(0.533, 0.588, 0.690)` を **MC_GRAY** (負け色)。

| ノード | font_color 設定 |
|---|---|
| ResultsLabel | MC_CYAN |
| ScoreValue | MC_WHITE |
| ScoreUnit | MC_WHITE |
| ScoreCaption | MC_DIM (alpha 0.7) |
| NewBestLabel | MC_GOLD (textの濃ゴールド色を直接) |
| YouCaption | MC_CYAN (alpha 0.6) |
| YouValue | MC_CYAN |
| GhostCaption | MC_DIM (alpha 0.6) |
| GhostValue | MC_DIM (alpha 1) |
| VictoryLabel | MC_GOLD |
| PerfectCaption | MC_DIM (alpha 0.7) |
| PerfectValue | MC_WHITE |
| MissCaption | MC_DIM (alpha 0.7) |
| MissValue | MC_GRAY (赤撤廃) |
| SpeechText | MC_CYAN |
| HomeIcon | MC_CYAN |
| HomeText | MC_CYAN |

### 4. theme_type_variation の取り扱い

`premium_card`, `glass_bubble`, `new_best_badge`, `victory_badge`, `stat_card`, `cta_blue`, `home_button`, `icon_pill` は `default_theme.tres` で定義されている。これらがどう描画されるかは theme 側に依存:

- もし theme 側が古い水色基調なら、別フェーズで theme リデザインが必要
- 本フェーズでは scene 内で **直接 font_color を override** することで上書き (上記マップ通り)
- theme そのものの修正は本フェーズのスコープ外

## データフロー

変更なし。GameManager 経由のシーン遷移 (`on_game_finished_handler` → `individual_result.tscn`) はそのまま。controller の `_ready()` で各ノード参照を取得し、`_current_play_log` 経由でスコアを表示する流れも維持。

## エラーハンドリング戦略

- ノード命名を維持することで `@onready var` の null 参照を防ぐ
- 背景階層の置き換え時、`PageBackground` の参照が controller に無いことを事前確認

## テスト戦略

### 静的チェック

- `grep -r "ghost_seirei" scenes/ui/individual_result.tscn` で 0 件
- `godot --headless --import` でシーンが警告なくロードできる

### 実機検証

- ゴースト7番勝負 → 完走 → 個別結果画面が Midnight Cat で表示される
- 縦動線 (reflex_tap 等) でも同様に Midnight Cat で表示される
- Replay / Home ボタンが正しく動作する

## 依存ライブラリ

なし。既存の `star_layer.gd` / `speech_bubble.gd` を流用。

## ディレクトリ構造

```
/workspace/
└── scenes/ui/
    └── individual_result.tscn  ← 編集対象 (シーンのみ)
```

スクリプト・テーマファイルは変更しない。

## 実装の順序

1. **rule_explain.tscn から背景階層の SubResource をコピー** (Gradient_nebula / GradientTexture2D_nebula)
2. **ext_resource の差し替え** (ghost_seirei → catboy_electric, star_layer.gd 追加)
3. **PageBackground ノード削除 + VoidBg/NebulaBg/StarLayer 追加**
4. **不要な SubResource (Gradient_resultbg / GradientTexture2D_resultbg) の削除**
5. **各 Label の font_color 上書き**
6. **デプロイ & 実機検証**
7. **振り返り**

## セキュリティ考慮事項

該当なし (UI 変更のみ)

## パフォーマンス考慮事項

StarLayer が追加で _process しているが、rule_explain / countdown と同じスケールなので追加負荷ほぼなし。

## 将来の拡張性

- 総合結果画面が今後実装される場合、同様のリデザインパターン (背景階層 + 色マップ) で対応可能
- theme_type_variation の中身を Midnight Cat 化するなら、`default_theme.tres` 側で個別結果画面以外の参照箇所と一気に更新する流れになる
