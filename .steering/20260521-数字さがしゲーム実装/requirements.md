# 要求内容

## 概要

`docs/ideas/games/ghost-number-search-spec.md v1.1` の **MVP 範囲（Week 2 実装）** を、現状の MidnightCat デザインシステムに合わせて Godot 4 / GDScript で実装する。

## 背景

- ブレインゴーストの 6 種ミニゲームのうち、`number_search`（観察力軸）は機能設計のみ済みで実装ゼロ。
- 既存実装の 4 種（reflex_tap / flash_calc / sequence_memory / ghost_7ban_shobu）は MidnightCat 化済み。同等のトーンに揃える。
- プロモーション画像 `docs/design/promotion/game_search.png` でビジュアルが確定済み（黒背景 / 緑ハイライト 5×5 グリッド / 上部 HUD「次:14」 / 下部「★ベスト:22秒」）。
- ScoreSystem の `number_search` 計算式は v1.0 時代の `max(0, 3000 − clear_sec×100)` のまま。spec v1.1 の「残り時間比率ベース」に改訂が必要。
- game_list_controller.gd には既に `number_search` カードが定義されているが、`_implemented_games` には未登録。

## 実装対象（MVP）

### 1. ゲームロジック（BaseGame サブクラス）

| 項目 | 仕様 |
|---|---|
| ティア | **T3（5×5 / 数字 1〜25 統一表示）のみ** |
| 制限時間 | 60 秒キャップ |
| 操作 | 1 から昇順にタップ。誤タップは無視（ミスタップ数のみ加算） |
| クリア判定 | 25 までタップ完了 / タイムアウト |
| ゴースト | クリア系（プレイ中非表示、結果画面で比較） |
| デイリーシード | ティアごと独立シャッフル（spec §8-1） |

### 2. シーン / UI

- **シーン構成**: `scenes/games/number_search/number_search.tscn`（プレイ画面）
  - 上部 HUD: 「次: N」「⏱ Ns」 + ベスト表示
  - 中央: 5×5 グリッド（セル 56dp、間隔 4dp）
  - 下部: ⭐ ベストタイム
- **ビジュアル**: MidnightCat パレット
  - 未タップ: 暗グラス背景 + 白文字（INK_100）
  - タップ済み: 緑系（`GOLD_400` 相当でも可、ただし spec §3-2 に従い緑系を採用 = `EMERALD_400` 新色 or `CYAN_400` 派生）
  - 現在対象: HUD にのみ表示（グリッド内は区別しない）
- **プレイ中ゴースト**: 非表示（クリア系ルール）

### 3. スコア計算（ScoreSystem 改訂）

`scripts/core/score_system.gd` の `number_search` 分岐を改訂:

```gdscript
const BASE_SCORE = 1500
const TIME_LIMIT = 60.0  # T3 のみ MVP のため一律

# play_data からの入力:
#   clear_time_sec: float
#   is_clear: bool
#   tier_multiplier: float（T3=1.0）

if not is_clear:
    return 0
var remaining_ratio = (TIME_LIMIT - clear_time_sec) / TIME_LIMIT
return int(BASE_SCORE * remaining_ratio * tier_multiplier)
```

### 4. ゴーストデータ統合

- `GhostData` Autoload にプレイ結果を保存。`game_type = "number_search"`, `tier = "T3"`。
- 初回ゴースト初期値: 35 秒（spec §6-3）。
- 結果画面の表示は「クリアタイム」中心。スコアは詳細エリアに（spec §3-3）。

### 5. GameManager 統合

- `GAME_SCENES["number_search"] = "res://scenes/games/number_search/number_search.tscn"` を追加。
- `_build_play_data_for(log)` に `number_search` 分岐を追加。`log.events` から `clear_time_sec` / `is_clear` を抽出。

### 6. 脳トレ一覧画面への登録

- `scripts/ui/game_list_controller.gd` の `_implemented_games` に `"number_search"` を追加 → カードがアクティブ化される。

## 非対象（v1.1 以降）

- T1（3×3）/ T2（4×4）/ T4-T6（視覚干渉）は今回作らない。
- オンボーディング 3×3 練習ラウンドは今回作らない（既存の rule_explain / countdown を使う）。
- 振動フィードバック・色覚配慮モード（既存ゲームと同レベルにとどめる）。

## 受け入れ条件

1. 脳トレ一覧画面から「数字さがし」を選んで起動できる。
2. ルール説明 → カウントダウン → プレイ → 個別結果 のフローが他ゲームと同じく機能する。
3. 1〜25 を正しく昇順タップでき、25 タップでクリア確定。タイムアウト時はその時点のスコア（0 pts）が記録される。
4. 結果画面で「クリアタイム」「ゴースト比較（前回平均タイム）」「スコア（詳細エリア）」が表示される。
5. デイリーシードが同日同ティアで一致（決定論性）。
6. Web / Android 両方でクラッシュなく動作する。
