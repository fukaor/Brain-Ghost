# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

スキップ時は必ず理由を明記:
```markdown
- [x] ~~タスク名~~（実装方針変更により不要: 具体的な技術的理由）
```

---

## フェーズ1: アセット移植

- [x] `assets/characters/` に新キャラ 6 枚をコピー + リネーム
  - [x] `cat_normal.png` → `sumineko_normal.png`
  - [x] `cat_fight.png` → `sumineko_fight.png`
  - [x] `cat_running.png` → `sumineko_running.png`
  - [x] `cat_double.png` → `sumineko_double.png`
  - [x] `cat_tauch.png` → `sumineko_touch.png` (タイポ訂正)
  - [x] `cat_sleep.png` → `sumineko_sleep.png`
- [x] `assets/backgrounds/` ディレクトリ新設
- [x] `assets/backgrounds/` に和紙背景 7 枚をコピー + リネーム
  - [x] `01_全画面共通テクスチャ.png` → `washi_base.png`
  - [x] `02_ホーム画面.png` → `washi_home.png`
  - [x] `03_プレイ中.png` → `washi_play.png`
  - [x] `04_勝利リザルト.png` → `washi_result_win.png`
  - [x] `05_敗北リザルト.png` → `washi_result_lose.png`
  - [x] `06_チュートリアル.png` → `washi_tutorial.png`
  - [x] `07_プロモ素材.png` → `washi_promo.png`
- [x] `godot --headless --import` で `.import` 自動生成 + import エラーゼロ確認

## フェーズ2: ColorPaletteUtil v4 化

- [x] `scripts/utils/color_palette.gd` のドックコメントを v4「Sumi Ghost」に更新
- [x] 新パレット v4 ブロックを追加
  - [x] 和紙系 3 階層（WASHI_BASE / WASHI_PANEL / WASHI_SHADE）
  - [x] 墨系 4 階層（SUMI_INK / SUMI_MID / SUMI_LIGHT / SUMI_DIM）
  - [x] 鬼火青系 3 階層（ONIBI_BLUE / ONIBI_GLOW / ONIBI_DEEP）
  - [x] アクセント 3 種（GOLD_AGED / JADE_INK / GHOST_INK）
- [x] 旧 v3 定数を新値で alias 化
  - [x] BG_* / INK_* / CYAN_* / GOLD_*
  - [x] PRIMARY_* / SURFACE_* / ON_SURFACE / BACKGROUND / OUTLINE
  - [x] POSITIVE_GREEN → JADE_INK
  - [x] POSITIVE_GOLD → GOLD_AGED
  - [x] NEUTRAL_GRAY → GHOST_INK
- [x] win_color / lose_color / best_score_color の戻り値が新値で動作することを確認
- [x] 禁止色ルール（赤）のドックコメントを維持

## フェーズ3: Theme リフォーム

- [x] `assets/themes/default_theme.tres` を読んで色指定箇所 182 件を特定
- [x] StyleBoxFlat / fonts / colors を v3→v4 マッピングで置換
  - [x] 黒系背景（Color(0, 0, 0, *), Color(0.04 系)） → 和紙系
  - [x] CYAN_400 系（Color(0.435, 0.706, ...)） → ONIBI_BLUE
  - [x] 中間白（Color(0.886, 0.91, ...)） → WASHI_PANEL or SUMI_INK
  - [x] ゴールド（Color(0.98, 0.8, ...)） → GOLD_AGED
- [x] theme_type_variation 名は維持（mc_cta_glow / glass_bubble など）
- [x] Godot エディタで開いてリソースエラーが出ないことを確認

## フェーズ4: ハードコード色定数の置換

- [x] `scripts/ui/components/card.gd` の COLOR_* を v4 値に置換
  - [x] BACK_BG / BACK_BORDER
  - [x] FRONT_BG / FRONT_BORDER
  - [x] MATCH_FLASH_BG / MATCH_FLASH_BORDER → JADE_INK 系
  - [x] MISMATCH_FLASH_BG / MISMATCH_FLASH_BORDER → SUMI_DIM 系
  - [x] MATCHED_BG / MATCHED_BORDER
- [x] `scripts/ui/rule_step_preview.gd` の COLOR_* を v4 値に置換
  - [x] COLOR_RAIL / COLOR_GATE
  - [x] COLOR_GLOW_GOLD / COLOR_GLOW_CYAN
  - [x] COLOR_TEXT / COLOR_DIM
  - [x] COLOR_PANEL_OFF / COLOR_PANEL_ON
  - [x] STROOP_RED / BLUE / GREEN / YELLOW は維持（ゲーム性のため）
