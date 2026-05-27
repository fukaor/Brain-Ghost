# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- 全てのタスクを `[x]` にすること
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: デザインシステム文書化

- [ ] `docs/design/sumi_ghost_design_system.md` を新設
  - [ ] 13 色トークン表
  - [ ] 表面階層 3 段（WASHI_BASE / WASHI_PANEL / WASHI_SHADE）
  - [ ] テキスト階層 5 段（H1/H2/Body/Caption/Disabled）
  - [ ] アクセント（CTA/Achievement/Positive/Ghost）
  - [ ] 背景レイヤリング規約（WashiBackground のみ、他禁止）
  - [ ] コンポーネントパターン（Button/Card/Pill/Badge/Headline）
  - [ ] v3 → v4 移行表（font_color / bg_color 全頻出値）
  - [ ] 禁止事項（白系直書き / 黒系直書き / NebulaBg）
- [ ] 既存ドキュメントの SSOT 切替注記
  - [ ] `docs/design/manifest.md` 冒頭に「**Sumi Ghost Design System (docs/design/sumi_ghost_design_system.md) が真の Single Source of Truth。本ドキュメントは旧 Midnight Cat v3 用で参考扱い**」を追記
  - [ ] `docs/design/patterns.md` 冒頭に同様の注記

## フェーズ2: 旧背景ノードの除去

- [ ] 【シーンスキャン事前確認】`grep -rE '\[node name="(VoidBg|NebulaBg|StarLayer)"' scenes/` でヒット件数を取得し、削除対象の存在を確認する（前 2 本のステアリングで省略した工程）
- [ ] Python ヘルパー `/tmp/strip_old_bg.py` を作成
  - [ ] 引数で対象シーンを取り、`[node name="VoidBg" ...] ... 次の [node` までを削除
  - [ ] 同様に NebulaBg / StarLayer ブロックも削除
  - [ ] 削除されたノードが参照していた ext_resource (Gradient/Texture) も孤児になるが warning のみで OK
- [ ] 15 シーンに適用
  - [ ] scenes/main/launch.tscn
  - [ ] scenes/main/home.tscn
  - [ ] scenes/ui/game_list.tscn
  - [ ] scenes/ui/rule_explain.tscn
  - [ ] scenes/ui/rule_explain_landscape.tscn
  - [ ] scenes/ui/countdown.tscn
  - [ ] scenes/ui/countdown_landscape.tscn
  - [ ] scenes/ui/individual_result.tscn
  - [ ] scenes/games/flash_calc/flash_calc_home.tscn
  - [ ] scenes/games/flash_calc/flash_calc_play.tscn
  - [ ] scenes/games/sequence_memory.tscn
  - [ ] scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn
  - [ ] scenes/games/number_search/number_search.tscn
  - [ ] scenes/games/card_match/card_match.tscn
  - [ ] scenes/games/stroop/stroop.tscn
  - [ ] **scenes/ui/components/nav_link_button.tscn**（NavLink ボタン共通テンプレ、複数シーンから参照）
- [ ] `grep -rE '\[node name="(VoidBg|NebulaBg|StarLayer)"' scenes/` で 0 件確認

## フェーズ3: インライン色の一括置換

- [ ] **sed バッチ戦略の確認**
  - [ ] font_color 行と bg_color 行は**別パス**で sed を回す。同じ Color() 値でも文脈で異なるトークンへマップする（例 `Color(0.435, 0.706, 1, 1)`：font は ONIBI_DEEP、bg は ONIBI_BLUE）
  - [ ] sed パターン例: `sed -i 's/font_color = Color(旧値)/font_color = Color(新値)/g'`（先頭 `font_color = ` を含めて完全一致）
  - [ ] 同様に bg_color 用は `sed -i 's/bg_color = Color(旧値)/bg_color = Color(新値)/g'`
  - [ ] 置換ごとに `git diff scenes/ | head -200` で誤置換チェック

