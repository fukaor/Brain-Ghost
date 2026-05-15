# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: individual_result.tscn のリデザイン

- [x] ext_resource の差し替え
  - [x] `ghost_seirei.png` → `catboy_electric.png`
  - [x] `star_layer.gd` を ext_resource に追加
- [x] SubResource の整理
  - [x] `Gradient_nebula` (rule_explain.tscn からコピー) を追加
  - [x] `GradientTexture2D_nebula` (rule_explain.tscn からコピー) を追加
  - [x] `Gradient_resultbg` を削除
  - [x] `GradientTexture2D_resultbg` を削除
- [x] 背景階層の再構築
  - [x] `PageBackground` ノードを削除
  - [x] `VoidBg` (ColorRect 黒) を追加
  - [x] `NebulaBg` (TextureRect + Gradient_nebula) を追加
  - [x] `StarLayer` (Control + star_layer.gd) を追加
- [x] Label の font_color 上書き (Midnight Cat 統一)
  - [x] `ResultsLabel` → MC_CYAN
  - [x] `ScoreValue` → MC_WHITE
  - [x] `ScoreUnit` → MC_WHITE
  - [x] `ScoreCaption` → MC_DIM
  - [x] `NewBestLabel` → MC_GOLD
  - [x] `YouCaption` → MC_CYAN (alpha 0.6)
  - [x] `YouValue` → MC_CYAN
  - [x] `GhostCaption` → MC_DIM (alpha 0.6)
  - [x] `GhostValue` → MC_DIM
  - [x] `VictoryLabel` → MC_GOLD (緑→ゴールド)
  - [x] `PerfectCaption` → MC_DIM
  - [x] `PerfectValue` → MC_WHITE
  - [x] `MissCaption` → MC_DIM
  - [x] **`MissValue` → MC_GRAY (赤撤廃)**
  - [x] `SpeechText` → MC_CYAN
  - [x] `HomeIcon` → MC_CYAN
  - [x] `HomeText` → MC_CYAN
- [x] エディタで開いて警告がないことを確認
  - [x] `godot --headless --import --quit-after 60` 実行

## フェーズ2: 静的チェック

- [x] `grep -r ghost_seirei /workspace/scenes /workspace/scripts` で 0 件
- [x] `grep -E "Gradient_resultbg|GradientTexture2D_resultbg|PageBackground" /workspace/scenes/ui/individual_result.tscn` で 0 件
- [x] ノード命名が controller の `@onready var` パスと一致 (16 ノード全てチェック OK)

## フェーズ3: 実機検証

- [ ] `bash scripts_build/connect_android.sh`
- [ ] `bash scripts_build/deploy_android.sh`
- [ ] 縦動線テスト:
  - [ ] reflex_tap または flash_calc または sequence_memory を完走
  - [ ] 個別結果画面が Midnight Cat (黒地 + シアン + ゴールド) で表示される
  - [ ] Replay / Home ボタンが動作する
- [ ] 横動線テスト:
  - [ ] ghost_7ban_shobu を完走
  - [ ] portrait に戻り、個別結果画面が Midnight Cat で表示される
  - [ ] スコア・YouValue・GhostValue・VictoryLabel・MissValue 等が正しく表示される

## フェーズ4: 振り返り

- [ ] 実装後の振り返りをこのファイル下部に記録

---

## 実装後の振り返り

### 実装完了日
{未記入}

### 計画と実績の差分

**計画と異なった点**:
- {未記入}

**新たに必要になったタスク**:
- {未記入}

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- {該当なし or 詳細}

### 学んだこと

**技術的な学び**:
- {未記入}

**プロセス上の改善点**:
- {未記入}

### 次回への改善提案
- {未記入}