- [x] `scripts/ui/individual_result_controller.gd` の COLOR_* を v4 値に置換
  - [x] COLOR_GOLD / COLOR_CYAN300 / COLOR_CYAN100
  - [x] COLOR_INK95 / INK80 / INK60
  - [x] COLOR_GRAY_DIM
- [x] `scripts/ui/effects/glow_cta.gd` のグロー色を ONIBI_BLUE / GOLD_AGED に
- [x] `scripts/ui/effects/star_layer.gd` を無効化（render を skip するフラグ追加 or _draw 内 return）
- [x] `scripts/ui/stroop_view.gd` の `Color(0.067, 0.094, 0.153, ...)` を WASHI_SHADE 系に置換
- [x] `scripts/ui/components/number_cell.gd` の `COLOR_NORMAL_BG` を WASHI_PANEL 系に置換
- [x] その他 `grep "Color(0.04, 0.08\|Color(0.067, 0.094\|Color(0.043, 0.071" scripts/` で見つかる残存箇所をすべて置換

## フェーズ5: シーン背景の和紙化

- [x] 主要 UI シーンに WashiBackground (TextureRect) を配置
  - [x] `scenes/main/launch.tscn` → washi_base.png
  - [x] `scenes/main/home.tscn` → washi_home.png
  - [x] `scenes/ui/game_list.tscn` → washi_base.png
  - [x] `scenes/ui/rule_explain.tscn` → washi_tutorial.png
  - [x] `scenes/ui/rule_explain_landscape.tscn` → washi_tutorial.png
  - [x] `scenes/ui/countdown.tscn` → washi_base.png
  - [x] `scenes/ui/countdown_landscape.tscn` → washi_base.png
  - [x] `scenes/ui/individual_result.tscn` → washi_result_win.png（初期値）
