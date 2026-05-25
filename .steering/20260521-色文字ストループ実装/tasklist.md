# タスクリスト（v1.1 / Rev 反映）

## Phase 1: 骨組み

- [x] T1-01 `scripts/games/stroop/tier_config.gd` 作成（TIER_CONFIGS = T1〜T3、initial_ghost 含む）
- [x] T1-02 `scripts/games/stroop/stimulus_generator.gd` 作成
  - [x] T1-02-a `generate_pool(seed) -> Array` ティア非依存コア属性プール（40 問）
  - [x] T1-02-b `select_for_tier(pool, tier) -> Array` ティア別比率フィルタリング
- [x] T1-03 `scripts/games/stroop/stroop.gd` 作成
  - [x] T1-03-a BaseGame サブクラス、`is_time_based = true`
  - [x] T1-03-b `_resolve_tier()` で GameManager._current_tier を読み（MVP は T1 固定）
  - [x] T1-03-c `_on_finish()` で `log.score = max(0, net) * tier_mult` を完成（flash_calc パターン）
- [x] T1-04 `scripts/ui/components/answer_button.gd` 作成（4 色 + 形状アイコン）
- [x] T1-05 `scenes/games/stroop/answer_button.tscn` 作成

## Phase 2: View 実装

- [x] T2-01 `scenes/games/stroop/stroop.tscn` 作成
  - [x] T2-01-a SafeAreaMargin / MainColumn 階層
  - [x] T2-01-b 上部 Header（TitleLabel + TimerLabel）
  - [x] T2-01-c Ghost セクション（PlayerBar + GhostBar、max_value=20）
  - [x] T2-01-d StimulusContainer（StimulusLabel + ShapeContainer/ShapePanel + InnerLabel）
  - [x] T2-01-e Footer（AnswerButtons HBoxContainer + ScoreLabel + BestLabel）
- [x] T2-02 `scripts/ui/stroop_view.gd` 作成
  - [x] T2-02-a Stroop インスタンス化 + game_finished signal 接続
  - [x] T2-02-b `_ready()` で `_ghost_target` をティアから読み、PlayerBar/GhostBar の max_value を 20 固定で設定
  - [x] T2-02-c 刺激表示（Congruent / Incongruent / Shape）と `_render_shape()` 実装
  - [x] T2-02-d 4 色ボタンと押下ハンドラ（色 → handle_input("answer")）
  - [x] T2-02-e 正誤フィードバック（緑/グレーフラッシュ 0.1 秒、赤禁止）
  - [x] T2-02-f 3 秒応答タイムアウト Timer（answer_timer.timeout → "answer_timeout"）
  - [x] T2-02-g 30 秒ゲームタイマー（`_process`）+ **close-race 対策**: time_over 発火直後に `answer_timer.stop()` / `_present_current` 冒頭に `_is_active` ガード
  - [x] T2-02-h ゴーストバー線形追従（`_update_ghost_bar`）
  - [x] T2-02-i T3 のボタン 3 問ごとシャッフル（_shuffle_answer_buttons）
  - [x] T2-02-j game_finished → GameManager.on_game_finished_handler

## Phase 3: GameManager / ScoreSystem 統合 + rule_explain（前倒し）

- [x] T3-01 `scripts/core/score_system.gd` の stroop 分岐を **precomputed_score パススルー**に変更（既存式は廃止）
- [x] T3-02 `scripts/autoload/game_manager.gd` GAME_SCENES に stroop 追加
- [x] T3-03 `scripts/autoload/game_manager.gd` `_build_play_data_for` の stroop 分岐を `{"precomputed_score": int(log.score)}` に簡素化（**T3-01 と同時変更**）
- [x] T3-04 `_load_implemented_games()` は GAME_SCENES.keys() から自動取得（手動編集不要を確認）
- [x] T3-05 `scripts/ui/game_list_controller.gd` GAME_CARDS の stroop エントリの `name` を「色文字テスト」→「**色文字ストループ**」に変更
- [x] T3-06 `scripts/ui/rule_explain_controller.gd` の RULES Dictionary に stroop エントリを追加（Phase 4 から前倒し）

## Phase 4: 動作確認

- [x] T4-01 シーン開いてエディタエラーゼロ
- [x] T4-02 PC 実機で 30 秒プレイ完走
- [x] T4-03 正解 / 誤答カウンタ正常
- [x] T4-04 3 秒応答タイムアウト処理確認
- [x] T4-05 30 秒ぴったりに回答した場合の close-race 確認（二重 finish が起きないこと）
- [x] T4-06 ゴーストバー線形追従確認
- [x] T4-07 結果画面で score / 自己ベスト比較が表示される
- [x] T4-08 同日シードで刺激プールが同一（決定論性）
- [x] T4-09 Shape 刺激（T1 では出現しないが、コード上は通る経路）の単体動作確認 — 任意（v1.1 T3 解放時）

## 完了条件

- requirements.md 受け入れ条件 1〜8 すべて満たす
- T2-02-g の close-race 対策が手作業テストで確認できる
