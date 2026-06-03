# タスクリスト: 墨絵以外アセット整理・削除

> **自己完結メモ（/clear 後の実行者へ）**: 本作業は「現行 sumi が使うアセット＋法的必須だけ残し、旧デザイン/汚染/重複を削除」する。詳細分類は同ディレクトリの design.md を参照。全候補は git 追跡済みで `git restore` 復元可。各 `.png` 削除時は対の `.import`/`.uid` も削除（`git rm` なら自動巻き込み）。

## T0. 着手前の再監査（必須）
- [x] `git status` がクリーン寄りか確認（既存の未コミット変更は `.claude/` スキルdoc＋`addons/gut/` フォントimportのみで本作業と無関係。コミットは削除パスのみ stage する）
- [x] 削除候補が本当に参照0か再確認（実参照0確認済。`id="2_catboy"` はリソースID名のみ・実パスは sumineko_normal.png、`SBF_cd_bar_fill` は StyleBox SubResource 名でテクスチャ非参照、その他は全てコメント言及のみ）
- [x] `assets/themes/default_theme.tres` が project.godot/全シーンから参照0であることを再確認（参照0確認済）。`.uid` ファイルは存在せず `.import` のみ。

## T1. 重複デザインツリー削除（最大の削減・最低リスク）
- [x] `git rm -r docs/design/claude_design/`（約31M。追跡済104ファイル削除＋未追跡.import等51ファイルは rm -rf で物理削除。working tree から完全消去確認）

## T2. Tier1: 非墨絵・旧デザインシステム削除
- [x] `git rm assets/themes/default_theme.tres`（.uid は元々無し）
- [x] `git rm -r assets/textures/gradients/`（追跡.png削除＋未追跡.import を rm -rf。ディレクトリ消去確認）
- [x] `git rm -r assets/backgrounds/`（washi_* 旧背景。同上で.import 巻き込み消去）
- [x] `git rm -r assets/icons/`（hitodama_lv*＋game_icon.png。同上）
- [x] 非 sumineko キャラ削除: catboy_*3 / Defensive_ / Minimalist_ / Sleek_*4 / Sleeping_ / ghost_seirei の .png＋.import を削除
  - ※保持確認済: `sumineko_*` 一式 ＋ `ghost_placeholder.svg`

## T3. Tier2: 汚染パーツ（design.md で禁止・置換済み・参照0）削除 ※残したければスキップ可
- [x] `git rm -r assets/textures/frames/`（frame_ink_border* → StyleBoxFlat。.import 巻き込み消去）
- [x] `git rm -r assets/textures/decorations/`（arrow/divider/hitodama/*_ref → _draw/SumiDivider）
- [x] `git rm -r assets/textures/bars/`（bar_fill*/stamp_row_ref → ProgressBar/StyleBox）
- [x] `git rm -r assets/textures/game_icons/`（game_icon_*・_art → Material Symbols, B-8撤去済み）
- [x] badges を stamp_shuin 以外削除（badge_best/new/new_corner/tier_frame, icon_lock, mark_lose/win）
  - ※保持確認済: `stamp_shuin.png`（残り badges はこれのみ）

## T4. 保持確認（消さないもの）
- [x] 全て残存確認: fonts 5種＋OFL.txt / sumi_theme.tres / sumineko_*6＋ghost_placeholder.svg / backgrounds bg_*7種(bg_rule・bg_washi_base含む) / buttons btn_*3種 / badges stamp_shuin.png / branding 5種 / CREDITS.md / images・sounds(サブディレクトリ構造)

## T5. 再インポート＆検証
- [x] `godot --headless --import` → 削除パス起因のエラー/欠損リソース無し（exit 0）
- [x] home 実起動キャプチャ → /tmp/home_after_cleanup.png (720x1280) 正常: 和紙背景/墨猫マスコット/脳年齢30歳/レーダー/今日のチャレンジカード/始めるボタン、文字化けなし
- [x] 主要シーン load: home.tscn / rule_explain.tscn / ghost_7ban_shobu.tscn 全て **OK**（DataStore未解決は load_check のautoload非ロード起因の既存事象・アセット無関係）
- [x] 回帰: GUT **82/82 passed**（6+11+6+22+8+20+9, All tests passed!）。flash_calc パースエラーは既存別件で無視

