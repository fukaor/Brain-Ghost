# ブレインゴースト UI パターン集

> `docs/design/manifest.md` の仕様を実装に落とし込むときの **実装者向けテンプレート集**。新しい画面を作るときはまずこのファイルを開き、該当パターンをコピーして出発点にする。
>
> manifest.md は「何を使うか」、patterns.md は「どう組むか」。

---

## 1. 画面ルートのボイラープレート

全ての画面は同じルート構造で開始する。`SafeAreaMargin` + `PageBackground` を省くと背景色・余白が破綻する。

```gdscript
[gd_scene load_steps=? format=3 uid="..."]

[ext_resource type="Script" path="res://scripts/ui/<screen>_controller.gd" id="1_ctrl"]
[ext_resource type="Texture2D" path="res://assets/textures/gradients/page_bg.png" id="2_pagebg"]

[node name="<ScreenName>" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_ctrl")

[node name="PageBackground" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2_pagebg")
expand_mode = 1
stretch_mode = 6

[node name="SafeAreaMargin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 32
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="MainColumn" type="VBoxContainer" parent="SafeAreaMargin"]
layout_mode = 2
theme_override_constants/separation = 12
```

`MainColumn` 配下にその画面固有の情報ブロックを並べる。垂直方向の並びは常に VBoxContainer。

---

## 2. ノード命名規則

ノード名はサフィックスで種別が分かるようにする。これは Godot の慣習 + ブレインゴースト 固有のルール。

| サフィックス | 用途 | 例 |
|---|---|---|
| `*Panel` / `*Card` | PanelContainer | `HeroSection` (=PanelContainer), `StampPreviewCard` |
| `*VBox` / `*HBox` | BoxContainer | `MainColumn`, `HeroVBox`, `StampHBox` |
| `*Button` | Button | `StartButton`, `HomeTabButton` |
| `*Label` | Label | `GreetingLabel`, `LastScoreLabel` |
| `*Icon` | Label (icon_* variation) | `StreakIcon`, `HomeTabIcon` |
| `*Row` | HBoxContainer で 1 行の情報 | `TopHudRow`, `GreetingRow` |
| `*Grid` | GridContainer | `ActionGrid` |

ルートノードは画面名 PascalCase（`Home`, `Settings`）、その他は PascalCase + サフィックス。スネークケースは使わない（Godot 4 のエディタ表示と揃える）。

---

## 3. Theme Variation の使い分け表

`theme_type_variation = &"..."` で Theme の variation を指定する。個別ノードに `add_theme_*_override` を書くのは禁止（§6 禁則参照）。

### Label

| Variation | サイズ | 色 | 用途 | 例 |
|---|---|---|---|---|
| default | 18pt | NEUTRAL_GRAY | 本文 | "おかえりなさい" |
| `h1` | 32pt | BG_DARK | 画面タイトル | "今日のチャレンジ" |
| `h2` | 24pt | BG_DARK | セクション見出し | "前回の成績" |
| `display` | 64pt | BG_DARK | スコア・脳年齢の主役表示 | "28 歳" |
| `caption` | 14pt | NEUTRAL_SLATE | 補助情報・注記 | "3 種類 / 約 2 分" |
| `hero_big` | 40pt | BG_DARK | ヒーローカードのメインタイトル | "今日のチャレンジ" |
| `card_title` | 18pt | BG_DARK | アクションカードのタイトル | "全ゲーム", "今週のハンコ" |
| `value` | 26pt | BG_DARK | HUD ピルの主値 | "5 日", "28 歳", "67 %" |
| `value_label` | 12pt | NEUTRAL_GRAY | HUD ピルのキャプション（使用頻度低） | — |

### Label (アイコンフォント)

Material Symbols Rounded をフォントに差し替えた Label variation。`text` にリガチャ名（`home`, `settings`, `calendar_month` など）を入れるとアイコンが描画される。

| Variation | サイズ | 色 | 用途 |
|---|---|---|---|
| `icon_nav` | 28pt | NEUTRAL_GRAY | ボトムナビ・ドロワー |
| `icon_pill` | 20pt | POSITIVE_GOLD | HUD ピル内の先頭アイコン |
| `icon_card` | 32pt | BG_DARK | アクションカードの左アイコン、スタンプセル |
| `icon_hero` | 24pt | BG_DARK | ヒーローカード前置アイコン、セクション見出し装飾 |
| `icon_tip` | 24pt | ACCENT_BLUE | ヒントカードの電球 |

