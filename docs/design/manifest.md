# Brain Boost デザインマニフェスト

> 生成日: 2026-04-10
> モード: Generate（新規プロジェクト、既存 UI なし）
> 一次情報源:
> - `scripts/utils/color_palette.gd` (ColorPaletteUtil)
> - `docs/design/references/competitor-research.md` (競合 7 アプリ UI リサーチ)
> - `docs/ideas/brain_training_gdd.md` (GDD v1.0)
> - `docs/product-requirements.md` FR-07 / FR-08 / FR-09 / FR-12

このマニフェストは **home.tscn / theme.tres を作るときの参照仕様書** であり、以降のすべての画面設計における Single Source of Truth です。迷ったらここに戻る。ここに書かれていない数値は使わない。

---

## 1. ブランドトーン

Brain Boost は「**朝の通勤電車で 2 分、昨日の自分に挑む**」アプリです。主要ペルソナ（セルフチャレンジャー）は中高年寄りで、**華美な演出より確実な読みやすさと迷わない導線**を好みます。したがってデザイン言語は次の 4 つの軸で構成されます:

- **落ち着いた明度高めのライト基調** — ダーク背景は使わない。朝の電車でもまぶしくなく、老眼でも読みやすい
- **実直なミニマル** — イラスト・キャラクター・パーティクル演出は最小限。情報密度は低め、1 画面 1 メインアクション
- **丸ゴシック太字の安心感** — 和製脳トレアプリの定石。Noto Sans JP Bold を基本に、数値は極太・極大で情報の階層を瞬時に伝える
- **ゴールドの達成感** — 勝ち・ベスト更新・CTA は金色で一貫。赤は一切使わず、負けはグレーに逃がすことで「続けやすさ」を担保（GDD 必須ルール）

競合比較:
- **毎日脳トレ / みんなの脳トレ** の実直トーンを下敷きにしつつ
- **PEAK** のカード UI・カテゴリカラーコーディングを部分採用（ダークテーマは採用しない）
- **Brain Test** のコミカル演出は結果画面のマイクロアニメ 1 点のみに限定

---

## 2. カラートークン（ColorPaletteUtil 1 対 1 対応）

色はすべて `scripts/utils/color_palette.gd` の `ColorPaletteUtil` 定数を参照。生 hex の直書きは禁止（下記 §9）。

### 対応表

| Token 名（Theme 側） | ColorPaletteUtil 定数 | hex | 用途 |
|---|---|---|---|
| **color/bg/default** | `BG_LIGHT` | `#F8FAFC` | アプリ全体の背景 |
| **color/bg/card** | `BG_LIGHT` | `#F8FAFC` | カード背景（背景と同色でシャドウで浮かせる） |
| **color/text/primary** | `BG_DARK` | `#0F172A` | 見出し、本文、数値、ボタンラベル（CTA 内以外） |
| **color/text/secondary** | `NEUTRAL_GRAY` | `#64748B` | サブ情報、補助テキスト |
| **color/text/caption** | `NEUTRAL_SLATE` | `#94A3B8` | キャプション、注記、タイムスタンプ |
| **color/border/default** | `NEUTRAL_LIGHT_GRAY` | `#E2E8F0` | 区切り線、薄い境界 |
| **color/cta/primary** | `POSITIVE_GOLD` | `#FACC15` | メイン CTA ボタン背景、ベスト更新演出 |
| **color/cta/primary_text** | `BG_DARK` | `#0F172A` | ゴールド CTA 上のテキスト色（コントラスト確保） |
| **color/cta/secondary** | `ACCENT_BLUE` | `#3B82F6` | セカンダリ CTA、リンク、情報系アイコン |
| **color/win** | `POSITIVE_GREEN` | `#22C55E` | 勝利・スコア上昇・達成表示 |
| **color/lose** | `NEUTRAL_GRAY` | `#64748B` | 負け表示（**絶対に赤にしない**） |
| **color/disabled/bg** | `NEUTRAL_LIGHT_GRAY` | `#E2E8F0` | 無効化されたボタン背景 |
| **color/disabled/text** | `NEUTRAL_SLATE` | `#94A3B8` | 無効化されたテキスト |

### 予約（v1.1 以降）

| Token 名 | ColorPaletteUtil 定数 | 備考 |
|---|---|---|
| **color/bg/dark** | `BG_DARK` | ダークモード（v1.1 以降）。MVP では未使用 |

### 設計判断

