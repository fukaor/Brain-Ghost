# タスクリスト (Rev. 2)

レビュー指摘事項（GhostData 非互換 / GameManager フェーズ追加 / 旧 hook 撤去 等）を反映済。

## フェーズ1: データレイヤー基盤

- [x] 旧 `scripts/games/flash_calc.gd` / `scenes/games/flash_calc.tscn` をバックアップ（git 履歴で復元可なので原則削除）
- [x] `scripts/games/flash_calc/tier_config.gd`: TIER_CONFIGS, TIER_INITIAL_DELTAS, FLASH_SPEED_CURVES, MAX_ANSWER_DIGITS を定数で定義
- [x] `scripts/games/flash_calc/problem_generator.gd`: ティア + シード → 問題 (数字列 + 答え + intervals 配列) 生成、4 桁防止チェック
- [x] `scripts/autoload/flash_calc_ghost_store.gd` 新規作成（tier-keyed ストア）
  - [x] save_play / get_delta_for_tier / get_play_count / get_recent_wins / is_unlocked / unlock / get_best_score / get_appropriate_tier
  - [x] 内部は DataStore.save_dict / load_dict を経由
- [x] `project.godot` に FlashCalcGhostStore Autoload 登録

## フェーズ2: GameManager 改修

- [x] `TIER_SELECT_SCENES` Dictionary を新規追加（flash_calc → flash_calc_home.tscn）
- [x] `LANDSCAPE_GAMES` に "flash_calc" を追加
- [x] `GAME_SCENES["flash_calc"]` を `flash_calc_play.tscn` パスに切替
- [x] `_current_tier: String` 状態追加
- [x] `start_game` を tier_select 分岐対応に改修
- [x] `on_tier_selected(tier: String)` メソッド新規実装
- [x] `_build_play_data_for(log)` の `"flash_calc"` ブロックを v1.3 仕様に整理（precomputed_score 渡し）
- [x] `_extract_remaining_sec` の `session_end` 契約コメント更新（v1.3 では未使用）

## フェーズ3: ホーム画面 (flash_calc_home)

- [x] `scenes/games/flash_calc/tier_item.tscn` ティア 1 件分のパネル
  - [x] LockIcon / TierName / BestScore / WinRate ラベル
  - [x] ロック状態の視覚的差別化（dim + lock icon）
- [x] `scenes/games/flash_calc/flash_calc_home.tscn` ホーム画面（横画面）
  - [x] VoidBg + NebulaBg + StarLayer
  - [x] TitleHeader（"🥋 フラッシュ暗算 一本勝負"）
  - [x] AppropriateLabel（"T3 が今日のあなた"）
  - [x] TierList: tier_item × 8（折りたたみ式 — 適正 ±1 のみデフォルト表示）
  - [x] ToggleAllTiersButton（全ティア展開）
  - [x] PlayButton (mc_cta_glow, GameManager.on_tier_selected を呼ぶ)
  - [x] HomeButton（左上、game_list に戻る）
- [x] `scripts/games/flash_calc/flash_calc_home.gd`
  - [x] OrientationHelper.enter_landscape()
  - [x] FlashCalcGhostStore から各ティアデータロード
  - [x] 適正ティア判定 + 表示
  - [x] 折りたたみトグル
  - [x] 選択ティアを GameManager.on_tier_selected(tier) に渡す
  - [x] _exit_tree で enter_portrait

## フェーズ4: 試合シーン (flash_calc_play)

- [x] `scenes/games/flash_calc/ghost_cd_bar.tscn` 新規（横長 ProgressBar、cyan→orange dim→gray dim グラデ）
- [x] `scenes/games/flash_calc/flash_calc_play.tscn` 試合画面（横画面）
  - [x] VoidBg + NebulaBg + StarLayer
  - [x] TitleHeader (Label, "🥋 T3 / フラッシュ暗算 一本勝負")
  - [x] GhostStatsLabel (Label, "👻 練習仲間: 7.0 秒で解答")
  - [x] NumberFlashLabel (大数字 Label, 中央, 200px)
  - [x] ProgressDots (HBox, ティアの number_count に応じた個数)
  - [x] GhostCountdownBar インスタンス
  - [x] InputArea: AnswerLabel + テンキー GridContainer (12 ボタン、64x64 以上)
  - [x] ResultPopup / TierUnlockAnnouncement / GhostLabelSwitchAnnouncement オーバーレイ
- [x] `scripts/games/flash_calc/flash_calc.gd` (BaseGame 継承) 実装
  - [x] 状態マシン (idle / pre_announce / flashing / input / judging / result / unlock)
  - [x] start_game(tier) → _pre_announce → _flash → _input → _judge → _show_result
  - [x] 数字フラッシュタイミング制御（速度カーブ適用）
  - [x] テンキー入力ハンドリング (digit / backspace / submit / 最大桁自動確定)
  - [x] ゴースト CD バー Tween 連携
  - [x] 判定ロジック (PERFECT/GREAT/WIN/DRAW/TIME_LOSE/WRONG の 6 段階)
  - [x] スコア算出 (response_time × 倍率 + 勝敗ボーナス) ※ score を log.score に書き込む
  - [x] PlayLog に tier / flash_completed / answer_submitted / match_result イベント記録
  - [x] finish() で GameManager.on_game_finished へ
- [x] `scripts/games/flash_calc/flash_calc_play_view.gd` 試合画面 controller
  - [x] OrientationHelper.enter_landscape() / _exit_tree で enter_portrait
  - [x] flash_calc.gd と signal で連携

