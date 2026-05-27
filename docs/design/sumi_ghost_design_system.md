# Sumi Ghost Design System (v4)

> **Single Source of Truth (SSOT)**
>
> 本ドキュメントはブレインゴーストの**色・テキスト・コンポーネント仕様の唯一の正本**。
> 既存 `docs/design/manifest.md` と `docs/design/patterns.md` は旧 Midnight Cat v3 用の参考資料に降格。
>
> 一次情報源:
> - `scripts/utils/color_palette.gd` (v4 Sumi Ghost ブロック)
> - ユーザ提供アセット `assets/characters/sumineko_*.png` / `assets/backgrounds/washi_*.png`
> - 2026-05-25 墨絵リブランド経緯
>
> バージョン: v4 / 2026-05-26 / Sumi Ghost (墨絵調)

---

## 1. トークン

### 1-1. カラートークン（13 色）

| トークン | Hex | 用途 |
|---|---|---|
| `WASHI_BASE` | `#F2E9D5` | 全画面最背景（和紙） |
| `WASHI_PANEL` | `#E8DCC0` | カード／パネル背景 |
| `WASHI_SHADE` | `#D6CFBE` | サブパネル／セパレータ |
| `SUMI_INK` | `#1B1B1F` | 主要テキスト・線・SDキャラ墨 |
| `SUMI_MID` | `#3D3D44` | サブテキスト・ボタン文字 |
| `SUMI_LIGHT` | `#6B6B72` | キャプション・説明文 |
| `SUMI_DIM` | `#A39E94` | プレースホルダ・無効状態 |
| `ONIBI_BLUE` | `#7AB3E0` | CTA・進捗・ハイライト |
| `ONIBI_GLOW` | `#D8EBF7` | グロー・明色アクセント |
| `ONIBI_DEEP` | `#3D6B95` | 押下色・深い鬼火・リンク／CTAテキスト |
| `GOLD_AGED` | `#C8A951` | NEW BEST・達成・猫目 |
| `JADE_INK` | `#5A8A6E` | 正解・ペア成立 |
| `GHOST_INK` | `#7A7A7E` | 生霊ゴースト（α 連動） |

### 1-2. タイポグラフィ

| 用途 | フォント | サイズ |
|---|---|---|
| 見出し（明朝） | NotoSerifJP-Bold | 24-72px |
| 本文・ボタン | NotoSansJP-Bold | 14-22px |
| アイコン | MaterialSymbolsRounded | 16-64px |

---

## 2. 表面階層（Surface Hierarchy）

3 段の和紙階層で深度を表現する。**色だけで階層を作る**（影は最小限、StyleBox の border は SUMI_DIM × α）。

```
Background  (WASHI_BASE)          画面全体
  └─ Panel  (WASHI_PANEL)         カード / ピル
       └─ Shade (WASHI_SHADE)     サブパネル / セパレータ / 入力欄
```

---

## 3. テキスト階層

| 階層 | トークン | サイズ目安 | フォント |
|---|---|---|---|
| H1 Display | `SUMI_INK` | 36-72px | NotoSerifJP-Bold |
| H2 Headline | `SUMI_INK` | 24-32px | NotoSerifJP / NotoSansJP-Bold |
| Body | `SUMI_MID` | 14-18px | NotoSansJP-Bold |
| Caption | `SUMI_LIGHT` | 12-14px | NotoSansJP-Bold |
| Disabled | `SUMI_DIM` | — | — |

---

## 4. アクセントトークン

| 役割 | トークン | 使用例 |
|---|---|---|
| CTA / Active | `ONIBI_BLUE` (枠 + ハイライト) + `ONIBI_DEEP` (テキスト) | スタートボタン / 進捗バー |
| Achievement | `GOLD_AGED` | NEW BEST / ベスト pill / 達成バッジ |
| Positive / Match | `JADE_INK` | 正解フィードバック / ペア成立 |
| Ghost / 生霊 | `GHOST_INK` (α 0.25 〜 1.0) | ゴースト本体（精度 % で α 連動） |