- **win/lose に赤を置かない**のは GDD §6 と development-guidelines.md §色の使用 の絶対ルール。`ColorPaletteUtil` には意図的に `RED` 定数が存在しない（コメントで明文化）
- **CTA プライマリはゴールド固定**。Brain Boost のブランド色として、ホームの「今日のチャレンジ」・結果画面の「もう一度」・ベスト更新バッジすべてに使い、ユーザーの視線誘導を一貫させる
- **カード背景は背景と同色**。視覚的分離はシャドウだけで行う（マテリアルデザインの elevation 発想）。塗り分けでカードを作らないことで背景が騒がしくならない
- **アクセントブルーはリンクと情報系のみ**。CTA に使わない（ゴールドと役割を分ける）

---

## 3. タイポグラフィ

### フォント

- **一次フォント**: **Noto Sans JP Bold** (`.otf`, CFF-based OpenType)
  - ライセンス: SIL Open Font License 1.1（`assets/fonts/OFL.txt` に同梱）
  - 配置: `assets/fonts/NotoSansJP-Bold.otf`
  - 取得元: https://github.com/notofonts/noto-cjk (`Sans/SubsetOTF/JP/NotoSansJP-Bold.otf`)
  - 理由: 日本語・英数字・記号を 1 ファイルで網羅、Godot 4 は OTF/TTF 両対応、公式配布元から入手確実
- **代替候補**: M PLUS Rounded 1c Bold（より丸く親しみがあるが、Noto Sans JP Bold で実装後に満足できなければ差し替え検討）
- **フォールバック**: Godot デフォルトフォント（フォントファイル読み込み失敗時の自動フォールバック）

### タイプスケール

| Variation 名 | サイズ | 用途 | 実例 |
|---|---|---|---|
| **display** | 64pt | 結果画面のスコア / 脳年齢の主役表示 | "28 歳" "3200" |
| **h1** | 32pt | 画面タイトル | "今日のチャレンジ" |
| **h2** | 24pt | セクション見出し、カード内タイトル | "前回の成績" |
| **body** | 18pt | 標準本文、ボタンラベル | "スタート" |
| **caption** | 14pt | 補助情報、注記、タイムスタンプ | "3 種類 / 約 2 分" |

**重要**: Godot 4 の **Theme Type Variation** 機能で `h1`, `h2`, `display`, `caption` を登録する。個別 Label に `add_theme_font_size_override()` を書くのは禁止（§9 参照）。

### 行間・字間

- **行間** (`line_spacing`): 本文 `body` のみ `8px` を指定。その他は Godot デフォルト（フォントメトリクス依存）
- **字間** (`spacing_top/spacing_bottom`): 変更しない（日本語フォントは字間調整が事故のもとなのでデフォルトに従う）

### 太さ

- **すべて Bold** を基本とする。Regular / Medium は用意しない
  - 理由: 中高年ターゲットに対して読みやすさを最優先。複数ウェイトを使い分けるとむしろ読みにくくなる。また Noto Sans JP は Regular/Bold の 2 枚持つよりも Bold 1 枚に集約する方がファイルサイズの面でも有利

### 設計判断

- **display は結果画面と脳年齢表示のみ**。ホーム画面のスコア表示は `h1` か `h2` で十分。display を多用すると威厳が薄れる
- **caption は 14pt 未満にしない**。12pt は老眼で読めなくなる。中高年ターゲットでの最小可読サイズを 14pt と定義
- **英数字と和文で別フォントを使わない**。Noto Sans JP に含まれる英数字グリフで統一（字体の混在を避ける）

---

## 4. スペーシング（8pt グリッド）

### スケール

| Token 名 | 値 | 用途 |
|---|---|---|
| **space/xs** | 4px | ラベル内の改行、アイコンとテキストの隙間 |
| **space/sm** | 8px | カード内の行間、小さな要素間 |
| **space/md** | 16px | 標準の要素間隔、ボタン間、カード内 padding（通常） |
| **space/lg** | 24px | セクション区切り、カード間の余白、画面左右 margin |
| **space/xl** | 32px | 主要セクション間の余白 |
| **space/2xl** | 48px | Safe Area 上端余白、見出しブロック前後 |
| **space/3xl** | 64px | 特別な余白、エラー画面中央寄せ等 |

### デフォルト値

- **画面左右 margin**: `space/lg` (24px)
- **画面上端 Safe Area**: `space/2xl` (48px)
- **画面下端 Safe Area**: **96px**（親指ゾーン確保。下記 §6 参照）
- **VBoxContainer の separation**: `space/md` (16px) をデフォルト、カード内だけ `space/sm` (8px)
- **カード内 padding**: `space/md` (16px)

### 設計判断