**リガチャ名の調べ方**: https://fonts.google.com/icons?icon.set=Material+Symbols&icon.style=Rounded で検索し、"home" / "settings" のような単語をそのまま `text` に入れる。

### PanelContainer

| Variation | 背景 | 影 | 角丸 | 用途 |
|---|---|---|---|---|
| default | StyleBoxEmpty | なし | — | 透明（構造専用） |
| `card` | BG_LIGHT | 微シャドウ (0.08) | 16px | 通常カード・ボトムナビバー |
| `card_elevated` | BG_LIGHT | 強シャドウ (0.12) | 16px | 目立たせたいサブカード |
| `hero_card` | クリーム (#FFFCED) | 極強シャドウ (0.22) + ゴールド下ボーダー 4px | 24px | ヒーローセクション 1 箇所のみ |
| `pill_chip` | 白 | 中シャドウ (0.12) + 上ボーダー 2px | 16px | HUD ピル |
| `action_card` | 白 | 中シャドウ (0.14) | 16px | アクションカードグリッド、スタンプカード、ヒントカード |
| `speech_bubble` | 白 | 中シャドウ (0.15) + 下ボーダー 3px | 20px | ゴースト吹き出し |

### Button

| Variation | 背景 | 用途 |
|---|---|---|
| default | POSITIVE_GOLD 単色 + 影 | 標準ボタン |
| `secondary` | NEUTRAL_LIGHT_GRAY 単色 + 影なし | セカンダリアクション |
| `cta_gradient` | ゴールドグラデテクスチャ | ヒーロー CTA（画面に 1 個のみ） |

---

## 4. 情報ブロックの並べ方（ホーム画面テンプレ）

ホーム画面以降の画面でも同じ「8 段構成」を下敷きにする:

```
MainColumn
 ├─ [Top HUD]      3 ピル (ストリーク・脳年齢・精度)       … ステータスサマリ
 ├─ [Ghost Area]   GhostCharacter instance                … 対話 + 生霊
 ├─ [Hero]         PanelContainer "hero_card" + CTA       … 主要アクション
 ├─ [Action Grid]  GridContainer 2×2                       … セカンダリアクション
 ├─ [Data Preview] ハンコ / チャート / 履歴 ミニカード    … 最近の状態
 ├─ [Tip]          action_card with ghost quote           … ソフトガイド
 ├─ [FlexSpacer]   size_flags_vertical=3                  … 下部への押し出し
 └─ [Bottom Nav]   PanelContainer "card"                   … ナビゲーション
```

画面ごとに Ghost / Hero / Data Preview が何を指すかが変わるだけで、段構成は変わらない。**これがアプリの一貫性を作る最大の装置**。

---

## 5. ゴーストキャラクタ (生霊システム) の使い方

`scenes/ui/ghost_character.tscn` は全画面で再利用する。メモリ: `memory/project_ghost_character.md` 参照。

### 画面への組み込み

```gdscript
[ext_resource type="PackedScene" path="res://scenes/ui/ghost_character.tscn" id="3_ghost"]

[node name="GhostCharacter" parent="SafeAreaMargin/MainColumn" instance=ExtResource("3_ghost")]
layout_mode = 2
```

### コントローラからの操作

```gdscript
@onready var _ghost: GhostCharacter = $SafeAreaMargin/MainColumn/GhostCharacter

func _ready() -> void:
    # 精度を反映（MUST）
    _ghost.set_accuracy(DataStore.get_accuracy())  # 0.0〜1.0

    # セリフを場面に応じて
    _ghost.set_dialogue("ここは %s の画面だよ。%s" % [screen_name, context_message])

    # v1.1 以降（現在は no-op）
    _ghost.set_brain_age(DataStore.get_brain_age())
    _ghost.set_streak(DataStore.get_streak())
    _ghost.set_mood("idle")  # idle/happy/tired/surprised/celebrating
```

### セリフのトーン規約

- **一人称**: "昨日の自分" 設定なのでユーザを "きみ" 呼び推奨。"あなた" は距離がありすぎる
- **語尾**: やや幼めの親しみ口調。"〜だよ" "〜してみよう" "〜しようね"
- **ポジティブのみ**: 負け・失敗時も励ます (GDD §6 の赤禁止ルールと整合)
  - NG: "今日はダメだったね"
  - OK: "惜しかった！次は行けるよ"
- **長さ**: 1〜3 行、40〜80 文字目安。吹き出しが画面を占有しすぎないように
- **場面別テンプレ**:
  - ホーム (ログイン): "おかえり！X 日連続すごいね。今日もやる？"
  - ゲーム開始前: "3 種類、約 2 分。一緒にがんばろう！"
  - 個別結果 (勝ち): "やった！前より早くなってる！"
  - 個別結果 (負け): "惜しい！でもリアクションは確実に良くなってるよ"
  - 総合結果 (ベスト更新): "ベスト更新！今日のきみはすごい！"
  - ストリーク復帰: "久しぶり！また一緒にやれて嬉しい"

---

## 6. 新しい画面を作る手順（10 ステップ）

1. `.steering/<date>-<screen>-implementation/` を起こす（steering スキル モード 1）
2. `docs/design/manifest.md` §2-8 を読み、使う色・フォント・余白を確認
3. この patterns.md の §4「情報ブロックの並べ方」を見て、画面を 6〜8 段に分ける
4. §1 のボイラープレートをコピーして `scenes/<category>/<screen>.tscn` を作成
5. 各情報ブロックに §3 の Theme variation を割り当てる（**生 hex・絶対配置・theme_override は禁止**）
6. 必要なら §5 の手順で GhostCharacter をインスタンス配置
7. `scripts/ui/<screen>_controller.gd` を作り、@onready でノード参照 + シグナル接続 + ゴーストへの状態伝達
8. `godot --headless --quit` でパースエラー無しを確認
9. xvfb + `--display-driver x11 --rendering-driver opengl3` + スクショ取得スクリプトで実機レンダリング検証
10. competitor-research.md の Top 5 画面 + manifest.md の目標トーンと並べて自己評価 → ユーザー承認

---

## 7. ゴースト (modulate) の正当な例外について

manifest.md §9 では **GDScript 内で `modulate = Color(...)` を書くこと** を禁則としている。しかし `ghost_character.gd` は `modulate.a` (不透明度) を精度 % に連動させるために **意図的に使っている**。これが OK な理由:

- 禁則の目的は「色のハードコードを避けて Theme に一元化する」こと
- `modulate.a` はデータ駆動の**不透明度制御**であり、色のハードコードではない
- Theme にはインスタンス単位で alpha を動的変更する仕組みがない
- 禁則の精神的意図に反していない

つまり **例外条件: "data-driven opacity via modulate.a, color tuple remains (1,1,1,alpha)"**。同じパターンを他で使うときはこの条件（色は白固定、alpha のみ操作）を守ること。

色を動的に変えたくなったら (`modulate = Color.RED` 等)、それは禁則違反で、代わりに Theme variation を増やすのが正解。

---

## 8. アンチパターン早見表（やると何が起きるか）

| アンチパターン | 起きる問題 | 正しい対処 |
|---|---|---|
| 生 hex を .tscn / .gd に直書き | カラー変更時に全ファイル修正が必要、GDD ルール違反の検出が困難 | `ColorPaletteUtil` の定数を使う、または Theme variation を増やす |
| `offset_left = 120` のような絶対配置 | 解像度変更で崩れる | `anchors_preset` + `MarginContainer` + `custom_minimum_size` で組む |
| `add_theme_font_size_override()` を GDScript で書く | Theme が単一ソースでなくなる | Theme に variation を追加し `theme_type_variation` を使う |
| `modulate = Color.RED` 等の色系 modulate | Theme を迂回して色を変えている | Theme variation で対応 |
| ナビに `text = "ホーム"` などテキストを使う | 情報密度が下がる、"Web ページっぽさ" が出る | Material Symbols の `icon_nav` variation + リガチャ名（`home`, `settings` など） |
| FlexSpacer の size_flags_vertical を忘れる | コンテンツが画面上部に固まり下部に空白 | 必ず `size_flags_vertical = 3` で expand させる |
| ゴーストを配置したが `set_accuracy()` を呼ばない | 精度システムが視覚化されない（生霊理論が壊れる） | `_ready()` で必ず `_ghost.set_accuracy(...)` を呼ぶ |
| アイコンの `text = "🏠"` のような絵文字使用 | Noto Sans JP は絵文字グリフを持たず豆腐 (□) 化 | Material Symbols のリガチャ名を使う（`home` など） |
| StyleBoxTexture に shadow を期待する | 影が出ない。Godot 4 の StyleBoxTexture は shadow 非対応 | StyleBoxFlat + bg_color で影を出す、または外側に shadow 付きコンテナをネスト |

---

## 9. ミニゲーム実装のテンプレ

新しいミニゲームを追加するときは、反射タップ (`scripts/games/reflex_tap.gd` + `scenes/games/reflex_tap.tscn` + `scripts/ui/reflex_tap_view.gd`) を下敷きにする。

### 9-1. ロジッククラス (`scripts/games/<game>.gd`)

```gdscript
class_name <PascalCaseGame>
extends BaseGame

# 定数（ゲーム固有の上限・範囲）
const TARGET_COUNT: int = 20

# 状態（_ プレフィックスで private）
var _tapped_count: int = 0

# BaseGame ライフサイクルフック
func _on_setup(_seed_value: int) -> void:
    game_type = "<game>"
    is_time_based = true  # or false
    _tapped_count = 0
    # rng は既に setup() で初期化済み

func _on_start() -> void:
    pass  # シーン側 (view) が初期描画を担当

func _on_user_input(input: Dictionary) -> void:
    # input.type で分岐
    pass

func _on_finish() -> PlayLog:
    var log := super._on_finish()
    log.game_type = "<game>"
    return log
    # score は GameManager が ScoreSystem 経由で埋める設計
```

### 9-2. シーン (`scenes/games/<game>.tscn` + `scripts/ui/<game>_view.gd`)

- ルート: Control + PageBackground + SafeAreaMargin + MainColumn (§1 ボイラープレート準拠)
- TopHudRow: 3 ピル (進捗 / 経過時間 / その他) で情報表示
- GameArea: Control + size_flags_vertical=3 + clip_contents=true でゲーム固有のプレイ領域
- view スクリプトが BaseGame 派生クラスを `add_child` してロジックを駆動
- view は `_process(delta)` で HUD 更新、`Timer` で次イベントスケジュール

### 9-3. ScoreSystem への登録

`scripts/core/score_system.gd` の `calculate_score()` の `match game_type:` に新ゲームの算出式を追加する。GDD §6 のスコア計算式に準拠。

### 9-4. GameManager フローへの組み込み

`scripts/autoload/game_manager.gd` に以下のメソッドを追加 (反射タップを参考):
- `start_<game>(mode)` — シーン遷移開始
- `on_<game>_finished(log)` — ゲーム終了時のフィルイン + ScoreSystem 呼び出し + DataStore 保存 + 結果画面遷移

### 9-5. 共有ルール説明データ

`scripts/ui/rule_explain_controller.gd` の `RULES` Dictionary に新ゲームのエントリを追加するだけで、同じルール説明シーンで新ゲームをサポートできる:

```gdscript
const RULES: Dictionary = {
    "reflex_tap": {...},
    "<new_game>": {
        "title": "<ゲーム名>",
        "dialogue": "<ゴーストが説明するルール文>",
    },
}
```

### 9-6. ユニットテスト

`tests/unit/games/test_<game>.gd` に以下を最低限カバー:
- 決定論性 (同じ seed で同じ結果)
- 範囲チェック (生成値がパラメータ内)
- スコア境界 (0、上限値、不正入力)
- エッジケース (空、極端な値)

GUT の `before_each` でゲームインスタンスを seed 付きで setup する。

### 9-7. 反射タップを写経するときのチェックリスト

- [ ] BaseGame 継承
- [ ] `class_name` を新規追加 (Godot 4 ネイティブクラスと衝突しない名前)
- [ ] `Array.shuffle()` を使っていない (`rng.randi_range` のみ)
- [ ] `ScoreSystem.calculate_score("<game>", play_data)` の呼び出しが GameManager 側
- [ ] `RULES` Dictionary に新ゲーム追加
- [ ] `GameManager.start_<game>` メソッド追加
- [ ] view スクリプトが ScoreSystem / DataStore を直接呼んでいない (GameManager 経由)
- [ ] 新規シーンで生 hex / 絶対配置 / theme_override がゼロ
- [ ] GUT テスト追加

---

## 10. 参照ドキュメント

- `docs/design/manifest.md` — カラートークン・タイポ・スペーシング仕様
- `docs/design/references/competitor-research.md` — 競合 7 アプリ UI リサーチ
- `memory/project_ghost_character.md` — ゴーストシステムのナラティブ・ステート対応表
- `scripts/utils/color_palette.gd` — 色定数の実装本体
- `scripts_build/build_theme.gd` — Theme Resource 生成スクリプト
- `scripts_build/build_gradients.gd` — グラデーションテクスチャ生成スクリプト
