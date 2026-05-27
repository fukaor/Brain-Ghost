# 設計書

## アーキテクチャ概要

3 層の上書き：

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: シーン (tscn) — 背景 TextureRect / SubResource 色 │
│           ↑ 参照                                              │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Theme (default_theme.tres) — StyleBox / フォント色 │
│           ↑ 値の発生源                                        │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: ColorPaletteUtil v4 — 命名された色定数             │
└─────────────────────────────────────────────────────────────┘
```

すべての色は Layer 1 から流れる。Layer 2 はテーマリソース、Layer 3 はインスタンス固有の StyleBoxFlat / TextureRect。

## カラーパレット v4「Sumi Ghost」

ユーザ提供アセットから抽出。実機の見た目に最も近い 6 桁 Hex で定義。

### 和紙層（背景階層）

| 名前 | Hex | RGB float | 用途 |
|---|---|---|---|
| `WASHI_BASE` | `#F2E9D5` | (0.949, 0.914, 0.835) | 全画面最背景 |
| `WASHI_PANEL` | `#E8DCC0` | (0.910, 0.863, 0.753) | カード / パネル |
| `WASHI_SHADE` | `#D6CFBE` | (0.839, 0.812, 0.745) | サブパネル / セパレータ |

### 墨層（テキスト・線）

| 名前 | Hex | RGB float | 用途 |
|---|---|---|---|
| `SUMI_INK` | `#1B1B1F` | (0.106, 0.106, 0.122) | 主要テキスト / SDキャラ線 |
| `SUMI_MID` | `#3D3D44` | (0.239, 0.239, 0.267) | サブテキスト / ボタン文字 |
| `SUMI_LIGHT` | `#6B6B72` | (0.420, 0.420, 0.447) | キャプション / 説明文 |
| `SUMI_DIM` | `#A39E94` | (0.639, 0.620, 0.580) | プレースホルダ / 無効 |

### 鬼火青（主アクセント）

| 名前 | Hex | RGB float | 用途 |
|---|---|---|---|
| `ONIBI_BLUE` | `#7AB3E0` | (0.478, 0.702, 0.878) | CTA / 進捗 / ハイライト |
| `ONIBI_GLOW` | `#D8EBF7` | (0.847, 0.922, 0.969) | グロー / 明色アクセント |
| `ONIBI_DEEP` | `#3D6B95` | (0.239, 0.420, 0.584) | 深い鬼火（ボタン押下色等） |

### その他アクセント

| 名前 | Hex | RGB float | 用途 |
|---|---|---|---|
| `GOLD_AGED` | `#C8A951` | (0.784, 0.663, 0.318) | NEW BEST / 達成 / 猫目 |
| `JADE_INK` | `#5A8A6E` | (0.353, 0.541, 0.431) | 正解・ペア成立 |
| `GHOST_INK` | `#7A7A7E` | (0.478, 0.478, 0.494) | ゴースト本体（精度% で alpha） |

### 旧 v3 alias（段階移行用、撤去は次々回）

```gdscript
# v3 Midnight Cat alias → v4 Sumi Ghost
const BG_VOID := WASHI_BASE        # 黒板 → 和紙
const BG_DEEP := WASHI_PANEL       # 旧 BG_DEEP は階層色だったので WASHI_PANEL にマップ（平坦化回避）
const BG_PANEL := WASHI_PANEL
const BG_ELEV := WASHI_SHADE
const INK_100 := SUMI_INK
const INK_80 := SUMI_MID
const INK_60 := SUMI_LIGHT
const INK_40 := SUMI_DIM
const INK_20 := WASHI_SHADE
const CYAN_300 := ONIBI_GLOW
const CYAN_400 := ONIBI_BLUE
const CYAN_500 := ONIBI_DEEP
const CYAN_GLOW := Color(0.478, 0.702, 0.878, 0.55)
const GOLD_300 := Color(0.835, 0.741, 0.490)   # 古色寄せた #D5BC7D
const GOLD_400 := GOLD_AGED
const GOLD_GLOW := Color(0.784, 0.663, 0.318, 0.6)
```