## T6. ドキュメント整合・コミット
- [x] `assets/CREDITS.md`: 削除アセットへの言及なし（フォント/プラグイン中心）→ 更新不要を確認
- [x] `docs/repository-structure.md`: assets セクション全面更新（doc承認済）。fonts5種/characters sumineko_*/textures backgrounds・buttons・badges/sumi_theme.tres/branding を現状反映。default_theme・gradients・icons・build_theme/gradients.gd の記載を除去。残存乖離0確認
- [x] 追加対応（doc承認済）: 孤立生成スクリプト `scripts_build/build_gradients.gd`・`build_theme.gd`（削除済アセットの生成元）も削除
- [ ] 独立コミット化（例: `chore: 墨絵以外の死蔵アセット削除（旧テーマ/グラデ/旧キャラ/汚染パーツ/重複docツリー）`）

## T7. 振り返り
- [ ] 削除総量・残アセット数を記録／想定外の参照が無かったか／次回への教訓

---

## 実装後の振り返り
### 実装完了日
2026-06-03

### 計画と実績の差分
- **計画通り**: T1〜T4 の削除分類（重複docツリー / Tier1 旧デザイン / Tier2 汚染パーツ）はそのまま実行。参照0前提も全て成立。
- **追加対応（doc承認で実施）**: repository-structure.md は当初「乖離確認」だったが、sumi リブランド前のスナップショット由来で広範に陳腐化していたため assets セクションを**全面更新**。併せて、削除した default_theme/gradients の生成元 `scripts_build/build_theme.gd`・`build_gradients.gd`（スコープ外だが孤立）も承認の上で削除。
- **想定外**: `.png` は git 追跡済みだが対の `.png.import` は**未追跡**だった（git rm では消えず孤立）。`rm -rf`/`rm -f` で物理削除して対処。claude_design ツリーも追跡104＋未追跡51の混在だった。

### 削除実績
- git 追跡削除: 181 ファイル（docs/design/claude_design 104＋assets 系 75＋scripts_build 2）＋未追跡 .import 多数。
- 残アセット: 37 ファイル（.import除く）＝ fonts5＋OFL / sumi_theme.tres / sumineko_*6＋ghost_placeholder / backgrounds bg_*7 / buttons3 / badges stamp_shuin / branding5 / CREDITS。すべて「現行sumi使用 or 法的必須 or 構造」。
- 検証: import エラー0 / home実起動キャプチャ正常（文字化けなし）/ 主要3シーン load OK / GUT 82/82 passed。

### 学んだこと
- **Godot の .import は追跡外運用のことがある** → アセット削除時は `git rm` だけでなく `.png.import` の物理削除（ディレクトリ単位なら `rm -rf`）まで必須。次回は最初から `git rm` 後に対象ディレクトリの `rm -rf` をワンセットにする。
- substring 衝突（`washi_base` ↔ `bg_washi_base`）は basename grep で実際に衝突し得たが、`assets/backgrounds`（旧）と `textures/backgrounds/bg_*`（現行）はパスで明確に分離でき誤削除回避。
- リソースID名（`id="2_catboy"`）やSubResource名（`SBF_cd_bar_fill`）は実パス参照と別物。grep ヒット＝参照ではない点に注意。

### 次回への改善提案
- repository-structure.md は sumi リブランドの他セクション（scripts/ や docs/design/ の説明）にもまだ陳腐化が残る可能性。別タスクで全体整合レビューを推奨。
- `docs/design/patterns.md` に削除済み build_theme/build_gradients への参照が残存（本タスクのスコープ外で未修正）。design doc 整理タスクで対応すべき。
