# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### 実装可能なタスクのみを計画
- 計画段階で「実装可能なタスク」のみをリストアップ
- 「将来やるかもしれないタスク」は含めない
- 「検討中のタスク」は含めない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は必ず理由を明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的な技術的理由）
```

### タスクが大きすぎる場合
- タスクを小さなサブタスクに分割
- 分割したサブタスクをこのファイルに追加
- サブタスクを1つずつ完了させる

---

## フェーズ0: アセット受け入れ準備（ユーザ作業待ち）

> **判定**: 本フェーズはユーザ（人間）によるアセット作成が前提。
> フェーズ0 が未完でもフェーズ1（共通基盤）は並行着手可能（fallback として `catboy_electric.png` を暫定参照）。
> フェーズ0 の全チェックが完了した時点でフェーズ2 のシーン差し替えに移る。
> **タスク完全完了の原則は守る**：本フェーズの全項目は最終的に `[x]` にしてから振り返りに進む。

- [ ] 新キャラの正式名称を確定（仮: `ghostneko`）
- [ ] 新キャラの画像ファイルを `assets/characters/` に配置
  - [ ] `ghostneko_idle.png`（必須）
  - [ ] `ghostneko_blink.png`
  - [ ] `ghostneko_yawn.png`
  - [ ] `ghostneko_tail_flick.png`
  - [ ] `ghostneko_celebrate.png`
  - [ ] `ghostneko_sad.png`
  - [ ] `ghostneko_shock.png`
  - [ ] `ghostneko_think.png`
  - [ ] `ghostneko_sleep.png`
  - [ ] `ghostneko_zap.png`
  - [ ] `ghostneko_eyes_only.png`（起動演出用）
- [ ] 各画像の透過 / 長辺 512px 以下を確認
- [ ] `.import` ファイルが自動生成されることを確認

## フェーズ1: 共通基盤（フェーズ0 と並行可能）

- [ ] **【Critical 先行】** `scripts/autoload/platform.gd` に `supports_haptics()` を追加（Android のみ true）
- [ ] `juicy_button.gd` を新設（composition 型に確定）
  - [ ] `scripts/ui/components/juicy_button.gd` 作成（`extends Node`、`target_button: Button` を export）
  - [ ] 親 Button 自動取得フォールバック実装
  - [ ] 240ms 3 段スプリング（0.95→1.05→1.0）の Tween
  - [ ] `Platform.supports_haptics()` ガード経由で `Input.vibrate_handheld(20)` 発火
- [ ] `MascotController` 基盤を新設
  - [ ] `scripts/ui/components/mascot_controller.gd` 作成
  - [ ] `set_accuracy(value)` 実装（Tween による補間、`_acc_tween` で重複発火防止）
  - [ ] `react_celebrate / sad / shock / think` API 実装
  - [ ] アイドルタイマー（30s curl_up / 120s sleep）実装
- [ ] `SpeechBubble` 拡張（既存 `scripts/ui/speech_bubble.gd`）
  - [ ] `set_text(text: String, dwell_sec: float = 2.0)` API 追加
  - [ ] fade in (0.2s) / dwell / fade out (0.3s) の Tween 実装
  - [ ] 連続呼び出し時の Tween kill 処理
  - [ ] 既存利用箇所（countdown / home / ghost_character）の後方互換確認（既存テキスト指定方法を壊さない）

## フェーズ2: マスコット差し替えと AnimationTree 構築

- [ ] AnimationTree（StateMachine）を MascotController と接続
  - [ ] AnimatedSprite2D に SpriteFrames を設定（各状態 = 各 animation 名）
  - [ ] AnimationTree ノードを配置し 7 系統 + idle/blink/yawn/tail_flick/curl_up/sleep の遷移を定義
  - [ ] 各 react_* メソッドから travel() で遷移できることを確認
  - [ ] **GPUParticles2D.amount_ratio の Tween が実機で動作することを Godot エディタで動作確認**
- [ ] 既存シーンのマスコットを差し替え（`ext_resource` の `path` を書き換えるだけで OK）
  - [ ] `scenes/main/home.tscn` の `catboy_electric.png` 参照を新キャラに置換
  - [ ] `scenes/ui/countdown.tscn` の `catboy_electric.png` 参照を置換
  - [ ] `scenes/ui/countdown_landscape.tscn` の `catboy_electric.png` 参照を置換
  - [ ] `scenes/ui/individual_result.tscn` の `catboy_electric.png` 参照を置換
  - [ ] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` の `catboy_confident.png` 参照を置換
    - ※ ext_resource id="5_ghostcat" を 3 ノード (GhostMarker/Mascot, ReadyOverlay/Mascot, DoneOverlay/DoneMascot) で共有しているため、path 書き換えで 3 箇所同時更新される
