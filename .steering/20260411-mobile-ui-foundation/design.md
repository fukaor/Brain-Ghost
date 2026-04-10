# 設計書 — モバイルアプリ UI/UX 基盤

## アーキテクチャ概要

Godot の **Theme Resource + Control ノード + Container レイアウト** を正規の構成として採用する。ビジュアルはすべて `.tres` と `.tscn` に寄せ、GDScript には見た目の情報を持たせない（ロジックとビジュアルを分離する Godot の流儀に従う）。

```
┌────────────────────────────────────────────────────┐
│ assets/themes/default_theme.tres                   │
│  ├─ Button (default/hover/pressed/disabled)        │
│  ├─ Label  (default/h1/h2/display/caption)         │
│  └─ Panel  (card/card_elevated)                    │
│  ← project.godot の gui/theme/custom に登録        │
└────────────────┬───────────────────────────────────┘
                 │ 自動継承
                 ▼
┌────────────────────────────────────────────────────┐
│ scenes/main/home.tscn                              │
│  MarginContainer (Safe Area 余白)                  │
│   └─ VBoxContainer                                 │
│      ├─ HeaderPanel (前回スコア・ストリーク)       │
│      ├─ HeroSection (大型 CTA)                     │
│      ├─ SecondaryCTA (全ゲーム一覧)                │
│      └─ BottomNavBar (3 タブ + 広告枠)             │
└────────────────┬───────────────────────────────────┘
                 │ シグナル
                 ▼
┌────────────────────────────────────────────────────┐
│ scripts/ui/home_controller.gd                      │
│  - ボタンシグナル接続のみ（遷移は print ログ）      │
│  - DataStore からダミー値読み取り（無ければ規定値）│
│  - 色・フォント・サイズには一切触れない            │
└────────────────────────────────────────────────────┘
```

**重要な設計原則**:
1. **ビジュアルは `.tres` に、ロジックは `.gd` に**。GDScript 内で `modulate` や `add_theme_font_override` するのは最終手段
2. **絶対配置禁止**。`Anchor + MarginContainer + VBox/HBox` だけで組む
3. **色は `ColorPaletteUtil` 経由**、生 hex はレビューでリジェクト
4. **Theme 継承を活かす**。シーンルートに Theme を置けば子 Control に自動伝播するので、個別ノードに `theme_override` を振らない

## コンポーネント設計

### 1. default_theme.tres（共通テーマ）

**責務**:
- アプリ全体の色・フォント・スペーシング・形状の Single Source of Truth
- `Button`, `Label`, `Panel` の StyleBox 定義
- フォント（Noto Sans JP Bold）のバンドル

**実装の要点**:
- Godot エディタで `New Resource → Theme` で作成（テキスト編集より GUI が速い。生成後は `.tres` で管理してテキスト diff 可能）
- Button の default 状態は **ゴールド CTA**（`POSITIVE_GOLD` = #FACC15）。hover/pressed は彩度を 10% 落とす
- Label Variations（Godot 4 の機能）で `h1`, `h2`, `display`, `caption` を定義。個別フォントサイズオーバーライドは使わない
- Panel は `card` (BG_LIGHT + 角丸 16 + 微シャドウ) と `card_elevated` (影をもう少し強く) の 2 variations
- `project.godot` の `[gui]` セクションに `theme/custom="res://assets/themes/default_theme.tres"` を追加

**技術的制約**:
- Noto Sans JP は日本語フォントでサイズが大きい（5〜10MB）。Web 版のダウンロード時間を考慮し、**Subset（JIS 第1水準 + 記号 + 英数字）だけ埋め込む**ことを検討。ただし MVP では Full を使い、最適化は別タスクで
- Godot 4.6 の Theme Resource 形式はエディタでしか正確に編集できない。テキストエディタで無理に触らない

### 2. home.tscn（ホーム画面）

**責務**:
- FR-07 の受け入れ条件を満たす UI を表示
- ユーザー入力（タップ）を受け取り `home_controller.gd` にシグナル発火

**ノード階層**:

