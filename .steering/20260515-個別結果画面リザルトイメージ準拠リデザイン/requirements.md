# 要求内容

## 概要

`scenes/ui/individual_result.tscn` + `scripts/ui/individual_result_controller.gd` を、ユーザ提供のリザルトイメージ画像 `docs/design/promotion/game_tap_result.png` に準拠したレイアウトに刷新する。共通画面のままで、ゴースト7番勝負特有要素 (ラウンドドット) は条件表示。

設計判断は脳トレアプリの UX ベストプラクティス (Lumosity / Peak / Elevate 調査 - `brain-training-ux` skill) に準拠。

## 背景

- 直前ステアリング `20260512-個別結果画面MidnightCat化` で背景・色だけ Midnight Cat に揃えたが、レイアウト構造は反射タップ時代の RESULTS ヘッダ + VICTORY/DEFEAT + パーフェクト/ミス という古い設計のまま
- 参考画像は次の構成: PERFECT WIN 大見出し + ラウンドドット + 勝ち越し！装飾タイトル + スコア (前回比デルタ + BESTピル) + YOU/GHOST 平均ms 並列カード + マスコット+吹き出し + 「もう一度」/「ホームへ戻る」
- 既存 `_previous_score` (GameManager) を活用して前回比デルタを表示できる状態

## UX ベストプラクティス準拠の原則

(本セクションの根拠は `.claude/skills/brain-training-ux/SKILL.md`)

- **赤色は局所要素でも使用しない** (§3.1, §4.1) — ラウンド × も例外なくグレー
- **fake ゴーストは出さない** (§4.3 Honest framing) — 真のゴーストデータがあるゲームのみ「GHOST」比較を表示
- **失敗ワード禁止** (§4.1) — "DEFEAT" "LOSE" "MISS" などのワードは使わず "NICE TRY" "あと一歩" など主体性回復系
- **軌跡 > スナップショット** (§4.1) — 前回比 delta は正方向のみ表示し、負の delta は非表示
- **演出ヒエラルキー** (§4.2) — 結果の階層 (PERFECT WIN / GREAT / WIN / NICE TRY) で装飾サイズを変える

## 実装対象の機能

### 1. ヘッダー (grade headline + subtitle + round dots)

#### 1-1. GradeHeadline (金色セリフ大見出し + 星装飾)

**装飾**: 両側に Material Symbols `auto_awesome` 36px gold (`Color(1.0, 0.914, 0.659)`)

**ghost_7ban_shobu の grade マッピング** (UX §4.2 演出ヒエラルキー準拠):

| wins / 7 | Headline | サイズ | 装飾色 | 演出 |
|---|---|---|---|---|
| 7 | **PERFECT WIN** | 72px | gold | 星装飾+輝度高め |
| 5-6 | **GREAT WIN** | 64px | gold | 星装飾 |
| 4 | **WIN** | 56px | gold | 星装飾 |
| ≤3 | **NICE TRY** | 56px | cyan dim | 星装飾なし |

**他ゲームの grade マッピング**:

| 条件 | Headline | サイズ | 装飾色 |
|---|---|---|---|
| log.is_new_best == true | **NEW BEST** | 64px | gold |
| score > _previous_score | **IMPROVED** | 56px | gold |
| score <= _previous_score | **NICE TRY** | 56px | cyan dim |
| _previous_score == 0 (初回) | **NICE START** | 56px | gold |

#### 1-2. Subtitle (small caps cyan)

ゲーム種別ラベル。色 `Color(0.7, 0.93, 1.0, 0.7)`、サイズ 24px、文字間隔広め。

| game_type | Subtitle |
|---|---|
| ghost_7ban_shobu | "7ラウンド対決" |
| reflex_tap | "反射タップ" |
| flash_calc | "フラッシュ暗算" |
| stroop | "ストループ" |
| sequence_memory | "順番記憶" |
| card_match | "神経衰弱" |
| number_search | "数字さがし" |

#### 1-3. RoundDots (7個、ghost_7ban_shobu のみ表示)

各ラウンドのアイコン:

| ラウンド結果 | アイコン | 色 |
|---|---|---|
| **win** | filled 円 (◉) または Material `circle` | cyan `Color(0.7, 0.93, 1.0)` |
| **loss** | × 印 (Material `close`) | **gray `Color(0.6, 0.65, 0.75)`** (UX §3.1: 赤禁止) |
| **miss** (delta=1000ms) | 小さい dim 円 (Material `radio_button_unchecked`) | gray dim `Color(0.6, 0.65, 0.75, 0.5)` |

データ源: PlayLog の `round_result` イベント (delta) と新規追加する `round_win` イベント (win 0/1) のペア。

