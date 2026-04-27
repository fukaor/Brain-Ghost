# フラッシュ暗算実装 — Tasklist

## 🚨 タスク完全完了の原則
全タスク `[x]` 化必須。スキップは技術的理由のみ。

---

## 概要

GDD §4-1 のフラッシュ暗算 (計算力) を実装。あわせて GameManager の `on_reflex_tap_finished` を **ゲーム種別非依存版** にリファクタし、3 つ目以降のゲーム追加でテンプレ化できる状態にする。

## フェーズ A: GameManager ジェネリック化

- [x] A-01: `GAME_SCENES` Dictionary を GameManager に追加 (game_type → tscn パス、reflex_tap + flash_calc)
- [x] A-02: `start_game(game_type: String)` 汎用メソッドを追加
- [x] A-03: `start_reflex_tap("free")` を `start_game("reflex_tap")` を呼ぶ薄いラッパに改修 (後方互換維持)
- [x] A-04: `on_countdown_finished` を `_current_game_type` から GAME_SCENES 経由で動的解決
- [x] A-05: `on_reflex_tap_finished(log)` → `on_game_finished_handler(log)` に汎用化、`on_reflex_tap_finished` は薄いラッパで残置
- [x] A-06: reflex_tap_view.gd の呼び出し先を `on_game_finished_handler` に更新

## フェーズ B: FlashCalc ゲームロジック

- [x] B-01: `scripts/games/flash_calc.gd` 新規作成、`class_name FlashCalc extends BaseGame`
- [x] B-02: 定数定義 (TOTAL_PROBLEMS=12, NUMBERS_PER_PROBLEM=4, NUMBER_MIN=1, NUMBER_MAX=9, TIME_LIMIT_SEC=30)
- [x] B-03: 状態変数 (_problems, _expected_sums, _current_index, _correct_count)
- [x] B-04: `_on_setup` 実装 (game_type, is_time_based=true, **全問題を事前生成して決定論的に**)
- [x] B-05: `_on_user_input` 実装 (`{type: "submit", answer}` / `{type: "timeout"}` を分岐)
- [x] B-06: ~~`generate_problem(rng)` 静的ヘルパー~~ (setup 内でループで生成、ヘルパー化不要と判断)
- [x] B-07: `get_current_problem_text()` public (例: `"3 + 5 + 2 + 7"`)
- [x] B-08: `get_current_expected()` public (テスト用)
- [x] B-09: `get_correct_count() / get_current_index() / get_total_problems()` public
- [x] B-10: `get_remaining_sec()` public (TIME_LIMIT_SEC - elapsed_sec、min 0)
- [x] B-11: `_on_finish` で PlayLog を返す (score は GameManager 側で計算、session_end イベントに remaining_sec 値を入れる)
- [x] B-12 (追加): `_handle_submit` private で正誤判定 + 次問題進行 + 全問完了で finish
- [x] B-13 (追加): `_record_session_end` で remaining_sec を session_end イベントとして記録 (GameManager 側で読み取る契約)

## フェーズ C: ユニットテスト

- [x] C-01: `tests/unit/games/test_flash_calc.gd` 新規作成
- [x] C-02: `test_setup_initializes_state` — 初期状態
- [x] C-03: `test_deterministic_problems` — 同じ seed で同じ問題列 + 期待値が一致
- [x] C-04: `test_problem_count_equals_total` — TOTAL_PROBLEMS 個生成
- [x] C-05: `test_each_problem_has_correct_number_count` — 4 数字
- [x] C-06: `test_each_number_in_range` — 1-9 の範囲
- [x] C-07: `test_expected_sum_matches_numbers` — 期待値 = 合計
- [x] C-08: `test_correct_input_increments_count` — 正答で count +1、index +1
- [x] C-09: `test_wrong_input_no_increment_but_advances` — 誤答で count 不変、index +1
- [x] C-10: `test_complete_all_correct_finishes` — 全問完了で finish (game_finished シグナル)。GDScript ラムダの値キャプチャ問題で Array でラップが必要だった
- [x] C-11: `test_problem_text_format` — テキスト形式 "X + X + X + X" の検証
- [x] C-12: `before_each` で `setup → start` を必須化 (BaseGame.handle_input が `_is_active` チェックがあるため)
- [x] C-13: 全 10 テスト + 既存 67 = **77/77 passed**, 1124 asserts, 0.967s

## フェーズ D: シーン (flash_calc.tscn + view)

