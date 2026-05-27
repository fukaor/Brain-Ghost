# Brain Ghost — 墨絵テーマ実装指示書

## このドキュメントについて

本ドキュメントは Claude Code への実装指示書。
`docs/ideas/sumi-theme/` 配下に背景PNG・シート画像・キャラリファレンスが配置済みの前提で、以下を全て実行すること。

## 現在の配置状況

```
docs/ideas/sumi-theme/
├── references/
│   ├── character_ref.png              ← 墨絵黒猫キャラ（画風の参照用）
│   ├── home_components_sheet.png      ← ホーム画面コンポーネントの生成シート
│   ├── game_cards_sheet.png           ← ゲームカード6種の生成シート
│   ├── card_states_sheet.png          ← カード状態4種の生成シート
│   └── ui_parts_sheet.png            ← 共通UIパーツシートの生成シート
│
└── backgrounds/
    ├── bg_washi_base.png
    ├── bg_home.png
    ├── bg_play.png
    ├── bg_result_win.png
    ├── bg_result_lose.png
    └── bg_onboarding.png
```

## 実行タスク（上から順に全て実行）

### Task 1: シート画像からパーツを切り出す

references/ のシート画像から個別パーツPNGを切り出す Python スクリプトを書いて実行すること。

出力先: `docs/ideas/sumi-theme/parts/` 以下

全パーツ共通の処理:
- 背景を透過にする（白背景を除去）
- 周囲の余白を最小限にトリム

**ui_parts_sheet.png から切り出し:**

| 切り出すパーツ | 出力先 |
|---|---|
| プライマリボタン | `parts/buttons/btn_primary.png` |
| セカンダリボタン | `parts/buttons/btn_secondary.png` |
| アクセントボタン（朱色） | `parts/buttons/btn_accent.png` |
| BEST バッジ（金丸印） | `parts/badges/badge_best.png` |
| NEW バッジ（朱の旗） | `parts/badges/badge_new.png` |
| ティアバッジ枠（円相） | `parts/badges/badge_tier_frame.png` |
| 朱印スタンプ（鮮やか） | `parts/badges/stamp_shuin.png` |
| 朱印スタンプ（薄い） | `parts/badges/stamp_shuin_faded.png` |
| 未スタンプ枠（点線丸） | `parts/badges/stamp_empty.png` |
| 勝ちマーク ○（円相） | `parts/badges/mark_win.png` |
| 負けマーク ×（薄墨） | `parts/badges/mark_lose.png` |
| 鍵アイコン（墨筆錠前） | `parts/badges/icon_lock.png` |
| 人魂（青い炎） | `parts/decorations/hitodama.png` |
| 墨飛沫 1 | `parts/decorations/ink_splatter_1.png` |
| 墨飛沫 2 | `parts/decorations/ink_splatter_2.png` |
| 墨飛沫 3 | `parts/decorations/ink_splatter_3.png` |
| 太区切り線（乾筆） | `parts/decorations/divider_thick.png` |
| 細区切り線（濡れ筆） | `parts/decorations/divider_thin.png` |
| 上昇矢印（筆の一閃） | `parts/decorations/arrow_up_brush.png` |
| 下降矢印（筆の一閃） | `parts/decorations/arrow_down_brush.png` |
| 猫シルエット（極小） | `parts/decorations/icon_cat_silhouette.png` |
| タイマーバー塗り（墨） | `parts/bars/bar_fill_ink.png` |
| タイマーバー塗り（朱） | `parts/bars/bar_fill_vermillion.png` |
| ゴーストバー塗り（青） | `parts/bars/bar_fill_blue.png` |
| ゴーストバー塗り（灰） | `parts/bars/bar_fill_gray.png` |

**game_cards_sheet.png から切り出し:**

| 切り出すパーツ | 出力先 |
|---|---|
| ゴースト7番勝負アイコン | `parts/game_icons/game_icon_7ban.png` |
| ゴースト一本勝負アイコン | `parts/game_icons/game_icon_ippon.png` |
| 数字さがしアイコン | `parts/game_icons/game_icon_search.png` |
| 色文字ストループアイコン | `parts/game_icons/game_icon_stroop.png` |
| 順番記憶アイコン | `parts/game_icons/game_icon_sequence.png` |
| 神経衰弱ライトアイコン | `parts/game_icons/game_icon_memory.png` |

**card_states_sheet.png から切り出し:**

