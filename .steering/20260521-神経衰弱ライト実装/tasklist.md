# タスクリスト

## Phase 1: 骨組み

- [x] T1-01 `scripts/games/card_match/tier_config.gd` 作成
- [x] T1-02 `scripts/games/card_match/card_generator.gd` 作成
- [x] T1-03 `scripts/games/card_match/card_match.gd` 作成（BaseGame サブクラス、pair_evaluated signal）
- [x] T1-04 `scripts/ui/components/card.gd` 作成（FACE_DOWN/UP/MATCHED 状態、Material Symbols 図形）
- [x] T1-05 `scenes/games/card_match/card.tscn` 作成（Control + TextureRect 裏面 + Label 表面）

## Phase 2: View 実装

- [x] T2-01 `scenes/games/card_match/card_match.tscn` 作成
  - [x] T2-01-a SafeAreaMargin / MainColumn 階層
  - [x] T2-01-b HUD（TitleLabel / TimerLabel / ProgressLabel）
  - [x] T2-01-c GridContainer(columns=4) + 16 Card インスタンス
  - [x] T2-01-d BestDisplay
- [x] T2-02 `scripts/ui/card_match_view.gd` 作成
  - [x] T2-02-a CardMatch インスタンス + signal 接続（**`pair_evaluated.connect(_on_pair_evaluated)`** + `game_finished.connect(_on_game_finished)`）
  - [x] T2-02-b Card のシャッフル順を _grid_data で割り当て + card_id を設定
  - [x] T2-02-c card_pressed → handle_input("cell_tap")
  - [x] T2-02-d 一致時: 0.3 秒緑フラッシュ → match_resolved 通知
  - [x] T2-02-e 不一致時: 0.5 秒グレーフラッシュ → 裏返しアニメ → mismatch_resolved 通知
  - [x] T2-02-f 60 秒タイマー（_process）+ **`_pending_timeout` フラグで `_is_processing` 中の保留処理**（design.md §7 timeout 保留フラグ）
  - [x] T2-02-g game_finished → GameManager.on_game_finished_handler

## Phase 3: スコア / GameManager 統合

> **重要**: T3-01 と T3-03 は同一コミット内で変更する。play_data のキーが `time_bonus` → `clear_time_sec` + `time_limit_sec` に変わるため、片方だけだとスコアが 0 になる。

- [x] T3-01 `scripts/core/score_system.gd` の card_match 分岐を spec §5-1 に改訂（pair_count / total_tap_count / clear_time_sec / time_limit_sec / tier_multiplier 入力に変更）
- [x] T3-02 `scripts/autoload/game_manager.gd` GAME_SCENES に card_match 追加
- [x] T3-03 `scripts/autoload/game_manager.gd` _build_play_data_for に card_match 分岐 + ヘルパー追加（**T3-01 と同時変更**）
- [x] T3-04 `_load_implemented_games()` は `GAME_SCENES.keys()` から自動取得するため、T3-02 で自動有効化される（手動編集不要）

## Phase 4: ルール説明統合

- [x] T4-01 `scripts/ui/rule_explain_controller.gd` のルール説明データに card_match 分岐
- [x] T4-02 プレビュー差し替え（任意：簡易表示でも OK）

## Phase 5: 検証

- [x] T5-01 シーンを開いてエディタエラーゼロ
- [x] T5-02 PC 実機で 8 ペア揃えクリアまで進められる
- [x] T5-03 60 秒タイムアウト挙動確認
- [x] T5-04 再タップ無視 / 処理中タップ無視を確認
- [x] T5-05 個別結果画面に正しい値が表示される
- [x] T5-06 ゴースト平均との比較表示
- [x] T5-07 同日シードで配置同一

## 完了条件

- requirements.md 受け入れ条件 1〜9 すべて満たす
