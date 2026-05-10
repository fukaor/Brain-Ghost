# 設計書 — Midnight Cat (v3) 全面リデザイン

## アーキテクチャ概要

UI レイヤのみの差し替え。データレイヤ・サービスレイヤは温存する。

```
[シーン] -- theme_type_variation --> [default_theme.tres / mc_*]
   |                                       |
   +---- 色定数 ---> [color_palette.gd v3]
   +---- 明朝 -----> [NotoSerifJP-Bold.otf]
   +---- 黒猫 -----> [Sleek_black_cat_with_icy_accents.png]

[home.tscn] --press CTA--> GameManager.start_game("ghost_7ban_shobu")
   |                              |
   |                              v
   |                       [rule_explain.tscn] --press スタート-->
   |                              ↑                                  GameManager.on_rule_explain_confirmed()
   |                              |                                              |
   |                              | (set_rule(game_type) で                        v
   |                              |  ghost_7ban_shobu / reflex_tap /         [countdown.tscn]
   |                              |  flash_calc / sequence_memory                 |
   |                              |  などに切替)                                   v
   |                              |                                  [scenes/games/ghost_7ban_shobu/...]
   v                              |
[scenes/ui/game_list.tscn] --pick--+
```

## コンポーネント設計

### 1. ColorPaletteUtil v3 (Midnight Cat)

**責務**:
- 漆黒 void / シアン / 金 / グレー の色定数を一元管理
- 旧 v2 定数を alias として温存し、breaking change を起こさない

**実装の要点**:
- `BACKGROUND = #000` を最上位とし、`SURFACE_LOW/MID/HIGH/GLOW` で elevation を作る（border 禁止）
- `RED` 定数は引き続き定義しない（負け＝NEUTRAL_GRAY）
- `PRIMARY_BLUE` 等の旧定数は `PRIMARY_CYAN` の alias として残し、ファイル単位で段階的に書き換え

### 2. default_theme.tres `mc_*` バリアント群

**責務**:
- 各画面で再利用可能な dark+mincho バリアントを Theme に集約

**追加バリアント**:
| 名前 | 用途 |
|---|---|
| `mc_void` / `mc_card` / `mc_score_pill` / `mc_streak_ribbon` / `mc_speech` / `mc_step_card` | 各種 PanelContainer |
| `mc_cta_glow` | シアン発光ピル (Button) |
| `mc_back_btn` | ヘッダーチップ（戻る等） |
| `mc_h1_lg` / `mc_h1` / `mc_h2` | 明朝見出し |
| `mc_subtitle` / `mc_body` / `mc_body_strong` / `mc_caption` | 文字 |
| `mc_score_value` / `mc_score_unit` / `mc_score_delta` | スコア表示 |
| `mc_brain_age` / `mc_brain_age_label` | 脳年齢 |
| `mc_streak_text` / `mc_step_index` / `mc_step_title` / `mc_step_body` | 補助 |
| `mc_icon` / `mc_icon_cyan` / `mc_link` | アイコン・リンク |

### 3. RadarChart (新規 Control)

**責務**:
- 6 軸レーダーチャートを `_draw()` でカスタム描画

**実装の要点**:
- 4 リング + 6 軸 + 値ポリゴン + 頂点ドット + 軸ラベル
- `set_values(Array)` で 0.0..1.0 の 6 値を渡す
- ラベルは `labels` プロパティ（既定: 計算力 / 記憶力 / 注意力 / 反射速度 / 観察力 / 判断力）

### 4. RuleStepPreview (新規 Control)

**責務**:
- ルール説明画面のステップごとのミニ図を `_draw()` で描画

**variant**:
- `"ready"` — 第N戦/7 ヘッダ + 進捗ドット + YOU/GHOST 球 + 中央ゲート
- `"tap"` — 中央発光 + "TAP!" テキスト
- `"compare"` — YOU 球 + GHOST 球 + ms 値（ゲート基準）

**実装の要点**:
- `_ready()` で `custom_minimum_size` を上書きしない（scene 側の指定を尊重）

### 5. RuleExplain（再構築・データドリブン）

**責務**:
- ゲームに依存せず、`set_rule(game_type)` で表示内容を差し替えられる