| 切り出すパーツ | 出力先 |
|---|---|
| 通常カード枠 | `parts/frames/frame_ink_border.png` |
| 選択中カード枠（シアン縁） | `parts/frames/frame_ink_border_selected.png` |
| ロック中カード枠（墨霧） | `parts/frames/frame_ink_border_locked.png` |

### Task 2: アセットをプロジェクトにコピー

```
docs/ideas/sumi-theme/backgrounds/ → assets/textures/backgrounds/
docs/ideas/sumi-theme/parts/frames/ → assets/textures/frames/
docs/ideas/sumi-theme/parts/buttons/ → assets/textures/buttons/
docs/ideas/sumi-theme/parts/badges/ → assets/textures/badges/
docs/ideas/sumi-theme/parts/decorations/ → assets/textures/decorations/
docs/ideas/sumi-theme/parts/game_icons/ → assets/textures/game_icons/
docs/ideas/sumi-theme/parts/bars/ → assets/textures/bars/
```

### Task 3: カラーパレット定数を作成

`scripts/constants/colors.gd` を作成:

```gdscript
class_name SumiColors

const WASHI = Color("#F5F0E8")       # 和紙の地色（背景）
const SUMI_DARK = Color("#2C2C2C")   # 濃墨（メインテキスト）
const SUMI_LIGHT = Color("#8C8C8C")  # 薄墨（サブテキスト・敗北表示）
const HITODAMA = Color("#B8D8E8")    # 人魂の青（アクセント・レーダー塗り）
const WAKATAKE = Color("#7DB88A")    # 若竹（勝利・スコア上昇・正解ハイライト）
const KINDEI = Color("#C9A84C")      # 金泥（BEST バッジ・最強軸）
const SHU = Color("#C85A4A")         # 朱（アクセントボタン・ストリークスタンプ・タイマー警告）
const GINNEZUMI = Color("#9EA1A3")   # 銀鼠（敗北・グレー系表示。赤の代替）
const HITODAMA_FILL = Color(0.72, 0.85, 0.91, 0.2)  # レーダーチャート塗り用
```

### Task 4: テーマリソースを構築

`assets/theme/sumi_theme.tres` を構築。

フォント:
- 和風テキスト: Noto Serif JP Bold（ゲーム名・ラベル・セリフ）
- スコア数字: Space Grotesk Bold（スコア・脳年齢の数字）
- タイマー等幅: JetBrains Mono Regular（カウントダウン・反応時間ms表示）

ボタン:
- プライマリ: btn_primary.png を NinePatchRect 背景、白テキスト
- セカンダリ: btn_secondary.png を NinePatchRect 背景、SUMI_DARK テキスト
- アクセント: btn_accent.png を NinePatchRect 背景、白テキスト

背景:
- Panel のデフォルト背景: WASHI 色

### Task 5: ホーム画面を構築

`scenes/screens/home.tscn` を作成。

背景: `bg_home.png` を TextureRect に設定（stretch_mode = keep_aspect_covered）

上から順に以下のコンポーネントを配置:

**1. 脳年齢カード（ミニマル墨洗いスタイル）**

references/home_components_sheet.png を参照。

- PanelContainer
- 上部: Label「脳年齢」（Noto Serif JP、14sp、SUMI_LIGHT）
- 中央: Label「31」（Space Grotesk Bold、64sp、SUMI_DARK）+ Label「歳」（24sp）
- 中央下: Line2D で乾筆風アンダーライン（始点 width 3px → 終点 1px、SUMI_DARK）
- 下部: ProgressBar（高さ 4dp、fill: HITODAMA、bg: SUMI_LIGHT alpha 0.2）+ Label「精度: 100%」（10sp、SUMI_LIGHT）
- 右下隅: TextureRect（ink_splatter_1.png、alpha 0.3）

**2. デイリースコアカード（墨枠トレーディングカード）**

references/home_components_sheet.png を参照。

- NinePatchRect（frame_ink_border.png、stretch_margin 四辺 12px）
- 右上隅: TextureRect（icon_cat_silhouette.png、枠の隙間に配置）
- 内部:
  - Label「3,230 pts」（Space Grotesk Bold、36sp、SUMI_DARK）
  - HBoxContainer: TextureRect（arrow_up_brush.png）+ Label「+285」（16sp、WAKATAKE）
  - Label「脳年齢: 31歳」（14sp、SUMI_LIGHT）
  - HBoxContainer: mark_win.png × 2 + mark_lose.png × 1

**3. ゴースト戦績 + ストリーク（横並び）**

references/home_components_sheet.png を参照。

