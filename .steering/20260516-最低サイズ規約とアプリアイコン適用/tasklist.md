# タスクリスト

## フェーズ1: ガイドライン文書化

- [x] `docs/ui-design-guidelines.md` に「最低文字/アイコンサイズ規約」セクションを追加（既存ファイルがあれば追記、なければ新規作成）

## フェーズ2: アプリアイコン適用

- [x] `docs/design/promotion/game_icon.png` を `assets/icons/game_icon.png` にコピー（または直接 promotion を参照）
- [x] `project.godot` の `config/icon` を新アイコンに切替
- [x] `export_presets.cfg` の Android `launcher_icons/main_192x192` を設定

## フェーズ3: home.tscn 修正

- [x] SettingsButton: icon font_size 24→32, custom_minimum_size 48→56
- [x] AllGamesLink: font_size 14→24, custom_minimum_size を 48px 確保

## フェーズ4: game_list.tscn 修正（29 箇所）

- [x] カードキャプション系（13/14/15）→ 20
- [x] 能力タグ（ATTENTION 等）14 → 16
- [x] Bottom Nav ラベル（13）→ 18
- [x] Bottom Nav アイコン（32）→ 36

## フェーズ5: ghost_battle_bar.tscn 修正（6 箇所）

- [x] "LIVE SYNC" 10 → 16
- [x] 「自分」「ゴースト」11 → 16
- [x] スコア値 14 → 22
- [x] 「ゴーストバトル」14 → 18

## フェーズ6: ghost_7ban_shobu.tscn 修正（9 箇所）

- [x] HUD ラベル系 12-14 → 16-18
- [x] スコア値系 14 → 22
- [x] 装飾 12-13 → 16

## フェーズ7: reflex_tap.tscn 修正（3 箇所）

- [x] HUD キャプション 12 → 16

## フェーズ8: 検証

- [x] Godot parse / 起動エラーなし
- [x] ホームと game_list の修正後キャプチャ取得
- [x] Android デプロイ → 実機目視確認

## 実装後の振り返り

（フェーズ8 完了後に追記）