**RULES Dict スキーマ**:
```gdscript
{
    "<game_type>": {
        "title": "<明朝大見出し>",
        "ability_label": "鍛える能力：<能力軸>",
        "steps": [
            {
                "index": "1.",
                "title": "<ステップ見出し>",
                "body": "<2-3 行の説明>",
                "preview_variant": "ready" | "tap" | "compare",
            },
            { ... step 2 ... },
            { ... step 3 ... },
        ],
    },
}
```

**新ゲーム追加手順**:
1. `RULES` に `<game_type>` エントリを 1 件追加
2. 必要なら `rule_step_preview.gd` に新 `variant` を実装（既存 3 種で足りない場合のみ）
3. `GameManager.GAME_SCENES` に game_type を登録すれば、home からの遷移が自動的に動く

### 6. ghost_7ban_shobu — 1 レーン正面衝突への書き換え（最大の変更）

**責務**:
- promo `game_tap_touch.png` 仕様：YOU 左→右 / GHOST 右→左 / 中央 GATE / 5 種レーン形状ローテ

**新しい構造**:

```
Ghost7BanShobu (Control, root)
├─ VoidBg (ColorRect, #000)
├─ NebulaBg (TextureRect, radial gradient)
├─ TapArea (Control, full screen, mouse_filter=1)
├─ Hud (top, 第N戦/7 + 進捗ドット + YOU 0 - 0 GHOST)
├─ Playfield (Control)
│   ├─ Lane (Node2D, _draw() で曲線レーンを描画)
│   ├─ YouOrb (Node2D, gold glow)
│   ├─ GhostOrb (Node2D, cyan glow)
│   └─ GateLine (vertical line + glow at x = width / 2)
├─ AnnounceLabel (large mincho, "READY" / "START")
├─ ResultOverlay (mincho "PERFECT WIN" 等 + ms 数値 + GATE 補助線)
└─ ReadyOverlay (現状の Ready phase をそのまま維持)
```

**ゲームロジック (`ghost_7ban_shobu.gd` 改修)**:

```gdscript
const TOTAL_ROUNDS := 7
const LANE_SHAPES := ["line", "s_curve", "sine_wave", "zigzag", "arc"]

# CFG_BASE 各 round に lane_shape を追加（直線→S→波→ジグザグ→弧→直線→…ローテ）
const CFG_BASE: Array[Dictionary] = [
    {"move": 2200, "pre": 1500, "shape": "line"},
    {"move": 2000, "pre": 1200, "shape": "s_curve"},
    {"move": 1500, "pre": 1000, "shape": "sine_wave"},
    {"move": 1200, "pre":  900, "shape": "zigzag"},
    {"move": 1000, "pre":  800, "shape": "arc"},
    {"move":  900, "pre":  700, "shape": "line"},
    {"move":  900, "pre": 1000, "shape": "s_curve"},
]

# 進行度 t∈[0,1] からレーン上の (x, y) を計算
static func lane_position(shape: String, t: float, size: Vector2) -> Vector2

# 状態：
# - move_started_ms: 両者同時発進
# - youGateTime / youTapT: ユーザがタップした時刻と進捗
# - ghostOffsetMs: ゴースト判定オフセット (CFG_BASE で決まる、常に固定値)
# - ghostStopT = 0.5 + ghostOffsetMs / move_ms (停止位置)
```

**判定**:
- ユーザがタップ → `youTapMs = (now - moveStart_ms)` を記録
- `youDeltaMs = abs(youTapMs - move_ms / 2)` (ゲート時刻からの差)
- ghost は `ghostDeltaMs = abs(ghostOffsetMs)` (固定)
- `youDeltaMs < ghostDeltaMs` → YOU 勝利

**Result 表示**:
- 爆発位置 = `lane_position(shape, youTapT, size)` （**タップ位置**）
- ゲート補助線：画面中央 (x = w/2) に金縦線
- ms ラベル: YOU は爆発点の **上**、GHOST は爆発点と GHOST 停止位置の **下**
- GHOST 停止位置: `lane_position(shape, 1 - ghostStopT, size)` （右からの逆走で停止）

**動的可視化（プレイ中）**:
- フレーム毎に `t = (now - moveStart_ms) / move_ms` を計算
- YOU orb 位置 = `lane_position(shape, t, size)`
- GHOST orb 位置 = `lane_position(shape, 1 - t, size)` （ただし `t > ghostStopT` で停止）
- レーンは半透明 cyan で `_draw()` 描画

## データフロー