- [ ] **font_color 置換**（sed バッチ）
  - [ ] `Color(0.7, 0.93, 1, 1)` → `Color(0.106, 0.106, 0.122, 1)` (SUMI_INK)
  - [ ] `Color(0.722, 0.878, 1, 1)` → `Color(0.106, 0.106, 0.122, 1)`
  - [ ] `Color(0.722, 0.878, 1, 0.7)` → `Color(0.106, 0.106, 0.122, 0.85)`
  - [ ] `Color(0.722, 0.878, 1, 0.75)` → `Color(0.106, 0.106, 0.122, 0.85)`
  - [ ] `Color(0.95, 0.97, 1, 1)` → `Color(0.106, 0.106, 0.122, 1)`
  - [ ] `Color(0.957, 0.969, 1, 0.95)` → `Color(0.106, 0.106, 0.122, 0.95)`
  - [ ] `Color(0.957, 0.969, 1.0, 1)` → `Color(0.106, 0.106, 0.122, 1)`
  - [ ] `Color(0.78, 0.824, 0.91, 1)` → `Color(0.239, 0.239, 0.267, 1)` (SUMI_MID)
  - [ ] `Color(0.78, 0.824, 0.91, 0.75)` → `Color(0.239, 0.239, 0.267, 0.85)`
  - [ ] `Color(0.533, 0.588, 0.69, 1)` → `Color(0.420, 0.420, 0.447, 1)` (SUMI_LIGHT)
  - [ ] `Color(0.435, 0.706, 1, 1)` → `Color(0.239, 0.420, 0.584, 1)` (ONIBI_DEEP)
  - [ ] `Color(0.435, 0.706, 1.0, 1)` → `Color(0.239, 0.420, 0.584, 1)`
  - [ ] `Color(1, 0.914, 0.659, 1)` → `Color(0.784, 0.663, 0.318, 1)` (GOLD_AGED)
  - [ ] `Color(1.0, 0.914, 0.659, 1)` → `Color(0.784, 0.663, 0.318, 1)`
  - [ ] `Color(1.0, 0.914, 0.659, 0.9)` → `Color(0.784, 0.663, 0.318, 0.9)`
  - [ ] `Color(0.961, 0.78, 0.416, 1)` → `Color(0.784, 0.663, 0.318, 1)` (GOLD_AGED)
  - [ ] `Color(0.78, 0.824, 0.91, 0.7)` → `Color(0.239, 0.239, 0.267, 0.75)` (SUMI_MID × 0.75)
  - [ ] `Color(0.78, 0.824, 0.91, 0.85)` → `Color(0.239, 0.239, 0.267, 0.9)`
  - [ ] `Color(0.78, 0.824, 0.91, 0.95)` → `Color(0.239, 0.239, 0.267, 1)`
  - [ ] `Color(0.78, 0.824, 0.91, 0.6)` → `Color(0.239, 0.239, 0.267, 0.6)`
  - [ ] `Color(0.7, 0.93, 1, 0.85)` → `Color(0.106, 0.106, 0.122, 0.9)`
  - [ ] `Color(0.7, 0.93, 1, 0.7)` → `Color(0.106, 0.106, 0.122, 0.75)`
  - [ ] `Color(0.7, 0.93, 1, 0.6)` → `Color(0.106, 0.106, 0.122, 0.65)`
  - [ ] `Color(0.722, 0.878, 1.0, 1)` → `Color(0.106, 0.106, 0.122, 1)` (末尾 .0 揺れ)
  - [ ] `Color(0.722, 0.878, 1, 0.95)` → `Color(0.106, 0.106, 0.122, 0.95)`
  - [ ] `Color(0.95, 0.97, 1, 0.9)` → `Color(0.106, 0.106, 0.122, 0.9)`
  - [ ] `Color(0.957, 0.969, 1, 1)` → `Color(0.106, 0.106, 0.122, 1)`
  - [ ] `Color(0.949, 0.957, 0.98, 1)` → `Color(0.106, 0.106, 0.122, 1)`
  - [ ] `Color(0.682, 0.722, 0.812, 1)` → `Color(0.420, 0.420, 0.447, 1)` (SUMI_LIGHT)
  - [ ] `Color(0.6, 0.65, 0.75, 1)` → `Color(0.639, 0.620, 0.580, 1)` (SUMI_DIM)
  - [ ] `Color(0.29, 0.333, 0.439, 1)` → `Color(0.239, 0.239, 0.267, 1)` (SUMI_MID)
  - [ ] `Color(0.118, 0.533, 0.898, 1)` → `Color(0.239, 0.420, 0.584, 1)` (ONIBI_DEEP)
  - [ ] `Color(0.435, 0.847, 0.624, 1)` → `Color(0.353, 0.541, 0.431, 1)` (JADE_INK 正解色)
  - [ ] `Color(0.98, 0.8, 0.082, 1)` → `Color(0.784, 0.663, 0.318, 1)` (GOLD_AGED)
  - [ ] `Color(0.49, 0.827, 0.988, 1)` → `Color(0.239, 0.420, 0.584, 1)` (nav_link_button 用 ONIBI_DEEP)
