# 要求内容 — 反射タップ (Reflex Tap) 実装

## 概要

Week 1 の本丸である **反射タップゲーム (GDD §4-4 / PRD FR-01)** を本実装する。あわせて、これまで整備してきたアーキテクチャ全層（BaseGame / ScoreSystem / PlayLog / GhostCharacter / Theme / Material Symbols）が実際のゲームフローで統合動作することを検証する最初のケーススタディとする。

## 背景

- UI 基盤ステアリング (`20260411-mobile-ui-foundation`) でデザインシステム・ゴースト生霊キャラクタ・ホーム画面を整備完了
- GUT セットアップステアリング (`20260411-gut-plugin-setup`) でユニットテスト環境を整備完了
- 環境構築ステアリング (`20260410-環境構築`) で BaseGame / ScoreSystem / PlayLog など基盤クラスを整備完了
- 実際のゲームは 1 本も実装されていない状態（プレースホルダのみ）
- 反射タップはロジックが最もシンプル（ランダム位置 + タップタイミング計測）で、**アーキテクチャの統合検証** に最適
- 6 ゲームの中で最初に実装することで、残り 5 ゲームの実装テンプレートを確立する
- ゴースト生霊キャラクタ (FR-14) を **ゲームフロー全体で使う最初のケーススタディ** でもある

## 実装対象の機能

### 1. 反射タップゲームロジック (`scripts/games/reflex_tap.gd`)

- `BaseGame` を継承した本実装
- **ターゲット**: 画面内のランダム位置に円形ターゲットが出現。タップされたら次のターゲットへ
- **セッション長**: 合計 20 回タップで終了 (GDD §4-4)
- **決定論**: `BaseGame.rng` を使用し、`Array.shuffle()` は絶対に使わない
- **パラメトリック要素** (GDD §4-4):
  - 出現位置 (画面マージンを考慮)
  - ターゲットサイズ (80-120px の範囲)
  - 次ターゲットまでの待機時間 (400-1200ms の範囲)
  - **フェイクターゲット** (別色で出現、タップするとペナルティ。3-5 回に 1 回混入)
- **記録するイベント** (`PlayEvent` 経由):
  - `"target_shown"` — ターゲット表示時刻
  - `"target_tapped"` — ターゲットタップ時刻 (value に反応時間 ms)
  - `"fake_tapped"` — フェイクタップ (ペナルティ)
- **スコア計算**: 既存の `ScoreSystem.calculate_score("reflex_tap", {"average_reaction_ms": X})` を呼ぶ
- **average_reaction_ms の算出**: 正規タップ 20 回の反応時間平均。フェイクタップは平均に含めず、代わりに平均値を +50ms する簡易ペナルティ方式

### 2. 反射タップシーン (`scenes/games/reflex_tap.tscn`)

- 上部 HUD: 残りタップ数 (`X / 20`) + 経過時間 + スコアサマリ
- 中央: タップエリア（画面全体が有効、ターゲットは TextureRect または ColorRect で動的配置）
- 下部: `Platform.supports_admob()` 時のみ広告バナー枠 (home.tscn と同パターン)
- ターゲットは `Control` ノードを動的生成し `pressed` シグナルで反応時間を記録

### 3. ルール説明画面 (`scenes/ui/rule_explain.tscn` + `rule_explain_controller.gd`)

- **ゴーストキャラクタ** が登場し、吹き出しで反射タップのルールを説明
- 見出し: "反射タップ"
- 説明文 (ゴーストのセリフ): "ランダムに出てくる丸をできるだけ速くタップしてね。20 回の平均時間でスコアが決まるよ。違う色の偽物はタップしちゃダメ！"
- CTA: `[スタート]` ボタン
- `UserConfig.onboardingCompleted == true` の場合は `[スキップ]` ボタンを表示 (PRD FR-07 準拠)
- データドリブン設計: 各ゲームでルール文字列を差し替えられるように `Dictionary` で管理

### 4. カウントダウン画面 (`scenes/ui/countdown.tscn` + `countdown_controller.gd`)

- 3-2-1 のカウントダウンアニメーション
- **ゴーストキャラクタ** が登場し、段階的にセリフ更新: "3..." → "2..." → "1..." → "いくよ！"
- 1 秒ごとに数字が大きく表示されて縮小する演出 (display フォント 64pt 基準)
- カウント完了で自動的にゲーム画面へ遷移

### 5. 個別結果画面 (`scenes/ui/individual_result.tscn` + `individual_result_controller.gd`)

- スコア大表示 (display フォント 64pt)
- 前回比 (+X / -X 点)
- 平均反応時間表示 ("平均 318 ms")
- ベスト更新演出 (更新時は ⭐ Material Symbol + "ベスト更新！" 表示)
- **ゴーストキャラクタ** が結果に応じたセリフ:
  - ベスト更新: "ベスト更新！今日のきみはすごい！"
  - 前回比プラス: "前より早くなってる！"
  - 前回比マイナス: "惜しい！でも確実に良くなってるよ"
  - 初回: "お疲れさま！これがきみの初めての記録だよ"
