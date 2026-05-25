# 要求内容

## 概要

`docs/ideas/games/ghost-stroop-showdown-spec.md v1.1` の **MVP 範囲（Week 3 実装, T1〜T3 含む Shape）** を Godot 4 / GDScript で実装する。

## 背景

- 既存 game_list に `id = "stroop"` カードが定義済み。`_implemented_games` には未登録。表示名は「色文字テスト」となっているが、spec v1.1 で **「色文字ストループ」** に統一する。
- ScoreSystem の `stroop` 分岐は `correct*100 − incorrect*50` が既に正しい（GDD §6 と一致）。**改訂不要**。
- プロモ画像 `docs/design/promotion/game_stroop.png` でビジュアル確定:
  - 上部: タイトル「色文字ストループ」+ 残り秒数
  - 中段: 👤今日 / 👻いつもの自分 プログレスバー（タイム系ゴースト）
  - 中央: 大きな色付きひらがな（「あか」を青で表示）
  - 下部: 4 色ボタン（●あか / ▲あお / ■みどり / ◆きいろ）+ 正解/誤答カウンタ
- タイム系のため、プレイ中ゴーストバー表示（既存の ghost_7ban_shobu の進行表示パターンとは異なり、`stroop` 専用の累計正答数バー）。

## 実装対象（MVP）

### 1. ゲームロジック（BaseGame サブクラス）

| 項目 | 仕様 |
|---|---|
| ティア | **T1〜T3 まで実装**（T3 は Shape 含む） |
| 時間 | 30 秒タイムアタック |
| 判定 | 4 色 × 4 択。正解 +100 / 誤答 −50 / タイムアウト（3 秒）= 0 |
| 刺激プール | 40 問程度を事前生成（同日シード共通） |
| 出現比率 | T1: Congruent 50% / Incongruent 50% / T2: 30% / 70% / T3: 20% / 50% / Shape 30% |
| ボタン配置 | T1-T2 固定、T3 は 3 問ごとにシャッフル |
| 解放条件 | 正答率 70% 以上 × 直近 5 回中 3 回（v1.0 MVP は T1 のみ自動解放、上位ティアは TierManager で管理） |
| ゴースト | タイム系（プレイ中プログレスバー表示） |

### 2. 使用する色（4 色体系）

| 色 | カラー | ひらがな | 図形 (Material Symbols) |
|---|---|---|---|
| あか | `#E53935` | あか | `circle` ● |
| あお | `#1E88E5` | あお | `change_history` ▲ |
| みどり | `#43A047` | みどり | `square` ■ |
| きいろ | `#FDD835` | きいろ | `diamond` ◆ |

MVP では色覚配慮モードは形状アイコン併記のみ（spec §9-1）。色置換切替は v1.1。

### 3. シーン / UI

- **シーン**: `scenes/games/stroop/stroop.tscn`
  - 上部: TitleLabel + TimerLabel
  - 中段: PlayerProgressBar / GhostProgressBar（タイム系ゴースト）
  - 中央: StimulusContainer
    - StimulusLabel（色付きひらがな、48px Bold）
    - ShapeContainer（T3 Shape 時のみ可視：色付き図形 + 内側にひらがな）
  - 下部: AnswerButtons HBoxContainer（4 ボタン、各最低 80dp 幅）
  - フッター: 「正解: N  誤答: N」+ ⭐ベスト
- **フィードバック**:
  - 正解: 0.1 秒緑フラッシュ + ✓
  - 誤答: 0.1 秒グレーフラッシュ + ×（赤禁止）

### 4. ゴーストデータ統合

- `game_type = "stroop"`, `tier ∈ ("T1", "T2", "T3")`。
- 各秒時点の累計正答数を `events: [{time_ms, correct: bool}]` で記録。
- 初回ゴースト: T1=10 / T2=9 / T3=8 問（spec §6-3）。

### 5. GameManager 統合

- `GAME_SCENES["stroop"] = "res://scenes/games/stroop/stroop.tscn"`。
- `_build_play_data_for` の stroop 分岐は既存だが、`correct_count` / `incorrect_count` を log.events から正しく集計するように整備（既存実装でカバーされていない場合は追加）。
- `TIER_SELECT_SCENES["stroop"]` は **追加しない**（MVP は T1 固定で開始。ティア選択 UI は v1.1）。
- **コード上は T1〜T3 を完全サポート**: StimulusGenerator・TierConfig・Shape レンダリングを MVP に含める。v1.1 でティア選択 UI を後付けする際に再実装が発生しないようにする。

### 6. 脳トレ一覧画面への登録

- `_implemented_games` に `"stroop"` 追加。
- GAME_CARDS の `name` を **「色文字ストループ」** に変更（spec §1-1b の命名統一）。
- 説明文も v1.1 表現に合わせて微修正可。

## 非対象（v1.1 以降）

- T4-T6 / 逆ストループ / 5 択ダミーボタン / 毎問シャッフル
- 色覚配慮の色置換モード切替（形状アイコン併記のみ MVP に含む）
- 音声応答モード / 干渉量トレンドグラフ
- ティア選択画面（MVP は T1 固定）

## 受け入れ条件

1. 脳トレ一覧から「色文字ストループ」を選んで起動できる。
2. ルール説明 → カウントダウン → プレイ → 個別結果 のフローが他ゲームと同じく機能する。
3. 30 秒間、4 色 4 択で連続出題。最後の問題回答中に 30 秒経過したら、その回答までは処理して終了。
4. 正解 +100 / 誤答 −50 のスコア計算が機能する。負のネットスコアは 0 pts でクランプ。
5. プレイ中にゴースト累計正答数のプログレスバーが追従表示される。
6. 同日のシードで刺激プールが同一。
7. 結果画面に正答数 / 誤答数 / 平均反応時間が表示される。
8. Web / Android 両方でクラッシュなく動作する。
