# Review 対応ログ (v1.0 → v1.1)

Claude Code feature-dev:code-reviewer による事前レビュー結果を反映。

## 取り込み済み修正

| ID | 重要度 | 概要 | 修正内容 |
|---|---|---|---|
| C1 | 🔴 | ティア設計矛盾：requirements「T1〜T3 実装」と design「T1 固定」が不整合 | **方針確定**: コード上は T1〜T3 を完全サポート。MVP 起動時は T1 固定（ティア選択 UI なし）。TierManager は最小 stub（常に T1 返却）で実装し、v1.1 で UI 追加。design.md §1 と §4 の冒頭にこの方針を明記 |
| C2 | 🔴 | `_on_finish()` が PlayLog を返さず BaseGame 契約違反 | flash_calc.gd パターンに揃え、`_on_finish()` で log.score を計算済み値で埋める方針に変更。play_data は `precomputed_score` 渡し |
| C3 | 🔴 | デイリーシードが 2 段階方式になっていない | StimulusGenerator を `generate_pool(seed)` + `select_for_tier(pool, tier)` の 2 関数に分離。ティア非依存のコア属性プールから比率フィルタリング |
| M1 | 🟡 | 30 秒 / 3 秒の close-race で二重終了 | `_present_current` の冒頭に `if not _game._is_active: return` 追加。`_process` 内 time_over 発火時に answer_timer.stop() を明示 |
| M2 | 🟡 | ティア倍率の適用先が不明 | `_on_finish()` 内で `int(max(0, net) * tier_mult)` を計算して log.score に格納。ScoreSystem 側は `precomputed_score` パススルー（flash_calc と同パターン） |
| M3 | 🟡 | ゴーストバー max_value 不安定 | `initial_ghost` を _ready() でティアから読み込み、max_value は **「想定最大正答数 20」固定**（30 秒 × 1.5 秒/問 ≈ 20）に設定。バーは player_correct と ghost_eta を [0, 20] レンジに正規化 |
| m1 | 🟢 | ShapeContainer の render 仕様明記 | design.md §6 に `_render_shape()` スケッチを追加 |
| m2 | 🟢 | rule_explain 統合を Phase 4 → Phase 3 に前倒し | tasklist の Phase 構成を組み直し |

## design.md 追記事項

- §1 冒頭にティア方針確定（T1〜T3 サポート、起動時 T1）
- §4 _on_setup で TierManager 経由のティア取得
- §4 _on_finish() を flash_calc パターンに刷新（precomputed_score を log.score に格納）
- §5 StimulusGenerator を 2 関数（generate_pool / select_for_tier）に分離
- §6 _render_shape() スケッチ追加
- §6 _present_current() の `_is_active` ガード + answer_timer.stop()
- §9 ゴーストバー max_value 固定値の根拠

## tasklist.md 追記事項

- T1-02 を「2 段階生成（generate_pool / select_for_tier）」に書き換え
- T3-01 を「precomputed_score 方式に変更」+ T1-03 の _on_finish() でスコア計算
- T4-01 (rule_explain) を Phase 3 に前倒し
- ゴーストバー max_value 設定タスク追加

## 結論

修正反映後、実装フェーズへ進行可。