```
Home (Control, anchors_preset=15 フル)
 └─ SafeAreaMargin (MarginContainer)
     margin_top=48, margin_bottom=96, margin_left=24, margin_right=24
     └─ MainColumn (VBoxContainer, separation=16)
         ├─ HeaderPanel (PanelContainer, theme_type_variation="card")
         │   └─ HeaderVBox (VBoxContainer, separation=4)
         │       ├─ GreetingLabel (Label, "おかえりなさい")
         │       ├─ StreakRow (HBoxContainer)
         │       │   ├─ StreakIcon (TextureRect, 24x24)
         │       │   └─ StreakLabel (Label, "5日連続")
         │       └─ LastScoreLabel (Label, "前回スコア 3200 / 脳年齢 28歳")
         │
         ├─ Spacer1 (Control, custom_minimum_size.y=8)
         │
         ├─ HeroSection (PanelContainer, theme_type_variation="card_elevated")
         │   └─ HeroVBox (VBoxContainer, separation=12)
         │       ├─ HeroTitleLabel (Label variation="h2", "今日のチャレンジ")
         │       ├─ HeroSubLabel (Label variation="caption", "3 種類 / 約 2 分")
         │       └─ StartButton (Button, text="スタート", minimum_size=(0, 88))
         │
         ├─ Spacer2 (Control, custom_minimum_size.y=16)
         │
         ├─ SecondaryCTA (Button, text="全ゲーム一覧", minimum_size=(0, 56))
         │
         ├─ GhostStatsLabel (Label variation="caption", "ゴースト通算 15 勝 8 敗")
         │
         ├─ FlexSpacer (Control, size_flags_vertical=EXPAND)  # ここで下に余白を押し出す
         │
         └─ BottomNavBar (PanelContainer)
             └─ NavHBox (HBoxContainer)
                 ├─ HomeTabButton (Button, flat, icon + "ホーム")
                 ├─ CalendarTabButton (Button, flat, icon + "カレンダー")
                 └─ SettingsTabButton (Button, flat, icon + "設定")

 └─ AdBannerArea (MarginContainer, anchor 下端固定, Android でのみ可視)
     custom_minimum_size.y = 60
```

**実装の要点**:
- **親指ゾーン**: `StartButton` と `SecondaryCTA` は画面下 1/3 の親指リーチ領域に配置する
- **FlexSpacer** で可変余白を作り、ヘッダとメイン CTA を画面上部、セカンダリと広告を画面下部に固定
- **ボトムナビはダミー**。アイコンはプレースホルダ（`assets/icons/` に Material Symbols 3 個を SVG で置く or 絵文字ラベルで代用）
- **広告枠**: `AdBannerArea` は `Platform.supports_admob()` が `true` のときだけ `visible = true`。Web 版では `hide()`

**技術的制約**:
- Godot 4 の `Theme Type Variation` を使うには Theme 側で variation を登録する必要がある。エディタで `Panel` → `+ Type` → `card` で追加
- `PanelContainer` は子に StyleBox margin を自動適用するので、内部に追加の MarginContainer を入れない（二重余白になる）

### 3. home_controller.gd

**責務**:
- ボタンシグナル → `print()` でログ出力（実遷移は次ステアリング）
- ダミーデータでラベル更新（DataStore 無しでも動く）

**実装の要点**:

```gdscript
extends Control

@onready var _greeting := $SafeAreaMargin/MainColumn/HeaderPanel/HeaderVBox/GreetingLabel
@onready var _streak := $SafeAreaMargin/MainColumn/HeaderPanel/HeaderVBox/StreakRow/StreakLabel
@onready var _last_score := $SafeAreaMargin/MainColumn/HeaderPanel/HeaderVBox/LastScoreLabel
@onready var _ghost_stats := $SafeAreaMargin/MainColumn/GhostStatsLabel
@onready var _start_button := $SafeAreaMargin/MainColumn/HeroSection/HeroVBox/StartButton
@onready var _secondary := $SafeAreaMargin/MainColumn/SecondaryCTA
@onready var _ad_banner := $AdBannerArea

func _ready() -> void:
    _apply_placeholder_data()
    _wire_signals()
    _configure_platform_visibility()

func _apply_placeholder_data() -> void:
    _greeting.text = "おかえりなさい"
    _streak.text = "5 日連続"
    _last_score.text = "前回スコア 3200 / 脳年齢 28 歳"
    _ghost_stats.text = "ゴースト通算 15 勝 8 敗"

func _wire_signals() -> void:
    _start_button.pressed.connect(func(): print("[Home] StartButton pressed (TODO: 次ステアリングで遷移)"))
    _secondary.pressed.connect(func(): print("[Home] SecondaryCTA pressed"))

func _configure_platform_visibility() -> void:
    _ad_banner.visible = Platform.supports_admob() if Engine.has_singleton("Platform") else false
```

