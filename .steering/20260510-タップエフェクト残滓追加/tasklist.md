# タスクリスト — タップエフェクト残滓追加

## 1. tap_residue.gd 新規作成

- [x] `scripts/ui/effects/tap_residue.gd` を新規作成（class_name TapResidue extends Control）
- [x] PARTICLE_COUNT = 80, TOTAL_DURATION_MS = 1700
- [x] `start(hit_pos)` で 80 粒のダストを生成
- [x] サイズ・不透明度・寿命・遅延・sway phase を個別ジッタ
- [x] `_draw()` で各粒子の現在位置と alpha を計算してdraw_circle
- [x] 大粒子はハロー（半径 2.4 倍 + α 0.35）

## 2. _draw_you_star の強化

- [x] `scripts/ui/ghost_7ban_lane_view.gd` の `_draw_you_star` を編集
- [x] 4 主軸はそのまま維持
- [x] 16 副軸を 22.5° おきに追加（5.6° オフセット）
- [x] 偶数番＝中尺ジッタ、奇数番＝短尺ジッタ
- [x] `sin(i * 7.91 + 1.7)` ベースの決定論ハッシュで長さ・太さを個別化

## 3. view 配線

- [x] `scripts/ui/ghost_7ban_shobu_view.gd` に `TapResidueScript` の preload 追加
- [x] `_spawn_burst_and_lasers` 内、TapBurst 直後に TapResidue を spawn
- [x] hot_color / mid_color を hot/mid (win/lose 分岐) から継承

## 4. snap timing 調整

- [x] `tools/snap_g7_result.gd` の `_wait_sec` を 0.6 → 1.1（tap timing）/ 0.25 → 0.55（result wait）に変更

## 5. キャプチャ検証

- [x] xvfb 経由で `snap_g7_result.gd` を実行
- [x] 1 回目: timing が早すぎ FLYING/999ms 早でキャプチャ不適
- [x] 2 回目: timing 修正後、GREAT/WIN/67ms シナリオでキャプチャ成功
- [x] promotion `game_tap_touch.png` と並べて目視比較
- [x] result.png に 80 粒のダスト + 24 ray スター + リング + cyan 横レーザーが揃っていることを確認

## 6. コミット

- [ ] このステアリング 3 点を含めて commit
- [ ] 変更ファイル: tap_residue.gd（新規）/ ghost_7ban_lane_view.gd / ghost_7ban_shobu_view.gd / snap_g7_result.gd / 更新後 captures

## 7. 残課題（任意）

- [ ] 粒子数 80 が Web 版で 60fps を維持できるか実機確認
- [ ] 他のキャプチャ（home / rule × 3 / ghost_7ban_ready / play）にも回帰がないことを確認（snap_all 全実行）

## 振り返り

### 計画と実績の差分

- 当初は粒子数 48 + 寿命 1500ms で実装したが、初回キャプチャで残滓が薄く見えたため 80 粒 + 1700ms に増強した
- snap_g7_result の旧 timing（YOU tap = 0.6s into moving）が moving 中央 1100ms に対して早すぎ、FLYING 判定で YOU が画面端に飛ぶ事故。修正済み

### 学んだこと

- particle effect は「数 × 寿命 × ハロー」のバランスで etheric 感が決まる。最初は控えめに見えたら増やす
- snap timing と実ゲームのフェーズ進行（READY 0.55s + START 0.35s + moving 2200ms / 2 = 1100ms）を揃えないと、毎回違う grade のキャプチャが取れて比較できない
- ステアリング不整備のままコード作業に入ってしまった。次回からは着手前に必ず requirements/design/tasklist を切る（メモリに保存済み）
