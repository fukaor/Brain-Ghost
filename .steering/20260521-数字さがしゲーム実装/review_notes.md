# Review 対応ログ (v1.0 → v1.1)

Claude Code feature-dev:code-reviewer による事前レビュー結果を反映。

## 取り込み済み修正

| ID | 重要度 | 概要 | 修正内容 |
|---|---|---|---|
| C1 | 🔴 | tasklist T3-04 が `_implemented_games` を手動更新する誤った前提 | `game_list_controller._load_implemented_games()` は `GameManager.GAME_SCENES.keys()` から自動取得。T3-04 を「T3-02 (GAME_SCENES 追加) で自動反映されることを確認」に書き換え |
| M1 | 🟡 | `_on_finish()` の契約分担（ロジック側 vs GameManager 側）が design.md に明記されていない | design.md §4 にコメントを追加: `_on_finish()` は game_type だけ設定し、id / score / mode / played_at / is_new_best 等は GameManager.on_game_finished_handler が完成させる（sequence_memory パターン） |
| M2 | 🟡 | ベスト記録の取り扱い不明（タイム表示か、スコア表示か） | individual_result_controller.gd L121-129 で number_search は `compare_mode = "self_best"` を使用。「YOU スコア vs BEST スコア」で表示済み。プレイ画面の BestDisplay は **スコア表記** にする（spec の「ベスト 22秒」は v1.1 で個別対応） |
| M3 | 🟡 | `ghost_result` 設定責務が不明確 | MVP は `compare_mode = "self_best"` のため `ghost_result` は使わない。GhostData 連携は v1.1 で追加 |
| m1 | 🟢 | View `_process` での `_is_active` チェック | sequence_memory_view パターンに揃え、`_process` の冒頭で `_game._is_active` チェックを追加 |
| m2 | 🟢 | `timeout` event の value 単位コメント追記 | design.md §4 にコメント「value = 到達数字（秒ではない）」を追加 |

## design.md 追記事項

- §4 `_on_finish()` のコメント追加
- §7 View `_process` 冒頭の `_is_active` ガード明記
- §10 GhostData 連携は v1.1 (MVP は self_best モード)

## tasklist.md 追記事項

- T3-04 を「GAME_SCENES 追加で自動反映確認」に書き換え
- T3-05 を削除（BestDisplay はスコアで表示）
- T2-01-d のベスト表示形式を「`★ ベスト: N pts`」に変更

## 結論

修正反映後、実装フェーズへ進行可。