- CTA 2 つ: `[もう一度]` / `[ホームへ]`
- **ゴースト対戦結果はこの段階では表示しない** (ゴースト蓄積 5 回未満のため、GhostSystem の判定結果 "not_ready" をゴーストのセリフで扱う)

### 6. GameManager の反射タップフロー (`scripts/autoload/game_manager.gd`)

- `start_reflex_tap(mode: String)` — モードは `"free"` / `"onboarding"` / `"daily"` を受け付ける
- シーン遷移: home → rule_explain → countdown → reflex_tap → individual_result → home
- 状態保持: 現在のゲーム、スコア、PlayLog を session scope で保持
- `PlayLog` を DataStore に保存 (既存 DataStore スタブを利用、save に失敗しても警告のみでフロー継続)
- `GameBest` との比較で `is_new_best` を判定

### 7. ホーム画面からの起動 (`scripts/ui/home_controller.gd`)

- `StartButton.pressed` で `GameManager.start_reflex_tap("free")` を呼ぶ
- 既存の TODO コメント `# TODO: 次ステアリングで GameManager.start_daily_challenge() を呼ぶ` を削除
- **注**: MVP 段階ではデイリーチャレンジ (3 種) ではなく単体反射タップから起動する。デイリーは次タスクで実装

### 8. ユニットテスト (`tests/unit/games/test_reflex_tap.gd`)

- GUT テスト新規ファイル。テスト対象:
  - **決定論性**: 同じ seed で同じターゲット列が生成される
  - **ターゲット生成**: 位置が画面マージン内に収まる、サイズが範囲内
  - **平均反応時間の算出**: `PlayEvent` の `"target_tapped"` 値から正しく算出
  - **フェイクペナルティ**: フェイクタップが含まれると平均が +50ms される
  - **エッジケース**: 0 回タップ (score=0)、20 回タップ完了 (正常終了)
  - **PlayLog 形式**: 終了時に返される PlayLog の必須フィールドが全て埋まっている

## 受け入れ条件

### 1. 反射タップゲームロジック

- [ ] `scripts/games/reflex_tap.gd` が BaseGame を継承している
- [ ] 20 回タップで自動終了する
- [ ] ターゲット位置・サイズ・間隔がランダム（シード付きで決定論的）
- [ ] フェイクターゲットが 3-5 回に 1 回出現する
- [ ] フェイクをタップするとペナルティ（平均 +50ms）
- [ ] `PlayEvent` に正しい形式で記録される（target_shown, target_tapped, fake_tapped）
- [ ] `Array.shuffle()` を使っていない

### 2. シーンとUI

- [ ] `scenes/games/reflex_tap.tscn` が縦 720×1280 で崩れない
- [ ] 上部 HUD に残りタップ数と経過時間を表示
- [ ] ターゲットがタップ対象として 44pt 以上のサイズ
- [ ] すべての色が ColorPaletteUtil / Theme 経由
- [ ] 生 hex 0 件、絶対配置 0 件
- [ ] Material Symbols アイコンを使用（`play_arrow`, `replay`, `home` など）

### 3. ルール説明画面

- [ ] `scenes/ui/rule_explain.tscn` が存在する
- [ ] ゴーストキャラがルールを吹き出しで説明
- [ ] `[スタート]` ボタンで countdown へ遷移
- [ ] `UserConfig.onboardingCompleted == true` で `[スキップ]` ボタンが出る
- [ ] ルール文字列を `Dictionary` で他ゲームに差し替え可能な設計

### 4. カウントダウン画面

- [ ] `scenes/ui/countdown.tscn` が存在する
- [ ] 3-2-1 のカウントダウンが 1 秒ごとに進む
- [ ] ゴーストのセリフが段階的に更新される
- [ ] カウント完了で自動的にゲーム画面へ遷移

### 5. 個別結果画面

- [ ] `scenes/ui/individual_result.tscn` が存在する
- [ ] スコアが display フォント (64pt) で大表示
- [ ] 前回比・平均反応時間を表示
- [ ] ベスト更新時は特別演出（⭐ + "ベスト更新！"）
- [ ] ゴーストが結果に応じた 4 パターンのセリフを喋る
- [ ] `[もう一度]` / `[ホームへ]` の 2 つの CTA

### 6. GameManager フロー

- [ ] `GameManager.start_reflex_tap("free")` でフロー開始
- [ ] home → rule_explain → countdown → reflex_tap → individual_result → home の遷移が動く
- [ ] PlayLog が DataStore に保存される（スタブでも保存呼び出しが成功）
- [ ] GameBest との比較で is_new_best が判定される

### 7. ホーム画面からの起動