`color_palette.gd` 内の旧名（PRIMARY_CYAN / SURFACE_* / ON_SURFACE / BACKGROUND 等）も新値に連動する。

## コンポーネント設計

### 1. assets/characters/ 命名規約

旧 `docs/ideas/character/cat_*.png` → `assets/characters/sumineko_*.png` に移植。元ファイルは参考用に残置。

```
assets/characters/
├── sumineko_normal.png      # 通常立ち姿（青鬼火 2 つ）
├── sumineko_fight.png       # 闘志ポーズ（目光、青鬼火 2 つ）
├── sumineko_running.png     # 走り（残像 + 横長）
├── sumineko_double.png      # 通常猫 + ゴースト猫（生霊化）
├── sumineko_touch.png       # 前足タッチ（cat_tauch.png の名前訂正）
├── sumineko_sleep.png       # 眠り（丸まり、大きい）
└── (旧 catboy_*.png, ghost_seirei.png は当面残置、参照ゼロ化)
```

### 2. assets/backgrounds/ 配置

新設ディレクトリ。すべて縦長 1080×1920 想定（promo のみ横長）。

```
assets/backgrounds/
├── washi_base.png          # 01: 全画面共通テクスチャ（薄染み）
├── washi_home.png          # 02: ホーム画面（上部墨雲 + 鬼火 + 右下墨はね）
├── washi_play.png          # 03: プレイ中（控えめ、上下に薄墨）
├── washi_result_win.png    # 04: 勝利リザルト（墨ストローク + 鬼火上昇）
├── washi_result_lose.png   # 05: 敗北リザルト（円相 + 鬼火下降）
├── washi_tutorial.png      # 06: チュートリアル（上下山墨 + 金線）
└── washi_promo.png         # 07: プロモ素材（横長、ストア用）
```

### 3. ColorPaletteUtil 書き換え戦略

ファイル: `scripts/utils/color_palette.gd`

書き換え方針:
- ファイル冒頭のドックコメントを「v4 Sumi Ghost」に更新
- 新パレット v4 ブロックを先頭に追加（上記カラーパレット v4 全 13 色）
- 既存定数は新値で再定義（alias）：BG_VOID / INK_100 / CYAN_300 等
- POSITIVE_GREEN は JADE_INK に置換、POSITIVE_GOLD は GOLD_AGED に置換
- NEUTRAL_GRAY は GHOST_INK に置換
- 禁止色ルール（赤）は引き続き保持（コメント明記）

#### RED 系定数の扱い

- `RED_400` / `RED_500` / `RED_GLOW` は **v4 でも維持**（削除は次々回 PR）
- 理由: `scripts/ui/effects/progress_dots.gd:70` で参照中。今回スコープに含めず、UI へ侵食する変更を抑える
- 維持の方針として、コメントを「**ゲーム内 UI への新規使用禁止、particle 装飾エフェクト限定**」に更新
- `progress_dots.gd` 自体の置換は次ステアリング（マスコット強化版）以降で扱う

### 4. Theme リソース改修方針

ファイル: `assets/themes/default_theme.tres`（1522 行）

**手順**（sed 一括 + diff 目視に変更）:
1. ファイル全体を読んで色指定パターンを特定（個別 Edit ではなく**色値グループごとに sed 一括**）
2. 色値ごとに sed で全件置換、その後 `git diff` で目視確認
3. 1 グループ置換ごとに Godot エディタで開いてリソースエラーが出ないか確認
4. デフォルトフォント色 / ボタン状態色も同じパターンで grep → 一括置換

**マッピング表（主要なもの）**:

