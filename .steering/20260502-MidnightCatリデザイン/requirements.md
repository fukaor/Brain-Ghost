# 要求内容 — Midnight Cat (v3) 全面リデザイン

## 概要

ブレインゴーストの DS を旧「Animated Intellectual」(白系・丸ゴシック) から「Midnight Cat」(漆黒void + シアン発光 + 明朝 + 黒猫マスコット) に全面差し替え、ホーム / ルール説明 / ゴースト7番勝負ゲームを `docs/design/promotion/*.png` 準拠で再構築する。

## 背景

ユーザーが Claude Design (claude.ai/design) で大幅にデザインを刷新。promo 画像 6 枚と handoff bundle (`docs/design/claude_design/`) で最終形が共有された。chat1 末尾でユーザーが採用した最終仕様は:

- 漆黒 void 背景 + シアン発光 + ゴールドアクセント
- 明朝フォント (Noto Serif JP Bold) で見出し
- catboy / 黒猫マスコットに刷新（旧 ghost_seirei.png 少女 → Sleek_black_cat_*）
- ゴースト7番勝負: **1 レーン正面衝突**（YOU 左→右 / GHOST 右→左、中央ゲートで判定）+ 5 種レーン形状ローテ

旧実装は 2 レーン (上=YOU / 下=GHOST 並走) で promo と一致しないため、ゲーム機構ごと書き換えが必要。

## 実装対象の機能

### 1. Midnight Cat デザイントークン全面差し替え（完了済）
- `scripts/utils/color_palette.gd` を v3 (#000 void / #7DD3FC cyan / #FACC15 gold) に書き換え
- `assets/fonts/NotoSerifJP-Bold.otf` 追加（SIL OFL）
- `assets/themes/default_theme.tres` に `mc_*` バリアント群を追加
- `project.godot` の `default_clear_color` を黒に

### 2. home.tscn を home.png 準拠で再構築（完了済）
- 漆黒 void + 黒猫マスコット + 吹き出し + 脳年齢 + ⚙設定
- ポイント (3,230pts +285) + 通算戦績 (15勝 8敗) ピル
- 「今日のチャレンジ」シアン発光ピル CTA (→ ghost_7ban_shobu)
- 5日連続ストリーク + 6軸レーダーチャート + 全ゲーム一覧リンク

### 3. rule_explain.tscn を game_tap_rule.png 準拠で再構築（完了済 → 流用フォーマット化を追加実施）
- 明朝大見出し + 「鍛える能力：◯◯」サブタイトル
- 3 ステップカード（各カードは preview ミニ図 + 番号 + タイトル + 本文）
- スタート CTA
- **データドリブン**：RULES Dict に game_type → 仕様 を登録、`set_rule(game_type)` で他ゲームでも再利用可能
- **本タスクの追加要求**：他ミニゲーム流用のフォーマットを仕様化し、ドキュメント化

### 4. ghost_7ban_shobu を 1 レーン正面衝突に書き換え（着手予定）
- YOU は画面中央水平線の左→右、GHOST は右→左、同速度・同タイミングで発進
- 中央 GATE（金色縦光線）で判定。ヒット位置がゲートに近い側が勝ち
- 5 種レーン形状ローテ（直線 / S字 / サインウェーブ / ジグザグ / 弧）
- ターゲットはレーン形状に沿って移動
- アナウンス文字廃止 → 「READY → START」のみ
- Result 画面：ヒット点中央の爆発 + GATE 縦線 + GHOST 同様の停止位置表示
- ms 表示は YOU 上 / GHOST 下に分離

### 5. rule_explain フォーマット仕様の明文化（着手予定）
- `docs/design/patterns.md` または専用ドキュメントに「ルール説明画面のデータ構造」を記録
- 新ゲーム追加時の登録手順（RULES Dict / preview_variant 選択 / 必要なら新 variant 追加）

### 6. 実装画面キャプチャ取得（着手予定）
- 画面ごとに 720x1280 PNG を撮影
- `.steering/20260502-MidnightCatリデザイン/captures/` 配下に保存
- 対象: home / rule_explain (ghost_7ban_shobu / reflex_tap / flash_calc 各バリアント) / ghost_7ban_shobu (Ready)

## 受け入れ条件

### Midnight Cat トークン
- [x] `color_palette.gd` v3 移行（旧定数は alias で温存、breaking change なし）
- [x] `NotoSerifJP-Bold.otf` 同梱、Godot 4 で正常 import
- [x] `mc_*` バリアントが theme.tres に追加されている

### home.tscn
- [x] home.png と視覚的に一致（漆黒 / マスコット / CTA / 戦績 / レーダー）
- [x] CTA → `start_game("ghost_7ban_shobu")` で rule_explain に遷移する

### rule_explain.tscn
- [x] game_tap_rule.png と視覚的に一致（明朝タイトル / 3 ステップ / スタート CTA）
- [x] RULES Dict に 4 ゲーム以上が登録されている
- [ ] ドキュメントに「他ゲームへの流用手順」が明記されている

### ghost_7ban_shobu (1 レーン正面衝突)
- [ ] game_tap_touch.png と視覚的に一致（YOU 左 / GHOST 右 / 中央 GATE / 1 本レーン）
- [ ] 5 種レーン形状（直線 / S字 / サインウェーブ / ジグザグ / 弧）が round_index でローテする
- [ ] YOU と GHOST が同速度同タイミングで発進し、ゴーストは ghost_offset 位置で停止
- [ ] Result 画面でタップ位置に爆発、GATE からの距離が ms 値で表示される
- [ ] ms ラベルは YOU 上 / GHOST 下に重ならず分離
- [ ] 既存の BaseGame / GhostData / GameManager 連携が維持されている（保存・スコアリング）

### キャプチャ
- [ ] `.steering/20260502-MidnightCatリデザイン/captures/home.png` 等が存在
- [ ] 4 画面以上のキャプチャ（home / rule × 2 以上 / 7ban_shobu）

## 成功指標

- promo 画像 6 枚との視覚一致率を目視で確認可能
- 新ゲーム追加時、rule_explain への登録は RULES Dict に 1 エントリ追加するだけで動く
- ghost_7ban_shobu の 1 レーン挙動が chat1 で合意した仕様（正面衝突 / 5 形状ローテ / ms 分離）を満たす

## スコープ外

- フラッシュ暗算 (`flash_calc`) の Midnight Cat 移行（次イテレーション）
- 旧 light theme バリアント（`bar_win_v2` / `cta_blue` / `glass_bubble` 等）の削除（互換維持中、置換完了後にクリーンアップ）
- ghost_character.tscn / countdown.tscn / individual_result.tscn の Midnight Cat 移行（次イテレーション）
- 設定画面の実装

## 参照ドキュメント

- `docs/ideas/brain_training_gdd.md` — GDD v1.0
- `docs/design/promotion/*.png` — 最終 UI 仕様（6 枚）
- `docs/design/claude_design/brain-ghost/chats/chat1.md` — ゴースト7番勝負の 1 レーン仕様確定までのやり取り
- `docs/design/claude_design/brain-ghost/project/uploads/ghost-7ban-shobu-spec.md` — ゴースト7番勝負仕様書
