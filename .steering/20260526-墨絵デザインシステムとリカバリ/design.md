# 設計書

## アーキテクチャ概要

「色の発生源を一本化」を **本ステアリングで初めて本気で実現する**。

```
┌────────────────────────────────────────────────────────────────┐
│ Layer 4: 実画面 (シーン tscn)                                    │
│   - 背景レイヤは WashiBackground のみ (VoidBg/NebulaBg は削除済) │
│   - インライン色は Layer 1 から派生した値のみを使う              │
├────────────────────────────────────────────────────────────────┤
│ Layer 3: コンポーネントパターン (Card / Button / Badge / Headline) │
│   - デザインシステム文書に明示されたルール                       │
├────────────────────────────────────────────────────────────────┤
│ Layer 2: Theme (assets/themes/default_theme.tres)                │
│   - 既定の StyleBox / Font Color                                 │
├────────────────────────────────────────────────────────────────┤
│ Layer 1: ColorPaletteUtil v4 + デザインシステム文書              │
│   - 13 色トークン                                                │
│   - 表面/テキスト階層                                            │
│   - v3→v4 移行表                                                 │
└────────────────────────────────────────────────────────────────┘
```

## コンポーネント設計

### 1. デザインシステム文書 (新規)

**配置**: `docs/design/sumi_ghost_design_system.md`

**目次**:

```markdown
# Sumi Ghost Design System (v4)

1. Tokens
   - Color (13)
   - Typography (Noto Sans JP / Noto Serif JP の使い分け)
2. Surface Hierarchy
   - Background  → WASHI_BASE  #F2E9D5
   - Panel       → WASHI_PANEL #E8DCC0
   - Shade       → WASHI_SHADE #D6CFBE
3. Text Hierarchy
   - H1 Display       → SUMI_INK   font_size 36+ (Serif)
   - H2 Headline      → SUMI_INK   font_size 24-32
   - Body             → SUMI_MID   font_size 14-18
   - Caption          → SUMI_LIGHT font_size 12-14
   - Disabled         → SUMI_DIM
4. Accent Tokens
   - CTA / Active     → ONIBI_BLUE (border + label)
   - Achievement      → GOLD_AGED
   - Positive / Match → JADE_INK
   - Ghost            → GHOST_INK (alpha 連動)
5. Background Layering 規約
   - シーンの背景ノードは "WashiBackground" 1 つだけ
   - VoidBg / NebulaBg / StarLayer / Background / BG はすべて禁止 (=削除する)
   - WashiBackground は `anchors_preset=15, stretch_mode=6, z_index=-100`
6. Components
   - Button (Primary/Secondary/Ghost)
   - Card / Pill / Badge / Chip
   - Headline / Title / SectionTitle
7. v3 → v4 移行表 (大量)
8. 禁止事項
```

### 2. v3 → v4 移行表（design.md 内に同等を抜粋）

#### Font color