- [ ] `StartButton` タップで反射タップフローが開始
- [ ] 既存の TODO コメントが削除されている
- [ ] ゴーストのセリフが "今日もチャレンジする？" から "よーし！一緒にがんばろう！" などへ更新

### 8. ユニットテスト

- [ ] `tests/unit/games/test_reflex_tap.gd` が GUT で実行される
- [ ] 決定論性テスト (同じ seed で同じ結果)
- [ ] ターゲット生成範囲テスト
- [ ] 平均反応時間算出テスト
- [ ] フェイクペナルティテスト
- [ ] エッジケーステスト (0 回・20 回)
- [ ] 既存 GUT 45 テストはリグレッション 0 で全パス

### 9. 静的チェック

- [ ] `godot --headless --quit` exit=0、Parse Error なし
- [ ] 生 hex 検出 grep 0 件
- [ ] 絶対配置 offset の直書き 0 件（anchor 由来は許容）
- [ ] `modulate` の違反 0 件（ゴーストの alpha 例外のみ）
- [ ] `OS.get_name()` の直接呼び出し 0 件（Platform Autoload 経由のみ）

### 10. 実機検証

- [ ] xvfb で 4 画面分のスクショ取得:
  - home（StartButton 更新済み）
  - rule_explain（ゴースト + ルール）
  - reflex_tap（プレイ中のターゲット表示）
  - individual_result（結果 + ゴーストのセリフ）
- [ ] スクショがユーザ承認を得る

## 成功指標

**定量**:
- GUT 既存 45 + 新規 10 以上 = 合計 55+ テストすべてパス
- 生 hex 0 件、絶対配置 0 件、modulate 違反 0 件 (ゴースト例外除く)
- `godot --headless --quit` exit=0
- 同じシードで 3 回実行した平均反応時間が完全一致（決定論的）

**定性**:
- ユーザがスクショを見て「反射タップが楽しそう」「ゴーストの掛け合いが自然」と感じる
- 反射タップの実装パターンを patterns.md や次ゲーム実装に流用できる状態になっている
- Brain Boost の MVP 完成度が 10% → 30% に進む（主観目安）

## スコープ外

以下はこのフェーズでは実装しない:

- **他 5 ミニゲーム**（フラッシュ暗算・数字さがし・ストループ・順番記憶・神経衰弱ライト）
- **ゴーストバー表示**（PlayLog 5 回未満ではデータ不成立のため不要）
- **ゴースト対戦の本格判定**（`GhostSystem.judge_result` は既存スタブのまま）
- **ゴースト対戦 "あと◯回" メッセージの本実装**（メッセージは個別結果画面に 1 行出すのみ）
- **総合結果画面**（3 種連続プレイは次タスク）
- **デイリーチャレンジ統合**（3 種選出、日付シード起動は次タスク）
- **シェア URL 生成**
- **広告の実表示**（枠のみ）
- **買い切り課金フロー**
- **オンボーディング画面**（次タスク以降、反射タップ画面を 1 つめのゲームとして組み込む）
- **ゴースト生霊キャラの脳年齢・ストリーク反映**（v1.1 扱い）
- **アニメーション演出の精緻化**（最低限の機能のみ）
- **サウンド・BGM**（AudioService は既存、呼び出しは追加するがアセットなし）

## 参照ドキュメント

- `docs/ideas/brain_training_gdd.md` §4-4（反射タップ設計）、§5e（ゴースト生霊キャラクタ）、§6（スコアリング）
- `docs/product-requirements.md` FR-01（ミニゲーム）、FR-02（ゴースト対戦）、FR-07（日常フロー）、FR-14（ゴースト生霊）
- `docs/functional-design.md`
  - コンポーネント設計 > `core/ScoreSystem`, `games/BaseGame`, `ui/GhostCharacter`
  - アルゴリズム設計 > A-01 反射タップのスコア算出
- `docs/design/manifest.md`（色・タイポ・余白・禁則）
- `docs/design/patterns.md`
  - §1 画面ルートボイラープレート
  - §3 Theme variation 使い分け表
  - §5 GhostCharacter の使い方
  - §7 modulate の正当な例外条件
- `memory/project_ghost_character.md`（ゴースト生霊システムの仕様）
- `memory/project_app_name.md`（ブレインゴースト命名規約）
- `memory/feedback_ui_density.md`（情報密度目標）
- `memory/feedback_icons_not_text.md`（アイコン優先原則）
- 既存実装:
  - `scripts/games/base_game.gd`（継承元）
  - `scripts/core/score_system.gd`（スコア算出）
  - `scripts/core/ghost_system.gd`（判定枠組みのみ）
  - `scripts/models/play_log.gd`, `play_event.gd`（データモデル）
  - `scripts/ui/ghost_character.gd`（再利用コンポーネント）
- 既存テスト:
  - `tests/unit/core/test_score_system.gd`（反射タップ境界テスト 3 件が既にパス）