- [ ] **bg_color (StyleBoxFlat) 置換**（sed バッチ）
  - [ ] `Color(0.067, 0.094, 0.153, 0.7)` → `Color(0.910, 0.863, 0.753, 0.85)`
  - [ ] `Color(0.067, 0.094, 0.153, 0.6)` → `Color(0.910, 0.863, 0.753, 0.75)`
  - [ ] `Color(0.067, 0.094, 0.153, 0.55)` → `Color(0.910, 0.863, 0.753, 0.7)`
  - [ ] `Color(0.067, 0.094, 0.153, 0.45)` → `Color(0.910, 0.863, 0.753, 0.6)`
  - [ ] `Color(0.04, 0.08, 0.16, 0.7)` → `Color(0.910, 0.863, 0.753, 0.85)`
  - [ ] `Color(0.04, 0.08, 0.16, 0.55)` → `Color(0.910, 0.863, 0.753, 0.7)`
  - [ ] `Color(0.063, 0.075, 0.118, 0.6)` → `Color(0.839, 0.812, 0.745, 0.7)`
  - [ ] `Color(0.043, 0.071, 0.125, 0.85)` → `Color(0.910, 0.863, 0.753, 0.9)`
  - [ ] `Color(0.7, 0.93, 1, 0.6)` → `Color(0.847, 0.922, 0.969, 0.6)`
  - [ ] `Color(0.435, 0.706, 1, 1)` → `Color(0.478, 0.702, 0.878, 1)`
  - [ ] `Color(0.435, 0.706, 1, 0.9)` → `Color(0.478, 0.702, 0.878, 0.9)`
  - [ ] `Color(0.435, 0.706, 1, 0.15)` → `Color(0.478, 0.702, 0.878, 0.15)`
  - [ ] `Color(0.118, 0.533, 0.898, 1.0)` → `Color(0.239, 0.420, 0.584, 1.0)`
  - [ ] `Color(1, 0.914, 0.659, 0.15)` → `Color(0.784, 0.663, 0.318, 0.15)`
  - [ ] `Color(0.58, 0.639, 0.722, 0.5)` → `Color(0.420, 0.420, 0.447, 0.5)`
  - [ ] `Color(0.04, 0.08, 0.16, 0.6)` → `Color(0.910, 0.863, 0.753, 0.75)`
  - [ ] `Color(0.04, 0.08, 0.16, 0.9)` → `Color(0.910, 0.863, 0.753, 0.95)`
- [ ] 残存チェック（**修正済 grep**: ERE で `\|` ではなく `(a|b|c)` グループ化）
  - [ ] `grep -rE 'font_color = Color\((0\.7, 0\.93, 1|0\.722, 0\.878, 1|0\.435, 0\.706, 1|0\.78, 0\.824, 0\.91|0\.533, 0\.588, 0\.69)' scenes/` で 0 件
  - [ ] `grep -rE 'bg_color = Color\((0\.067, 0\.094, 0\.153|0\.04, 0\.08, 0\.16|0\.063, 0\.075, 0\.118|0\.043, 0\.071, 0\.125)' scenes/` で 0 件

## フェーズ4: 検証 + デプロイ

- [ ] `timeout 60 godot --headless --quit-after 30` でパースエラーなし（"Orphan SubResource" 警告は許容、ビルドエラーでなければ合格）
- [ ] `bash scripts_build/deploy_android.sh --no-launch` で APK ビルド成功
- [ ] 実機にデプロイ + 起動
- [ ] 実機スクリーンショット取得
  - [ ] `docs/design/snapshots/sumi_ghost/home.png`
  - [ ] `docs/design/snapshots/sumi_ghost/game_list.png`
  - [ ] `docs/design/snapshots/sumi_ghost/rule_explain.png`
  - [ ] `docs/design/snapshots/sumi_ghost/result_new_best.png`
  - [ ] `docs/design/snapshots/sumi_ghost/result_nice_try.png`
  - [ ] `docs/design/snapshots/sumi_ghost/game_card_match.png`
- [ ] スクリーンショット目視で和紙背景 + 墨色テキストが読めるか確認
- [ ] 端末ロック画面が邪魔する場合のフォールバック:
  - [ ] (1) `adb shell input keyevent KEYCODE_WAKEUP` でウェイク
  - [ ] (2) `adb shell input keyevent 82` でメニューキー（一部端末でロック解除）
  - [ ] (3) `adb shell input swipe 500 1500 500 500` で上スワイプ
  - [ ] (4) PIN/パターン無しなら上記で解除される。あるなら 6 桁 PIN を `adb shell input text "..."` で送信できる
  - [ ] (5) 全部ダメなら、ユーザに対面確認を依頼し、振り返りに「ユーザ確認 OK」と記録

## フェーズ5: ドキュメント更新

- [ ] 旧ステアリング 2 本（`20260525-墨絵テーマ刷新/` と `20260526-SDキャラ強化UX書換版/`）の冒頭に「**本ステアリング実装後、デザインシステム不在による不可視問題が発覚。20260526-墨絵デザインシステムとリカバリ で全面修正済み**」の注記を追加
- [ ] MEMORY.md に `design_system_sumi_ghost.md` の参照を追加
- [ ] 振り返りに「**デザインシステムを先に作る**」の教訓を残す

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分

**計画と異なった点**:

**新たに必要になったタスク**:

**技術的理由でスキップしたタスク**: なし

### 学んだこと

**技術的な学び**:

**プロセス上の改善点**:
- デザインシステム文書を**先に**作る。color_palette.gd と theme.tres だけ書き換える "色置換" は不十分で、インラインオーバーライドとシーン内ノード（VoidBg/NebulaBg）が必ず残る。**シーンスキャン → 移行表 → 一括置換** までセットで計画する

### 次回への改善提案
- テーマ刷新タスクの定型として: (1) デザインシステム文書 → (2) パレット定数 → (3) theme.tres → (4) シーン内インライン置換 → (5) 背景ノード整理 → (6) 実機キャプチャ検証 をテンプレ化
