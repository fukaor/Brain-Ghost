---
name: stitch-to-godot
description: Stitch(HTML/Tailwind)デザインをGodot 4のtscnシーンに変換するスキル。Stitchデザインの取得、サイズ換算、ノード構造マッピング、キャプチャ比較まで一貫して行う。
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebFetch
---

# Stitch → Godot 変換スキル

StitchのHTML/Tailwind CSSデザインを、Godot 4の.tscnシーンファイルに正確に変換するためのスキル。

## 前提知識

### なぜ直接変換できないのか

Stitch MCPが生成するのは **HTML + Tailwind CSS** のWebコードであり、Godotの `.tscn + StyleBoxFlat + theme_override` とはまったく別のUIシステム。自動変換は不可能なため、人間（またはAI）がデザイン意図を読み取り、Godotノード構造に手動変換する必要がある。

| Stitch (HTML/CSS) | Godot (.tscn) |
|---|---|
| `<div>` + flexbox/grid | VBoxContainer / HBoxContainer |
| Tailwind クラス | StyleBoxFlat + theme_override |
| Material Symbols (Web font) | MaterialSymbolsRounded.ttf (ローカル) |
| `backdrop-filter: blur()` | ShaderMaterial (カスタム) or theme_type_variation |
| CSS animation | Tween / AnimationPlayer |
| `<img src="URL">` | ローカル Texture2D リソース |
| px単位のサイズ | Godot viewport単位のサイズ（スケール換算必須） |

## 変換フロー

### Step 1: 正しいデザインソースを特定する

**最重要**: Stitch MCPには複数バージョンのスクリーンが存在する。必ず**ユーザーが指定した参照画像**と一致するHTMLを使うこと。

```
1. mcp__stitch__list_screens でスクリーン一覧を取得
2. タイトルから該当スクリーンを特定
3. mcp__stitch__get_screen でHTMLダウンロードURLを取得
4. curl でHTMLをダウンロードし、中身を直接読む
   ※ WebFetchの要約は不正確になりがち。必ず生HTMLを読むこと
5. 参照画像と照合し、正しいバージョンか確認
```

**失敗パターン**: HTMLを取得せず参照画像だけを見てアイコン名や色を推測する → 間違える。HTMLのソースコードが唯一の正解。

### Step 2: サイズ換算（最重要）

HTMLのviewportサイズとGodotのviewportサイズからスケール比を算出する。

```
スケール比 = Godot viewport幅 / HTML body幅
```

**このプロジェクトの場合:**
```
HTML: body { width: 1080px; height: 1920px; }
Godot: viewport_width=720, viewport_height=1280
スケール比 = 720 / 1080 = 2/3 ≈ 0.667
```

**全てのサイズにスケール比を適用する:**

| HTML | 計算 | Godot |
|---|---|---|
| 320px (キャラサイズ) | 320 × 2/3 | 213px |
| text-6xl (60px) | 60 × 2/3 | 40px |
| text-[34px] | 34 × 2/3 | 23px |
| text-2xl (24px) | 24 × 2/3 | 16px |
| text-5xl (48px) | 48 × 2/3 | 32px |
| text-3xl (30px) | 30 × 2/3 | 20px |
| p-14 (56px) | 56 × 2/3 | 37px |
| gap-10 (40px) | 40 × 2/3 | 27px |
| w-40 (160px) | 160 × 2/3 | 107px |
| text-[120px] | 120 × 2/3 | 80px |

**Tailwind サイズ早見表:**
```
text-xs=12px  text-sm=14px  text-base=16px  text-lg=18px
text-xl=20px  text-2xl=24px text-3xl=30px   text-4xl=36px
text-5xl=48px text-6xl=60px text-7xl=72px   text-8xl=96px

p-1=4px  p-2=8px  p-3=12px  p-4=16px  p-5=20px
p-6=24px p-7=28px p-8=32px  p-10=40px p-12=48px p-14=56px

gap-1=4px gap-2=8px gap-3=12px gap-4=16px gap-6=24px
gap-8=32px gap-10=40px gap-12=48px

w-10=40px w-12=48px w-14=56px w-16=64px w-20=80px
w-24=96px w-32=128px w-40=160px w-48=192px w-64=256px
```

**失敗パターン**: スケール比を計算せずに「見た目で合わせる」→ 全体的にテキストが小さくなる。

### Step 3: HTML→Godotノード構造マッピング

#### レイアウト

| HTML | Godot |
|---|---|
| `<div class="flex flex-col">` | VBoxContainer |
| `<div class="flex">` / `flex-row` | HBoxContainer |
| `<div class="grid grid-cols-2">` | HBoxContainer (size_flags_horizontal=3 で等分) |
| `<div class="flex items-center justify-center">` | CenterContainer |
| `<div class="relative">` + absolute child | Control + anchors_preset |
| `gap-N` | theme_override_constants/separation |
| `p-N` | MarginContainer の margin 値、または StyleBoxFlat の content_margin |

#### 背景・装飾

