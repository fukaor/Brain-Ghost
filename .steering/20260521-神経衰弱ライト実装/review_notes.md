# Review 対応ログ (v1.0 → v1.1)

Claude Code feature-dev:code-reviewer による事前レビュー結果を反映。

## 取り込み済み修正

| ID | 重要度 | 概要 | 修正内容 |
|---|---|---|---|
| C1 | 🔴 | `_is_processing == true` 時の timeout 保留が実装計画にない | View 側に `_pending_timeout` フラグを実装。`_pair_evaluated` 処理完了時に `if _pending_timeout: _game.timeout()` を発火。design.md §7 と tasklist T2-02-f に明示追記 |
| C2 | 🔴 | GameManager の `_build_play_data_for` に card_match 分岐が無い | 既に design.md §9 で記述済み。tasklist T3-03 を明示化 |
| C3 | 🔴 | ScoreSystem 改訂と GameManager play_data の同時変更必須 | tasklist T3-01 と T3-03 を**同一コミット内**で変更する依存関係を明示。design.md §8 に「play_data キーの変化（time_bonus 廃止 / clear_time_sec / time_limit_sec 追加）」を確定記載 |
| M1 | 🟡 | `_on_finish()` 契約分担の明文化 | design.md §4 にコメント追加（数字さがし同様） |
| M2 | 🟡 | `_implemented_games` 自動反映 | tasklist T3-04 を「自動反映確認」に書き換え |
| M3 | 🟡 | `pair_evaluated` signal の接続が tasklist に欠落 | T2-02-a に「`pair_evaluated.connect(_on_pair_evaluated)`」明示 |
| m1 | 🟢 | カードサイズ 72dp / 64dp の食い違い | **72dp タップ領域 = カード本体 + 余白で 72dp 確保。カード本体 64dp + 内側 padding 4dp**。spec 表と統一。design.md §10 を訂正 |
| m2 | 🟢 | ゴースト初回値 800pts の設定 | MVP は GhostData 連携不要（individual_result の compare_mode = "self_best"）。v1.1 で対応 |

## design.md 追記事項

- §4 `_on_finish()` のコメント追加
- §7 View `_pending_timeout` フラグ実装
- §8 ScoreSystem play_data キー一覧の確定
- §10 カードサイズ 72dp ↔ 64dp の整理
- 新 §13: GhostData は MVP 対象外（self_best 比較）

## tasklist.md 追記事項

- T2-02-a に `pair_evaluated` signal 接続を明示
- T2-02-f に `_pending_timeout` 実装を追加
- T3-01 と T3-03 の同時変更必須を明示
- T3-04 を「自動反映確認」に書き換え

## 結論

修正反映後、実装フェーズへ進行可。
