# 要求内容

## 概要

`docs/ideas/games/ghost-memory-match-lite-spec.md v1.1` の **MVP 範囲（Week 3 実装）** を Godot 4 / GDScript で実装する。

## 背景

- 既存 game_list の判断力枠カードは `id = "card_match"` で登録済み（実装は未完）。spec v1.1 では「神経衰弱ライト」と呼称。**game_type の内部 ID は既存に合わせて `card_match` を維持**（リネームはスコープ外）。
- プロモーション画像 `docs/design/promotion/game_memory.png` でビジュアル確定（黒背景＋4×4 グリッド。カード裏面に黒猫マスコットの薄い影。表は赤丸/三角/星の単色図形）。
- 黒猫マスコットの画像は `assets/branding/` 配下に既に存在（Catboy 系）。これを薄く tile したカード裏面とする。
- ScoreSystem の `card_match` 計算式は v1.0 時代の `(pair/tap)×1000` のままなので、spec v1.1 の **`(pair×2/tap)×1000 + 時間ボーナス`** に改訂が必要。
- game_list_controller の `_implemented_games` には未登録。

## 実装対象（MVP）

### 1. ゲームロジック（BaseGame サブクラス）

| 項目 | 仕様 |
|---|---|
| ティア | **T1（4×4 / 8 ペア / 単色図形 8 種）のみ** |
| 制限時間 | 60 秒キャップ |
| カード状態 | `face_down` / `face_up` / `matched` の 3 状態（spec §2-5） |
| ペア判定演出 | 一致: 0.3 秒緑フラッシュ → 固定 / 不一致: 0.5 秒グレーフラッシュ → 裏に戻る |
| ゴースト | クリア系（プレイ中非表示、結果画面でスコア比較） |
| デイリーシード | 共通プール生成 → ティア別切り出し（spec §8-1） |

### 2. カードの図柄（言語非依存）

spec §2-2 T1 の 8 種を採用。Material Symbols Rounded フォントで描画する:

| # | 図形 | Material Symbol | 色 |
|---|---|---|---|
| 1 | ● | `circle` | `#E53935` |
| 2 | ■ | `square` | `#1E88E5` |
| 3 | ▲ | `change_history` | `#43A047` |
| 4 | ◆ | `diamond` | `#FDD835` |
| 5 | ★ | `star` | `#FF6B35` |
| 6 | ⬡ | `hexagon` | `#7B1FA2` |
| 7 | ♥ | `favorite` | `#EC407A` |
| 8 | ⬟ | `pentagon` | `#00BCD4` |

### 3. シーン / UI

- **シーン**: `scenes/games/card_match/card_match.tscn`
  - 上部 HUD: 「🃏 神経衰弱ライト」「⏱ Ns」「タップ: N / ペア: N/8」
  - 中央 GridContainer（4 列 × 4 行、セル 72dp、間隔 10dp）
  - 下部: ⭐ ベスト（タップ数 / 秒）
- **カード表面**: Material Symbols 図形 + 色（spec §2-2 表）
- **カード裏面**: Catboy 影 + シアン縁。`assets/branding/` のマスコット PNG を 0.18 アルファで配置。
- **プレイ中ゴースト**: 非表示

### 4. スコア計算（ScoreSystem 改訂）

`card_match` 分岐を spec §5-1 の式に置換:

```gdscript
# 入力: pairs_found, total_taps, clear_time_sec, time_limit_sec, tier_mult
var efficiency = float(pairs * 2) / float(total_taps) if total_taps > 0 else 0.0
var efficiency_score = int(efficiency * 1000)
var time_remaining = max(0.0, time_limit_sec - clear_time_sec)
var time_bonus = int((time_remaining / time_limit_sec) * 500)
return int(round((efficiency_score + time_bonus) * tier_mult))
```

### 5. ゴーストデータ統合

- `game_type = "card_match"`, `tier = "T1"`。
- 初回ゴーストスコア: 800 pts（spec §6-3）。
- 結果画面はスコア比較（spec §3-3 / §6-1）。

### 6. GameManager 統合

- `GAME_SCENES["card_match"] = "res://scenes/games/card_match/card_match.tscn"` を追加。
- `_build_play_data_for(log)` に `card_match` 分岐を追加（pairs_found / total_taps / clear_time_sec / is_clear を log.events から復元）。

### 7. 脳トレ一覧画面への登録

- `_implemented_games` に `"card_match"` を追加。
- GAME_CARDS の表示名は既存「神経衰弱」のまま OK（ライト感は判定不要）。説明文を spec v1.1 に合わせて微修正可。

## 非対象（v1.1 以降）

- T2〜T6 / シャッフルルール / プレビュー機能 / 3D 回転エフェクト。
- オンボーディング 2×2 練習画面（rule_explain で代用）。

## 受け入れ条件

1. 脳トレ一覧から「神経衰弱」を選んで起動できる。
2. ルール説明 → カウントダウン → プレイ → 個別結果 のフローが他ゲームと同じく機能する。
3. 4×4 グリッドが描画され、カード 16 枚（8 ペア × 2）が裏向きで配置される。
4. 1 枚目タップで表になり、2 枚目で判定が走る。一致は固定、不一致は 0.5 秒後に裏に戻る。
5. 8 ペア揃えでクリア。60 秒経過でタイムアウト（ゲームオーバーではなく到達状態でスコア算出）。
6. spec §2-5 の例外処理（再タップ無視 / 処理中タップ無視）が機能する。
7. 同日のシードで配置が同一。
8. 結果画面に主要指標（スコア + 前回比 + ゴースト勝敗）が表示される。
9. Web / Android 両方でクラッシュなく動作する。
