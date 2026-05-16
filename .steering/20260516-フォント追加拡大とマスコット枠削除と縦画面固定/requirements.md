# 要求内容

## 概要

直前ステアリング (`20260516-最低サイズ規約とアプリアイコン適用`) のデプロイ後、ユーザレビューで 3 件のフィードバックを受領:

1. **「全体的に文字が小さい」** — 最低サイズ規約をさらに上方修正
2. **「Ready画面で SD キャラが四角い枠の中に入っている」** — countdown.tscn / countdown_landscape.tscn の `ChibiBg` 枠を撤去
3. **「ホーム画面で端末を横にしたら横画面になった。ルール説明とゲーム時以外は縦横の基準が変わらないようにすること。縦横の変更はゲーム側のみで実施すること」** — project の orientation を sensor (6) → portrait (1) に固定、ゲーム側 (OrientationHelper) でのみ landscape 切替

## 最低サイズ規約・上方修正

| 用途 | 直前規約 | **新規約** | 推奨 |
|---|---|---|---|
| 本文・カード説明 | 20 | **24** | 26 |
| ナビラベル | 18 | **22** | 24 |
| HUD 補助文言 | 16 | **20** | 22 |
| HUD 内スコア値 | 22 | **26** | 28 |
| 装飾チップ・タグ | 16 | **18** | 20 |
| ボタン文言・テキストリンク | 24 | **28** | 32 |
| 単独アクションアイコン | 36 | **44** | 48 |
| ナビバーアイコン | 36 | **40** | 44 |
| 行内アイコン | 22 | **24** | 28 |
| タップ可能要素の最小高さ | 48 | **56** | 64 |

## マスコット枠削除

- `scenes/ui/countdown.tscn` の `ChibiBg` (PanelContainer) を撤去、または `StyleBoxEmpty` で透明化
- `scenes/ui/countdown_landscape.tscn` も同様
- ChibiTexture (TextureRect) は ChibiBg の子にせず親 VBox/MainContent の直下に配置（パディング相当のサイズを TextureRect 自身で持たせる）

## 画面向きロジック

### project.godot 修正

- `window/handheld/orientation=6` (sensor) → `window/handheld/orientation=1` (portrait)
- 副作用: 端末を横に持っても全画面が縦のまま固定される

### 影響範囲（OrientationHelper 呼び出し点）

| 呼び出し点 | 現状 | 修正後の動作 |
|---|---|---|
| `rule_explain_controller._ready` (landscape版) | enter_landscape() | 維持（landscape ゲームのルール説明） |
| `countdown_controller._ready` (landscape版) | enter_landscape() | 維持 |
| `ghost_7ban_shobu_view._force_landscape()` | enter_landscape() | 維持 |
| `ghost_7ban_shobu_view._exit_tree → _restore_orientation()` | enter_portrait() | 維持 |
| home / game_list / individual_result 等 | 呼び出さない | プロジェクト既定（portrait）のまま |

### Godot 4 仕様注意

- `window/handheld/orientation=1` 設定下でも `DisplayServer.screen_set_orientation(SCREEN_LANDSCAPE)` の runtime call は動作する（Android: activity の setRequestedOrientation 経由）
- 既存 OrientationHelper.gd の docstring に「project.godot で orientation=6 (SENSOR) が前提」と書いてあるので、portrait (1) に変更後の追記が必要

## 受け入れ条件

- [ ] `grep -E "font_size = (1[0-9]\b|2[0-3]\b)" scenes/` で本文・ナビ範囲の小サイズが 0 件（HUD 補助文言は 20 以上）
- [ ] `countdown.tscn` / `countdown_landscape.tscn` で ChibiBg が削除または完全透明
- [ ] `project.godot:37` が `orientation=1`
- [ ] OrientationHelper docstring が portrait 既定の説明に更新
- [ ] Android 実機で:
  - ホーム画面で端末を横回転しても縦画面のまま
  - ゴースト7番勝負を開始したら横画面に切替
  - ゴースト7番勝負を抜けたら縦画面に戻る

## スコープ外

- 個別結果画面（前 2 ステアリングでクリア済み）
- Settings 画面（未実装）
- アナリティクス画面（未実装）
