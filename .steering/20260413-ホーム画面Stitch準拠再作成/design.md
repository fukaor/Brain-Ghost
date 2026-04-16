# 設計書

## アーキテクチャ概要

既存のシーン構造（`home.tscn` + `home_controller.gd`）を再構築。Stitch v0.1準拠のレイアウトにしつつ、Docs仕様の追加要素を組み込む。

```
Home (Control)
├── PageBackground (TextureRect)          ← 差し替え可能な背景テクスチャ
├── GhostMascotLayer (TextureRect)        ← 差し替え可能なキャラ画像
└── SafeAreaMargin (MarginContainer)
    └── MainColumn (VBoxContainer)
        ├── HeaderRow                      ← 脳年齢 + ゴーストバトル
        ├── StreakBadge                    ← ストリーク表示（Docs追加）
        ├── SpeechBubblePanel             ← ゴースト吹き出し
        ├── FlexSpacer
        ├── ConditionalBannerArea         ← 年代設定/復帰演出（Docs追加、条件付き）
        ├── AbilityCard                   ← 6能力グリッド
        ├── StartButton                   ← CTA
        └── BottomNavBar                  ← 5タブ
    └── AdBannerArea                      ← 広告（Android、Docs追加）
```

## コンポーネント設計

### 1. アセット差し替え容易性

**責務**:
- キャラ画像、アイコン、背景テクスチャをパス変更のみで差し替え可能にする

**実装の要点**:
- キャラ画像: `GhostMascotLayer` の `texture` プロパティにリソースパスを設定。スクリプト上部に `const GHOST_TEXTURE_PATH` を定義
- 能力アイコン: 各セルの `TextureRect` に個別テクスチャを設定。アイコンマッピング辞書 `ABILITY_ICONS` をスクリプト上部に定義
- 背景: `PageBackground` のテクスチャパス。`const BG_TEXTURE_PATH` を定義
- CTAボタン: テクスチャベースのStyleBox。パス定数化

### 2. ヘッダー行（HeaderRow）

**責務**:
- 脳年齢表示（暫定/確定切替）
- ゴーストバトル戦績バー

**実装の要点**:
- 脳年齢: 精度 < 1.0 なら「約」プレフィックス付与、= 1.0 なら数値のみ
- 「娯楽目的です」キャプションを脳年齢パネル下部に小さく表示
- 戦績バー: 既存の stretch_ratio 方式を維持

### 3. ストリーク表示（StreakBadge）— Docs追加

**責務**:
- 「○日連続！」のバッジ表示

**実装の要点**:
- `HBoxContainer` にアイコン + ラベル
- ストリーク0日の場合は非表示（`visible = false`）
- DataStore.load_streak_state() から取得

### 4. 吹き出し（SpeechBubblePanel）

**責務**:
- ゴーストのセリフ表示
- 復帰演出時の特別セリフ表示（Docs A-06）

**実装の要点**:
- 復帰演出: `_on_home_ready()` で `StreakState.welcome_back_shown` をチェック
- 通常時: プレースホルダーセリフまたはDataStoreベースの動的セリフ

### 5. 条件付きバナーエリア（ConditionalBannerArea）— Docs追加

**責務**:
- 年代設定バナー（条件: `ageBannerDismissed == false && ageGroup == null`）
- 初期状態 `visible = false`、条件成立時のみ表示

**実装の要点**:
- PanelContainer + Label + 閉じるボタン
- 閉じた際に `DataStore` を更新

### 6. 能力グリッド（AbilityCard）

**責務**:
- 6能力の人魂アイコン+ラベル表示
- 人魂サイズ（Lv1〜5）で得意/苦手を視覚化
- タップで対応ゲーム起動

**実装の要点**:
- 既存のGridContainer 6列構成を維持
- 各セルの IconRect を人魂テクスチャ（hitodama_lv1〜5.png）に差し替え
- IconLabel（MaterialSymbolsフォントのアイコン文字）は削除
- スクリプトで能力レベル（1〜5）に応じて動的にテクスチャを切替
- 人魂レベル算出: プレイ済みスコアから相対ランク（未プレイ=Lv1, 最高=Lv5）
- テクスチャパス: `res://assets/icons/hitodama_lv{1-5}.png`

### 7. ボトムナビ（BottomNavBar）— 5タブに拡張

**責務**:
- 脳トレ / 分析 / ホーム / アワード / 設定の5タブ

**実装の要点**:
- 「分析」タブを追加（Stitch準拠）
- アクティブタブのハイライトをプログラム的に切替
- 遷移先未実装のタブは print stub

## データフロー

### ホーム画面表示時
```
1. _ready() → DataStore から UserConfig, StreakState, PlayLog を読み込み
2. 脳年齢を算出 → ヘッダーに表示（精度に応じて「約」付与）
3. ゴースト戦績を取得 → 戦績バーに反映
4. ストリーク日数を取得 → StreakBadge に反映
5. 復帰演出チェック → 該当すれば吹き出しに表示
6. 年代設定バナーチェック → 該当すれば表示
7. ゴースト不透明度を精度から算出 → GhostMascotLayer に反映
8. Platform判定 → AdBannerArea の visible 設定
```

## パフォーマンス考慮事項

- ホーム→ゲーム開始は2秒以内（Docs非機能要件）
- `_process()` のアニメーションは軽量に（sine計算のみ）

## 差し替え容易性の設計

```gdscript
# スクリプト上部にアセットパス定数をまとめる
const GHOST_TEXTURE := "res://assets/characters/ghost_placeholder.svg"
const BG_TEXTURE := "res://assets/textures/gradients/page_bg_v2.png"
const CTA_NORMAL := "res://assets/textures/gradients/cta_blue.png"
const CTA_PRESSED := "res://assets/textures/gradients/cta_blue_pressed.png"
const ABILITY_CIRCLE := "res://assets/textures/gradients/ability_circle_blue.png"

# アイコンマッピング（テクスチャ差し替え時はここを変更）
const ABILITY_ICONS := {
    "calculation": "res://assets/icons/ability_calculation.png",
    "memory": "res://assets/icons/ability_memory.png",
    "attention": "res://assets/icons/ability_attention.png",
    "reflex": "res://assets/icons/ability_reflex.png",
    "observation": "res://assets/icons/ability_observation.png",
    "judgment": "res://assets/icons/ability_judgment.png",
}
```

## ディレクトリ構造（変更対象）

```
scenes/main/home.tscn          ← 再構築
scripts/ui/home_controller.gd  ← 再構築
assets/themes/default_theme.tres ← テーマバリエーション追加・修正
```

## 実装の順序

1. home_controller.gd のスクリプト再構築（アセット定数、データ読み込み、Docs仕様追加）
2. home.tscn のシーンツリー再構築（ノード追加・再配置）
3. テーマの調整（必要に応じて）
4. 動作確認
