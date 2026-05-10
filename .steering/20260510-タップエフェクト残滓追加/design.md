# 設計 — ゴースト7番勝負 タップエフェクト残滓

## 1. 新規エフェクト `tap_residue.gd`

**ファイル**: `scripts/ui/effects/tap_residue.gd`

**役割**: タップ位置から放射状にダスト粒子を散布し、ゆっくりドリフトしながら 1700ms かけてフェード。promotion `game_tap_touch.png` の余韻を再現。

### パーティクル仕様

- 個数: 80
- 全体寿命: 1700ms（個々の粒子は 800〜1700ms の範囲で揺らぎ）
- 出現遅延: 0〜220ms 内で個別ジッタ（一斉ではなく波状に出現）

### 粒子クラス分け（roll で分布）

| 確率 | サイズ | 不透明度 | ハロー |
|---|---|---|---|
| 45% | 1.2〜1.9 | 0.50〜0.75 | なし |
| 35% | 1.9〜2.9 | 0.70〜0.90 | あり |
| 20% | 2.8〜4.2 | 0.85〜1.00 | あり、`hot_color` |

### 動き

- 初期距離: 0〜200px（pow(u, 0.55) で外側にやや偏らせる）
- 半径方向ドリフト: 10〜48px/sec（個別揺らぎ）
- 垂直方向 sway: 1.5〜4.5px の正弦揺れ（位相も個別）
- 出現フェーズ（0〜18%）でフェードイン、残り 82% でフェードアウト

### 色

- `hot_color` / `mid_color` は外部から設定（win/lose で hot/mid を継承）
- 大粒子は `hot_color`、それ以外は `mid_color`

## 2. `_draw_you_star` の強化（24 ray + ジッタ）

**ファイル**: `scripts/ui/ghost_7ban_lane_view.gd`

### 変更前

- 4 長軸（上下左右、長さ 78px、幅 6px）
- 4 短対角（長さ 28px、幅 4px、α=0.7）
- 計 8 本、完全対称

### 変更後

- 4 主軸（上下左右、78px、幅 6px）— 維持
- **16 副軸（22.5° おき、5.6° オフセットで主軸を避ける）**
  - 偶数番（中尺）: `RAY_LONG_LENGTH * 0.55〜0.85`、幅 3.5〜5.0、α=0.7
  - 奇数番（短尺）: `RAY_SHORT_LENGTH * 0.7〜1.4`、幅 2.0〜3.5、α=0.55
- 長さ・太さは `sin(i * 7.91 + 1.7) * 0.5 + 0.5` の決定論ハッシュでジッタ（同じ ray index は常に同じ表情）

合計 **20 本のレイ**（主軸 4 + 副軸 16）。promotion の不揃いなスターバーストに近づける。

## 3. view 配線

**ファイル**: `scripts/ui/ghost_7ban_shobu_view.gd`

```gdscript
# 残滓ダスト粒子（promotion の余韻）
var residue := TapResidueScript.new()
residue.hot_color = hot
residue.mid_color = mid
residue.size = _effects_layer.size
residue.position = Vector2.ZERO
_effects_layer.add_child(residue)
residue.start(hit_pos)
```

`_spawn_burst_and_lasers` 内、TapBurst の直後に挿入。win/lose で hot/mid を継承する既存ロジックに乗る。

## 4. snap_g7_result の timing 調整

`tools/snap_g7_result.gd`:

```gdscript
# Before
await _wait_sec(0.6)   # tap timing → 600ms into moving = FLYING (too early)
await _wait_sec(0.25)  # capture too early, residue not yet bloomed

# After
await _wait_sec(1.1)   # 1100ms = move/2 で center 付近 → GREAT
await _wait_sec(0.55)  # 残滓粒子が満開のタイミング
```

## 5. 描画レイヤ重ね順（変更なし、既存通り）

下→上:
1. lane_view（StarLayer 背景 → Lane → GATE → orbs → result 時 `_draw_you_star`）
2. effects_layer（TapBurst → **TapResidue（新）** → SideLaser×2）
3. HUD / Announce