| v3 値 | v4 値 | 用途 |
|---|---|---|
| `Color(0.7, 0.93, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK (主要見出し・本文) |
| `Color(0.722, 0.878, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.722, 0.878, 1, 0.7)` | `Color(0.106, 0.106, 0.122, 0.85)` | SUMI_INK 半透明 |
| `Color(0.722, 0.878, 1, 0.75)` | `Color(0.106, 0.106, 0.122, 0.85)` | 同上 |
| `Color(0.95, 0.97, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.957, 0.969, 1, 0.95)` | `Color(0.106, 0.106, 0.122, 0.95)` | SUMI_INK |
| `Color(0.957, 0.969, 1.0, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.78, 0.824, 0.91, 1)` | `Color(0.239, 0.239, 0.267, 1)` | SUMI_MID (サブ本文) |
| `Color(0.78, 0.824, 0.91, 0.75)` | `Color(0.239, 0.239, 0.267, 0.85)` | SUMI_MID 半透明 |
| `Color(0.533, 0.588, 0.69, 1)` | `Color(0.420, 0.420, 0.447, 1)` | SUMI_LIGHT (キャプション) |
| `Color(0.435, 0.706, 1, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP (CTA テキスト/リンク) |
| `Color(0.435, 0.706, 1.0, 1)` | `Color(0.239, 0.420, 0.584, 1)` | 同上 |
| `Color(1, 0.914, 0.659, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED (達成・強調) |
| `Color(1.0, 0.914, 0.659, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED |
| `Color(1.0, 0.914, 0.659, 0.9)` | `Color(0.784, 0.663, 0.318, 0.9)` | GOLD_AGED 半透明 |
| `Color(0.961, 0.78, 0.416, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED |
| `Color(0.78, 0.824, 0.91, 0.7)` × 2 | `Color(0.239, 0.239, 0.267, 0.75)` | SUMI_MID × 0.75 |
| `Color(0.78, 0.824, 0.91, 0.85)` | `Color(0.239, 0.239, 0.267, 0.9)` | SUMI_MID × 0.9 |
| `Color(0.78, 0.824, 0.91, 0.95)` | `Color(0.239, 0.239, 0.267, 1)` | SUMI_MID |
| `Color(0.78, 0.824, 0.91, 0.6)` | `Color(0.239, 0.239, 0.267, 0.6)` | SUMI_MID × 0.6 |
| `Color(0.7, 0.93, 1, 0.85)` × 2 | `Color(0.106, 0.106, 0.122, 0.9)` | SUMI_INK × 0.9 |
| `Color(0.7, 0.93, 1, 0.7)` | `Color(0.106, 0.106, 0.122, 0.75)` | SUMI_INK × 0.75 |
| `Color(0.7, 0.93, 1, 0.6)` | `Color(0.106, 0.106, 0.122, 0.65)` | SUMI_INK × 0.65 |
| `Color(0.722, 0.878, 1.0, 1)` × 2 | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK（末尾 .0 表記揺れ） |
| `Color(0.722, 0.878, 1, 0.95)` × 2 | `Color(0.106, 0.106, 0.122, 0.95)` | SUMI_INK × 0.95 |
| `Color(0.95, 0.97, 1, 0.9)` | `Color(0.106, 0.106, 0.122, 0.9)` | SUMI_INK × 0.9 |
| `Color(0.957, 0.969, 1, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.949, 0.957, 0.98, 1)` | `Color(0.106, 0.106, 0.122, 1)` | SUMI_INK |
| `Color(0.682, 0.722, 0.812, 1)` × 2 | `Color(0.420, 0.420, 0.447, 1)` | SUMI_LIGHT |
| `Color(0.6, 0.65, 0.75, 1)` | `Color(0.639, 0.620, 0.580, 1)` | SUMI_DIM |
| `Color(0.29, 0.333, 0.439, 1)` | `Color(0.239, 0.239, 0.267, 1)` | SUMI_MID |
| `Color(0.118, 0.533, 0.898, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP |
| `Color(0.435, 0.847, 0.624, 1)` | `Color(0.353, 0.541, 0.431, 1)` | JADE_INK（正解色） |
| `Color(0.98, 0.8, 0.082, 1)` | `Color(0.784, 0.663, 0.318, 1)` | GOLD_AGED（旧 POSITIVE_GOLD） |
| `Color(0.49, 0.827, 0.988, 1)` | `Color(0.239, 0.420, 0.584, 1)` | ONIBI_DEEP（nav_link_button 用） |

#### StyleBoxFlat bg_color

| v3 値 | v4 値 |
|---|---|
| `Color(0.067, 0.094, 0.153, 0.7)` | `Color(0.910, 0.863, 0.753, 0.85)` |
| `Color(0.067, 0.094, 0.153, 0.6)` | `Color(0.910, 0.863, 0.753, 0.75)` |
| `Color(0.067, 0.094, 0.153, 0.55)` | `Color(0.910, 0.863, 0.753, 0.7)` |
| `Color(0.067, 0.094, 0.153, 0.45)` | `Color(0.910, 0.863, 0.753, 0.6)` |
| `Color(0.04, 0.08, 0.16, 0.7)` | `Color(0.910, 0.863, 0.753, 0.85)` |
| `Color(0.04, 0.08, 0.16, 0.55)` | `Color(0.910, 0.863, 0.753, 0.7)` |
| `Color(0.063, 0.075, 0.118, 0.6)` | `Color(0.839, 0.812, 0.745, 0.7)` |
| `Color(0.043, 0.071, 0.125, 0.85)` | `Color(0.910, 0.863, 0.753, 0.9)` |
| `Color(0.7, 0.93, 1, 0.6)` | `Color(0.847, 0.922, 0.969, 0.6)` |
| `Color(0.435, 0.706, 1, 1)` | `Color(0.478, 0.702, 0.878, 1)` |
| `Color(0.435, 0.706, 1, 0.9)` | `Color(0.478, 0.702, 0.878, 0.9)` |
| `Color(0.435, 0.706, 1, 0.15)` | `Color(0.478, 0.702, 0.878, 0.15)` |
| `Color(0.118, 0.533, 0.898, 1.0)` | `Color(0.239, 0.420, 0.584, 1.0)` |
| `Color(1, 0.914, 0.659, 0.15)` | `Color(0.784, 0.663, 0.318, 0.15)` |
| `Color(0.58, 0.639, 0.722, 0.5)` | `Color(0.420, 0.420, 0.447, 0.5)` |
| `Color(0.04, 0.08, 0.16, 0.6)` | `Color(0.910, 0.863, 0.753, 0.75)` |
| `Color(0.04, 0.08, 0.16, 0.9)` | `Color(0.910, 0.863, 0.753, 0.95)` |

### 3. 背景ノード除去パターン

各シーンに対して以下を実施:
1. `VoidBg` (type ColorRect) の `[node ...]` ブロックを削除
2. `NebulaBg` (type TextureRect) の `[node ...]` ブロックと、その関連 `[ext_resource ...]` を削除
3. `StarLayer` (type Control) の `[node ...]` ブロックと、その関連 `[ext_resource ...]` を削除
4. これらが参照していた SubResource（GradientTexture2D / Gradient）も孤児になるが、tscn パーサが警告するだけなので残置可

Python ヘルパースクリプトで一括処理する。

### 4. WashiBackground の z_index 解除

VoidBg/NebulaBg を消したあとは WashiBackground を最背面に保つ必要なし。`z_index = -100` の指定を削除しても OK（残しても害なし）。

## データフロー

### 修正対象シーンの判定フロー

```
1. find scenes -name "*.tscn" でシーン列挙
2. 各シーンに対して:
   a. VoidBg/NebulaBg/StarLayer のノードブロックを削除
   b. inline font_color を移行表で sed 置換
   c. inline bg_color を移行表で sed 置換
3. 全 tscn を保存後、godot --headless で import エラーチェック
4. 実機ビルド → デプロイ → スクリーンショット取得
```

## エラーハンドリング戦略

- ノード削除で参照される SubResource が孤児になっても Godot は警告のみ。クラッシュしない
- sed 一括置換は完全一致パターン。誤置換のリスクは低いが、置換後に diff を目視確認

## テスト戦略

### 静的チェック

- `grep -rE '\[node name="(VoidBg|NebulaBg|StarLayer)"' scenes/` → 0 件
- 既存ハードコード色パターン grep → 0 件
- `godot --headless --quit-after 30` でパースエラーなし

### 実機検証

- 実機 deploy 後にスクリーンショット 4 枚以上を取得
- 取得不可の場合は最低限ユーザに目視確認を依頼

## ディレクトリ構造

```
docs/
├── design/
│   ├── sumi_ghost_design_system.md   (新設、本ステアリングの中核)
│   └── snapshots/
│       └── sumi_ghost/                (新設、実機キャプチャ保存)

scenes/
├── main/ ... (VoidBg/NebulaBg/StarLayer 削除 + inline 色置換)
├── ui/   ... 同上
└── games/... 同上
```

## 実装の順序

1. **デザインシステム文書作成** (`docs/design/sumi_ghost_design_system.md`)
2. **背景ノード削除** (Python ヘルパー `/tmp/strip_old_bg.py`)
3. **インライン色一括置換** (sed スクリプト)
4. **godot import + パースエラーチェック**
5. **実機 deploy** + スクリーンショット取得
6. **MEMORY 更新** + 振り返り

## セキュリティ考慮事項

なし（純粋な見た目変更）

## パフォーマンス考慮事項

- VoidBg + NebulaBg + StarLayer を削除することでむしろ描画コストが下がる
- WashiBackground 1 枚のみで構成 → 軽量

## 将来の拡張性

- デザインシステム文書をプロジェクトの単一信頼源とし、今後の UI 変更はすべてこれを参照する
- 「夜の和紙」モード等の追加時もこの文書を拡張する形で対応
