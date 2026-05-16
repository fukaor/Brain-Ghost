# 要求内容

## 概要

1. ユーザーレビューで「全体的に文字が小さい / ホームの設定アイコンと全ゲーム一覧が見えない」と指摘された問題を解決
2. アプリ全体に最低文字/アイコンサイズ規約を策定し、`docs/ui-design-guidelines.md` に追記
3. 規約に従って 5 ファイルの font_size を一括修正（48 箇所中、本文・ナビ・補助文言を対象）
4. `docs/design/promotion/game_icon.png` をアプリ正式アイコンとして適用（project.godot + Android export_presets）

## 最低サイズ規約

| 用途 | 例 | **最低値** | 推奨 |
|---|---|---|---|
| 本文・カード説明 | ゲーム概要文 | **20** | 22 |
| ナビラベル | 脳トレ/分析/ホーム/アワード | **18** | 20 |
| HUD 補助文言 | "LIVE SYNC"・「自分」「ゴースト」 | **16** | 18 |
| HUD 内スコア値 | "0" / "—" | **22** | 24 |
| 装飾チップ・タグ | ATTENTION / CALCULATION | **16** | 18 |
| ボタン文言・テキストリンク | 「全ゲーム一覧 ›」 | **24** | 28 |
| 単独アクションアイコン | Settings | **32** | 36 |
| ナビバーアイコン | Bottom Nav | **36** | 40 |
| 行内アイコン | HBox の小アイコン | **22** | 24 |
| タップ可能要素の最小高さ | — | **48px** | 56px |

## アイコン適用

- `docs/design/promotion/game_icon.png` を `assets/icons/game_icon.png` にコピー（または直接参照）
- `project.godot` の `config/icon` を新アイコンに切替（旧 `res://icon.svg` を廃止）
- `export_presets.cfg` の Android `launcher_icons/main_192x192` 等を新アイコンに設定
- 必要であればホームのマスコット位置にも反映（既存 catboy_electric は維持で良いか判断）

## 修正対象ファイル

- `scenes/main/home.tscn`（SettingsButton 24→32、AllGamesLink 14→24）
- `scenes/ui/game_list.tscn`（カードキャプション 13→20、能力タグ 14→16、ナビラベル 13→18）
- `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn`（HUD ピル 12-16 を 16-22 に）
- `scenes/games/reflex_tap.tscn`（HUD キャプション 12→16）
- `scenes/shared/ghost_battle_bar.tscn`（10→16 / 11→16 / 14→22）

## 受け入れ条件

- [ ] `docs/ui-design-guidelines.md` に最低サイズ規約セクションが追加されている
- [ ] `grep -E "font_size = ([0-9]|1[0-5])\b" scenes/` で本文系の小サイズが 0 件（HUD 数値表示など意図的なものは規約値に合わせ済）
- [ ] ホーム画面の設定アイコンと「全ゲーム一覧」が拡大されている
- [ ] アプリアイコンが新しい猫耳キャラ+グロー脳に変わっている
- [ ] Android ビルド → 実機デプロイで実機表示確認

## スコープ外

- 文字サイズに合わせたレイアウト微調整（コンテナサイズが破綻したらフェーズ追加）
- 横画面シーン（rule_explain_landscape / countdown_landscape）の修正
- 個別結果画面（直前ステアリング完了済み、サイズ規約はクリア済み）