**技術的制約**:
- `Platform` Autoload が未実装の段階ではシングルトン存在チェックで fallback。環境構築タスクで Platform が先に入っていればそのまま動く
- 色・フォントを GDScript で触らない。ここで `modulate = Color.RED` みたいなコードを書いたら負け

### 4. patterns.md（テンプレドキュメント）

**責務**:
- ホーム画面で確立したパターンを 1 ページに集約
- 次画面の実装者（自分 or 将来の自分）が迷わず同じトーンを再現できる

**記載内容**:
- シーンルートテンプレ（`Control` + `SafeAreaMargin` + `MainColumn` のボイラープレート）
- ノード命名規則（`*Panel`, `*VBox`, `*Button`, `*Label`）
- Theme variation の使い分け表（いつ `h1` vs `h2`、いつ `card` vs `card_elevated`）
- よくあるアンチパターン（絶対配置、theme_override、生 hex、赤色使用）とそれをやると何が起きるか

## データフロー

### ホーム画面起動時

```
1. Launch シーン → GameManager.change_scene("home.tscn")
2. home.tscn _ready() 発火
3. home_controller._apply_placeholder_data() がダミー値を Label に流し込む
4. home_controller._wire_signals() がボタンシグナルを接続
5. home_controller._configure_platform_visibility() で広告枠を Web では非表示
6. Theme が自動適用され見た目が確定
```

### ユーザーが [スタート] をタップ

```
1. StartButton.pressed シグナル発火
2. home_controller のラムダが print() 出力
3. （次ステアリングで GameManager.start_daily_challenge() 呼び出しに置き換える）
```

## エラーハンドリング戦略

本フェーズは UI 骨格のみなのでエラーハンドリングは最小限:

- **Font 読み込み失敗**: Godot デフォルトフォントに fallback（自動）
- **Theme 読み込み失敗**: `project.godot` に登録していなければシステムデフォルトが使われるだけ（クラッシュしない）
- **DataStore 未実装**: ダミー値を直書きするため、DataStore の有無に関わらず動く
- **Platform Autoload 未登録**: `Engine.has_singleton("Platform")` でチェックし、無ければ広告枠は非表示

## テスト戦略

### ユニットテスト（GUT）

本フェーズはビジュアル中心のため、新規ユニットテストは追加しない。以下を確認:

- **リグレッション**: 既存の GUT 45 テストが引き続き全パス（色定数名の衝突等が起きていないか）
- **スモークテスト**: `tools/smoke_test.gd` 54/54 パス

新規テスト追加は次ステアリング（反射タップ実装）でロジックと一緒に書く。

### ビジュアルテスト（スクリーンショット）

手動または半自動で:

1. `godot --headless --main-scene scenes/main/home.tscn --screenshot /tmp/home.png` または同等コマンドで PNG 出力
2. `docs/design/references/competitor-research.md` の Top 5 画面と並べて目視比較
3. スクショを `.steering/20260411-mobile-ui-foundation/screenshots/` に保存（iteration_01.png, iteration_02.png, ...）
4. ユーザー承認を待つ

**Note**: Godot headless で本当にスクショが撮れるか要検証。撮れない場合は `--rendering-driver opengl3` + X11 virtual display か、手動でエディタ起動してスクショを取る手順に切り替える。

### 静的チェック

- `grep` で生 hex 検出: `Color\(0?\.\d` ヒットが `color_palette.gd` 以外 0 件
- `grep` で絶対配置検出: `offset_left = [-0-9]`, `offset_top = [-0-9]` が `scenes/main/home.tscn` 内で不要に使われていない
- `godot --headless --editor --quit-after 60` で class cache が Parse Error なく生成される

## 依存ライブラリ

新規追加:

- **Noto Sans JP Bold** (`.otf` or `.ttf`)
  - 取得元: Google Fonts（`https://fonts.google.com/noto/specimen/Noto+Sans+JP`）
  - ライセンス: SIL Open Font License 1.1
  - 配置: `assets/fonts/NotoSansJP-Bold.otf`
  - クレジット: `assets/CREDITS.md` に追記

代替案:

