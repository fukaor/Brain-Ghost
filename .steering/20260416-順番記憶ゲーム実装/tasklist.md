# タスクリスト: 順番記憶ゲーム実装

## フェーズ1: テーマスタイル追加

- [x] memory_panel variation追加（白背景、底8pxシャドウ、角丸17px、1:1比率）
- [x] memory_panel pressed スタイル（押し込み: translateY相当のmargin調整）

## フェーズ2: ゲームロジック (sequence_memory.gd)

- [x] SequenceMemoryクラス作成（BaseGame継承、game_type="sequence_memory"）
- [x] シーケンス生成ロジック（rng決定論、重複なしパネル選択）
- [x] フェーズ管理（showing → input → finished）
- [x] パネルタップ判定（correct / level_clear / wrong）
- [x] レベル進行（初期3 → 正解でN+1、失敗でfinish）
- [x] イベント記録（"level_cleared" / "level_failed"）

## フェーズ3: シーン + ビュー (sequence_memory.tscn + sequence_memory_view.gd)

- [x] tscn基本構造（放射グラデ背景 + SafeAreaMargin + MainColumn）
- [x] ラウンド表示バッジ + 指示テキスト
- [x] 3x3メモリーグリッド（GridContainer、9パネルButton）
- [x] タイマー表示（右上）
- [x] ~~ゴーストバトルバー~~（GDD §5c: クリア系ゲームはプレイ中非表示。結果画面でのみ比較）
- [x] sequence_memory_view.gd（表示フェーズアニメ、入力フェーズ処理、ラウンド進行、タイマー）

## フェーズ4: GameManager連携 + キャプチャ

- [x] GameManagerのsequence_memory対応確認（GAME_SCENES、_build_play_data_for）
- [x] 720x1280でXvfbキャプチャ取得
- [x] Stitchデザインと比較・差分確認

## 実装後の振り返り

- **実装完了日**: 2026-04-16
- **計画と実績の差分**:
  - GDD §5c に従い、クリア系ゲームのプレイ中ゴーストバトルバーを非表示に決定（Stitchデザインには描かれていたが、GDD優先）
  - GameManagerにsequence_memory対応を追加（GAME_SCENES + _build_play_data_for + _extract_max_level ヘルパー）
  - ROUND表示は初期値 "01"（_current_level=3 をラウンド番号に変換するかは要検討。現状はlevelをそのまま表示）
- **変更ファイル**:
  - `assets/themes/default_theme.tres`: memory_panel / memory_panel_pressed / memory_panel_active の3スタイル追加
  - `scripts/games/sequence_memory.gd`: 新規（ロジック: フェーズ管理、シーケンス生成、レベル進行）
  - `scripts/ui/sequence_memory_view.gd`: 新規（ビュー: 表示アニメ、入力処理、ラウンド進行）
  - `scenes/games/sequence_memory.tscn`: 新規（シーン: 3x3グリッド、ROUNDバッジ、タイマー）
  - `scripts/autoload/game_manager.gd`: sequence_memory対応追加