左半分 — 戦績（相撲番付風）:
- Label「通算」（12sp、SUMI_LIGHT）
- Label「15勝」（Space Grotesk Bold + Noto Serif JP、28sp、SUMI_DARK）← 濃墨
- Label「8敗」（28sp、SUMI_LIGHT）← 薄墨
- TextureRect（icon_cat_silhouette.png、40×30、alpha 0.6）

右半分 — ストリーク（朱印帳）:
- HBoxContainer（spacing: 8dp）に TextureRect × 7
  - プレイ済み当日: stamp_shuin.png
  - プレイ済み過去: stamp_shuin_faded.png
  - 未プレイ: stamp_empty.png
- Label「5日連続！」（12sp、SUMI_DARK）

区切り: TextureRect（divider_thin.png）

**4. レーダーチャート（円相ベース同心円）**

references/home_components_sheet.png を参照。
PNG は使わない。全て _draw() で描画。

`scripts/ui/radar_chart.gd`（extends Control）を作成:

- 3 つの同心円: 円相風の不完全な円。各円に 3 点分の隙間、線幅に ±0.5px のランダム変動。色: SUMI_LIGHT
- 6 本の放射軸: 中心→外周。width 始点 2px → 終点 0.5px の先細り。色: SUMI_LIGHT
- 軸先端: 小丸（radius 2px、SUMI_DARK）
- データ塗り: Polygon2D、色: HITODAMA_FILL
- データ輪郭: 線、色: HITODAMA、width 1.5px
- 最強軸の頂点: 丸（radius 4px、KINDEI）
- 軸ラベル: 計算力（上）、記憶力（右上）、注意力（右下）、反射速度（下）、観察力（左下）、判断力（左上）。Noto Serif JP、11sp、SUMI_DARK
- 最弱軸のラベル下に「鍛える →」（10sp、SHU、タップ可能）

**5. デイリーチャレンジ帯（絵巻物スクロール）**

- Label「今日のチャレンジ」（14sp、SUMI_DARK）+ TextureRect（hitodama.png）
- HBoxContainer（3 ゲームアイコン。divider_thin.png を 90° 回転して区切り）
- 各アイコン: game_icon_*.png（60×45）+ Label ゲーム名（10sp）
- 右端: btn_accent.png + Label「始める」（白、14sp）

**6. 全ゲーム一覧ボタン**

- btn_secondary.png + Label「全ゲーム一覧」（SUMI_DARK）

### Task 6: ミニゲーム一覧画面を構築

`scenes/screens/game_list.tscn` を作成。

背景: `bg_washi_base.png`

- GridContainer（columns: 2、h_separation: 12、v_separation: 12）
- 各カード:
  - NinePatchRect（frame_ink_border.png）
  - HBoxContainer:
    - TextureRect（game_icon_*.png、80×60）
    - VBoxContainer:
      - Label ゲーム名（Noto Serif JP、14sp、SUMI_DARK）
      - Label 能力（11sp、SUMI_LIGHT）
      - Label ベスト記録 or ロック表示（10sp、SUMI_LIGHT）
  - 右上隅: TextureRect（hitodama.png、24×24、alpha 0.5）
- ロック中カード: frame_ink_border_locked.png + icon_lock.png を中央に
- NEW 付きカード: badge_new.png を右上に
- ティア選択中: frame_ink_border_selected.png + badge_tier_frame.png + ティアテキスト

6 種のカード:

| ゲーム名 | アイコン | 能力 |
|---|---|---|
| ゴースト7番勝負 | game_icon_7ban.png | ⚡反射速度 |
| ゴースト一本勝負 | game_icon_ippon.png | 🔢計算力 |
| 数字さがし | game_icon_search.png | 👁観察力 |
| 色文字ストループ | game_icon_stroop.png | 🎯注意力 |
| 順番記憶 | game_icon_sequence.png | 🧠記憶力 |
| 神経衰弱ライト | game_icon_memory.png | ⚖判断力 |

### Task 7: 全画面の背景差し替え

| 画面 | 背景 |
|---|---|
| ホーム | bg_home.png |
| ミニゲームプレイ中（全6種共通） | bg_play.png |
| リザルト（ゴースト勝利時） | bg_result_win.png |
| リザルト（ゴースト敗北時） | bg_result_lose.png |
| オンボーディング・ルール説明 | bg_onboarding.png |
| その他（設定画面等） | bg_washi_base.png |

全て TextureRect で最背面に配置。stretch_mode = keep_aspect_covered。