### ホーム → 「今日のチャレンジ」 → ゴースト7番勝負
```
1. home.tscn の CTA 押下 → home_controller._on_cta_pressed()
2. GameManager.start_game("ghost_7ban_shobu")
3. _current_game_type = "ghost_7ban_shobu", scene_change → rule_explain.tscn
4. rule_explain_controller._ready() → set_rule(_current_game_type)
   → RULES["ghost_7ban_shobu"] を読み 3 ステップを描画
5. スタート押下 → GameManager.on_rule_explain_confirmed()
6. scene_change → countdown.tscn
7. countdown 終了 → GameManager.on_countdown_finished()
8. scene_change → ghost_7ban_shobu.tscn
9. ゲーム終了 → BaseGame.game_finished → GameManager.on_game_finished_handler()
10. scene_change → individual_result.tscn → home.tscn
```

## エラーハンドリング戦略

- 未登録 game_type で `set_rule()` 呼ばれた場合 → ghost_7ban_shobu の RULES に fallback（既存実装維持）
- DataStore に config / streak が無い場合 → モック値を表示
- レーン形状計算で `t` が範囲外 → `clamp(t, 0, 1)`

## テスト戦略

### ユニットテスト
- `lane_position()` が各 shape で `t=0/0.5/1` の境界値で期待座標を返すか
- `youDeltaMs / ghostDeltaMs` の比較で正しい勝者を返すか

### 統合テスト
- home → rule → countdown → ghost_7ban_shobu → result の遷移
- 既存 GhostData.save_play / load_round_medians との互換維持
- 5 ラウンドの shape ローテが期待通り

### 視覚確認
- xvfb-run + screenshot による各画面 PNG キャプチャを `.steering/.../captures/` に保存
- promo 画像との目視比較

## 依存ライブラリ

- 新規追加なし（Noto Serif JP は font asset）

## ディレクトリ構造（変更点）

```
assets/fonts/
  + NotoSerifJP-Bold.otf
  + NotoSerifJP-Bold.otf.import

scripts/
  utils/
    color_palette.gd                  ← v3 書き換え（完了）
  ui/
    radar_chart.gd                    ← 新規（完了）
    rule_step_preview.gd              ← 新規（完了）
    home_controller.gd                ← 全面書き換え（完了）
    rule_explain_controller.gd        ← データドリブン書き換え（完了）
    ghost_7ban_shobu_view.gd          ← 1 レーン化リファクタ（着手）
  games/
    ghost_7ban_shobu/
      ghost_7ban_shobu.gd             ← 1 レーン仕様に変更（着手）

scenes/
  main/
    home.tscn                         ← 再構築（完了）
  ui/
    rule_explain.tscn                 ← 再構築（完了）
  games/
    ghost_7ban_shobu/
      ghost_7ban_shobu.tscn           ← 1 レーン化（着手）

assets/themes/
  default_theme.tres                  ← mc_* バリアント追加（完了）

docs/design/
  + claude_design/                    ← bundle 展開済（完了）

.steering/20260502-MidnightCatリデザイン/
  requirements.md
  design.md
  tasklist.md
  captures/                           ← 各画面キャプチャ
```

## 実装の順序

1. ステアリングファイル作成（このフェーズ）
2. ghost_7ban_shobu.gd を 1 レーン仕様に書き換え（lane_position / shape / 判定）
3. ghost_7ban_shobu.tscn を 1 レーン構造に再構築（Lane / YouOrb / GhostOrb / GateLine）
4. ghost_7ban_shobu_view.gd を新シーンに合わせて書き換え
5. 既存 BaseGame / GhostData との互換確認（PlayLog 形式）
6. rule_explain フォーマット仕様を `docs/design/patterns.md` に追記
7. xvfb-run で各画面キャプチャを取得、`.steering/.../captures/` に保存
8. 振り返り記録

## セキュリティ考慮事項

- 該当なし（UI 層のみ）

## パフォーマンス考慮事項

- レーン形状の `_draw()` は `queue_redraw()` をフレーム単位で呼ぶため、必要に応じて Polyline 更新を最小化
- Web 版の GL Compatibility で動作するよう、シェーダ・ParticleSystem は使用しない（既存方針）

## 将来の拡張性

- レーン形状を 5 種から増やすには `LANE_SHAPES` と `lane_position()` に追加するだけ
- rule_explain は新ゲーム追加時 RULES に 1 エントリ追加するだけで対応
- mc_* バリアントは他画面（個別結果 / 全体結果 / カウントダウン等）にもそのまま流用可能