---

## 5. 背景レイヤリング規約（**最重要**）

### 規約

- **シーン内の背景ノードは `WashiBackground` 1 つだけ**
- 以下のノードはすべて**禁止**：
  - `VoidBg` (ColorRect 黒系)
  - `NebulaBg` (TextureRect グラデ)
  - `StarLayer` (Control 星粒子)
  - `Background` / `BG` 系の独自背景
- WashiBackground は以下の構造で配置：

```
[node name="WashiBackground" type="TextureRect" parent="."]
texture = ExtResource("res://assets/backgrounds/washi_<screen>.png")
expand_mode = 1
stretch_mode = 6    # KEEP_ASPECT_COVERED
layout_mode = 1
anchors_preset = 15  # full rect
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2     # IGNORE
z_index = -100
```

### 画面別 washi 背景アセット

| シーン | 推奨アセット |
|---|---|
| launch.tscn | `washi_base.png` |
| home.tscn | `washi_home.png` |
| game_list.tscn | `washi_base.png` |
| rule_explain.tscn / _landscape | `washi_tutorial.png` |
| countdown.tscn / _landscape | `washi_base.png` |
| individual_result.tscn | 動的: `washi_result_win.png` / `washi_result_lose.png` |
| ゲームシーン 6 種 | `washi_play.png` |

---

## 6. コンポーネントパターン

### 6-1. Button (Primary CTA)

```
StyleBoxFlat:
  bg_color = WASHI_PANEL (0.85α)
  border_color = ONIBI_BLUE
  border_width = 2
  corner_radius = 999  # ピル形

Label:
  font_color = ONIBI_DEEP  (押下時は ONIBI_GLOW)
```

JuicyBounce attach 推奨（タップで scale spring + ハプティック）。

### 6-2. Button (Secondary / Ghost)

```
StyleBoxFlat:
  bg_color = transparent
  border_color = SUMI_LIGHT
  border_width = 1
  corner_radius = 16

Label:
  font_color = SUMI_MID
```

### 6-3. Card / Panel

```
StyleBoxFlat:
  bg_color = WASHI_PANEL
  border_color = SUMI_DIM (α 0.4)
  border_width = 1
  corner_radius = 12
  content_margin = 16
```

### 6-4. Pill / Badge

```
StyleBoxFlat:
  bg_color = WASHI_SHADE (0.85α)
  corner_radius = 999

Label:
  font_color = SUMI_INK (主要) / GOLD_AGED (達成系)
```

### 6-5. Headline (Display)

```
Label:
  font = NotoSerifJP-Bold
  font_size = 48-72
  font_color = SUMI_INK
```

### 6-6. CardComponent（神経衰弱）

| 状態 | bg | border | テキスト |
|---|---|---|---|
| 裏面 | WASHI_PANEL | SUMI_LIGHT (0.6α) | 肉球 `pets` を ONIBI_BLUE 0.25α |
| 表面 | WASHI_BASE | ONIBI_BLUE (0.95α) | visual.color |
| Match Flash | JADE_INK (0.3α) | JADE_INK | （アイコン維持） |
| Mismatch Flash | SUMI_DIM (0.3α) | SUMI_LIGHT | （アイコン維持） |
| Matched | WASHI_PANEL (0.5α) | ONIBI_BLUE (0.3α) | visual.color (α 0.4) |

---

## 7. 状態色（インタラクション）

| 状態 | Button | Card |
|---|---|---|
| normal | base | base |
| hover | bg + ONIBI_GLOW × 0.15 | shadow 強め |
| pressed | bg = ONIBI_DEEP × 0.3 | shadow なし |
| disabled | bg = WASHI_SHADE, text = SUMI_DIM | — |
| focus | border = ONIBI_BLUE × 2.0px | — |

---

## 8. v3 (Midnight Cat) → v4 (Sumi Ghost) 移行表

