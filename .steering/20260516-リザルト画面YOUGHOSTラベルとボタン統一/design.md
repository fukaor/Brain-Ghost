# 設計

## シーン変更概要

### CompareCards

```
CompareCards (HBox)
├── YouCard (PanelContainer, glass_dark + cyan border)
│   └── YouVBox (VBox, separation=4)
│       ├── YouHeader (Label, "YOU", cyan300, 28pt, serif)   ★新規
│       ├── YouAvatar (TextureRect 64x64)                    (既存より小さく)
│       ├── YouCaption (Label, "平均", 20pt, dim)
│       └── YouValue (Label, "112ms", 48pt, cyan)
└── OpponentCard (PanelContainer, glass_dark + gray/gold border)
    └── OpponentVBox (VBox, separation=4)
        ├── OpponentHeader (Label, "GHOST"/"BEST", 28pt, serif) ★新規
        ├── OpponentAvatar (TextureRect 64x64)
        ├── OpponentCaption (Label, "平均"/"自己ベスト", 20pt, dim)
        └── OpponentValue (Label, "158ms", 48pt, dim/gold)
```

### Button 群

```
SafeAreaMargin/MainColumn
├── ...
├── ReplayCTAWrap (Control, height 88px)        ★新規構造
│   ├── GlowFx (Control, script=glow_cta.gd)
│   └── ReplayButton (Button, mc_cta_glow, text="もう一度  ↻")
├── HomeButton (Button, StyleBoxEmpty,          ★差し替え
│    text="‹  ホームへ戻る",
│    font_color cyan dim, font_size 18)
```

ButtonSpacer は据え置き（VBox の vertical_size_flags=3 で残スペースを確保）。

## カード別ボーダー色

SBF_glass_dark を 3 種類に分岐:

- **SBF_card_you**: border `Color(0.435, 0.706, 1.0, 0.55)` (cyan)
- **SBF_card_ghost**: border `Color(0.6, 0.65, 0.75, 0.4)` (gray dim)
- **SBF_card_best**: border `Color(1.0, 0.914, 0.659, 0.55)` (gold)

シーンには SBF_card_you / SBF_card_ghost を最初から適用しておき、`_apply_compare_cards` で compare_mode が self_best の場合のみ OpponentCard を SBF_card_best に差し替える（コントローラ内で `theme_override_styles/panel` 経由）。

## Controller 変更

### 新規 @onready
- `_you_header: Label`
- `_opponent_header: Label`

### `_apply_compare_cards()` の挙動

```gdscript
_you_header.text = "YOU"
_you_header.add_theme_color_override("font_color", COLOR_CYAN300)

if mode == "ghost":
    _opponent_header.text = "GHOST"
    _opponent_header.add_theme_color_override("font_color", COLOR_GRAY_DIM)
    # ボーダーは scene デフォルト (SBF_card_ghost) のまま
else:  # self_best
    _opponent_header.text = "BEST"
    _opponent_header.add_theme_color_override("font_color", COLOR_GOLD)
    _opponent_card.add_theme_stylebox_override("panel", _sbf_card_best)
    _opponent_value.add_theme_color_override("font_color", COLOR_GOLD)
```

ボタンノードパス変更:
- `_replay_button` のパス: `$SafeAreaMargin/MainColumn/ReplayCTAWrap/ReplayButton`

## キャプチャ検証

- `tools/capture_individual_result.gd` は既存のまま使用（OS 環境変数 CAPTURE_CASE で 4 ケース）
- 4 ケース PNG を steering captures フォルダに上書き出力
- 比較:
  - YOU / GHOST / BEST の文言が読み取れる
  - ボタンが home / rule_explain と統一されたグロー CTA
  - HomeButton が地味で「副次的」に見える
