# タスクリスト

## フェーズ1: 縦画面固定

- [x] `project.godot:37` の `orientation=6` → `1`
- [x] `scripts/utils/orientation_helper.gd` docstring を portrait 既定の説明に更新

## フェーズ2: マスコット枠削除

- [x] `scenes/ui/countdown.tscn` の ChibiBg PanelContainer を撤去（ChibiTexture を直接親 VBox/Column の子に）
- [x] `scenes/ui/countdown_landscape.tscn` 同様

## フェーズ3: フォント追加拡大

- [x] `docs/ui-design-guidelines.md` の規約テーブルを新規約値で更新
- [x] `scenes/main/home.tscn`: SettingsButton 36→44、AllGamesLink 24→28（最小高 48→56）
- [x] `scenes/ui/game_list.tscn`:
  - カードキャプション (DescriptionLabel) 20→24
  - 装飾タグ 16→18
  - Bottom Nav ラベル 18→22
  - Bottom Nav アイコン 36→40
  - MetricCaption 16→18
  - ComingSoon 16→18
- [x] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn`:
  - RoundLabel 20→22
  - HUD YOU/GHOST 16→20
  - HUD Wins 22→26
  - HUD Divider 22→26
  - YouMarker/GhostMarker Label 18→22
  - Ready Eyebrow 18→22
  - Ready Hint 24→28
  - Done Eyebrow 18→22
- [x] `scenes/games/reflex_tap.tscn`: HUD キャプション 16→20
- [x] `scenes/shared/ghost_battle_bar.tscn`:
  - LIVE SYNC 16→20
  - 自分/ゴースト 16→20
  - スコア 22→26
  - ゴーストバトル 18→22

## フェーズ4: 検証

- [x] Godot parse / 起動エラーなし
- [x] Android 実機デプロイ
- [x] 実機で:
  - ホームを横回転 → 縦のまま
  - ゴースト7番勝負 ルール説明 → 横画面遷移
  - ゲーム終了 → 縦画面復帰
  - Ready (countdown) 画面で SD キャラに枠なし
  - 全体的に文字が読みやすい

## 実装後の振り返り

（フェーズ4 完了後に追記）