- **8pt グリッド**はモバイル UI の定石（iOS HIG / Material Design 共通）。すべての数値が 8 の倍数に揃うことで視覚的リズムが生まれる
- **4px (xs) は例外扱い**。通常は使わず、「どうしても 8px では詰まりすぎる場合の最小値」という位置づけ
- **32px (xl)・48px (2xl)・64px (3xl) は大きな呼吸**。ホーム画面ではほぼ `lg` までで足りる。特別な演出のときだけ

---

## 5. 角丸スケール

| Token 名 | 値 | 用途 |
|---|---|---|
| **radius/sm** | 8px | 小さなチップ、バッジ |
| **radius/md** | 16px | カード、パネル、ダイアログ |
| **radius/lg** | 24px | 主要 CTA ボタン（スタート・シェア） |
| **radius/pill** | 9999px | タグ、ピルボタン、円形アイコン背景 |

### デフォルト

- **Panel / Card**: `radius/md` (16px)
- **Button (CTA)**: `radius/lg` (24px)
- **Button (Secondary)**: `radius/md` (16px)
- **Tag / Badge**: `radius/pill` (9999px)

### 設計判断

- **直角 (0px) は使わない**。すべての要素に角丸を入れることで「やわらかい」印象を統一
- **CTA ボタンは他より大きな角丸**（24px）にすることで、タップしたくなる視覚的強調を行う
- **ピル形状**は統計バッジやカテゴリチップで使う（例: "5 日連続" "ベスト更新"）

---

## 6. Safe Area / 親指ゾーン

### Safe Area 余白

- **上**: 48px — ステータスバー + ノッチを考慮した最小余白
- **下**: 96px — ボトムナビ高さ 64px + 親指リーチ余白 32px
- **左右**: 24px — 標準 margin（`space/lg`）

### 親指ゾーン（重要）

縦 720×1280 を想定したとき、**画面下 1/3（y = 853 〜 1280）が親指リーチ領域**。主要 CTA は必ずこのゾーンに配置する。

```
┌──────────────────┐ y=0
│  上 Safe Area 48 │
│                  │
│  [Header]        │  ← 情報表示ゾーン（読むだけ）
│                  │
├──── y=853 ───────┤
│                  │
│  [Main CTA]      │  ← 親指リーチゾーン（タップ対象）
│                  │
│  [Secondary CTA] │
│  [Bottom Nav]    │
└──────────────────┘ y=1280
```

### 設計判断

- **片手操作前提**。両手持ちを前提にすると画面上部にボタンを置きがちだが、電車の中での片手操作では上端は指が届かない
- **情報は上、アクションは下**の原則を徹底
- **ホーム画面の「スタート」は y=900 前後に固定**

---

## 7. タップ領域

- **最小タップ領域**: **44×44pt**（iOS HIG 準拠）
  - Android Material は 48dp だが、厳しい方（44）に統一
- **推奨**: 56×56pt 以上
- **メイン CTA**: 88pt 高 × 画面幅 85%（約 600px 幅）

### 設計判断

- アイコンだけのボタンも必ず 44pt 以上の透明クリッカブル領域を確保
- Container の `custom_minimum_size` で最小サイズを担保し、`size_flags` で伸縮させる

---

## 8. シャドウ

### 標準シャドウ (shadow/card)

- `shadow_color`: `Color(0, 0, 0, 0.08)` — 黒 8% アルファ
- `shadow_offset`: `Vector2(0, 2)`
- `shadow_size`: `8px` (blur 相当)

### 強いシャドウ (shadow/card_elevated)

- `shadow_color`: `Color(0, 0, 0, 0.12)` — 黒 12% アルファ
- `shadow_offset`: `Vector2(0, 4)`
- `shadow_size`: `12px`

### 設計判断

- **シャドウの色は純黒 + アルファのみ**。青みシャドウ・茶色シャドウは使わない（トーンが汚れる）
- **elevated は画面中の 1 要素のみに限定**（通常はメイン CTA カード）。すべてに elevated を使うと "浮き" の意味が死ぬ
- **Godot の StyleBoxFlat.shadow_size は重い**との報告あり。Web 版のパフォーマンスが問題になったら片方を平坦化することを検討

---

## 9. 禁則事項（アンチパターン）

以下は **絶対に書かない**。レビューで見つけ次第リジェクト。

### 色

- ❌ **赤系の使用**（`#EF4444`, `Color(1, 0, 0)`, `Color(0.9, 0.1, 0.1)` 等）
  - 理由: GDD §6 の絶対ルール。負け表示にもネガティブ色を使わない