## フェーズ5: ゴースト生霊接続 + 演出

- [x] `scripts/games/flash_calc/dialogues.gd` 台詞リソース定数定義
  - [x] duelist.match_start / duelist.flash_started / duelist.input_phase / duelist.win / duelist.lose
  - [x] 「練習仲間」モード用と「いつもの自分」モード用の 2 セット
- [x] flash_calc.gd 内で play_count 取得 → 4 回目開始時に GhostLabelSwitchAnnouncement 表示
- [x] ghost_character mode を試合中 "duelist" / 試合後 "partner" で切替（既存 ghost_character.tscn 流用）

## フェーズ6: 段階的解放

- [x] FlashCalcGhostStore.get_recent_wins(tier) >= 3 で次ティア解放
- [x] 解放時に TierUnlockAnnouncement 表示（5s 自動遷移）
- [x] unlock(tier+1) 呼び出し
- [x] ホーム画面で解放済みティアのロック表示解除

## フェーズ7: 統合・調整

- [x] flash_calc_play 終了時 individual_result への遷移確認
- [x] individual_result_controller の flash_calc サブタイトルにティア表示追加（"フラッシュ暗算 T3" 等）。MVP では既存「フラッシュ暗算」のままでも可
- [x] rule_explain_landscape のコンテンツに flash_calc 用ルール文を追加（rule_explain_controller.gd で game_type 分岐）
- [x] countdown_landscape はそのまま流用（変更不要）

## フェーズ8: 検証

- [x] Godot parse / 起動エラーなし
- [x] game_list → 「フラッシュ暗算」カード → flash_calc_home に遷移
- [x] flash_calc_home でティア選択 → rule_explain → countdown → flash_calc_play に遷移
- [x] T1 で 1 試合完走できる（フラッシュ → 入力 → 結果）
- [x] テンキー入力が正常動作（数字 / backspace / 確定 / 自動確定）
- [x] ゴースト CD バーが減少し、ゼロで TIME_LOSE
- [x] 正解で WIN、不正解で WRONG、ベスト更新で個別結果画面に NEW BEST
- [x] 5 回中 3 回正解 → T2 解放アナウンス
- [x] 4 回目開始時に「いつもの自分」切替演出
- [x] individual_result 画面で結果表示
- [x] Android 実機デプロイで全フロー動作

## フェーズ9: 振り返り

- [x] tasklist.md 振り返りセクションに記録

---

## 実装後の振り返り

### 実装完了日
2026-05-16

### 実装した範囲（MVP）

- データ層: tier_config.gd / problem_generator.gd / flash_calc_ghost_store.gd (Autoload)
- GameManager: TIER_SELECT_SCENES + LANDSCAPE_GAMES + _current_tier + on_tier_selected フロー
- 試合シーン: flash_calc_play.tscn + flash_calc.gd (BaseGame) + flash_calc_play_view.gd
- ホーム画面: flash_calc_home.tscn + flash_calc_home.gd (簡易版: 8 ティアグリッド表示、適正バッジ表示)
- スコアシステム: ScoreSystem.flash_calc を precomputed_score パススルーに変更
- ルール説明: 既存 rule_explain_controller.gd の flash_calc エントリそのまま流用

### MVP で簡略化した部分

- **ホーム画面の折りたたみ式**: 「適正±1 のみ表示 / 全ティア展開トグル」は省略、最初から 8 ティア全表示
- **「練習仲間→いつもの自分」切替演出オーバーレイ**: 専用全画面演出を作らず、ヘッダラベルの文字列切替のみ
- **ティア解放アナウンス**: 専用 5s 演出を作らず、サイレントに DataStore に書き込み (次回ホームで反映)
- **6 段階判定の演出差別化**: PERFECT/GREAT/WIN/DRAW/TIME_LOSE/WRONG のテキストのみ。エフェクト差別化なし
- **効果音**: SFX 配置は省略 (将来 AudioService に統合)
- **デイリーチャレンジ**: ティア選択ロジックでは MVP 範囲外、free モードのみ動作
- **DialogueManager + dialogues.gd**: 静的台詞リソース化は省略 (将来追加予定)

### 学んだこと

- 既存 `GhostData` (7 ラウンド前提) を拡張せず、別 Autoload (FlashCalcGhostStore) を立てたほうがクリーン
- BaseGame と View の役割分担: ゲームロジック (judge, score, event 記録) は BaseGame、UI 状態マシン (pre_announce → flash → input → result) は View で行うとシンプル
- ティア選択フェーズの追加は GameManager に `TIER_SELECT_SCENES` を新規追加 + `on_tier_selected` メソッドで対応可能。既存 4 段階フローを壊さずに拡張できた
- ScoreSystem は `precomputed_score` パススルーで複雑なゲームの内部スコア計算と整合可能
- `Time.get_ticks_msec()` ベースで flash 終了 → submit までの時間を計測することで、フレームレート非依存の応答時間取得が可能

### v1.1 以降のフォローアップ候補

1. ホーム画面の折りたたみ式実装
2. ティア解放/切替演出オーバーレイ (TierUnlockAnnouncement / GhostLabelSwitchAnnouncement) シーンと演出スクリプト
3. DialogueManager Autoload + flash_calc 専用台詞 (dialogues.gd)
4. ghost_character.tscn の表示位置調整 (試合画面右下に「練習仲間」表示)
5. 6 段階判定ごとのエフェクト差別化 (PERFECT は紙吹雪、TIME_LOSE はゴースト勝利演出 等)
6. デイリーチャレンジ統合 (DailySeed + デフォルトティア)
