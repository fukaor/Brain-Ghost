# 要求内容

## 概要

GDD §4-1 / 仕様書 `docs/ideas/games/ghost-ippon-shobu-calc-spec.md` v1.3 に従い、**フラッシュ暗算ゲーム (ゴースト一本勝負・計算編)** を実装する。

既存の `scripts/games/flash_calc.gd` + `scenes/games/flash_calc.tscn` は「2 数演算 30 秒」の旧 v1.0 設計で、v1.3 仕様とは別物。本ステアリングでは v1.3 設計に沿って実質新規実装を行う（旧コードは置換・廃棄）。

## ゲーム概要 (v1.3)

- **コンセプト**: 「自分のレベルを自分で選び、過去の自分とフラッシュ暗算の一本勝負」
- **1 試合の流れ**: 予告 (1.5s) → 数字フラッシュ (4-5s) → 入力 + ゴースト CD (8-20s) → 判定 → 結果演出
- **核ギミック**: 入力中に減るゴーストカウントダウンバー
- **核データ**: 8 ティア (T1-T8) 独立のゴーストデータ + 段階的解放 (直近 5 回中 3 回正解で次ティア解放)

## MVP 実装範囲 (§11)

### 必須（このステアリングで実装）

- ホーム画面: ティア選択 UI（折りたたみ式）+ 適正ラベル + ベスト表示
- コアゲーム: フラッシュ暗算 1 試合（T1〜T8）
- 数字フラッシュ: 段階的速度カーブ（ウォームアップ→本番→追い込み）+ 桁数モード（1digit / mixed / 2digit）
- ゴースト CD バー: 残り時間表示・色変化・ゼロで脱落判定
- 入力 UI: 電卓配置テンキー（0-9 + ⌫ + 確定）、自動遷移（最大桁到達で自動確定）
- 判定: 6 段階（PERFECT / GREAT / WIN / DRAW / TIME_LOSE / WRONG）
- ゴースト Δt: ティア別初期値 + last_5_plays 中央値、緩和ロジック段階化
- 段階的解放: 直近 5 回中 3 回正解で T(N+1) 解放、解放演出表示
- 「練習仲間 → いつもの自分」切替演出（4 回目開始時）
- 生霊キャラクタ接続: ghost_character.tscn 流用、台詞は dialogue.json リソース化
- スコア算出: 反応時間 × 難度倍率 + 勝敗ボーナス
- 4 桁防止: 問題生成時のチェック

### スコープ外（v1.1 以降）

- 表情バリエーション、BGM 切替、結果演出強化
- 長期休止後のゴースト緩和
- ベスト更新を「勝利時のみ」に
- ティア別生霊の見た目変化
- そろばん表示モード、ライバルモード
- T9 / T10（3 桁加算）
- 効果音 13 種（簡易 SFX 3-4 種で代替、本格音響は別フェーズ）

## デザイン整合

- Midnight Cat 暗色テーマ（VoidBg + NebulaBg + StarLayer）
- 既存 ghost_battle_bar / ghost_character.tscn を最大限流用
- フォントは `docs/ui-design-guidelines.md` v2 規約準拠（本文 ≥ 24, ボタン ≥ 28 等）
- 横画面ベースで OrientationHelper.enter_landscape() を使用（ghost_7ban_shobu と同様の横画面ゲーム）。
  ※ 縦画面のままにする場合はテンキーが押しやすいレイアウトで再検討（design.md で決める）
- ルール説明 (rule_explain.tscn) は既存共通画面を流用、コンテンツのみ差し替え
- カウントダウン (countdown.tscn) は既存共通画面を流用

## 受け入れ条件

### ゲームプレイ
- [ ] T1〜T8 を全て選択してプレイできる（T2 以降はテスト用に初期解放しておいて OK、最終的にロックを有効化）
- [ ] 数字フラッシュが速度カーブに従って表示される
- [ ] ゴースト CD バーが減少し、ゼロで TIME_LOSE 判定
- [ ] テンキー入力で答えを送信、正解で WIN、不正解で WRONG
- [ ] 同タイ ±100ms 以内で DRAW、ゴースト Δt より早ければ WIN、遅ければ TIME_LOSE
- [ ] ベスト更新時に NEW BEST 表示
- [ ] 直近 5 回中 3 回正解で次ティア解放アナウンスが出る

### データ
- [ ] **新規 Autoload `FlashCalcGhostStore`** がティア別データ (last_5_plays + best_score + unlocked) を保存する（既存 ghost_data.gd は 7 ラウンド前提のため流用不可）
- [ ] ゴースト Δt がティアごとに独立して計算される
- [ ] PlayLog に試合結果が記録される（events: tier / flash_completed / answer_submitted / match_result）
- [ ] GameManager に `_current_tier` 状態と `on_tier_selected(tier)` フローが追加され、tier_select → rule_explain → countdown → play の遷移が動作する

### ゴースト生霊
- [ ] 初回〜3 回目: ghost_character mode = "duelist", 「練習仲間」呼称
- [ ] 4 回目開始時: 切替演出 → 「いつもの自分」呼称
- [ ] 試合後: ghost_character mode = "partner" に復帰

### UI/UX
- [ ] フォントが ui-design-guidelines.md v2 規約に準拠
- [ ] ホーム画面のティアセレクタが折りたたみ式（適正 ±1 ティアのみデフォルト表示）
- [ ] 解放演出が結果画面の後に出る（自動遷移）
- [ ] 「練習仲間→いつもの自分」演出が 4 回目開始時に出る

### 統合
- [ ] GameManager → flash_calc 遷移が動作
- [ ] flash_calc → individual_result 画面遷移で結果表示
- [ ] ホーム画面ゲーム一覧（game_list.tscn）のフラッシュ暗算カードから起動
- [ ] Android 実機デプロイで全フローが動作

## 参照

- 仕様書: `docs/ideas/games/ghost-ippon-shobu-calc-spec.md` v1.3（1255 行）
- GDD §4-1: `docs/ideas/brain_training_gdd.md`
- 既存実装参考: `scripts/games/ghost_7ban_shobu/ghost_7ban_shobu.gd`（横画面ゴーストバトルの先例）
- 共通シーン: `scenes/shared/ghost_battle_bar.tscn`, `scenes/ui/rule_explain_landscape.tscn`, `scenes/ui/countdown_landscape.tscn`
- ベース: `scripts/games/base_game.gd`
- データレイヤー: `scripts/autoload/data_store.gd`, `scripts/autoload/ghost_data.gd`