- ❌ **生 hex の直書き**（`#FACC15`, `Color(0.98, 0.8, 0.08)` 等を scenes/ や scripts/ に書く）
  - 理由: 変更が追跡不能になる。すべて `ColorPaletteUtil` メンバ経由にする
  - 例外: `ColorPaletteUtil` 内部の定数定義本体のみ
- ❌ **複数青・複数緑の乱立**（`ACCENT_BLUE` 以外の青、`POSITIVE_GREEN` 以外の緑を追加する）
  - 理由: パレットの意味が崩壊する。新しい色を足したくなったら必ず `ColorPaletteUtil` に定数として追加し、マニフェストのトークン表も同時更新する

### レイアウト

- ❌ **絶対配置 offset の直書き**（`offset_left = 120`, `offset_top = 240` 等）
  - 理由: 解像度変更で崩れる
  - 許容: `anchors_preset` 由来の自動 offset、`custom_minimum_size` による最小サイズ指定、MarginContainer の `theme_override_constants/margin_*`
- ❌ **タップ対象 44pt 未満**
- ❌ **画面上端（y < 300）への CTA 配置**（片手操作で指が届かない）
- ❌ **1 画面に 3 つ以上の主要 CTA**（ユーザーが迷う）

### タイポグラフィ

- ❌ **`add_theme_font_size_override()` を GDScript で書く**
  - 理由: ビジュアルはすべて Theme Resource に寄せる。GDScript はロジックのみ
  - 代替: Theme に variation を追加し、ノードに `theme_type_variation = "h1"` を設定
- ❌ **フォントサイズの中間値**（`20pt`, `22pt` 等、タイプスケールに含まれない値）
  - 許容: タイプスケール上の 5 段階（14 / 18 / 24 / 32 / 64）のみ
- ❌ **Regular / Light ウェイトの追加**
  - 理由: §3 参照

### Godot 固有

- ❌ **ビジュアル情報を GDScript に持たせる**（`modulate = Color.RED`, `add_theme_stylebox_override()` 等）
  - 代替: Theme Resource + `theme_type_variation`
- ❌ **OS.get_name() を直接呼ぶ**
  - 代替: `Platform` Autoload（`scripts/autoload/platform.gd`）経由
- ❌ **Color 定数を新規追加するとき ColorPaletteUtil を経由しない**
  - 手順: ColorPaletteUtil に `const` 追加 → manifest.md のトークン表を更新 → PR で審議

### 検出用 grep コマンド

レビュー時に以下を実行して違反を検出:

```bash
# 生 hex 検出（ColorPaletteUtil 以外）
grep -rnE "Color\(\s*[0-9]" scenes/ scripts/ | grep -v "color_palette.gd"
grep -rnE "#[0-9a-fA-F]{6}" scenes/ scripts/ --include="*.tscn" --include="*.gd" | grep -v "color_palette.gd"

# 絶対配置の直書き
grep -rnE "offset_(left|top|right|bottom)\s*=\s*-?[0-9]" scenes/ | grep -v "anchors_preset"

# GDScript でのビジュアル override
grep -rn "add_theme_.*_override\|modulate = Color" scripts/

# OS.get_name の散在
grep -rn "OS.get_name()" scripts/ | grep -v "platform.gd"
```

これらは CI で回すことを推奨（将来タスク）。

---

## 10. 参考パターン（競合リサーチから採用）

`docs/design/references/competitor-research.md` の「パターン抽出表」から以下を採用:

### 採用するパターン

| パターン | 出典 | Brain Boost での適用 |
|---|---|---|
| 白背景 + ゴールド CTA | みんなの脳トレ、毎日脳トレ | `color/bg/default` + `color/cta/primary` の組み合わせ。ホーム画面の骨格 |
| 脳年齢の極太大表示 | みんなの脳トレ、数字さがし | `display` (64pt) variation で結果画面中央に配置 |
| カード縦スクロール UI | 毎日脳トレ、PEAK | ホームのゲーム選択・カレンダー画面に適用 |
| 2×3 ゲームグリッド | みんなの脳トレ、パズル詰め合わせ | 「全ゲーム一覧」画面で採用候補 |
| ハンコカレンダー | 毎日脳トレ | `scenes/ui/stamp_calendar.tscn` に直接適用（和風スタンプ + 押印アニメ） |
| レーダーチャート | PEAK (Brain Map)、ソルティオ | `scenes/ui/radar_chart.tscn` に 6 軸固定で実装 |
| カテゴリ別カラーコーディング | PEAK | 6 つの能力軸（計算/記憶/注意/反射/観察/判断）それぞれに色割当 — **要別途決定**（manifest 将来版で追加） |
| ボトムナビ 3 タブ | PEAK、毎日脳トレ | ホーム / カレンダー / 設定 |
| 巨大 CTA ボタン | みんなの脳トレ | `StartButton` 高さ 88pt、画面幅 85% |

