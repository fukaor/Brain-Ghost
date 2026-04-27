# 要求: ホーム画面 Stitch準拠検証

## 概要
ホーム画面(home.tscn)をStitch HTMLデザイン「ホーム画面 (吹き出ししっぽ隙間調整・最終版)」に準拠させる。
ルール説明画面で確立したStitch→Godot変換ルール(スケール比2/3)を適用する。

## 参照元
- Stitch HTML: `/tmp/stitch_home.html` (1080x1920)
- Stitch画像: `.steering/stitch_assets/designs/stitch_home.png`
- 現在キャプチャ: `.steering/20260416-ホーム画面Stitch準拠検証/capture_home_before.png`

## 制約
- ルール説明画面で作成したコンポーネント(speech_bubble.gd等)を流用し統一感を持たせる
- テーマバリエーションに頼らず、明示的font_sizeで指定（Stitch完全一致のため）
- スケール比 2/3 (HTML 1080 → Godot 720) を全要素に適用