- **M PLUS Rounded 1c Bold** — より丸くアプリらしいが、サイズが大きい。MVP では Noto Sans JP を採用し、余裕があればスイッチ

## ディレクトリ構造

新規・変更されるファイル:

```
workspace/
├── .steering/20260411-mobile-ui-foundation/
│   ├── requirements.md          (作成済)
│   ├── design.md                (本ファイル)
│   ├── tasklist.md              (次に作成)
│   └── screenshots/             (iteration 中に作成)
│
├── docs/design/
│   ├── manifest.md              (新規: citadel:design で生成)
│   ├── patterns.md              (新規: 次画面展開用テンプレ)
│   └── references/
│       └── competitor-research.md (既存)
│
├── assets/
│   ├── fonts/
│   │   └── NotoSansJP-Bold.otf  (新規)
│   ├── themes/
│   │   └── default_theme.tres   (新規)
│   └── icons/
│       ├── nav_home.svg         (新規、プレースホルダ OK)
│       ├── nav_calendar.svg     (新規)
│       └── nav_settings.svg     (新規)
│
├── scenes/main/
│   └── home.tscn                (既存プレースホルダを置換)
│
├── scripts/ui/
│   └── home_controller.gd       (既存プレースホルダを置換 or 新規)
│
├── project.godot                (編集: gui/theme/custom に default_theme.tres)
└── assets/CREDITS.md            (編集: Noto Sans JP 追加)
```

## 実装の順序

1. **デザイン言語の明文化**（citadel:design or 手動で manifest.md）
2. **フォント調達**（Noto Sans JP Bold ダウンロード → `assets/fonts/`）
3. **Theme 作成**（`default_theme.tres` を Godot エディタで作成 → 最小 variations 登録）
4. **project.godot 登録**（theme/custom）
5. **home.tscn 骨格**（ノード階層を組む、ダミーテキスト）
6. **home_controller.gd**（シグナル接続 + ダミーデータ反映）
7. **起動確認**（`godot --headless --quit` exit=0、GUT 45/45）
8. **スクショ撮影 → 比較 → 調整ループ**（満足するまで）
9. **ユーザー承認**
10. **patterns.md 執筆**（次画面展開用テンプレ）
11. **リグレッション最終確認 + 振り返り**

## セキュリティ考慮事項

- フォントファイルは外部（Google Fonts）から取得。ダウンロード時は必ず HTTPS 経由、ハッシュは手動確認（OFL 配布元）
- `.tscn` には機密情報を含めない（本フェーズはダミーデータのみなので問題なし）

## パフォーマンス考慮事項

- **フォントファイルサイズ**: Noto Sans JP Bold Full は約 4-6 MB。Web 版の初回ロードに影響するので、将来的に Subset 版に差し替えることを patterns.md にメモ
- **シャドウ描画**: `StyleBoxFlat.shadow_size` は Godot で実装済みだが、重いと報告がある。Web 版のパフォーマンス次第では微シャドウを削って平坦にする
- **ノード数**: ホーム画面程度（20〜30 ノード）なら問題ないが、ノード階層を深くしすぎないこと

## 将来の拡張性

- **ダークモード** (GDD §v1.1): Theme を 2 つ用意し `project.godot` で切替。トークン名は変えず、値だけ入れ替える設計にしておく
- **タブレット対応**: Container ベースなので基本は拡大縮小で追従。固定ピクセル値（`custom_minimum_size`）を使っている箇所は patterns.md に一覧化しておき、タブレットで見直す
- **アニメーション**: AnimationPlayer は後付けで `.tscn` に足せる。本フェーズで構造さえ綺麗にしておけば手戻りしない
- **i18n**: 現状は日本語べた書き。将来的に `tr()` でラップする前提で、文字列は 1 箇所に集約しやすい位置（home_controller.gd の `_apply_placeholder_data()`）にまとめておく

## citadel スキルの活用戦略

- **`citadel:design`**: Step 1 で `manifest.md` の初稿を生成させる。インプットとして `competitor-research.md`、`color_palette.gd`、GDD の禁則事項を渡す
- **`citadel:live-preview`**: Step 8 でスクショループに使う。もし動かない or Godot 非対応なら手動スクショに切り替え
- 両スキルとも「走らせてみて、ダメなら手動」のフォールバックで運用する（スキルにロックインしない）