### 8-1. font_color マッピング

| 旧 (v3) | 新 (v4) | 役割 |
|---|---|---|
| `Color(0.7, 0.93, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.722, 0.878, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.722, 0.878, 1.0, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK (.0 揺れ) |
| `Color(0.722, 0.878, 1, 0.7)` | `Color(0.106, 0.106, 0.122, 0.85)` | SUMI_INK × 0.85 |
| `Color(0.722, 0.878, 1, 0.75)` | `Color(0.106, 0.106, 0.122, 0.85)` | |
| `Color(0.722, 0.878, 1, 0.95)` | `Color(0.106, 0.106, 0.122, 0.95)` | |
| `Color(0.7, 0.93, 1, 0.85)` | `Color(0.106, 0.106, 0.122, 0.9)` | |
| `Color(0.7, 0.93, 1, 0.7)` | `Color(0.106, 0.106, 0.122, 0.75)` | |
| `Color(0.7, 0.93, 1, 0.6)` | `Color(0.106, 0.106, 0.122, 0.65)` | |
| `Color(0.95, 0.97, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.95, 0.97, 1, 0.9)` | `Color(0.106, 0.106, 0.122, 0.9)` | |
| `Color(0.957, 0.969, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | |
| `Color(0.957, 0.969, 1, 0.95)` | `Color(0.106, 0.106, 0.122, 0.95)` | |
| `Color(0.957, 0.969, 1.0, 1)` | `Color(0.106, 0.106, 0.122, 1)` | |
| `Color(0.949, 0.957, 0.98, 1)` | `Color(0.106, 0.106, 0.122, 1)` | |
| `Color(0.78, 0.824, 0.91, 1)` | `Color(0.239, 0.239, 0.267, 1)` | SUMI_MID |
| `Color(0.78, 0.824, 0.91, 0.7)` | `Color(0.239, 0.239, 0.267, 0.75)` | |
| `Color(0.78, 0.824, 0.91, 0.75)` | `Color(0.239, 0.239, 0.267, 0.85)` | |
| `Color(0.78, 0.824, 0.91, 0.85)` | `Color(0.239, 0.239, 0.267, 0.9)` | |
| `Color(0.78, 0.824, 0.91, 0.95)` | `Color(0.239, 0.239, 0.267, 1)` | |
| `Color(0.78, 0.824, 0.91, 0.6)` | `Color(0.239, 0.239, 0.267, 0.6)` | |
| `Color(0.682, 0.722, 0.812, 1)` | `Color(0.420, 0.420, 0.447, 1)` | SUMI_LIGHT |
| `Color(0.533, 0.588, 0.69, 1)` | `Color(0.420, 0.420, 0.447, 1)` | SUMI_LIGHT |
| `Color(0.29, 0.333, 0.439, 1)` | `Color(0.239, 0.239, 0.267, 1)` | SUMI_MID |
| `Color(0.6, 0.65, 0.75, 1)` | `Color(0.639, 0.620, 0.580, 1)` | SUMI_DIM |
| `Color(0.435, 0.706, 1, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP |
| `Color(0.435, 0.706, 1.0, 1)` | `Color(0.239, 0.420, 0.584, 1)` | |
| `Color(0.49, 0.827, 0.988, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP (nav用) |
| `Color(0.118, 0.533, 0.898, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP |
| `Color(0.435, 0.847, 0.624, 1)` | `Color(0.353, 0.541, 0.431, 1)` | JADE_INK |
| `Color(1, 0.914, 0.659, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED |
| `Color(1.0, 0.914, 0.659, 1)` | `Color(0.784, 0.663, 0.318, 1)` | |
| `Color(1.0, 0.914, 0.659, 0.9)` | `Color(0.784, 0.663, 0.318, 0.9)` | |
| `Color(0.961, 0.78, 0.416, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED |
| `Color(0.98, 0.8, 0.082, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED |

### 8-2. bg_color マッピング (StyleBoxFlat)

| 旧 (v3) | 新 (v4) |
|---|---|
| `Color(0.067, 0.094, 0.153, 0.7)` | `Color(0.910, 0.863, 0.753, 0.85)` |
| `Color(0.067, 0.094, 0.153, 0.6)` | `Color(0.910, 0.863, 0.753, 0.75)` |
| `Color(0.067, 0.094, 0.153, 0.55)` | `Color(0.910, 0.863, 0.753, 0.7)` |
| `Color(0.067, 0.094, 0.153, 0.45)` | `Color(0.910, 0.863, 0.753, 0.6)` |
| `Color(0.04, 0.08, 0.16, 0.7)` | `Color(0.910, 0.863, 0.753, 0.85)` |
| `Color(0.04, 0.08, 0.16, 0.55)` | `Color(0.910, 0.863, 0.753, 0.7)` |
| `Color(0.04, 0.08, 0.16, 0.6)` | `Color(0.910, 0.863, 0.753, 0.75)` |
| `Color(0.04, 0.08, 0.16, 0.9)` | `Color(0.910, 0.863, 0.753, 0.95)` |
| `Color(0.063, 0.075, 0.118, 0.6)` | `Color(0.839, 0.812, 0.745, 0.7)` |
| `Color(0.043, 0.071, 0.125, 0.85)` | `Color(0.910, 0.863, 0.753, 0.9)` |
| `Color(0.7, 0.93, 1, 0.6)` | `Color(0.847, 0.922, 0.969, 0.6)` |
| `Color(0.435, 0.706, 1, 1)` | `Color(0.478, 0.702, 0.878, 1)` |
| `Color(0.435, 0.706, 1, 0.9)` | `Color(0.478, 0.702, 0.878, 0.9)` |
| `Color(0.435, 0.706, 1, 0.15)` | `Color(0.478, 0.702, 0.878, 0.15)` |
| `Color(0.118, 0.533, 0.898, 1.0)` | `Color(0.239, 0.420, 0.584, 1.0)` |
| `Color(1, 0.914, 0.659, 0.15)` | `Color(0.784, 0.663, 0.318, 0.15)` |
| `Color(0.58, 0.639, 0.722, 0.5)` | `Color(0.420, 0.420, 0.447, 0.5)` |

---

## 9. 禁止事項

- **白系の直書き** (`Color(1, 1, 1, *)`, `Color(0.95+, 0.95+, 1, *)`) → SUMI_INK 系を使う
- **黒系の直書き** (`Color(0, 0, 0, *)`, `Color(0.0X, ...)`) → WASHI_BASE / WASHI_PANEL を使う
- **NebulaBg / VoidBg / StarLayer** をシーンに追加すること
- **赤系** (`Color(1, 0, 0, *)`, `Color(0.9+, 0.2-0.3, 0.2-0.3, *)`) を UI に使う（GDD §6）。ゲーム内ストループ刺激色のみ例外
- **`scripts/utils/color_palette.gd` を経由しない `Color()` 直書き** を新規コードに含める（既存 tscn のリファクタは段階的）
- **影付け** で 4 階層を作ろうとする → 色の階層 3 段で表現する

---

## 10. 実装チェックリスト（新画面追加時）

新しいシーンを作成・既存シーンを編集するとき、以下を必ず確認:

- [ ] WashiBackground を最背面に配置（z_index=-100 不要、他に背景が無いので）
- [ ] VoidBg / NebulaBg / StarLayer 系をコピペしていない
- [ ] テキスト色は SUMI_INK / SUMI_MID / SUMI_LIGHT のいずれか
- [ ] CTA ボタンは ONIBI_BLUE + ONIBI_DEEP
- [ ] 達成系は GOLD_AGED
- [ ] 正解系は JADE_INK
- [ ] 赤色は使っていない
- [ ] CTA Button には JuicyBounce 子 Node を attach した
