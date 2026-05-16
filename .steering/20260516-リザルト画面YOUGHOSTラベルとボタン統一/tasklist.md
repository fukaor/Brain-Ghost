# タスクリスト

## フェーズ1: シーン変更 (individual_result.tscn)

- [x] CompareCards: SBF_glass_dark を SBF_card_you / SBF_card_ghost / SBF_card_best の 3 種類に分割
- [x] YouCard: theme_override_styles/panel = SBF_card_you に変更
- [x] YouCard/YouVBox 先頭に YouHeader Label を追加（text="YOU", cyan300, 28pt serif）
- [x] OpponentCard: theme_override_styles/panel = SBF_card_ghost に変更（デフォルト ghost、self_best はコントローラで差替）
- [x] OpponentCard/OpponentVBox 先頭に OpponentHeader Label を追加（text="GHOST", gray dim, 28pt serif）
- [x] アバターサイズを 72x72 → 64x64 に調整（ヘッダ追加分の高さ補正）
- [x] 既存 ReplayButton (cta_blue) を削除
- [x] ReplayCTAWrap (Control 88px) + GlowFx (Control + glow_cta.gd) + ReplayButton (mc_cta_glow) 構造を追加
  - [x] ReplayButton text を「もう一度  ↻」に
  - [x] theme_override_styles/normal hover pressed focus を StyleBoxEmpty で透明化
- [x] 既存 HomeButton (home_button) を削除
- [x] 新 HomeButton（StyleBoxEmpty + 地味な cyan dim テキスト, "‹  ホームへ戻る"）を追加
- [x] 外部リソースに `glow_cta.gd` を追加

## フェーズ2: Controller 更新 (individual_result_controller.gd)

- [x] @onready で `_you_header`, `_opponent_header` 追加
- [x] @onready で `_replay_button` のパスを `ReplayCTAWrap/ReplayButton` に更新
- [x] `_apply_compare_cards()` に YOU/GHOST/BEST ヘッダ反映ロジック追加
- [x] self_best モードで OpponentCard panel を SBF_card_best 相当に差替（preload で StyleBoxFlat 生成）
- [x] self_best モードで OpponentValue 色を gold に変更（ghost モードは既存の dim white）

## フェーズ3: キャプチャ検証

- [x] xvfb 経由で 4 ケース キャプチャを取り直す
- [x] perfect_win: GHOST 表示 + cyan/gray ボーダー
- [x] nice_try: GHOST 表示 + cyan/gray ボーダー
- [x] new_best: GHOST 表示（reflex_tap も ghost モード）
- [x] improved: BEST 表示 + cyan/gold ボーダー（flash_calc は self_best）
- [x] ReplayButton が GlowCTA 装飾、HomeButton が地味なテキストリンクであることを目視確認

## フェーズ4: 品質チェック

- [x] `grep "cta_blue\|home_button" scenes/ui/individual_result.tscn` が 0 件
- [x] Godot parse error なし

---

## 実装後の振り返り

### 実装完了日
2026-05-16

### 計画と実績の差分

**計画通り**:
- CompareCards に YOU/GHOST/BEST ヘッダ Label を追加し、視覚的に瞬時に判別可能になった
- YouCard の cyan ボーダー、OpponentCard のボーダー色を ghost=gray / self_best=gold に動的差替
- ReplayButton を `mc_cta_glow` + GlowCTA wrapper に置換、home.tscn / rule_explain.tscn と一貫
- HomeButton を StyleBoxEmpty ベースの地味なテキストリンクに置換

**新たに必要になったタスク**:
- OpponentCard のボーダー色を mode で切り替えるため、Controller 側に `_build_card_style()` ヘルパを追加（シーン側に SBF_card_ghost + SBF_card_best を 2 つ持つよりも、コードで生成するほうが保守しやすい判断）

### 学んだこと
- `mc_cta_glow` + GlowFx + `StyleBoxEmpty_cta_invisible` の 3 点セットは home / rule_explain と統一する際のテンプレートとして再利用可能
- 「YOU と GHOST のキャラ絵が似ていて判別不能」問題は、ヘッダ Label を 32pt serif + 強コントラスト色で配置することで解消。アバターは装飾でしかなく、テキストが第一識別子になる
- `_apply_compare_cards` で mode 分岐するときは、ヘッダ・ボーダー・値色の 3 点を一括で書き換えると首尾一貫したカード色が作れる

### 次回への改善提案
- `default_theme.tres` の `cta_blue` / `home_button` テーマ定義はもう参照されていないため、削除候補（別ステアリングで cleanup 推奨）
- `_build_card_style()` のような実行時 StyleBoxFlat 生成パターンが各 controller に増えてきたら、共通ファクトリ（例: `scripts/ui/mc_style_factory.gd`）に集約検討
