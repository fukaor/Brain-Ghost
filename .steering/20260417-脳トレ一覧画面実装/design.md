# 設計書

## アーキテクチャ概要

既存の MVC パターンに従い、シーン(.tscn) + コントローラ(.gd) のペアで実装。

```
Home ──(NavTrain)──> GameList ──(カードタップ)──> GameManager.start_game()
                     ↕ (NavHome)                        ↓
                    Home                           RuleExplain → ...
```

## コンポーネント設計

### 1. game_list.tscn + game_list_controller.gd

**責務**:
- 6種ゲームのカルーセル表示
- スワイプ/タップによるカード切り替え
- ゲーム選択 → GameManager 経由でルール説明画面へ遷移
- ボトムナビゲーション

**シーンツリー**:
```
Control (GameList)
├── BgTexture (TextureRect)
├── SafeAreaMargin (MarginContainer)
│   └── MainColumn (VBoxContainer)
│       ├── HeaderSection (VBoxContainer)
│       │   ├── TitleLabel ("脳トレ一覧")
│       │   └── SubtitleLabel ("トレーニングを選んで...")
│       ├── CarouselArea (Control) ← 固定サイズ、カード配置の親
│       │   ├── Card0 (PanelContainer)
│       │   ├── Card1 (PanelContainer)
│       │   ├── Card2 (PanelContainer)
│       │   ├── Card3 (PanelContainer)
│       │   ├── Card4 (PanelContainer)
│       │   └── Card5 (PanelContainer)
│       ├── DotIndicators (HBoxContainer)
│       │   └── Dot0..Dot5 (PanelContainer)
│       └── PlayButton (Button) "このゲームをプレイ"
└── BottomNavPanel (PanelContainer)
    └── BottomNavBar (HBoxContainer)
```

**カード内部構造**:
```
PanelContainer (Card)
└── CardMargin (MarginContainer)
    └── CardVBox (VBoxContainer)
        ├── IconLabel (Label) ← Material Symbols文字
        ├── GameNameLabel (Label)
        ├── DescriptionLabel (Label)
        └── MetricRow (HBoxContainer)
            ├── MetricCaption (Label)
            └── MetricValue (Label)
```

**カルーセルロジック**:
- `_current_index`: int — 現在フォーカス中のカード (0-5)
- 中央カード: scale(1.0), modulate.a=1.0, position=center
- 隣接カード: scale(0.75), modulate.a=0.5, position=±offset
- 2つ以上離れたカード: visible=false
- Tween で 0.4s ease_out でアニメーション遷移

**スワイプ検出**:
- `_input(event)` で InputEventScreenDrag を検出
- 累積水平ドラッグ > 80px でカード切り替え
- 切り替え後リセット

### 2. GameManager への追加

**追加メソッド**:
- `navigate_to_game_list()`: ゲーム一覧画面へ遷移
- `navigate_to_home()`: ホーム画面へ遷移

**追加定数**:
- `GAME_LIST_SCENE: String`

### 3. home_controller.gd の修正

**変更点**:
- `_nav_train` ボタンの pressed → `GameManager.navigate_to_game_list()` 呼び出し
- `IMPLEMENTED_GAMES` に `"sequence_memory"` 追加

## ゲームカード定義（データ駆動）

```gdscript
const GAME_CARDS: Array[Dictionary] = [
    {id="reflex_tap", icon="touch_app", name="反射タップ", desc="出現するターゲットを即座にタップ！反応速度を測定", metric_caption="High Score", metric_value="--"},
    {id="flash_calc", icon="calculate", name="フラッシュ暗算", desc="次々と表示される数字を暗算。計算力を鍛えます", metric_caption="High Score", metric_value="--"},
    {id="sequence_memory", icon="memory", name="順番記憶", desc="パネルが光る順番を記憶して再現。短期記憶をトレーニング", metric_caption="High Score", metric_value="--"},
    {id="stroop", icon="palette", name="色文字テスト", desc="文字の内容ではなく「色」を回答。注意力を磨きます", metric_caption="High Score", metric_value="--"},
    {id="card_match", icon="layers", name="神経衰弱", desc="ペアのカードを素早く見つける。判断力と記憶力の勝負", metric_caption="High Score", metric_value="--"},
    {id="number_search", icon="visibility", name="数字さがし", desc="1から順番に数字をタップ。周辺視野と集中力を強化", metric_caption="High Score", metric_value="--"},
]
```

## Stitch → Godot サイズ換算

Stitch HTML: 1080x1920 → Godot: 720x1280（スケール比 2/3）

| 要素 | Stitch(px) | Godot(px) |
|---|---|---|
| カード幅 | 600 | 400 |
| カード高さ | 約900 | 600 |
| カード角丸 | 24 | 16 |
| アイコンサイズ | 72 | 48 |
| タイトルフォント | 36 | 24 |
| 説明フォント | 24 | 16 |
| ドット直径 | 16 | 11 |
| ドット間隔 | 12 | 8 |
| 隣接カードオフセット | 450 | 300 |

## ディレクトリ構造

```
scenes/ui/game_list.tscn          # 新規
scripts/ui/game_list_controller.gd # 新規
scripts/autoload/game_manager.gd   # 修正（navigate追加）
scripts/ui/home_controller.gd      # 修正（NavTrain接続）
```

## 実装の順序

1. game_list_controller.gd — データ定義 + カルーセルロジック
2. game_list.tscn — シーンツリー構築（Theme使用）
3. GameManager — navigate メソッド追加
4. home_controller.gd — NavTrain ボタン接続 + IMPLEMENTED_GAMES更新
5. 動作確認・微調整
