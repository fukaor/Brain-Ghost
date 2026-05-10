# タスクリスト — Result Laser 色修正 + Rule Explain Preview Variant 追加

## A. side_laser 色修正

- [x] `scripts/ui/ghost_7ban_shobu_view.gd` の `_spawn_burst_and_lasers` 内 lose 色を RED → INK_60/INK_40 に変更
- [x] コメントで「GDD ネガ色禁止準拠」を明記
- [x] xvfb キャプチャで grayscale 化を確認（`ghost_7ban_shobu_result.png`）

## B. flash_calc 用 variant 追加

- [x] `scripts/ui/rule_step_preview.gd` に variant `flash_number` / `calc_sum` / `calc_input` を実装
  - [x] `flash_number`: 中央大字「7」+ 残像「3」「5」+ FLASH eyebrow
  - [x] `calc_sum`: 「3 + 5」+ 中央「= ?」+ glow
  - [x] `calc_input`: 3×3 テンキー + OK ピル（「7」をハイライト）
- [x] `@export_enum` を 9 種に拡張
- [x] レール/GATE 描画を `has_rail` で条件分岐

## C. sequence_memory 用 variant 追加

- [x] `scripts/ui/rule_step_preview.gd` に variant `grid_show` / `grid_tap` / `grid_grow` を実装
  - [x] `grid_show`: 3×3 グリッドの対角 3 パネル光 + 順序矢印 + 番号
  - [x] `grid_tap`: 3×3 グリッド + 中央光 + TAP!
  - [x] `grid_grow`: Lv1 (3 lit) → Lv5 (7 lit) の段階比較
- [x] ヘルパ `_draw_simon_grid` / `_draw_growth_step` を追加

## D. RULES dict 更新

- [x] `rule_explain_controller.gd` の `RULES["flash_calc"]["steps"][i]["preview_variant"]` を新 ID に差し替え
- [x] `RULES["sequence_memory"]["steps"][i]["preview_variant"]` を新 ID に差し替え
- [x] ghost_7ban_shobu の既存 variant はそのまま温存

## E. キャプチャ検証

- [x] `tools/snap_all.gd` を実行し 7 画面を再生成
- [x] `rule_explain_flash_calc.png` の 3 ステップが新 variant に置き換わっていることを確認
- [x] `rule_explain_sequence_memory.png` の 3 ステップが新 variant に置き換わっていることを確認
- [x] `rule_explain_ghost_7ban_shobu.png` の既存 variant がリグレッションしていないことを確認
- [x] `ghost_7ban_shobu_result.png` の負け側ラインがグレーに変わっていることを確認

## F. コミット

- [x] `44d2d8c fix: 負け色を赤→グレーに修正 + ルール説明 preview をゲーム別に` で 10 files 変更（+143/-18）

## 振り返り

- ステアリングファイルを着手時に書かず、後追いで作成する形になってしまった（ユーザから指摘あり、メモリに教訓として保存済み）
- 全タスクは完了しコミット済み。後続作業（タップエフェクト残滓）は別ステアリング `20260510-タップエフェクト残滓追加/` で管理
