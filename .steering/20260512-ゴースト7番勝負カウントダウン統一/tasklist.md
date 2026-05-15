# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ0: project.godot orientation 変更

- [x] `project.godot` の `window/handheld/orientation=1` を `=6` (SENSOR) に変更
- [x] `godot --headless --import --quit-after 60` で設定変更が反映されることを確認

## フェーズ1: orientation_helper.gd の実装

- [x] `scripts/utils/orientation_helper.gd` を新規作成
  - [x] `class_name OrientationHelper extends Object`
  - [x] `static func enter_landscape()` (`OS.has_feature("mobile")` 判定込み)
  - [x] `static func enter_portrait()` (同上)
- [x] エディタ import で `.uid` が生成されることを確認

## フェーズ2: GameManager の拡張

- [x] `scripts/autoload/game_manager.gd` を編集
  - [x] `LANDSCAPE_GAMES: Array = ["ghost_7ban_shobu"]` を追加
  - [x] `RULE_EXPLAIN_SCENES: Dictionary` を追加 (portrait/landscape マップ)
  - [x] `COUNTDOWN_SCENES: Dictionary` を追加
  - [x] `_is_landscape_game(game_type: String) -> bool` を実装
  - [x] `_orientation_key(game_type: String) -> String` を実装
  - [x] `start_game()` を `RULE_EXPLAIN_SCENES[_orientation_key(...)]` 参照に書き換え
  - [x] `on_rule_explain_confirmed()` を `COUNTDOWN_SCENES[_orientation_key(...)]` 参照に書き換え
- [x] **既存の縦画面ゲーム** (reflex_tap / flash_calc / sequence_memory) の動線が壊れていないか確認

## フェーズ3: rule_explain_controller.gd の find_child 化 + orientation 制御

- [x] `scripts/ui/rule_explain_controller.gd` を編集
  - [x] 既存の literal path の `@onready var` を `find_child()` ベースに書き換え
    - [x] `_title_label = find_child("TitleLabel")`
    - [x] `_ability_label = find_child("AbilityLabel")`
    - [x] `_step1_node = find_child("Step1")` から `_step1_index/title/body/preview = _step1_node.find_child("...")`
    - [x] Step2/Step3 同様
    - [x] `_start_button = find_child("StartButton")`
    - [x] `_back_button = find_child("BackButton")`
  - [x] `_ready()` 冒頭に orientation 分岐を追加
- [x] 既存の縦版 rule_explain.tscn から起動して動作確認 (find_child でノードが解決できることを確認)

## フェーズ4: countdown_controller.gd の find_child 化 + LoadingBar 削除 + orientation 制御

- [x] `scripts/ui/countdown_controller.gd` を編集
  - [x] `@onready var` を find_child 化:
    - [x] `_count_label = find_child("CountLabel")`
    - [x] `_ready_label = find_child("ReadyLabel")`
    - [x] `_bubble_text = find_child("BubbleText")`
  - [x] LoadingBar 関連 `@onready var` を削除 (`_loading_fill`, `_loading_text`, `_ready_pct`)
  - [x] `_update_loading_bar()` 関数を削除
  - [x] `_show_step()` から `_update_loading_bar(progress)` 呼び出しを削除
  - [x] `_ready()` 冒頭に orientation 分岐を追加 (rule_explain と同パターン)
- [x] 文法エラーがないことを確認

## フェーズ5: countdown.tscn 縦版のリデザイン

- [x] `scenes/ui/countdown.tscn` を編集
  - [x] `ext_resource` の `ghost_seirei.png` を `catboy_electric.png` に差し替え
  - [x] 背景階層の再構築:
    - [x] `VoidBg` (ColorRect 黒) を追加
    - [x] `NebulaBg` (TextureRect + Gradient_nebula)
    - [x] `StarLayer` (Control + star_layer.gd)
    - [x] 既存の水色グラデ (Gradient_countbg + GradientTexture2D_countbg + PageBackground) を削除
  - [x] `ReadyLabel`: 色を Midnight Cat シアン (`Color(0.7, 0.93, 1.0)`) に
  - [x] `CountLabel`: NotoSerifJP-Bold + 同シアン色
  - [x] `ChibiBg` の StyleBox を Midnight Cat 風 (半透明黒 + 角丸) に変更
  - [x] `ChibiTexture` の texture 参照を catboy_electric に
  - [x] `SpeechBubble` の `BubbleText` 色を Midnight Cat 系に
  - [x] **LoadingBarBg / LoadingBarFill / LoadingTextRow / FooterMargin / FooterVBox ノードを削除**
  - [x] StyleBoxFlat_loading_bg / _loading_fill SubResource を削除
- [x] エディタで開いて警告がないことを確認

## フェーズ6: rule_explain_landscape.tscn の新規作成

