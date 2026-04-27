# 要求: カウントダウン画面のStitch準拠リビルド

## 概要
ルール説明画面からプレイ画面に遷移する際のカウントダウン画面をStitch HTMLデザインに準拠して作成。

## 参照元
- Stitch HTML: `/tmp/stitch_countdown.html` (1080x1920)
- Stitch画像: `.steering/20260416-カウントダウン画面実装/stitch_countdown.png`
- 既存: `scenes/ui/countdown.tscn` + `scripts/ui/countdown_controller.gd`

## デザイン要素
1. 「まもなく開始！」テキスト + 装飾線
2. 巨大なカウントダウン数字 (3→2→1→GO) — 青グラデーション、パルスアニメーション
3. SDキャラ (右下) + 吹き出し「集中して！(Focus!)」
4. ローディングバー + 進捗テキスト
5. 背景: 水色放射グラデーション

## 制約
- スケール比 2/3 (HTML 1080 → Godot 720)
- ghost_character.tscn 依存を廃止し、ghost_seirei.png + speech_bubble.gd を流用
- 既存のコントローラロジック（3→2→1→いくよ！→完了）は維持