- [x] D-01: `scripts/ui/flash_calc_view.gd` 新規作成
- [x] D-02: HUD 3 ピル (進捗 / 残り時間 / 正答数) 構成
- [x] D-03: ProblemLabel (hero_big variation) で式 "8 + 4 + 5 + 7 = ?" を表示
- [x] D-04: NumPad (GridContainer columns=3, 12 ボタン: 1-9, C, 0, OK)
- [x] D-05: 各ボタンの pressed シグナルを `_wire_numpad()` で動的に接続
- [x] D-06: クリアボタン (C) で _current_input をリセット
- [x] D-07: 提出ボタン (OK) で `_game.handle_input({"type": "submit", "answer": int(_current_input)})`
- [x] D-08: 入力中表示 (InputLabel display variation)
- [x] D-09: TimeoutTimer (30 秒) で `{"type": "timeout"}` を発火
- [x] D-10: HUD の経過時間 _process で更新
- [x] D-11: `_on_game_finished` → GameManager.on_game_finished_handler 呼び出し
- [x] D-12: `scenes/games/flash_calc.tscn` 新規作成、ボイラープレート準拠

## フェーズ E: ScoreSystem 統合

- [x] E-01: GameManager の `_build_play_data_for(log)` 実装、game_type で分岐 (reflex_tap → average_reaction_ms / flash_calc → correct_count + remaining_sec)
- [x] E-02: PlayLog の events に "correct" / "wrong" / "session_end" イベントを記録する契約
- [x] E-03: GameManager の `_count_events_of_type(log, type)` ヘルパー (events から特定タイプの数を集計)
- [x] E-04: GameManager の `_extract_remaining_sec(log)` ヘルパー (session_end イベントの value から取得)
- [x] E-05: 既存の `_compute_avg_reaction_ms` は reflex_tap 用としてそのまま残置

## フェーズ F: ルール説明への登録

- [x] F-01: `scripts/ui/rule_explain_controller.gd` の RULES に "flash_calc" を追加
- [x] F-02: タイトル "フラッシュ暗算"、ダイアログ「計算式が次々出てくるよ。\n答えをテンキーで入力して OK を押してね。\n30 秒で何問解けるかな？」

## フェーズ G: ホームから起動

- [x] G-01: home_controller の StartButton から `GameManager.start_game("reflex_tap")` (汎用 API に切替)
- [x] G-01b: 「全ゲーム」アクションカード (AllGamesCard) に `gui_input` シグナルを wire し、左クリックで `start_game("flash_calc")` を呼ぶ暫定実装
- [x] G-02: ホームから両ゲーム (reflex_tap / flash_calc) を起動可能に。proper なゲーム選択画面は後続タスクで

## フェーズ H: 検証

- [x] H-01: `godot --headless --quit` exit=0
- [x] H-02: GUT フル → **77/77 passed** (既存 67 + 新規 10), 1124 asserts, 0.967s
- [x] H-03: 静的チェック (生 hex 0、絶対配置 0、modulate 違反 0、OS.get_name 0)
- [x] H-04: xvfb で flash_calc.tscn のスクショ取得 (`flash_calc.png`)
- [x] H-05: スクショで HUD + 式 + NumPad のレイアウト確認 (中央余白あるが許容範囲)

## フェーズ I: ドキュメント反映

- [x] I-01: `docs/repository-structure.md` の `scripts/ui/` ツリーに `flash_calc_view.gd` 追加
- [x] ~~I-02: patterns.md §9 写経チェックリストの更新~~ (既存内容で十分、新たに気づいた知見は次タスクで追記予定)

## フェーズ J: 振り返り

- [x] J-01: 振り返り記入

---

## 実装後の振り返り

### 実装完了日

2026-04-11 (DataStore 永続化の直後、同日完了)

### 実施結果サマリ

- **新規ファイル**: 4
  - `scripts/games/flash_calc.gd` (`class_name FlashCalc`、~120 行)
  - `scripts/ui/flash_calc_view.gd` (~95 行)
  - `scenes/games/flash_calc.tscn` (HUD 3 ピル + 問題表示 + 12 ボタンテンキー)
  - `tests/unit/games/test_flash_calc.gd` (10 テスト)