- [x] `scenes/ui/rule_explain_landscape.tscn` を新規作成
  - [x] ルート `Control` (custom_minimum_size = Vector2(1280, 720), anchors_preset = 15)
  - [x] script を `rule_explain_controller.gd` に設定
  - [x] `VoidBg` / `NebulaBg` / `StarLayer` を rule_explain.tscn からコピー
  - [x] `SafeArea` (MarginContainer) を内側に配置
  - [x] `MainColumn` (VBoxContainer) を SafeArea 直下に配置 (※縦版とノード命名は同じ)
  - [x] `Header` (HBoxContainer) を MainColumn 直下:
    - [x] BackButton (左)
    - [x] TitleBlock (右に寄せて TitleLabel + AbilityLabel)
  - [x] `StepsColumn` (**HBoxContainer**) を MainColumn 直下 ← 縦版は VBox、横版は HBox
    - [x] `Step1` / `Step2` / `Step3` の各 PanelContainer (size_flags_horizontal=3 で等分)
    - [x] 各 Step 内: `Row` (**VBoxContainer**) ← 縦版は HBox、横版は VBox
      - [x] `Preview` (Control + rule_step_preview.gd)
      - [x] `TextBlock` (VBoxContainer)
        - [x] `IndexRow` (HBoxContainer) → `Index` + `Title`
        - [x] `Body` (Label)
  - [x] `StartCTAWrap` を MainColumn 直下に配置
    - [x] `StartButton` (中央配置、size_flags_horizontal=4)
- [x] エディタで開いて表示確認 (ノードパスエラーが出ないこと)

## フェーズ7: countdown_landscape.tscn の新規作成

- [x] `scenes/ui/countdown_landscape.tscn` を新規作成
  - [x] ルート `Control` (1280x720)
  - [x] script を `countdown_controller.gd` に設定
  - [x] `VoidBg` / `NebulaBg` / `StarLayer` (リデザイン後 countdown.tscn と同じ)
  - [x] `SafeArea` (MarginContainer)
    - [x] `MainContent` (**HBoxContainer**) ← 縦版は VBox
      - [x] `ChibiArea` (VBoxContainer, size_flags_horizontal=3) ← 左半分
        - [x] `ChibiBg` → `ChibiTexture` (catboy_electric.png)
        - [x] `SpeechBubble` (glass_bubble) → `BubbleMargin` → `BubbleText`
      - [x] `RightColumn` (VBoxContainer, size_flags_horizontal=3) ← 右半分
        - [x] `ReadyLabel`
        - [x] `CountCenter` (CenterContainer)
          - [x] `CountLabel` (NotoSerifJP-Bold, size 320)
- [x] ノード命名 (`CountLabel`, `ReadyLabel`, `BubbleText`) を縦版と完全に揃える
- [x] エディタで開いて表示確認

## フェーズ8: ゴースト7番勝負本体の敵キャラ置換 + OrientationHelper 統一

- [x] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` の ext_resource を編集
  - [x] `Sleek_black_cat_with_icy_accents.png` の参照を `catboy_confident.png` に変更
- [x] `scripts/ui/ghost_7ban_shobu_view.gd` の既存 orientation 関数を OrientationHelper 経由に統一
  - [x] `_force_landscape()` → `OrientationHelper.enter_landscape()` 呼び出しに置換
  - [x] `_restore_orientation()` → `OrientationHelper.enter_portrait()` 呼び出しに置換
  - [x] `_saved_orientation` 変数を削除
- [x] `grep -r "Sleek_black_cat_with_icy_accents" /workspace` で残存参照が無いことを確認

## フェーズ9: ~~キャプチャによる横並びレビュー~~ (実機検証に統合)

- [x] ~~xvfb 経由 SubViewport キャプチャ取得~~ (技術的理由でスキップ: Godot 4.6.2 ヘッドレス環境で SubViewport.get_texture() が機能せず、参考実装の capture_ghost_7ban_ready.gd を含めすべて Terminated。実機 (moto g 66j) が利用可能なため、ユーザ承認のもと実機 `adb screencap` で代替)
- [x] memory `feedback_capture_after_uiux.md` を撤廃 (実機検証可能になったため)
- [x] フェーズ10 (実機検証) で全シーンの目視確認と必要に応じ screencap を行う

## フェーズ10: 実機検証

- [ ] `bash scripts_build/connect_android.sh`
- [ ] `bash scripts_build/deploy_android.sh --logcat`
- [ ] 縦動線テスト:
  - [ ] reflex_tap (または任意の縦ゲーム) を選択 → 縦 rule → 縦 count → ゲーム → ホーム
  - [ ] 端末向きが portrait 維持される
- [ ] 横動線テスト:
  - [ ] ghost_7ban_shobu を選択 → 横 rule → 横 count → 横ゲーム → ホーム
  - [ ] 端末向きが landscape に切替、ホーム戻りで portrait に戻る
- [ ] ゴースト7番勝負の敵キャラが catboy_confident になっている
- [ ] logcat に新規 WARN/ERROR が出ないこと

## フェーズ11: 品質チェック

- [ ] `bash scripts_build/run_unit_tests.sh` で全 pass
- [ ] `grep -r ghost_seirei /workspace/scenes /workspace/scripts` で 0 件
- [ ] `grep -r Sleek_black_cat /workspace/scenes /workspace/scripts` で 0 件 (or 残置箇所が意図したものか確認)
- [ ] `find /workspace/scenes /workspace/scripts -name "*.uid"` で新規 uid が生成済み

## フェーズ12: 振り返り

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
