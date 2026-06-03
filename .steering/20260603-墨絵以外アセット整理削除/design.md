# 設計: 削除/保持の分類と手順

## 参照監査の結論（2026-06-03 時点）
`scenes/ scripts/ assets/themes/ project.godot export_presets.cfg` を対象に、各アセットの basename/パスで全文検索した結果。

### 🟢 KEEP（現行 sumi が使用 / 法的必須 / 構造）
| パス | 理由 |
|---|---|
| `assets/fonts/*`（5フォント＋`OFL.txt`） | 全フォント LIVE。OFL.txt は OFL ライセンス本文（法的必須） |
| `assets/themes/sumi_theme.tres` | project.godot の theme/custom（現行テーマ） |
| `assets/characters/sumineko_{normal,fight,double,running,sleep,touch}.png` ＋ `ghost_placeholder.svg` | LIVE（マスコット） |
| `assets/textures/backgrounds/bg_*.png`（bg_home/onboarding/play/result_lose/result_win/washi_base/**bg_rule**） | bg_rule 以外は LIVE。bg_rule は未配線だが sumi ブランド背景のため保持 |
| `assets/textures/buttons/btn_{accent,primary,secondary}.png` | sumi_theme が参照 |
| `assets/textures/badges/stamp_shuin.png` | ghost_record_strip が使用 |
| `assets/branding/*` | アプリアイコン/ロゴ（ブランド資産） |
| `assets/CREDITS.md` | ライセンス台帳（規約上必須） |
| `assets/images/`・`assets/sounds/`（中身は `.gitkeep` のみ） | 将来の音/画像用の構造プレースホルダ。残す |

### 🗑 DELETE — Tier 1（明確に非墨絵 / 旧デザインシステム）
| 対象 | 理由 | 概算 |
|---|---|---|
| `docs/design/claude_design/`（ツリーごと） | 旧デザイン探索の重複ツリー（独自 CREDITS 含む）。現行と無関係 | 31M |
| `assets/themes/default_theme.tres` | 旧テーマ。project は sumi_theme を使用、参照0 | — |
| `assets/textures/gradients/`（ディレクトリごと） | グラスモーフィズム旧UI素材。default_theme 専用で、削除すると孤立 | 124K |
| `assets/backgrounds/`（`washi_*.png` ディレクトリごと） | `assets/textures/backgrounds/bg_*` に置換済みの旧背景 | 16M |
| `assets/characters/{catboy_*, Defensive_*, Minimalist_*, Sleek_*, Sleeping_*, ghost_seirei}.png` | 非 sumineko の旧キャラ探索（catboy 別案・英語名生成物） | — |
| `assets/icons/`（`hitodama_lv*.png` ディレクトリごと） | 旧アイコンセット。参照0 | 1.5M |

### 🗑 DELETE — Tier 2（墨絵風だが design.md で「汚染パーツ」認定・置換済み・参照0）
design.md（ホームリデザイン）で texture 使用禁止と明記し、`_draw()`/StyleBox/Material Symbols に置換済みのもの。
| 対象 | 置換先 | 概算 |
|---|---|---|
| `assets/textures/frames/`（frame_ink_border*） | StyleBoxFlat | 2.2M |
| `assets/textures/decorations/`（arrow/divider/*_ref） | `_draw()` / SumiDivider | 380K |
| `assets/textures/bars/`（bar_fill*/stamp_row_ref） | ProgressBar/StyleBox | 404K |
| `assets/textures/game_icons/`（game_icon_*・_art） | Material Symbols（B-8で撤去済み） | 3.1M |
| `assets/textures/badges/` の `stamp_shuin.png 以外`（badge_*, mark_win, mark_lose, icon_lock, badge_tier_frame, badge_new*） | Material Symbols / 未使用 | — |

> Tier 2 は「墨絵以外」ではなく「墨絵だが破棄済み」。実害なく軽量化できるため削除推奨。残したい場合はこの節をスキップ可。

## 手順方針
1. **再監査**（実行時の真実で確認。substring衝突に注意）。
2. 重複docツリー → Tier1 → Tier2 の順に `git rm -r`（`.import`/`.uid` も巻き込む）。
3. `godot --headless --import` で .godot 再生成・エラー確認。
4. **検証**: home 実起動キャプチャ（`tools/capture_home_live.tscn`）＋ `scripts_build/run_unit_tests.sh`（82期待）＋ 主要シーン load_check。
5. CREDITS.md / repository-structure.md の記述整合（必要なら doc 承認後更新）。
6. 独立コミット化。

## ロールバック
全候補は git 追跡済み。誤削除時は `git restore -- <path>`（コミット前）/ `git checkout <commit> -- <path>`（後）で復元。