- [x] ゲームシーンに washi_play.png を配置
  - [x] `scenes/games/flash_calc/flash_calc_home.tscn`
  - [x] `scenes/games/flash_calc/flash_calc_play.tscn`
  - [x] `scenes/games/sequence_memory.tscn`
  - [x] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn`
  - [x] `scenes/games/number_search/number_search.tscn`
  - [x] `scenes/games/card_match/card_match.tscn`
  - [x] `scenes/games/stroop/stroop.tscn`
- [x] 各シーンの StarLayer ノードを削除または `visible = false` で非表示化
  - [x] scenes/main/launch.tscn
  - [x] scenes/main/home.tscn
  - [x] scenes/ui/game_list.tscn
  - [x] scenes/ui/rule_explain.tscn
  - [x] scenes/ui/rule_explain_landscape.tscn
  - [x] scenes/ui/countdown.tscn
  - [x] scenes/ui/countdown_landscape.tscn
  - [x] scenes/ui/individual_result.tscn
  - [x] scenes/games/flash_calc/flash_calc_home.tscn
  - [x] scenes/games/flash_calc/flash_calc_play.tscn
  - [x] scenes/games/sequence_memory.tscn
  - [x] scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn
  - [x] scenes/games/number_search/number_search.tscn
  - [x] scenes/games/card_match/card_match.tscn
  - [x] scenes/games/stroop/stroop.tscn
- [x] `individual_result_controller.gd` で勝敗別に WashiBackground.texture を差し替えるロジック追加
  - [x] NEW BEST / WIN 系 → washi_result_win.png
  - [x] NICE TRY → washi_result_lose.png
  - [x] IMPROVED / NICE START → washi_result_win.png（明るい方）

## フェーズ6: マスコット参照置換

- [x] `scenes/main/home.tscn` の `catboy_electric.png` → `sumineko_normal.png`
- [x] `scenes/ui/countdown.tscn` の `catboy_electric.png` → `sumineko_fight.png`
- [x] `scenes/ui/countdown_landscape.tscn` の `catboy_electric.png` → `sumineko_fight.png`
- [x] `scenes/ui/individual_result.tscn` の `catboy_electric.png` → `sumineko_normal.png`
- [x] `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn` の `catboy_confident.png` → `sumineko_fight.png`
  - ※ ext_resource id=5_ghostcat 共有のため path 書き換えで 3 ノード同時更新
- [x] `grep "catboy_" scenes/ scripts/` で 0 件を確認

## フェーズ7: 検証

- [x] `godot --headless --quit-after 30` でパースエラー・インポートエラーなし
- [x] `bash scripts_build/deploy_android.sh` でビルド成功
- [x] 実機（moto g66j 5G）にデプロイ
- [x] スクリーンショット取得
  - [x] launch / home / game_list / rule_explain / countdown / play (任意 1 ゲーム) / individual_result (NEW BEST / WIN / NICE TRY ケース)
- [x] `washi_promo.png`（横長プロモ素材）が `assets/backgrounds/` に存在し、縦横比が崩れていないか目視確認
- [x] 6 ゲームを 1 回ずつプレイ完走（操作上の致命的問題が無いことを確認）

## フェーズ8: ドキュメント更新

- [x] `MEMORY.md` のマスコット情報を更新
  - [x] `project_mascot_catboy.md` → 内容を `sumineko` 設定に書き換え（ファイル名は維持してよい、本文を更新）
- [x] `docs/repository-structure.md` を更新
  - [x] `assets/backgrounds/` ディレクトリ追加を反映
  - [x] `assets/characters/sumineko_*` の追加を反映
- [x] `docs/development-guidelines.md` の色定数セクションを v4 に更新
- [x] スクリプトコメント / ドキュメント本文の「Midnight Cat」表記を整理（v3 履歴は残してよい）
- [x] 実装後の振り返り（このファイル下部）を記録

---

## 実装後の振り返り

### 実装完了日
2026-05-26

### 計画と実績の差分

**計画と異なった点**:
- `default_theme.tres` のリフォームを当初「個別 Edit 1 件ずつ」と計画したが、Rev 指摘を受けて sed 一括 + diff 目視に方針変更。1500 行 / 182 件を 3 パスで完遂
- WashiBackground のシーン配置は手動 Edit ではなく Python スクリプト (`/tmp/add_washi_bg.py`) で 15 シーン一括処理した

**新たに必要になったタスク**:
- 旧 Midnight Cat に当てはまらない navy/teal の細かい色 (`Color(0.157, 0.196, 0.275, 1)` 等) の追加置換
- スクリプトコメント内「Midnight Cat」表記を「Sumi Ghost (墨絵調)」に統一する作業 (10 ファイル)

**技術的理由でスキップしたタスク**: なし

### 学んだこと

**技術的な学び**:
- Godot 4 の `TextureRect.stretch_mode` は 0〜6 のみ。`KEEP_ASPECT_COVERED = 6`（事前レビューで Critical 修正済み）
- `--headless --quit-after` だけでは新規ディレクトリの import が走らないことがある。`--headless --import` を明示するか editor 起動が必要
- 大量の色置換は sed のシェル展開回避のため小数点完全一致パターンで実行する

**プロセス上の改善点**:
- ステアリング Rev で「stretch_mode = 7」のような構文エラーを事前に潰せたのは効果大
- アセットの命名規約（sumineko_*, washi_*）を最初に固めることで以降の置換タスクが一貫した

### 次回への改善提案
- アセット移植は `python3 + cp` でリネーム一括処理が確実
- color_palette.gd の v4 ブロック書き換えは新ファイル生成（Write）で済む — Edit より速い

### 不足ポーズの洗い出し（マスコット強化版ステアリングへの引き継ぎ）

実装中に判明した、現状の 6 ポーズでは表現しきれないマスコット状態（次ステアリングでユーザに作成依頼する候補）:

| 状態 | 用途 | 現状代替 | 追加要望 |
|---|---|---|---|
| `blink` | アイドル時のまばたき | normal 流用 | normal の目を薄く閉じたバリエーション 1 枚 |
| `yawn` | アイドル時のあくび | normal 流用 | 口を開けたあくびポーズ |
| `tail_flick` | アイドル時のしっぽフリック | normal 流用 | しっぽが反対側に振れているコマ |
| `eyes_only` | launch 演出（暗闇に目だけ光る） | normal 流用 | 黒背景 + 目（金 #C8A951）だけ光るシルエット |
| `celebrate_burst` | NEW BEST 時の最大演出 | fight 流用 | 鬼火が大量に舞う豪快ポーズ |
| `sad` | NICE TRY 結果用（赤禁止に配慮した「応援」表情） | double 流用 | しっぽが膨らみ気味で耳ペタの 1 枚 |
| `think` | IMPROVED 結果用 / 待機の応援 | normal 流用 | 前足を顎に当てる思案ポーズ |

※ 上記不足はマスコット強化版ステアリング（タスク #10）の「フェーズ0 アセット受け入れ」で扱う。