### 2. 判定タイトル (装飾セリフ)

大きいセリフ Label、両側に小装飾文字 (例: `✧ 勝ち越し！ ✧`)。装飾文字は Unicode 星 `✧` を小サイズで。

| 条件 | 判定タイトル | 色 |
|---|---|---|
| ghost_7ban_shobu, wins ≥ 4 | "勝ち越し！" | gold |
| ghost_7ban_shobu, wins < 4 | "あと一歩！" (UX §4.1: 失敗ワード禁止) | cyan dim |
| 他ゲーム, log.is_new_best | "自己最高記録！" | gold |
| 他ゲーム, score > _previous_score | "成長してる！" | gold |
| 他ゲーム, score <= _previous_score | "ナイスプレイ！" | cyan dim |
| 他ゲーム, _previous_score == 0 | "良いスタート！" | gold |

### 3. スコアブロック (delta + BEST pill)

- **ScoreCaption**: 「スコア」(small dim cyan, 28px)
- **ScoreRow** (HBox alignment center):
  - **ScoreValue**: 大数字 (100px white) — `1,280` のように 3 桁区切り
  - **ScoreUnit**: 「pts」「ms」など (32px dim)
  - **DeltaBadge** (PanelContainer, pill 形):
    - 「↑+180」 (Material `arrow_upward` + 数字)
    - 色: cyan `Color(0.435, 0.706, 1.0)`、bg: cyan dim 透明 (`Color(0.435, 0.706, 1.0, 0.15)`)
    - **表示条件**: `log.score - _previous_score > 0` のときのみ表示。負/0/初回は **非表示** (UX §4.1: 軌跡 > スナップショット)
- **BestPill** (PanelContainer, 金色 pill):
  - text: 「BEST」
  - 色: gold `Color(1.0, 0.914, 0.659)`、bg: gold dim 透明
  - 表示条件: `log.is_new_best == true`

### 4. YOU/GHOST 比較カード

旧 ComparisonCard + StatsGrid を統合した **CompareCards (HBox, 2 並列)**。

#### 4-1. ゲーム別の表示パターン

| game_type | YouCard | OpponentCard | 補足 |
|---|---|---|---|
| ghost_7ban_shobu | YOU 平均ms | GHOST 平均ms (真のゴーストデータ) | フル機能 |
| reflex_tap | YOU 平均ms | GHOST 平均ms (cfg.ghost_score_placeholder) | 暫定 (将来本物のゴーストに置換予定) |
| flash_calc / stroop / sequence_memory / card_match / number_search | YOU スコア | **自己ベスト** スコア (DataStore.load_best().best_score) | UX §4.3: fake ghost を出さない |

#### 4-2. YouCard (PanelContainer, glass_bubble 派生)

- **YouAvatar** (TextureRect, 64x64) — `catboy_electric.png` (今のあなた)
- **YouCaption**: 「平均」or「スコア」(small dim cyan, 24px)
- **YouValue**: 「112ms」or「1,280」(大 cyan, 56px)

#### 4-3. OpponentCard (PanelContainer, glass_bubble 派生)

- **OpponentAvatar** (TextureRect, 64x64) — `catboy_confident.png` (いつものあなた)
- **OpponentCaption**: 「平均」or「自己ベスト」(small dim grey, 24px)
- **OpponentValue**: 「158ms」or「1,100」(大 dim white, 56px)

### 5. マスコット + 吹き出し (既存維持・配置調整)

- 既存 GhostRow (GhostChibi + SpeechBubble) は維持 (catboy_electric)
- 配置のみ MainColumn 下部 (上から: ヘッダ → 判定タイトル → スコア → 比較カード → マスコット → ボタン)
- SpeechText の文言は controller の `_update_ghost_dialogue()` で動的に切替 (既存ロジック流用、ヘッドラインに合わせて文言調整)

### 6. ボタン (Replay + Home リンク)

- **ReplayButton**: 「もう一度」(cta_blue 塗りボタン、icon: replay 40px)
- **HomeLink**: 「ホームへ戻る」(home_button outline、icon: home 42px、text 32px)
- 「次のゲームへ」は採用しない (確認済み)

### 7. キャプチャ検証ツール

- `tools/capture_individual_result.gd` を新規作成 (godot --script 実行で 720x1280 PNG を出力)
- ダミーデータ (ghost_7ban_shobu wins=5 / wins=2 / reflex_tap new_best / flash_calc improved) で 4 ケース撮影
- `docs/design/promotion/game_tap_result.png` との視覚的一致を目視確認

### 8. PlayEvent スキーマ拡張 (round_win)

ghost_7ban_shobu.gd の `_commit_round_result` で `round_result` イベントに加えて新規 `round_win` イベントを emit:

```gdscript
record_event("round_result", float(int(result.get("delta", MISS_RECORDED_MS))))
record_event("round_win", float(1 if result.get("win", false) else 0))
```

result controller は両イベントを 1:1 にペアリングして round dot のアイコンを決定。

## 受け入れ条件

### 構造
- [ ] `grep -E "ResultsHeader|VictoryBadge|VictoryLabel|PerfectCard|MissCard|CompareBarRow|PlayerBarSegment|GhostBarSegment" scenes/ui/individual_result.tscn` が 0 件
- [ ] 新ノード `GradeHeadline`, `Subtitle`, `RoundDots`, `VerdictTitle`, `DeltaBadge`, `BestPill`, `YouCard`, `OpponentCard` が存在
- [ ] VoidBg + NebulaBg + StarLayer 3 層背景は維持
- [ ] PlayLog に新規 `round_win` イベントが正しく記録される

### controller ロジック
- [ ] `individual_result_controller.gd` が以下のメソッドを持つ:
  - `_compute_grade_headline(log) -> Dictionary` ({text, font_size, color})
  - `_compute_verdict_title(log) -> Dictionary`
  - `_compute_round_outcomes(log) -> Array[String]` (["win", "loss", "miss", ...])
  - `_compute_delta_badge(log) -> Dictionary` ({visible, text})
- [ ] ghost_7ban_shobu の wins 数に応じてヘッドラインが PERFECT WIN / GREAT WIN / WIN / NICE TRY に切り替わる
- [ ] _previous_score を読み取り DeltaBadge が表示される (delta > 0 の時のみ、0以下や初回は非表示)
- [ ] log.is_new_best のとき BestPill が表示される
- [ ] score-based ゲームでは OpponentCard が自己ベスト表示になる

### ゲーム別動作
- [ ] ghost_7ban_shobu でラウンドドット 7 個が PlayLog から復元される (win/loss/miss を正しく分類)
- [ ] reflex_tap でラウンドドットが非表示、CompareCards は YOU/GHOST 平均ms
- [ ] flash_calc 等 score-based でラウンドドットが非表示、OpponentCard は自己ベスト

### UX ベストプラクティス準拠
- [ ] 赤色 (`Color(.*0\.[6-9].*, .*0\.[0-1].*, .*0\.[0-1].*)` 範囲) が **0 件** (round dot の × も含む)
- [ ] "DEFEAT" / "LOSE" / "失敗" / "負け" の文言が **0 件**
- [ ] 負の delta は表示されない

### ビジュアル一貫性
- [ ] 「Stitch画面との完全一致チェック」: `tools/capture_individual_result.gd` で 4 ケース PNG キャプチャを取得し `docs/design/promotion/game_tap_result.png` と並べて遜色ない
- [ ] Midnight Cat 暗色トーン (VoidBg + NebulaBg + StarLayer + シアン/ゴールド) が維持

### 機能
- [ ] 「もう一度」→ `GameManager.on_individual_result_replay()` 呼び出し
- [ ] 「ホームへ戻る」→ `GameManager.on_individual_result_home()` 呼び出し

## 成功指標

- ユーザが「リザルト画像とほぼ一致している」と感じる視覚的な一致度
- ghost_7ban_shobu のラウンド結果が一目で把握できる
- 前回比デルタにより「成長している実感」が得られる (UX §4.1: 軌跡視覚化)
- 全 game_type で「赤色なし」「失敗ワードなし」が保たれる

## スコープ外

- 総合結果画面 (overall_result.tscn) のリデザイン
- レーダーチャート / シェアURL 機能
- 個別結果画面の横画面対応 (常に縦画面)
- ゴーストアバターの新規制作 (既存 `catboy_confident.png` を流用)
- 「次のゲームへ」自動遷移
- `default_theme.tres` 内 theme_type_variation の刷新 (必要なら別フェーズ)
- 紙吹雪 / パーティクル演出 (UX §8.1 のアニメーション領域、別フェーズ)

## 参照ドキュメント

- 画像: `docs/design/promotion/game_tap_result.png`
- UX ガイド: `.claude/skills/brain-training-ux/SKILL.md` (Lumosity / Peak / Elevate 調査ベース)
- GDD: `docs/ideas/brain_training_gdd.md` (§6 スコアリング、§4 ゴースト対戦)
- 前ステアリング: `.steering/20260512-個別結果画面MidnightCat化/` (色テーマの正本)
- 既存実装: `scripts/ui/individual_result_controller.gd` / `scripts/autoload/game_manager.gd`
- ゲームスペック: `docs/ideas/games/ghost-7ban-shobu-spec.md`
