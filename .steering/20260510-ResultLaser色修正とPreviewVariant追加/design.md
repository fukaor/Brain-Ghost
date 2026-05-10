# 設計 — Result Laser 色修正 + Rule Explain Preview Variant 追加

## A. side_laser 色修正

### 変更ファイル

`scripts/ui/ghost_7ban_shobu_view.gd`

### 変更内容

`_spawn_burst_and_lasers` の win=false 分岐:

```gdscript
# Before
hot = Color(0.898, 0.353, 0.353, 1.0)  # RED_400
mid = Color(0.78, 0.231, 0.231, 1.0)   # RED_500

# After
hot = Color(0.533, 0.588, 0.690, 1.0)  # INK_60 相当のグレー
mid = Color(0.290, 0.333, 0.439, 1.0)  # INK_40 相当のグレー
```

### 影響範囲

- TapBurst（中央バースト）も hot/mid を継承するため自動でグレーに
- SideLaser_left（YOU 側横レーザー）もグレーに
- SideLaser_right（GHOST 側）は cyan のままで変更なし
- lane_view 側の `_draw_you_star` の `COL_YOU_GLOW` (gold) は player color のため変更なし

## B. Preview Variant 追加

### 変更ファイル

1. `scripts/ui/rule_step_preview.gd` — variant 描画追加
2. `scripts/ui/rule_explain_controller.gd` — RULES dict 更新

### 新 variant 一覧

#### flash_calc 系

| variant | 描画 | 対応 step |
|---|---|---|
| `flash_number` | 中央大字「7」+ 残像「3」「5」+ FLASH eyebrow | 1. 覚える |
| `calc_sum` | 上に「3 + 5」、中央に「= ?」 + glow | 2. 計算する |
| `calc_input` | 3×3 テンキー（7 がハイライト）+ OK ピル | 3. 打ち込む |

#### sequence_memory 系

| variant | 描画 | 対応 step |
|---|---|---|
| `grid_show` | 3×3 グリッドの対角 3 パネルが番号付きで光って線で繋がる | 1. 光る順を覚える |
| `grid_tap` | 3×3 グリッド + 中央パネル光 + TAP! | 2. 同じ順でタップ |
| `grid_grow` | Lv1 (3 lit) → Lv5 (7 lit) の段階比較 | 3. ステージを伸ばせ |

### 実装の要点

- `@export_enum` の選択肢を 9 種（既存 3 + 新 6）に拡張
- `_draw()` のレール / GATE 描画は ghost_7ban variant 限定に条件分岐:
  ```gdscript
  var has_rail: bool = variant in ["ready", "tap", "compare"]
  if has_rail:
      draw_line(...)  # rail
      draw_line(...)  # gate
  ```
- ヘルパ関数を追加: `_draw_simon_grid` / `_draw_growth_step`
- 共通の round_label / progress dots は全 variant で描画継続

## キャプチャ検証

`xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 --path . --script tools/snap_all.gd` で 7 画面再生成。`.steering/20260502-MidnightCatリデザイン/captures/` を上書き。