| 旧 (v3) | 新 (v4) | 用途 |
|---|---|---|
| `Color(0, 0, 0, 1)` | `Color(0.949, 0.914, 0.835, 1)` | デフォルト背景 → 和紙 |
| `Color(0.043, 0.071, 0.125, ...)` | `Color(0.910, 0.863, 0.753, ...)` | BG_PANEL → WASHI_PANEL |
| `Color(0.063, 0.114, 0.196, ...)` | `Color(0.910, 0.863, 0.753, ...)` | 同上 |
| `Color(0.722, 0.878, 1, ...)` | `Color(0.106, 0.106, 0.122, ...)` | INK 系のテキスト色 → 墨色 |
| `Color(0.435, 0.706, 1, ...)` | `Color(0.478, 0.702, 0.878, ...)` | CYAN_400 → ONIBI_BLUE |
| `Color(0.886, 0.91, 0.941, ...)` | `Color(0.910, 0.863, 0.753, ...)` | 中間白 → 和紙パネル |
| `Color(0.106, 0.082, 0.039, ...)` | `Color(0.784, 0.663, 0.318, ...)` | 旧ゴールド系 → 古色金 |

**注意**:
- sed コマンドは **完全一致パターン**（小数点 5 桁の正確な値）で実行する。
- 置換後に必ず `git diff -- assets/themes/default_theme.tres | head -200` で差分目視確認。
- 例:
  ```bash
  # 黒系背景を和紙系に
  sed -i 's/Color(0, 0, 0, 1)/Color(0.949, 0.914, 0.835, 1)/g' assets/themes/default_theme.tres
  ```

### individual_result 背景分岐の実装メモ

- コントローラ内のグレード判定（`_grade` 関連変数 / `_compute_grade_headline()`）の戻り値で分岐
- `washi_result_lose.png` を適用するのは grade == "NICE TRY" のみ
- 他全グレード（NEW BEST / PERFECT WIN / GREAT WIN / WIN / IMPROVED / NICE START）は `washi_result_win.png`
- `_load_from_game_manager()` 完了後に `WashiBackground.texture = ...` を切替

### 5. シーン背景の置換

各 tscn に下記の構造を導入:

```
[ext_resource type="Texture2D" path="res://assets/backgrounds/washi_<screen>.png" id="bg_washi"]
... existing nodes ...
[node name="WashiBackground" type="TextureRect" parent="..."]
texture = ExtResource("bg_washi")
expand_mode = 1  # IGNORE_SIZE (親に合わせる)
stretch_mode = 6  # KEEP_ASPECT_COVERED
layout_mode = 1
anchors_preset = 15  # full rect
```

> **重要**: Godot 4 の `TextureRect.StretchMode` enum は 0〜6。`KEEP_ASPECT_COVERED = 6`。`7` を書くとパースエラーになる（既存 home.tscn は 6 で正しく動作）。

**配置順序**: 既存の `StarLayer` / `Background` ノードを **置換** または削除し、最背面に WashiBackground を置く。

**画面マッピング**:

| シーン | 背景 |
|---|---|
| launch.tscn | washi_base.png（または black-out 演出） |
| home.tscn | washi_home.png |
| game_list.tscn | washi_base.png |
| rule_explain.tscn / rule_explain_landscape.tscn | washi_tutorial.png |
| countdown.tscn / countdown_landscape.tscn | washi_base.png |
| individual_result.tscn | washi_result_win.png（勝利前提）。敗北時は controller でテクスチャ差し替え |
| ゲームシーン 6 種 | washi_play.png |

### 6. star_layer と glow_cta の扱い

- `scripts/ui/effects/star_layer.gd`: 漆黒星粒子描画 → **無効化**（render を skip するフラグ追加 or 削除）。墨絵背景上に星はそぐわない
- `scripts/ui/effects/glow_cta.gd`: グロー色を ONIBI_BLUE / GOLD_AGED に変更

### 7. プレビュー variant の色再調整

`scripts/ui/rule_step_preview.gd` の COLOR_* 定数を新パレットに準拠：