- **編集ファイル**: 4
  - `scripts/autoload/game_manager.gd` (ジェネリック化: GAME_SCENES, start_game, on_game_finished_handler, _build_play_data_for, _count_events_of_type, _extract_remaining_sec)
  - `scripts/ui/reflex_tap_view.gd` (on_game_finished_handler に切替)
  - `scripts/ui/rule_explain_controller.gd` (RULES に flash_calc 追加)
  - `scripts/ui/home_controller.gd` (start_game 経由 + AllGamesCard を flash_calc 起動に)
  - `docs/repository-structure.md` (flash_calc_view.gd 追加)
- **テスト結果**: 7 scripts / 77 tests / 1124 asserts / 0.967s / All passed

### 計画と実績の差分

**計画と異なった点**:
1. **GDScript ラムダ値キャプチャ問題** — `test_complete_all_correct_finishes` で `var finished := false; lambda { finished = true }` が動かず、Array `[false]` でラップして対応
2. **BaseGame.handle_input の `_is_active` ガード** — テストの before_each で setup() 後に start() を呼ばないと `handle_input` が無視される。最初テストで気付かず 3 失敗。後で修正
3. **AllGamesCard の gui_input 接続** — Button ではなく PanelContainer なので gui_input シグナルで InputEventMouseButton をハンドリング。proper には Button 化したいが暫定対応
4. **ジェネリック化の範囲** — 当初は flash_calc 専用の `start_flash_calc` / `on_flash_calc_finished` を作る計画だったが、3 つ目以降のゲーム追加を見越して `start_game(game_type)` / `on_game_finished_handler(log)` の汎用版にリファクタした。リファクタの方が結果的にコード量も少ない

**新たに必要になったタスク**:
- B-12: `_handle_submit` private (当初は `_on_user_input` 内に直接書く想定)
- B-13: `_record_session_end` (events に remaining_sec を載せる契約を追加)
- C-12: `before_each` で start() を呼ぶ修正 (テスト失敗から気付いた)

**技術的理由でスキップしたタスク**:
- I-02 patterns.md §9 更新 (既存内容で十分カバーしているため)

### 学んだこと

1. **GDScript ラムダの値キャプチャ** — Python と違って lambda 内から外部変数に書き戻せない。Array や class member でラップする必要あり
2. **BaseGame.handle_input の `_is_active` ガードはテストでも有効** — テストで直接 handle_input を呼ぶときも setup → start を実施する必要がある。これは reflex_tap テストでは pick_target_size を直接呼んでいたため気付かなかった
3. **GameManager のジェネリック化が想定以上に効いた** — `start_game(type)` + `on_game_finished_handler(log)` + `_build_play_data_for(log)` + GAME_SCENES の 4 セットで、新ゲーム追加時の touchpoint が劇的に減った。次以降のゲーム実装は本当に「ロジック + シーン + RULES + GAME_SCENES の 1 行」だけで済む
4. **PanelContainer.gui_input + InputEventMouseButton** — Button にしなくても Control 派生なら入力を受けられる。ただし mouse_filter のデフォルト (STOP) が必要
5. **events の "session_end" 契約** — flash_calc は時間ベースなので、最終的な remaining_sec を events に "session_end" として記録 → GameManager 側が `_extract_remaining_sec(log)` で読み取る、という分離設計。これは他の時間ベースゲームでも使えるパターン

### 次回への改善提案

1. **Proper なゲーム選択画面** — AllGamesCard の gui_input 暫定対応は最初の 2-3 ゲームで限界。3 ゲーム追加したら `scenes/ui/all_games.tscn` を作って 6 種選択画面にする
2. **`start_game` の戻り値** — 現在は void だが、エラー時に false を返す設計の方が呼び出し側で扱いやすい
3. **テンプレからの新ゲーム generator スクリプト** — 反射タップ + フラッシュ暗算で 2 ゲーム実装したので、「`scripts_build/scaffold_game.sh <game_name>`」のような bash スクリプトでひな形を生成する案
4. **flash_calc のレイアウト調整** — 中央の余白がやや大きい。問題表示エリアにアイコンや装飾を入れて埋めると良い (アセット調達後)

### 次のステアリング候補

1. **`20260415-third-game-implementation`** ⭐ daily challenge 解放のため 3 ゲーム目が必要 (number_search が決定論実装しやすい)
2. **`20260416-daily-challenge-flow`** — 3 種連続プレイ + 総合結果画面
3. **`20260417-game-selection-screen`** — AllGamesCard 暫定対応の解消、6 種選択画面
4. **`20260418-onboarding-flow`** — 初回オンボーディング (6 種順次プレイ)
5. **`20260419-ghost-system-averaging`** — GhostSystem の compute_ghost 本実装