| HTML | Godot |
|---|---|
| `bg-primary` (単色) | StyleBoxFlat の bg_color |
| `bg-primary/15` (透明度) | bg_color の alpha を 0.15 に |
| `rounded-full` | corner_radius を十分大きく (44+) |
| `rounded-[3rem]` (48px) | corner_radius = 48 × スケール比 |
| `border border-primary/30` | StyleBoxFlat の border_width + border_color |
| `shadow-lg` | Godotでは再現困難。省略可 |
| `backdrop-filter: blur()` | theme_type_variation = "glass_bubble" (テーマ定義済みの場合) |

#### テキスト

| HTML | Godot |
|---|---|
| `font-black` (900) | theme_override で太字フォント or font_size で視覚的に調整 |
| `text-primary` | theme_override_colors/font_color = Color(0, 0.484, 1, 1) |
| `tracking-widest` | Godotでは直接対応なし |
| `uppercase` | GDScript で .to_upper() |
| Material Symbols `text = "icon_name"` | 同じ icon_name を使用。FontFile 参照が必要 |
| `font-variation-settings: 'FILL' 1` | Godotでは FILL 制御不可。Rounded版TTFなら近い表現 |

#### ボタン

| HTML | Godot |
|---|---|
| `<button>` | Button ノード |
| ボタン内テキスト+アイコン | Button(text=" ") + 子HBoxContainer(mouse_filter=2) + Label群 |
| `active:scale-95` | StyleBoxFlat_pressed で bg_color を変える |
| `game-ui-btn` (グラデーション) | cta_blue テーマバリエーション or カスタム StyleBox |

### Step 4: 変換チェックリスト

HTMLの各要素について、以下を確認:

- [ ] サイズがスケール比で換算されているか
- [ ] 色がHTMLのカラーコードと一致しているか (Tailwind変数 → 実際の色値)
- [ ] フォントサイズが `theme_override_font_sizes/font_size` で明示指定されているか
  ※ テーマバリエーション (`h1`, `headline_v2` 等) はサイズが不明確。Stitch完全一致が必要な場合は明示指定を優先
- [ ] Material Symbolsのアイコン名がHTMLと一致しているか
- [ ] 透明度 (opacity, alpha) が一致しているか
- [ ] 角丸のサイズが一致しているか
- [ ] 余白 (margin/padding/gap) が一致しているか
- [ ] ノードのツリー構造がHTMLのDOM構造と対応しているか

### Step 5: キャプチャ比較検証

変換後、必ずXvfbキャプチャを取得してStitchデザインと比較する。

```bash
# Xvfb起動（Godotのviewportサイズに合わせる）
Xvfb :99 -screen 0 720x1280x24 &
sleep 1

# Godot起動・キャプチャ
DISPLAY=:99 timeout 20 godot --path /workspace \
  --scene-path res://scenes/ui/TARGET.tscn \
  --rendering-driver opengl3 &
GODOT_PID=$!
sleep 12

# スクリーンショット取得
DISPLAY=:99 import -window root OUTPUT_PATH.png

# クリーンアップ
kill $GODOT_PID 2>/dev/null
kill $(pgrep Xvfb) 2>/dev/null
```

**注意:**
- `--headless` では画面がレンダリングされない（黒画面になる）
- スプラッシュ画面を避けるため **12秒** 待つ
- Xvfbの画面サイズは **Godotのviewportサイズ** (720x1280) に合わせる
- Devcontainerの再起動はしない

### Step 6: 差異修正のイテレーション

キャプチャとStitchを並べて差異を洗い出し、修正→再キャプチャを繰り返す。

**よくある見落とし:**
- GDScriptのRULES辞書でデフォルト値が残っている（tscnは正しいがset_rule()で上書きされる）
- アイコン名の不一致（`close` vs `flare` 等 — HTMLのソースコードが正解）
- テーマバリエーション使用時のサイズ不一致（明示的 font_size 指定で解決）
- アイコンの色・透明度の不一致（HTMLの opacity-40 → Godotの alpha 0.4）

## Tailwindカラー → Godot Color 変換例

```
#007BFF → Color(0, 0.484, 1, 1)        # primary
#232c51 → Color(0.137, 0.173, 0.318, 1) # on-surface
#505a81 → Color(0.314, 0.353, 0.506, 1) # on-surface-variant
#6c759e → Color(0.424, 0.459, 0.62, 1)  # outline
#a2abd7 → Color(0.635, 0.671, 0.843, 1) # outline-variant
#e4e7ff → Color(0.894, 0.906, 1, 1)     # surface-container
#efefff → Color(0.937, 0.937, 1, 1)     # surface-container-low
#ffffff → Color(1, 1, 1, 1)             # surface-container-lowest
```

Tailwindの `/N` (opacity修飾子) はGodotの alpha に対応:
```
/10 → alpha 0.1   /15 → alpha 0.15   /20 → alpha 0.2
/30 → alpha 0.3   /40 → alpha 0.4    /50 → alpha 0.5
/60 → alpha 0.6   /70 → alpha 0.7    /80 → alpha 0.8
```