| 旧 | 新 |
|---|---|
| `COLOR_RAIL` | SUMI_LIGHT (薄墨ライン) |
| `COLOR_GATE` | ONIBI_BLUE |
| `COLOR_GLOW_GOLD` | GOLD_AGED |
| `COLOR_GLOW_CYAN` | ONIBI_BLUE |
| `COLOR_TEXT` | SUMI_INK |
| `COLOR_DIM` | SUMI_DIM |
| `COLOR_PANEL_OFF` | WASHI_SHADE |
| `COLOR_PANEL_ON` | GOLD_AGED |
| STROOP_* (4 色) | 維持（4 色は stroop ゲーム性として必要） |

### 8. card.gd 色更新

`scripts/ui/components/card.gd` の COLOR_* を新値に：

| 旧定数 | 新値 |
|---|---|
| `COLOR_BACK_BG` | WASHI_PANEL（不透明）|
| `COLOR_BACK_BORDER` | SUMI_LIGHT |
| `COLOR_FRONT_BG` | WASHI_BASE |
| `COLOR_FRONT_BORDER` | ONIBI_BLUE |
| `COLOR_MATCH_FLASH_BG` | JADE_INK with α 0.3 |
| `COLOR_MATCH_FLASH_BORDER` | JADE_INK |
| `COLOR_MISMATCH_FLASH_BG` | SUMI_DIM with α 0.3 |
| `COLOR_MISMATCH_FLASH_BORDER` | SUMI_LIGHT |
| `COLOR_MATCHED_BG` | WASHI_PANEL with α 0.5 |
| `COLOR_MATCHED_BORDER` | ONIBI_BLUE with α 0.3 |

### 9. individual_result_controller.gd 色更新

| 旧 | 新 |
|---|---|
| `COLOR_GOLD` | GOLD_AGED |
| `COLOR_CYAN300` | ONIBI_BLUE |
| `COLOR_CYAN100` | ONIBI_GLOW |
| `COLOR_INK95` | SUMI_INK |
| `COLOR_INK80` | SUMI_MID |
| `COLOR_INK60` | SUMI_LIGHT |
| `COLOR_GRAY_DIM` | SUMI_DIM |

### 10. マスコット参照置換

`grep "catboy_" scenes/` で見つかる 5 シーンの `ext_resource path` を `res://assets/characters/sumineko_normal.png` に書き換え（場面によっては fight / sleep に振り分けるが、まずは normal で統一）：

| シーン | 旧 | 新 |
|---|---|---|
| home.tscn | catboy_electric | sumineko_normal |
| countdown.tscn | catboy_electric | sumineko_fight |
| countdown_landscape.tscn | catboy_electric | sumineko_fight |
| individual_result.tscn | catboy_electric | sumineko_normal（場面で fight にも） |
| ghost_7ban_shobu.tscn (ext_resource id=5_ghostcat) | catboy_confident | sumineko_fight |

## データフロー

### ユースケース 1: アプリ起動 → ホーム

```
1. launch.tscn 起動 → WashiBackground (washi_base) 描画
2. 1.5s 後 → home.tscn に遷移
3. home.tscn → WashiBackground (washi_home) 描画
4. テキスト・ボタンは新パレット色（SUMI_INK / ONIBI_BLUE）
5. マスコット sumineko_normal が右上配置（既存と同じ）
```

### ユースケース 2: ゲームプレイ → 結果

```
1. ゲーム中: WashiBackground (washi_play) — 控えめな和紙
2. on_game_finished → individual_result.tscn
3. controller が log.is_new_best / score 結果で:
   - 勝利系 → WashiBackground.texture = washi_result_win
   - 敗北系 → WashiBackground.texture = washi_result_lose
4. リザルト UI は SUMI_INK / GOLD_AGED で描画
```

## エラーハンドリング戦略

### アセットが見つからない場合

- ext_resource パスが解決できない場合、Godot は import エラーを出す
- フェーズ1 のアセット移植は CI 前に `godot --headless --import` でエラーゼロを確認

### 既存 v3 色を参照しているコードのフォールバック

- alias 経由のため、旧名（CYAN_300 等）でアクセスしても新値が返る
- ただしセマンティクスは「シアン」ではなく「鬼火光（明色）」なので、視覚的に問題ないか個別検証する