### 採用しないパターン

| パターン | 出典 | 理由 |
|---|---|---|
| ダークテーマ基調 | PEAK | ペルソナ（朝通勤・中高年寄り）にはライト基調が合う |
| ロック解放演出 | 毎日脳トレ | Brain Boost は 6 ゲーム全解放。「精度 %」で別軸の解放感を演出 |
| 高彩度マルチカラー | PEAK | 情報過多になるため、6 軸カラー以外はトーンを抑える |
| 全面手描き演出 | Brain Test | 「脳年齢」の真面目さと矛盾 |
| ゲーム間広告 | 多数 | GDD 禁則 |

---

## 11. Godot Theme へのマッピング

このマニフェストを `assets/themes/default_theme.tres` に落とし込むときの対応:

```
default_theme.tres
├─ Default Font:        assets/fonts/NotoSansJP-Bold.otf
├─ Default Font Size:   18  (body)
│
├─ Button
│   ├─ normal (StyleBoxFlat)
│   │   ├─ bg_color:        POSITIVE_GOLD (#FACC15)
│   │   ├─ corner_radius:   24  (radius/lg)
│   │   ├─ shadow:          standard (alpha 0.08, offset 0/2, blur 8)
│   │   └─ content_margin:  16/24  (space/md / space/lg)
│   ├─ hover:     normal の bg を 90% 彩度
│   ├─ pressed:   normal の bg を 80% 彩度 + offset_y +2
│   ├─ disabled:  bg = NEUTRAL_LIGHT_GRAY
│   ├─ font_color:          BG_DARK (#0F172A)
│   └─ font_size:           20  (body より 1 段大きめ)
│
├─ Label
│   ├─ default
│   │   ├─ font_color:  NEUTRAL_GRAY (#64748B)
│   │   └─ font_size:   18  (body)
│   ├─ Type Variation "h1"       font_size: 32, font_color: BG_DARK
│   ├─ Type Variation "h2"       font_size: 24, font_color: BG_DARK
│   ├─ Type Variation "display"  font_size: 64, font_color: BG_DARK
│   └─ Type Variation "caption"  font_size: 14, font_color: NEUTRAL_SLATE
│
├─ PanelContainer
│   ├─ Type Variation "card"
│   │   └─ panel (StyleBoxFlat)
│   │       ├─ bg_color:        BG_LIGHT
│   │       ├─ corner_radius:   16
│   │       ├─ shadow:          standard
│   │       └─ content_margin:  16
│   └─ Type Variation "card_elevated"
│       └─ panel (StyleBoxFlat)
│           ├─ bg_color:        BG_LIGHT
│           ├─ corner_radius:   16
│           ├─ shadow:          strong (alpha 0.12, offset 0/4, blur 12)
│           └─ content_margin:  16
│
└─ (将来追加: TextureRect, ProgressBar 等)
```

`project.godot` の `[gui]` セクション:

```
[gui]
theme/custom="res://assets/themes/default_theme.tres"
```

これで全 `Control` ノードに自動継承される。

---

## 12. このマニフェストの使い方

### 画面を作るとき

1. このファイル（manifest.md）を開く
2. 使う色・サイズ・余白をすべてトークン名で把握（数値を決める前に名前を決める）
3. `.tscn` を組むときは Theme に任せる → `theme_type_variation` を指定するだけ
4. 生値を書きそうになったら止まってマニフェストに戻る

### マニフェストを更新するとき

以下の場合のみ更新可:

1. `ColorPaletteUtil` に新しい定数を追加したとき（色トークン表を同期）
2. タイプスケールに段階を追加したとき（ほぼ発生しないはず）
3. 新しい angular な数値パターンが必要になり、プロジェクト全体に波及することが確定したとき

個別画面の都合でトークンから外れる数値を使いたくなったら、**まずマニフェストへの追加を検討**する（その場しのぎで .tscn に直書きしない）。

### 参照ドキュメント

- `scripts/utils/color_palette.gd` — 色定数の実装
- `docs/design/references/competitor-research.md` — 競合 UI リサーチ
- `docs/design/patterns.md` — ノード階層・命名規則のテンプレ（本タスクのフェーズ H で作成予定）
- `docs/ideas/brain_training_gdd.md` — 設計の北極星
- `docs/product-requirements.md` — 受け入れ条件の定義
