# 要求 — Result Laser 色修正 + Rule Explain Preview Variant 追加

## 背景

Midnight Cat (v3) リデザイン後の動作確認キャプチャを精査した結果、以下 2 点の不具合・不足が判明した。

### A. ゴースト7番勝負 Result phase の負け側ライン色

- 現状: `_spawn_burst_and_lasers` で `win == false` のとき hot/mid を RED_400/RED_500（赤）にしていた
- 問題: GDD §5b ルール「**負けてもネガティブ色（赤）は使わない**」（CLAUDE.md にも明記）に違反

### B. ルール説明画面の Step Preview が全ゲーム共通で 7番勝負用のまま

- 現状: フラッシュ暗算 / 順番記憶 のルール説明でも、Step preview が ghost_7ban_shobu 用の `ready / tap / compare` (レーン + GATE) のままになっていた
- 問題: 各ゲームの実態と図が一致していない。フラッシュ暗算は「数字を覚える/計算/打ち込む」、順番記憶は「光る順を覚える/同じ順でタップ/段階拡張」なのに、レーン上の orb 比較が出てしまう

## 要件

### A.

- 負け色を **グレー（INK_60 / INK_40）** に置換する
- WIN（cyan）/ PERFECT（gold）の色は維持
- TapBurst 中央バーストも同じ hot/mid を継承するため、自動的にグレーになるはず
- YOU/GHOST orb の gold/cyan は「プレイヤー色」として常時固定（勝敗で変えない）

### B.

- `rule_step_preview.gd` に flash_calc 用 3 variant と sequence_memory 用 3 variant を追加
- ghost_7ban の rail/gate 描画は対応 variant のみに条件描画
- `rule_explain_controller.gd` の RULES dict で各 step の `preview_variant` を新 variant 名に差し替え
- 既存の ghost_7ban variant（ready / tap / compare）はリグレッションさせない

### 検証

- xvfb 経由で 7 画面（home, rule × 3, ghost_7ban × 3）を再キャプチャし promotion 画像と並べて目視確認