## テスト戦略

### ユニットテスト

- 既存テスト（test_score_system, test_data_store）は配色変更の影響なし → 既存パスすれば OK

### 統合テスト（手動）

- ホーム / 一覧 / ルール / カウントダウン / プレイ中 / 結果 の 6 画面シーケンスを実機で通しチェック
- 暗背景時代と比較して**視認性が確実に上がっている**ことを確認
- 6 ゲーム全部を 1 回ずつプレイ完走

### キャプチャ確認

- スプラッシュ / ホーム / 結果 (4 グレード) のスクリーンショットを `docs/design/snapshots/sumi-ghost/` に保存（命名: `2026-05-25_<画面名>.png`）

## 依存ライブラリ

新規ライブラリは追加しない。Godot 4.6.2 ネイティブのみ。

## ディレクトリ構造

```
assets/
├── characters/
│   ├── sumineko_*.png (6 枚、新規)
│   └── (catboy_*.png, ghost_seirei.png は残置)
├── backgrounds/             (新設)
│   └── washi_*.png (7 枚、新規)
└── themes/
    └── default_theme.tres (全面リフォーム)

scripts/
├── utils/
│   └── color_palette.gd     (v4 書き換え)
├── ui/
│   ├── rule_step_preview.gd  (色定数置換)
│   ├── individual_result_controller.gd (色定数置換)
│   ├── components/
│   │   └── card.gd          (色定数置換)
│   ├── effects/
│   │   ├── star_layer.gd    (無効化)
│   │   └── glow_cta.gd      (色変更)
│   └── launch_controller.gd (背景演出更新)
└── (他は基本ノータッチ)

scenes/
├── main/
│   ├── launch.tscn          (背景差し替え)
│   └── home.tscn            (背景差し替え + マスコット置換)
├── ui/
│   ├── game_list.tscn       (背景差し替え)
│   ├── rule_explain*.tscn   (背景差し替え)
│   ├── countdown*.tscn      (背景差し替え + マスコット置換)
│   └── individual_result.tscn (背景差し替え + マスコット置換)
└── games/
    ├── flash_calc/*.tscn    (背景差し替え)
    ├── number_search/*.tscn
    ├── card_match/*.tscn
    ├── stroop/*.tscn
    ├── sequence_memory.tscn
    └── ghost_7ban_shobu/*.tscn (背景 + マスコット置換)
```

## 実装の順序

1. **アセット移植**: docs/ideas → assets/ に複製 + リネーム
2. **ColorPaletteUtil v4**: 新定数 + alias で書き換え
3. **default_theme.tres**: 色置換
4. **ハードコード色置換**: card.gd / rule_step_preview.gd / individual_result_controller.gd
5. **シーン背景配置**: WashiBackground を全主要シーンに追加
6. **マスコット参照置換**: 5 シーンの ext_resource パス更新
7. **effects 系**: star_layer 無効化、glow_cta 色変更
8. **検証**: ビルド → 実機デプロイ → 6 画面 + 6 ゲーム通し動作確認
9. **ドキュメント更新**: MEMORY / repository-structure / development-guidelines

## セキュリティ考慮事項

- ない（純粋な見た目変更）

## パフォーマンス考慮事項

- 和紙背景画像は 1080×1920 で約 2MB/枚 × 7 枚 = 約 14MB のテクスチャ追加
- モバイル GPU 帯域への影響は小（同時表示は 1 枚のみ）
- `expand_mode = 1` で KEEP_ASPECT_COVERED にして縦横比破綻を防ぐ
- 既存の star_layer や heavy gradient sub_resource は削除されるので、トータルでむしろ軽くなる可能性

## 将来の拡張性

- v5（夜の和紙 = 黒和紙）モードを後で追加可能。WASHI_* 定数を別ファイル化することも検討
- 季節色（春の桜 / 秋の紅葉）の差し色追加も視野
- マスコットの AnimatedSprite2D 化は次ステアリングで実施
