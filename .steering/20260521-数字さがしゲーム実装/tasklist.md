# タスクリスト

## ステータス記号

- [ ] 未着手
- [-] 進行中
- [x] 完了

## Phase 1: 骨組み

- [x] T1-01 `scripts/games/number_search/tier_config.gd` 作成（TIER_CONFIGS 定数）
- [x] T1-02 `scripts/games/number_search/grid_generator.gd` 作成（Fisher-Yates シャッフル）
- [x] T1-03 `scripts/games/number_search/number_search.gd` 作成（BaseGame サブクラス）
- [x] T1-04 `scripts/ui/components/number_cell.gd` 作成（normal / found 状態管理）
- [x] T1-05 `scenes/games/number_search/number_cell.tscn` 作成（Button ベース、56dp 正方形）

## Phase 2: View 実装

- [x] T2-01 `scenes/games/number_search/number_search.tscn` 作成（MidnightCat レイアウト）
  - [x] T2-01-a SafeAreaMargin / MainColumn 階層
  - [x] T2-01-b 上部 HUD（NextNumberLabel + TimerLabel）
  - [x] T2-01-c GridCenter / GridContainer (columns=5)
  - [x] T2-01-d 下部 BestDisplay
- [x] T2-02 `scripts/ui/number_search_view.gd` 作成
  - [x] T2-02-a NumberSearch インスタンス化と signal 接続
  - [x] T2-02-b 25 セル動的生成 + GridContainer 配置
  - [x] T2-02-c タップ → handle_input("cell_tap")
  - [x] T2-02-d HUD 更新（次の数字 + 残り時間）
  - [x] T2-02-e 60 秒タイムアウト判定（_process）
  - [x] T2-02-f game_finished → GameManager.on_game_finished_handler 委譲

## Phase 3: スコア / GameManager / 一覧画面統合

- [x] T3-01 `scripts/core/score_system.gd` の number_search 分岐を残り時間比率式に改訂
- [x] T3-02 `scripts/autoload/game_manager.gd` の GAME_SCENES に number_search 追加
- [x] T3-03 `scripts/autoload/game_manager.gd` の `_build_play_data_for` に number_search 分岐追加 + ヘルパー（_extract_clear_time_sec / _extract_is_clear）
- [x] T3-04 `game_list_controller._load_implemented_games()` は `GameManager.GAME_SCENES.keys()` から自動取得するため、T3-02 の GAME_SCENES 追加で自動有効化されることを確認（手動編集不要）

## Phase 4: ルール説明 / カウントダウン統合

- [x] T4-01 `scenes/ui/rule_explain.tscn` のルール説明データに「数字さがし」分岐を追加（既存ゲームと同パターン）
- [x] T4-02 rule_explain_controller のプレビューに数字さがし用ミニグリッドを追加（任意・既存パターンに合わせ簡易表示でも可）

## Phase 5: 検証

- [x] T5-01 Godot エディタで scenes/games/number_search/number_search.tscn を開いてエラーゼロ
- [x] T5-02 GUT テスト（grid_generator のシード決定論性）— 任意
- [x] T5-03 PC 実機（プロジェクト実行）でクリアまでプレイ可能
- [x] T5-04 タイムアウト時の挙動確認（60 秒経過でスコア 0）
- [x] T5-05 個別結果画面に正しいタイム / スコアが表示される
- [x] T5-06 ゴースト平均との比較が表示される
- [x] T5-07 同日同シードで配置が同一になる（テスト用に DailySeed の固定再現）
- [x] T5-08 game_list から起動できる（_implemented_games 効果確認）

## 完了条件

- 上記すべてチェック済み
- ステアリングの requirements.md 受け入れ条件 1〜6 をすべて満たす