- [ ] ランタイム参照ゼロ化を確認（`grep "catboy_" scripts/ scenes/` で 0 件）
- [ ] 旧 catboy_* / ghost_seirei は assets/characters/ に残置（削除しない）

## フェーズ3: 画面別演出の実装

- [ ] **A-1**: juicy_button.gd を全 CTA に適用
  - [ ] スタートボタン（rule_explain / countdown 系）
  - [ ] ホームボタン（個別結果 / game_list）
  - [ ] リプレイボタン（個別結果）
  - [ ] その他 CTA（home.tscn / settings 等）
  - [ ] Android 実機で振動とバウンスを確認
- [ ] **A-2**: ホーム常駐マスコットを実装
  - [ ] home.tscn 右下に MascotController + AnimatedSprite2D 配置（96px）
  - [ ] idle / blink / yawn / tail_flick の 4 ループランダム切替（8〜15s 間隔）
  - [ ] タップで SpeechBubble + パーティクル発火
  - [ ] 30s / 120s 放置で curl_up / sleep
- [ ] **A-3**: 結果画面リアクション（既存 7 グレード対応）
  - [ ] individual_result.tscn にマスコット配置と MascotController 接続
  - [ ] set_result 後に 600ms 待機 → `_compute_grade_headline()` の戻り値で分岐
  - [ ] "NEW BEST" → react_celebrate + パーティクル + ハプティック × 3
  - [ ] "PERFECT WIN" / "GREAT WIN" / "WIN" → react_celebrate + ハプティック × 2
  - [ ] "IMPROVED" → react_think + ハプティック × 1
  - [ ] "NICE START" → react_celebrate（控えめ）+ ハプティック × 1
  - [ ] "NICE TRY" → react_sad（ハプティックなし）
  - [ ] SpeechBubble にグレード別吹き出し（12 文字以内、運用ルール）
- [ ] **A-5**: 精度連動グロー
  - [ ] HomeController から MascotController.set_accuracy() 呼び出し
  - [ ] IndividualResultController から同様に呼び出し
  - [ ] ScoreSystem.calculate_accuracy() の値で 0% / 50% / 100% の見た目差を確認

## フェーズ4: 起動演出とゲーム内改修

- [ ] **D-1**: launch.tscn 起動演出
  - [ ] 黒画面 → ghostneko_eyes_only.png を中央配置 → 1.2s 後にロゴへスプリング展開
  - [ ] 既存のスプラッシュ遷移と統合（壊さない）
- [ ] **C-神経衰弱**: カード裏面に肉球シルエット
  - [ ] card.gd `_apply_back()` で `_IconLabel.text = "pets"` + 薄シアン透過
  - [ ] 表向き遷移時にアイコンに上書きされる挙動を維持

## フェーズ5: 品質チェックと修正

- [ ] Godot --headless でシンタックスエラーが出ないことを確認
- [ ] `grep "catboy_" scripts/ scenes/` でランタイム参照ゼロ確認
- [ ] tests/unit/ の既存テストが通る
- [ ] 実機ビルド（`bash scripts_build/deploy_android.sh`）が成功
- [ ] 実機（moto g66j 5G）で 6 ゲーム全プレイ動作確認
- [ ] CAPTURE_CASE=perfect_win/nice_try/new_best/improved で個別結果画面 4 ケース確認
- [ ] Web 版エクスポートでハプティック呼び出しがクラッシュしないことを確認

## フェーズ6: ドキュメント更新

- [ ] `MEMORY.md` のマスコット情報を更新
  - [ ] `project_mascot_catboy.md` を新キャラ ID に書き換え
- [ ] `docs/repository-structure.md` を更新
  - [ ] `scripts/ui/components/` 配下に追加された `mascot_controller.gd` / `juicy_button.gd` を反映
  - [ ] `scripts/autoload/platform.gd` に `supports_haptics()` が追加されたことを反映
- [ ] 開発ガイドラインの該当箇所を更新（必要に応じて）
- [ ] 実装後の振り返り（このファイル下部）を記録

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:
- {計画時には想定していなかった技術的な変更点}
- {実装方針の変更とその理由}

**新たに必要になったタスク**:
- {実装中に追加したタスク}
- {なぜ追加が必要だったか}

**技術的理由でスキップしたタスク**（該当する場合のみ）:
- {タスク名}
  - スキップ理由: {具体的な技術的理由}
  - 代替実装: {何に置き換わったか}

### 学んだこと

**技術的な学び**:
- {実装を通じて学んだ技術的な知見}

**プロセス上の改善点**:
- {タスク管理で良かった点}

### 次回への改善提案
- {次回の機能追加で気をつけること}
- {より効率的な実装方法}
