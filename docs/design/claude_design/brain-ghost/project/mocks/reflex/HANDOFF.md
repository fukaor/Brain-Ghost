# ゴースト7番勝負 — Claude Code ハンドオフ

このフォルダの HTML モック (`ゴースト7番勝負.html`) を **実際の Godot 実装 (`fukaor/Brain-Ghost`)** に落とし込むための手順書。

---

## 1. このモックでロックした仕様

HTML 上で確定しているデザイン判断：

| 領域 | 決定事項 |
|---|---|
| **画面構成** | 横 892×412、上下 2 レーン + 中央 GHOST LINE |
| **READY 画面** | タイトル中央、SD キャラ（`ghost_seirei.png`）左下、吹き出し「今日は本気でいくよ」 |
| **HUD** | 左: `swords` + 第N戦/7 ／ 中央: YOU 0 - 0 GHOST ／ 右: 残り時間バー |
| **ANNOUNCE** | 方向矢印（←/→）＋「第 N 戦」＋「来るぞ」表示 1.5s |
| **MOVING** | 自レーンと ghost レーンで同時にターゲットが GHOST LINE へ |
| **Ghost 停止マーカー** | ghost が auto-fire した瞬間の X 座標に破線 + `+Npx` ラベル |
| **判定バケット** | PERFECT / GREAT / GOOD / LATE / FLYING / MISS |
| **結果カード** | 中央オーバーレイ、半透明 slate bg、★バッジ + Δt |
| **履歴ストリップ** | 画面下部、R1–R7 の勝敗 ○/× + 反応時間 ms |

仕様原本は `uploads/ghost-7ban-shobu-spec.md` (v1.0, 2026-04-22)。

---

## 2. Claude Code への渡し方

リポジトリ `fukaor/Brain-Ghost` の `develop` ブランチを開いて、Claude Code に以下を順に渡す：

### Step 1: コンテキスト読み込み
```
次の順で読んでから着手して：
1. docs/design/manifest.md
2. docs/design/patterns.md
3. docs/functional-design.md の A-10 (GhostCharacter)
4. scripts/utils/color_palette.gd
5. scenes/games/ 以下の既存ミニゲーム実装 1 本（参考に）
```

### Step 2: この HTML モックを共有
このフォルダをリポジトリに一時コピー、または URL で共有：
```
reference/mockup/ゴースト7番勝負.html  (+ variant-b.jsx, app.jsx, boot.js, ghost_seirei.png)
```

Claude Code に `variant-b.jsx` を読ませれば、**座標・配色・タイミング定数・判定しきい値・アニメカーブ**がすべて数値で取れる。

### Step 3: 実装依頼プロンプト（そのまま使える）

> `reference/mockup/variant-b.jsx` の挙動を Godot 4 シーンとして実装してほしい。
>
> - シーン: `scenes/games/ghost_7ban_shobu/ghost_7ban_shobu.tscn`
> - スクリプト: `scripts/games/ghost_7ban_shobu/ghost_7ban_shobu.gd`
> - ノード構成は `uploads/ghost-7ban-shobu-spec.md` §6 の図に従う
> - 色は `ColorPaletteUtil` から引く。ハードコード禁止
> - フォントは `assets/fonts/NotoSansJP-Bold.otf`、アイコンは Material Symbols
> - `GhostCharacter` autoload に `set_mode("duelist"/"companion")` と `set_dialogue()` を呼ぶ
> - `GhostData.save_play()` / `load_round_medians()` を `scripts/autoload/ghost_data.gd` 越しに使う
> - 判定しきい値・タイマー値は JSX の定数 (`MS_THRESHOLDS`, `MOVE_DURATION_MS` 等) をそのまま移植
>
> 既存ミニゲーム (`scenes/games/` 配下) のコード規約に合わせること。GUT テストも `scripts_build/run_unit_tests.sh` に載るよう書いてほしい。

### Step 4: アセット配置
- `ghost_seirei.png` はすでに `assets/characters/` 配下にある ✅
- 追加テクスチャは不要。背景の radial gradient は `CanvasLayer` + `ColorRect` の `shader_material` か、`assets/textures/gradients/` の既存 PNG で代替

---

## 3. JSX → GDScript 対応表

| JSX (このモック) | Godot 実装先 |
|---|---|
| `useState({phase, round, ...})` | `enum Phase { READY, ANNOUNCE, MOVING, RESULT, DONE }` + state var |
| `setTimeout(...)` | `SceneTreeTimer` or `create_tween()` |
| `requestAnimationFrame` ループ | `_process(delta)` |
| `style={{ background: ... }}` | `StyleBoxFlat` / `StyleBoxTexture` |
| `GhostOrb` / `PlayerTarget` コンポーネント | それぞれ `Sprite2D` + スクリプト |
| `GhostStopMarker` | `Line2D` + `Label` の静的配置 |
| `classifyDelta(dt)` | 同名関数をそのまま `.gd` に移植 |
| `@keyframes rb-slam` | `AnimationPlayer` の `result_card_in` |

判定しきい値 (`classifyDelta` の条件) は**そのままコピペでよい**。

---

## 4. やらないこと

- JSX の React ランタイムを Godot に持ち込まない（あくまで**設計書としての参照**）
- このモックの色を `Color(...)` で直書きしない → `ColorPaletteUtil` 経由
- SD キャラの差し替え禁止（`ghost_seirei.png` 一枚で通す）

---

## 5. 仕上げチェック

実装が上がったら以下をレビュー：

- [ ] 6 段階判定が HTML と同じ ms しきい値
- [ ] ghost 停止マーカーが表示され、距離 `+Npx` が正しい
- [ ] READY→ANNOUNCE→MOVING→RESULT のタイミング (ms 数) が一致
- [ ] `GhostCharacter` が duelist / companion を切り替える
- [ ] 7 ラウンド終了後に `GhostData.save_play` が呼ばれる
- [ ] ハードコード色・ハードコード日本語文字列なし (`ui_strings` / `ColorPaletteUtil`)

---

完成モック: [`ゴースト7番勝負.html`](ゴースト7番勝負.html)
