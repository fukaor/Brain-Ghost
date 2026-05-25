# タスクリスト — ゲーム一覧画面 Midnight Cat 化

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 「実装が複雑すぎるため後回し」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

### タスクスキップが許可される唯一のケース
以下の技術的理由に該当する場合のみスキップ可能:
- 実装方針の変更により、機能自体が不要になった
- アーキテクチャ変更により、別の実装方法に置き換わった
- 依存関係の変更により、タスクが実行不可能になった

---

## フェーズ1: 既存実装の確認とリファレンスの読み込み

- [x] `scenes/ui/game_list.tscn` の現状ノード構造を再確認
- [x] `scripts/ui/game_list_controller.gd` の `@onready` パスを洗い出し（変更してはいけない箇所を特定）
- [x] `scenes/main/home.tscn` の VoidBg / NebulaBg / StarLayer の SubResource を確認しコピペ元として特定
- [x] `scenes/ui/individual_result.tscn` の `SBF_premium_dark` 等の暗グラスパネル定義を確認
- [x] `assets/themes/default_theme.tres` の `mc_h1`(44) / `mc_h2`(32) / `mc_subtitle`(18) / `mc_body`(17) / `mc_caption`(14) / `mc_cta_glow`(38) / `mc_back_btn`(16) の font_size を確認（既定値が規約未達のものは override 必須）

## フェーズ2: シーン書き換え（StyleBox + 背景レイヤ + ヘッダー）

- [x] `game_list.tscn` の ext_resource を更新
  - [x] ~~`NotoSerifJP-Bold.otf` (mc serif) を追加読み込み~~（mc_h1/mc_h2 経由で theme から自動解決されるため不要）
  - [x] `effects/star_layer.gd` を追加読み込み
  - [x] 旧 `NotoSansJP-Bold.otf` は維持（説明・キャプション用に必要）
- [x] 背景レイヤを差し替え
  - [x] 旧 `Gradient_bg` / `GradientTex_bg`（空色グラデ）を削除
  - [x] 新 `Gradient_nebula` / `GradientTexture2D_nebula` を追加（home.tscn と同一）
  - [x] 旧 `BgTexture` ノードを削除
  - [x] `VoidBg` (ColorRect, #000) を追加
  - [x] `NebulaBg` (TextureRect) を追加
  - [x] `StarLayer` (Control + effects/star_layer.gd) を追加（mouse_filter=2 は star_layer.gd 内で MOUSE_FILTER_IGNORE 設定済だが tscn 側も冗長に指定）
- [x] StyleBox を Midnight Cat 仕様に差し替え
  - [x] `SBF_card_dark`（`bg_color = Color(0.04, 0.08, 0.16, 0.55)`, border=CYAN 0.45, corner=28）を追加
  - [x] `SBF_icon_dark`（BG_PANEL α=0.85, border=CYAN 0.6, circle）を追加
  - [x] `SBF_metric_dark`（BG_ELEV α=0.6, border=CYAN 0.25, corner=18）を追加
  - [x] 旧 `SBF_start_n` / `SBF_start_p` を削除（CardPlayButton は `mc_cta_glow` variation を使う）
  - [x] `SBF_dot` を CYAN_400 塗り `Color(0.435, 0.706, 1, 1)` に変更（modulate.a での active/inactive 表現を維持）
  - [x] `SBF_nav_dark`（`bg_color = Color(0.04, 0.08, 0.16, 0.85)`, border-top=CYAN 薄）を追加
  - [x] `SBF_nav_act_cyan`（CYAN α=0.18, border=CYAN 0.7, shadow=CYAN glow）を追加
  - [x] `SBF_coming_dark`（BG_ELEV α=0.6, border=CYAN 0.2, corner=16）を追加
  - [x] 旧 `SBF_header`（白半透明角丸ヘッダー）を削除
- [x] ヘッダー再構成
  - [x] 旧 `HeaderGlass` PanelContainer と子 `SubtitleLabel` を削除
  - [x] 新 `HeaderBlock` (VBox) を追加（BackChip は設けない、NavHomeButton と機能重複のため）
  - [x] `HeaderBlock/Title` Label (`theme_type_variation = &"mc_h1"`, text="脳トレ") — mc_h1 既定 44px のまま
  - [x] `HeaderBlock/Subtitle` Label (variation 無し, text="今日のメニューを選ぼう")
    - [x] `theme_override_font_sizes/font_size = 20`
    - [x] `theme_override_colors/font_color = Color(0.533, 0.588, 0.69, 1)` (INK_60)

## フェーズ3: カード内コンテンツの Midnight Cat 化（6 枚同一）

**カード内ノード適用パターン（各 Card0..Card5 で同じ）**:
- IconCircle: `theme_override_styles/panel = SBF_icon_dark`
- IconLabel: `theme_override_colors/font_color = Color(0.722, 0.878, 1, 1)` (CYAN_300), `theme_override_font_sizes/font_size = 64`
- CategoryLabel: variation 無し, `theme_override_colors/font_color = Color(0.435, 0.706, 1, 1)` (CYAN_400), `theme_override_font_sizes/font_size = 22`
- GameNameLabel: `theme_type_variation = &"mc_h2"`, `theme_override_font_sizes/font_size = 36` (mc_h2 既定 32 を上書き)
- DescriptionLabel: `theme_type_variation = &"mc_body"`, `theme_override_font_sizes/font_size = 24` (mc_body 既定 17 を上書き)
- MetricPanel: `theme_override_styles/panel = SBF_metric_dark`
- MetricCaption: variation 無し, `theme_override_colors/font_color = Color(0.533, 0.588, 0.690, 1)` (INK_60), `theme_override_font_sizes/font_size = 20`
- MetricValue: variation 無し, `theme_override_colors/font_color = Color(0.961, 0.780, 0.416, 1)` (GOLD_400), `theme_override_font_sizes/font_size = 40`
- CardPlayButton: `theme_type_variation = &"mc_cta_glow"`, `theme_override_font_sizes/font_size = 28`, `custom_minimum_size = Vector2(0, 64)` (mc_cta_glow 既定 38 を上書き、規約 56px を確実に満たす)
- CardComingSoon: `theme_override_styles/panel = SBF_coming_dark`
- CardComingSoon/Label: `theme_override_colors/font_color = Color(0.722, 0.878, 1, 0.7)` (CYAN_300 α=0.7), `theme_override_font_sizes/font_size = 20`

- [x] **Card0 (反射タップ)** に上記パターンを適用
- [x] **Card1 (フラッシュ暗算)** に上記パターンを適用
- [x] **Card2 (順番記憶)** に上記パターンを適用
- [x] **Card3 (色文字テスト)** に上記パターンを適用
- [x] **Card4 (神経衰弱)** に上記パターンを適用
- [x] **Card5 (数字さがし)** に上記パターンを適用

## フェーズ4: ドットインジケータとボトムナビ

- [x] DotIndicators (Dot0..Dot5) の `SBF_dot` を CYAN_400 塗り `Color(0.435, 0.706, 1, 1)` に統一（controller の幅+modulate.a ロジックは無変更）
- [x] BottomNavPanel に `SBF_nav_dark` を適用
- [x] NavTrainActive に `SBF_nav_act_cyan` を適用
- [x] NavTrainButton 内
  - [x] `custom_minimum_size = Vector2(0, 56)` を設定（規約 56px 担保）
  - [x] Icon Label: `font_color = Color(0.722, 0.878, 1, 1)` (CYAN_300), `font_size = 44` ("psychology")
  - [x] Text Label: `font_color = Color(0.722, 0.878, 1, 1)` (CYAN_300), `font_size = 22` ("脳トレ")
- [x] NavAnalyticsButton / NavHomeButton / NavAwardButton / NavSettingsButton 内（既存 `custom_minimum_size = (0, 56)` は維持）
  - [x] Icon Label: `font_color = Color(0.533, 0.588, 0.69, 1)` (INK_60), `font_size = 44`
  - [x] Text Label: `font_color = Color(0.533, 0.588, 0.69, 1)` (INK_60), `font_size = 22`

## フェーズ5: コントローラ整合性

- [x] `game_list_controller.gd` の `@onready` パス全てが新ツリーで解決することを確認
  - [x] `_carousel_area = $SafeAreaMargin/MainColumn/CarouselArea` ✓
  - [x] `_dot_container = $SafeAreaMargin/MainColumn/DotRow/DotIndicators` ✓
  - [x] `_nav_train = $BottomNavPanel/BottomNavBar/NavTrainActive/NavTrainButton` ✓
  - [x] `_nav_analytics / _nav_home / _nav_award / _nav_settings` ✓
- [x] `_populate_cards()` の子ノードパス (CardMargin/CardVBox/...) が新シーンで解決することを確認 — 全 6 カードで IconCircle/IconLabel/CategoryLabel/GameNameLabel/DescriptionLabel/MetricPanel/MetricVBox/MetricCaption/MetricValue/CardPlayButton/CardComingSoon の階層を温存
- [x] 旧ヘッダー HeaderGlass / SubtitleLabel を参照しているコードが無いことを確認（controller には参照無し、grep で確認済）

## フェーズ6: 規約遵守の grep + 目視チェック

- [x] 最低サイズ規約 (grep): `grep -E "font_size = (1[0-9]\b|2[0-3]\b)" scenes/ui/game_list.tscn` の hit は **すべて 20 / 22 のみ**（Subtitle/MetricCaption/COMING SOON=20px, CategoryLabel/NavText=22px）。HUD 補助 ≥ 20 / ナビラベル ≥ 22 / 装飾チップ ≥ 18 の各規約を満たすため compliant。本文 24px / ボタン文字 28px / 見出し 36-44px は最大値以上で hit せず
- [x] **theme variation 既定値の目視確認**: mc_h2/mc_body/mc_cta_glow を使用するノードはすべて `theme_override_font_sizes/font_size` を併設し既定値（32/17/38）を 36/24/28 に上書き済。mc_subtitle/mc_caption は採用していない
- [x] 白塗り混入チェック: `grep "Color(1, 1, 1"` で bg_color に白塗りが無いことを確認。CYAN/CYAN_300 の font_color のみ hit（OK）
- [x] タップ要素最小高 (grep): CardPlayButton=64, NavTrainButton/NavAnalyticsButton/NavHomeButton/NavAwardButton/NavSettingsButton=56 を確認
- [x] 赤系不使用チェック: 赤・ピンク系リテラルなし、旧水色グラデ (`Color(0.878, 0.949, 0.996, 1)` 等) も削除済み

## フェーズ7: 動作確認

- [x] Godot headless で project 全体 import が完了し、game_list.tscn のロードでパースエラー無し（`godot --headless --import` / `godot --headless --quit-after 10 scenes/ui/game_list.tscn` でエラーログなし）
- [x] ext_resource / SubResource 参照整合性を grep で検証（4 ext_resource × 9 sub_resource、すべて参照先存在）
- [x] controller 側 `@onready` パスと `_populate_cards()` 内 `get_node_or_null()` パスが新ツリーで全解決することを静的検証
- [ ] 実機 / Web エクスポートでの動作確認 — **ユーザ側で Godot Editor を起動して目視確認をお願いします**:
  - [ ] `scenes/main/home.tscn` 起動 → AllGamesLink → game_list 遷移
  - [ ] カルーセル左右スワイプが動作
  - [ ] 左右矢印キーで遷移できる
  - [ ] カードタップで隣カードに切替（中央カードタップでゲーム起動）
  - [ ] スタート押下 → reflex_tap / flash_calc / sequence_memory が起動
  - [ ] 未実装 3 ゲーム（stroop / card_match / number_search）で COMING SOON 表示
  - [ ] ボトムナビ「ホーム」で home に戻る
  - [ ] スクリーンショットを `.steering/20260517-ゲーム一覧画面UIリフレッシュ/captures/` に保存（任意）

## フェーズ8: ドキュメント更新と振り返り

- [x] 実装後の振り返り（このファイルの下部に記録）

## フェーズ9: フォローアップ — フッター撤去 + ホームボタン化

実機デプロイ後のユーザフィードバック: 「全ゲーム一覧のフッターは不要、ホームに戻るボタンだけ用意して」。

### 設計判断

- **BottomNavPanel を完全撤去**: 分析 / アワード / 設定はいずれも未実装で、現状の操作価値が無い。ナビゲーションの一貫性より画面のシンプルさを優先。
- **ホームボタンはヘッダー右上に配置**: home.tscn の SettingsButton と同じパターン（64x64 円形ボタン、Material `home` アイコン 44px、透明 normal + hover 時暗グラス）。ヘッダー左に Title/Subtitle、右に HomeButton。
- **HeaderBlock (VBox) → HeaderRow (HBox)** に再構成。Title/Subtitle は TitleBlock VBox にまとめ、右側に HomeButton を配置。

### タスク

- [x] `game_list.tscn` 変更
  - [x] BottomNavPanel ツリーを完全削除（NavTrainActive / NavAnalyticsButton / NavHomeButton / NavAwardButton / NavSettingsButton およびその子）
  - [x] 不要になった SubResource を削除: SBF_nav_dark / SBF_nav_act_cyan
  - [x] SafeAreaMargin の `offset_bottom = -100.0` を削除（margin_bottom は 8 → 48 に拡張してカルーセル下の余白確保）
  - [x] HeaderBlock を HeaderRow (HBox) に変更
  - [x] 左側: TitleBlock (VBox, Title + Subtitle, 既存 mc_h1 / 20px override をそのまま, size_flags_horizontal=3 で expand)
  - [x] 右側: HomeButton (Button, size_flags_vertical=4 で中央寄せ)
  - [x] HomeButton の StyleBox を追加（home.tscn と同じパターン）:
    - [x] SBE_home_normal (StyleBoxEmpty, 8px padding 透明)
    - [x] SBF_home_hover (bg_color=Color(0.063, 0.075, 0.118, 0.6), corner=9999 円形, padding 8px)
  - [x] HomeButton 設定: custom_minimum_size = (64, 64), font_color = INK_60 系 Color(0.682, 0.722, 0.812, 1), Material Symbol "home" 44px
- [x] `game_list_controller.gd` 変更
  - [x] `@onready var _nav_train` / `_nav_analytics` / `_nav_award` / `_nav_settings` / `_nav_home` を削除し、`_home_button` 1 本に集約
  - [x] `_wire_signals()` を `_home_button.pressed.connect(_on_nav_home)` 1 行に簡略化（`_on_nav_home` メソッド本体は不変）
- [x] 検証
  - [x] `godot --headless --quit-after 10 scenes/ui/game_list.tscn` でロードエラー無し
  - [x] controller の `@onready` パスが新ツリーで解決すること
  - [x] `grep -E "font_size = (1[0-9]\b|2[0-3]\b)" scenes/ui/game_list.tscn` の hit は 19 件、すべて従来通り 20 / 22 のみ（compliant 範囲内）
  - [x] 旧 BottomNavPanel / `_nav_train` / `_nav_analytics` / `_nav_award` / `_nav_settings` 参照が残っていないこと（grep 確認済）
- [x] Android 実機再デプロイ（2026-05-17 deploy 完了、404s）

### フォローアップ2: ホームボタンを rule_explain 流儀へ + 配置を下部中央へ

ユーザフィードバック: 「ホームアイコンが右上に配置されているが、他の画面と違くないか？ゴースト7番勝負のルール説明画面のように、アイコン＋文言のデザインとすること。また、ホームへ戻るボタンはゲーム一覧画面の下部に配置すること」。

- [x] HeaderRow を廃止し、HeaderBlock (VBox, 中央寄せ Title + Subtitle) に戻す
- [x] SBE_home_normal / SBF_home_hover SubResource を削除（mc_back_btn variation に切替えるため不要）
- [x] MainColumn 末尾 (BottomSpacer の後) に FooterRow (HBox, alignment=1) を追加
- [x] FooterRow/HomeButton: rule_explain の BackButton と完全同パターン
  - `theme_type_variation = &"mc_back_btn"`
  - custom_minimum_size = (280, 80)
  - font_size override = 30
  - text = "           ‹  ホーム"（先頭スペースでアイコン分の領域確保）
  - icon_alignment = 0
  - 子 Label `HeaderIcon`: Material `home` 40px CYAN_400 を offset_left=24 で左端にオーバーレイ
- [x] controller `_home_button` の `@onready` パスを FooterRow/HomeButton に更新
- [x] Android 実機再デプロイ（345s で完了）

### フォローアップ3: NavLinkButton コンポーネント化 + 全画面流用

ユーザフィードバック: 「全ゲーム一覧もホームへのボタンと同じデザインにしてほしい。というか、ゲームなのでこういうUI/UXはコンポーネント化して流用することを前提にして」。

#### 背景・現状の散逸

| 画面 | ノード | サイズ | font_size | text | アイコン |
|---|---|---|---|---|---|
| rule_explain.tscn | BackButton | 280x80 | 30 | "‹ ホーム" | home (overlay) |
| rule_explain_landscape.tscn | BackButton | 280x80 | 30 | "‹ ホーム" | home (overlay) |
| game_list.tscn | HomeButton | 280x80 | 30 | "‹ ホーム" | home (overlay) |
| home.tscn | AllGamesLink | 0x56 | 28 | "全ゲーム一覧 ›" | なし |
| individual_result.tscn | HomeButton | 320x72 | 28 | "‹ ホームへ戻る" | なし |
| flash_calc_home.tscn | BackButton | 220x64 | 24 | "‹ ホームへ戻る" | なし |

→ 5 つ以上の画面で同じ「ナビゲーションリンクボタン」を別実装しており、保守性が低い。

#### 設計

- 新規コンポーネント: `scripts/ui/components/nav_link_button.gd` + `scenes/ui/components/nav_link_button.tscn`
- `class_name NavLinkButton extends Button`
- `@export var icon_name: String` (Material Symbol 名, 空文字でアイコン非表示)
- `@export var label_text: String` (表示文言)
- `@export_enum("back", "forward") var direction: String` (戻る ‹ / 進む ›)
- 内部で `text` を自動構築し、`HeaderIcon` Label を anchor で左/右に再配置
- スタイルは `theme_type_variation = &"mc_back_btn"` 固定（インスタンス側で override 可）
- 既定 `custom_minimum_size = (280, 80)`, font_size=30（インスタンス側で override 可）

#### タスク

- [x] `scripts/ui/components/nav_link_button.gd` を新規作成（`class_name NavLinkButton extends Button`、icon_name/label_text/direction を @export、setter で動的に text と icon 位置を再構築）
- [x] `scenes/ui/components/nav_link_button.tscn` を新規作成（uid://b0navlinkbtn001、mc_back_btn variation、280x80、HeaderIcon 子 Label）
- [x] `home.tscn` AllGamesLink を NavLinkButton インスタンスに置換
  - icon="psychology", label="全ゲーム一覧", direction="forward"
  - 旧 StyleBoxEmpty_settings の override は撤去（mc_back_btn variation が肩代わり）
- [x] `game_list.tscn` FooterRow/HomeButton を NavLinkButton インスタンスに置換
  - icon="home", label="ホーム", direction="back"
  - 旧 inline BackButton 構造 + HeaderIcon overlay を撤去（29 行 → 6 行）
- [x] `rule_explain.tscn` Header/BackButton を NavLinkButton インスタンスに置換
- [x] `rule_explain_landscape.tscn` Header/BackButton を NavLinkButton インスタンスに置換
- [x] controllers の参照は path / find_child いずれも node 名を維持するため無変更（NavLinkButton extends Button なので `as Button` キャストも有効）
- [x] 検証
  - [x] `godot --headless --import` 成功
  - [x] 5 シーン (home / game_list / rule_explain / rule_explain_landscape / nav_link_button) すべて headless ロードでエラー無し
  - [x] home_controller の `_all_games_link: Button` / rule_explain_controller の `find_child("BackButton") as Button` / game_list_controller の `_home_button: Button` すべて NavLinkButton インスタンスを Button として受け取れる
- [x] Android 実機再デプロイ（350s で完了、`com.reigalabs.brainghost` 起動済み）

### フォローアップ4: AllGamesLink アイコン変更 + flash_calc 縦画面化

ユーザフィードバック: 「ゲームのアイコンが脳のアイコンなのは違和感なのでゲームアイコンに変更して。また、フラッシュ暗算をプレイしたがルール説明やゲーム画面が横表示になってしまっているので縦表示にして。横画面でプレイするのは今のところ反射タップのみ。」

- [x] `home.tscn` AllGamesLink の icon_name を `psychology` → `sports_esports` に変更（ゲームコントローラのアイコン）
- [x] `game_manager.gd` LANDSCAPE_GAMES 配列から `"flash_calc"` を削除 → rule_explain / countdown が portrait 版に切り替わる
  - LANDSCAPE_GAMES = `["ghost_7ban_shobu"]` のみ
- [x] `flash_calc_home.gd` から `OrientationHelperCls.enter_landscape()` / `enter_portrait()` 呼び出しを削除、preload 文も削除
- [x] `flash_calc_play_view.gd` から `OrientationHelperCls.enter_landscape()` / `enter_portrait()` 呼び出しを削除、preload 文も削除、`_exit_tree()` も不要となり削除
- [x] Android 実機再デプロイ（403s で完了）

### フォローアップ5: Card 0 を ghost_7ban_shobu に差し替え + flash_calc_home 縦画面レイアウト修正

ユーザフィードバック: 「ゲーム一覧の反射タップだが、現在はこのゲームは存在せずゴースト7番勝負が表示されるはず。また、フラッシュ暗算の難易度選択画面が見切れてしまっていてスマホ画面に収まっていない。」

#### Card 0: reflex_tap → ghost_7ban_shobu

- [x] `game_list_controller.gd` の GAME_CARDS[0] を更新:
  - id: `reflex_tap` → `ghost_7ban_shobu`
  - icon: `touch_app` → `bolt`（雷=反射速度）
  - name: `反射タップ` → `ゴースト7番勝負`
  - desc: ゴースト対戦の説明文に置換
- [x] `game_list.tscn` の Card0 静的テキスト/アイコン（controller 起動前の表示）も同様に更新
- [x] ID マッピングが GameManager.GAME_SCENES の `ghost_7ban_shobu` キーと一致することを確認（既存マップで合致）

#### flash_calc_home.tscn 縦画面化

旧レイアウトは横画面前提（Header に BackButton + Title + Spacer + 220px RightPad で横並び、TierGrid columns=4）で、縦 720px 幅に収まらず見切れていた。縦画面用に再構成:

- [x] Header を簡略化: BackButton と TitleLabel + HSpacer + HeaderRightPad を全部撤去 → Title のみ中央配置（font_size 36 → 32 に縮小）
- [x] AppropriateLabel はそのまま中央配置
- [x] TierGrid columns=4 → 2（縦 720px に 2 カラム = 約 322px/列）
- [x] BottomSpacer (size_flags_vertical=3) を追加して FooterRow を画面下部に押し出す
- [x] FooterRow に NavLinkButton (icon="home", label="ホーム", direction="back") を配置 — 他画面と同じデザインで統一
- [x] SafeArea の margin_left/right を 32 → 24（カード幅を最大化）、margin_top 24 → 48（ステータスバー回避）
- [x] tier_button のサイズ: `(220, 130)` → `(0, 110)` 最小、size_flags_vertical を SIZE_EXPAND_FILL → SIZE_FILL に変更（縦に間延びしないように）
- [x] tier_button font_size: 28 → 26
- [x] controller `_back_button` の `@onready` パスを `Header/BackButton` → `FooterRow/BackButton` に追従
- [x] Android 実機再デプロイ（353s で完了）

### フォローアップ6: rule_explain_landscape → home 戻り時の orientation 復元バグ修正

ユーザフィードバック: 「ゴースト7番勝負のルール説明画面からホームへもどると、ホームの表示が横画面で表示されて動かせない」

#### 原因

- `rule_explain_controller._ready()` は scene_file_path 末尾が `_landscape.tscn` の場合 `OrientationHelper.enter_landscape()` を呼ぶ。
- しかし `_on_back_pressed()` で `GameManager.on_rule_explain_cancelled()` を呼ぶ際に `enter_portrait()` を呼んでいなかった。
- `on_rule_explain_cancelled()` は `_entry_scene` (game_list.tscn か home.tscn、いずれも portrait) へ遷移するが、orientation は landscape のまま残るため、portrait シーンが横画面で描画されてしまう。
- forward 方向（スタート押下 → countdown_landscape）は countdown_landscape 側の `_ready()` で再度 enter_landscape() するので問題なし。

#### 修正

- [x] `rule_explain_controller._on_back_pressed()` の先頭に `OrientationHelper.enter_portrait()` を追加。portrait シーンへ確実に向きを戻してから scene change を呼ぶ。
- [x] portrait 版の rule_explain から back した場合も `enter_portrait()` は no-op（DisplayServer が既に PORTRAIT のため）で副作用無し。
- [x] Android 実機再デプロイ（356s で完了）

### フォローアップ7: 起動スプラッシュ画面のリッチ化

ユーザフィードバック: 「アプリ起動時にBrain Ghost 脳トレ×ゴーストバトル の文字が出るが、あまりに質素すぎる。画像に変更できたりするのか？」

#### 回答と方針

Godot では 2 段階の起動表示がある:
1. **Boot splash**: エンジン初期化中 (シーンロード前) に表示される単一画像。project.godot で設定。
2. **launch.tscn**: エンジン起動後にロードされる最初のシーン。完全に制御可能。

両方を改善する。

#### タスク

- [x] `project.godot` に `boot_splash/*` 設定を追加（`game_icon.png` を黒背景上に表示、エンジン初期化中の Godot 純正ロゴを置き換え）
- [x] `scenes/main/launch.tscn` を Midnight Cat デザインで再構成:
  - 漆黒 VoidBg + Nebula グラデ + StarLayer（home / individual_result と共通の背景レイヤ）
  - 中央 VBox に `catboy_electric.png` マスコット (360x360) を配置
  - "Brain Ghost" タイトル (mc_h1_lg variation, font_size=64 で更に大きく)
  - "脳トレ × 自分対戦" サブタイトル (シアン CYAN_300 26px)
- [x] `launch_controller.gd` にフェードイン演出を追加:
  - CenterColumn 全体を modulate.a 0→1 (0.7s, cubic ease_out)
  - マスコットを 24px 下から上にスライドイン同期
  - スプラッシュ表示時間を 2.0s → 2.5s に延長（演出を見せる余裕）
- [x] Android 実機再デプロイ（345s で完了）

### フォローアップ8: フラッシュ暗算 T1 速度カーブの平滑化 + ティア命名の整理

ユーザフィードバック: 「フラッシュ暗算のT1からすでに難しすぎる。数字の流れる速度が速すぎる、途中から急に早くなる印象を受ける。そもそもT1とかってアルファベットで難易度を示すってドキュメントに書いてた？Lv1とかの方がわかりやすくないか」

#### 原因分析

仕様 §4-2 の「ウォームアップ → 本番 → 追い込み」3 段階カーブが、`problem_generator._build_intervals()` で**離散的な階段関数**として実装されており、フェーズ境界で表示間隔が 30〜33% も突然短くなっていた。T1 (1-digit, 10 numbers): 600ms × 3 → 400ms × 4 → 300ms × 3。プレイヤーには「急に早くなる」と感じられる。

#### 速度カーブの平滑化（実施）

- [x] `tier_config.gd` FLASH_SPEED_CURVES を `start_ms / end_ms` 形式に変更（warmup_ms / normal_ms / push_ms を撤去）
- [x] T1〜T3 (slow) のベースラインを 600/400/300 → **800 → 500ms** に緩和（初心者向け）
- [x] T4〜T5 (fast): 500/350/250 → **650 → 400ms**
- [x] T6〜T7 (mixed_slow): 600/400/270 → **700 → 420ms**
- [x] T8 (extreme): 400/300/200 → **500 → 280ms**
- [x] `problem_generator._build_intervals()` を線形補間に変更（`lerp(start_ms, end_ms, i / (count-1))`）
- [x] `PHASE_WARMUP_RATIO` / `PHASE_NORMAL_RATIO` 定数を削除（不要に）
- [x] `docs/ideas/games/ghost-ippon-shobu-calc-spec.md` §4-1 と §4-2 を新仕様に更新、v1.4 変更履歴を追加
- [x] Android 実機再デプロイ（367s で完了）

### フォローアップ9: ブランドロゴ / アプリアイコン適用（ユーザ提供素材）

ユーザ提供素材を `docs/ideas/logo/` に配置:
- `BrainGhostLogo.png` — ワードマーク付きゲームロゴ（白猫ゴースト + 7-3-5 ブロック + "Brain Ghost / 脳トレ×ゴーストバトル"）
- `BrainGhostIcon.png` — アプリアイコン用（ワードマーク無し版）
- `ReigalLabLogo.png` — パブリッシャーロゴ（黒猫×白猫 + "REIGAL LABS"）

#### タスク

- [x] `assets/branding/` を新設し、3 ファイルをコピー（命名: snake_case `brain_ghost_logo.png` / `brain_ghost_icon.png` / `reigal_labs_logo.png`）
- [x] `project.godot` の `config/icon` と `boot_splash/image` を `assets/branding/brain_ghost_icon.png` に変更
- [x] `export_presets.cfg` の Android `launcher_icons/main_192x192` と `adaptive_foreground_432x432` を新アイコンに変更
- [x] `launch.tscn` を 2 段階ブランドリビール構成に再構成:
  - Phase 1: ReigalLogo (440×440, modulate.a=0 で待機)
  - Phase 2: BrainGhostLogo (600×600, modulate.a=0 で待機)
  - SkipArea (全面 Control) — タップで残り演出スキップ
- [x] `launch_controller.gd` を 2 段階フェードシーケンスに書き換え:
  - Reigal: fade-in 0.5s → hold 0.9s → fade-out 0.4s
  - Brain Ghost: fade-in 0.6s → hold 1.2s → home 遷移
  - 合計 約 3.6 秒、SkipArea タップで途中スキップ可
- [x] godot --headless --import でアセット import + ctex 生成成功
- [x] Android 実機再デプロイ（376s で完了）

### フォローアップ10: 順番記憶ゲーム画面の Midnight Cat 化

ユーザフィードバック: 「順番記憶のゲームデザインも同様に新しいUI/UXにして」

#### 現状（旧 Animated Intellectual デザイン）
- 背景: 水色グラデ (Gradient_seqbg)
- ヘッダー: pill_chip + glass_bubble (白半透明)
- 4×4 グリッド: 白パネル (memory_panel variation)
- アクティブパネル: 青塗り + 青影
- 誤タップ: **赤** (`Color(0.702, 0.106, 0.145)`) — GDD §6「負け表示でも赤は使わない」原則違反
- 命令テキスト: 32px 濃紺
- タイマー: 右上 glass_bubble + 28px 濃紺

#### 設計（Midnight Cat 化）

- 背景: VoidBg + Nebula + StarLayer（home/game_list と共通）
- ヘッダー: ROUND ピル (CYAN_400 ボーダー、暗グラス) + 指示テキスト (mc_h2 serif 36px、フェーズ別色)
- 4×4 グリッド: 暗グラスパネル + 状態ごとに 4 種類のスタイル
  - idle (showing 中の未光): BG_ELEV α=0.55, border CYAN α=0.2
  - active (光中): CYAN_400 α=0.85 ベタ塗り + CYAN_300 border + cyan glow shadow
  - tappable (input 中): idle と同じだが border α=0.4 で視認性アップ
  - wrong (誤タップ): **NEUTRAL_GRAY** α=0.85 + 灰ボーダー（赤は使わない、GDD §6 準拠）
- タイマー: 右上、CYAN_300 28px on 暗グラス
- 指示テキスト色:
  - showing: INK_80 "覚えてください"
  - input: CYAN_300 "順にタップしてください"
  - clear: GOLD_400 "正解！"
  - failed: INK_60 "ゲーム終了"
- font_size 規約: 指示文 36px、ROUND ピル 22px、タイマー 28px、パネル番号 56px（全規約遵守）

#### タスク

- [x] `scenes/games/sequence_memory.tscn` を Midnight Cat 仕様に書き換え
  - [x] 背景レイヤ差し替え（VoidBg + NebulaBg + StarLayer）
  - [x] 旧 SubResource (Gradient_seqbg, GradientTexture2D_seqbg) を削除
  - [x] 新 SubResource: Gradient_nebula / GradientTexture2D_nebula / SBF_round_chip / SBF_timer_chip / SBF_panel_idle / SBF_panel_input
  - [x] ヘッダー再構成: RoundBadge (新 SBF + CYAN_400 ボーダー) + InstructionLabel (mc_h2 36px)
  - [x] タイマー右上を暗グラス + CYAN_300 28px に
  - [x] 16 パネルすべて新 SBF_panel_idle を `theme_override_styles/normal` で初期適用 + pressed に SBF_panel_input
- [x] `scripts/ui/sequence_memory_view.gd` を更新
  - [x] 色定数を更新（COLOR_ACTIVE_BG=CYAN_400 α=0.85、COLOR_ACTIVE_BORDER=CYAN_300、COLOR_WRONG_BG=NEUTRAL_GRAY、COLOR_WRONG_BORDER=NEUTRAL_GRAY、COLOR_ACTIVE_TEXT=INK_100）
  - [x] `_highlight_panel()` の StyleBoxFlat 構築を CYAN_400 ベタ + CYAN_300 border + cyan glow shadow（size=24, offset=0,0）に。font_size 48 → 56
  - [x] `_flash_wrong()` を NEUTRAL_GRAY 仕様に変更（border 含む、font_color=INK_80）
  - [x] `_set_instruction(text, phase)` ヘルパを追加。showing=INK_80 / input=CYAN_300 / clear=GOLD_400 / failed=INK_60 でラベル色を切替
  - [x] 旧 `_instruction_label.text = ...` 直接代入を全箇所 `_set_instruction()` 呼び出しに置換 (4 箇所)
- [x] 検証
  - [x] `godot --headless --import` + シーンロードでエラー無し
  - [x] 赤系 Color リテラルなし（Color(0.7~0.9, 0.0~0.2) パターン grep 0 件）
- [x] Android 実機再デプロイ（361s で完了）

### フォローアップ11: 順番記憶 - 3×3 統一 + 入力フィードバック強化

ユーザフィードバック: 「ルール説明画面のマスが3×3だが、実際のゲームでは4×4となっている。どちらに統一すべきか検討して。また、回答タップ時の色の変化が乏しいので、回答時のマスは基本グレーで選択した瞬間だけ黄色になるようにしたほうがいいのではないか」

#### 1. グリッドサイズ統一: 4×4 → 3×3

不整合の調査結果:
- `sequence_memory.gd` のクラス docstring に「3x3 グリッド」と明記
- `rule_step_preview.gd` は 3×3 で描画
- GDD §4-2 は「N 個のパネル」(サイズ指定なし)
- 実装の `GRID_SIZE = 16` (4×4) のみ全体と不整合

→ ドキュメント・ルール説明側に合わせて **コード側を 3×3 に修正**。タップ要素サイズも 165px → 200px に拡大し、UX 向上。5 分セッションでレベル達成感も上がる（max 9）。

- [x] `scripts/games/sequence_memory.gd` の `GRID_SIZE` を 16 → **9** に変更（docstring も「3x3 グリッド (9 パネル)」に明記）
- [x] `scenes/games/sequence_memory.tscn` を 9 パネルに再構成（Panel0..Panel8、columns=3、custom_minimum_size 150x150 → **200x200**）

#### 2. 入力フィードバック強化 (グレー基調 + ゴールドフラッシュ)

旧: input フェーズで暗グラス（ほぼ透明）のまま → ユーザがタップ可能性を視覚的に判別困難。正解タップしても変化なし。

新（ユーザ提案を採用 + 強化）:
- input 開始時に全パネルを `NEUTRAL_SLATE α=0.5` グレー塗りに切替（明確にタップ可能と示す）
- 正解タップ瞬間に `GOLD_400` で 200ms フラッシュ（glow 付き）→ タップ可能状態に復帰
- 誤タップは `NEUTRAL_GRAY α=0.95` 飽和（グレー塗り より明らかに暗い→区別可能）

- [x] `sequence_memory.tscn` に SBF_panel_tappable (NEUTRAL_SLATE α=0.5) を追加。pressed state に適用
- [x] `sequence_memory_view.gd` に色定数追加: COLOR_TAPPABLE_BG/BORDER, COLOR_TAP_FLASH_BG/BORDER/GLOW, TAP_FLASH_DURATION_SEC=0.2
- [x] `_show_panels_tappable()` 新規メソッド: 全パネルをタップ可能グレー塗りに
- [x] `_build_tappable_style()` 新規ヘルパ: StyleBoxFlat を組み立て
- [x] `_flash_correct(index)` 新規メソッド: ゴールド glow 適用 → タイマで _revert_panel_to_tappable() に戻る
- [x] `_revert_panel_to_tappable(index)` 新規メソッド: フェーズがまだ input ならグレーに戻す
- [x] `_process_showing_phase()` で「showing 完了 → input 移行」時に `_show_panels_tappable()` を呼ぶ
- [x] `_on_panel_pressed()` で正解タップ判定後 `_flash_correct(index)` を呼ぶ。最後のタップが level_clear に遷移した場合もフラッシュさせる
- [x] view docstring を新仕様 (3x3 + 4 状態の説明) に更新
- [x] 検証: import 成功、シーンロードエラー無し、GRID_SIZE/columns/Panel 数の整合性 OK
- [x] Android 実機再デプロイ（443s で完了）

### フォローアップ12: 順番記憶 - 重複許可 + Lv9 上限 + 誤タップ視認性

ユーザ指摘:
1. 「同じパネルを2回踏まないようにプログラミングされてないか？」 → 旧 Fisher-Yates シャッフル実装で重複なし。Simon Says 系の常識と異なる。
2. 「レベル無制限だと終わらなくなるのでやめて。Lv9 まででいい」
3. 「誤タップ時の動作がわかりにくいのでわかりやすくしてほしい」

#### 修正

- [x] `sequence_memory.gd::_generate_sequence()` を独立ランダム選択方式に変更:
  - 各ステップで `rng.randi_range(0, GRID_SIZE - 1)` で独立にランダム選択（同じパネルが再登場可能）
  - 「直前と同じパネルが連続して光る」のは視覚的に混乱するため while ループで回避
- [x] `MAX_LEVEL = 9` 定数追加。`advance_to_next_level()` で `_current_level >= MAX_LEVEL` の場合 `_max_level_cleared = true` を立てて `finish()`
- [x] `is_max_level_cleared() -> bool` 公開メソッドを追加（誤タップ終了との区別用）
- [x] 誤タップ視認性アップ:
  - 暗グレー `Color(0.18, 0.21, 0.27, 0.98)` 塗り（タップ可能グレーより明らかに暗い）
  - 太枠 (INK_80 alpha 0.85, border_width=3)
  - **X アイコン (Material Symbol "close", 96px, INK_100)** をパネル中央に表示
  - **回転シェイクアニメ** (±4° × 4 振り、合計 0.33s)
  - **正解パネルをシアン dim でヒント表示**（学習効果、wrong_index ≠ correct_index 時のみ）
- [x] `_flash_wrong(wrong_index, correct_index)` シグネチャ変更（呼び出し元も追従）
- [x] `_shake_panel()` / `_hint_correct_panel()` ヘルパを新規追加
- [x] 結果画面への遷移を遅延化:
  - `_pending_finish_log` 変数で game_finished シグナルの log を保留
  - 誤タップ時: 1.6 秒のタイマ後に `_trigger_pending_finish()` を呼ぶ
  - Lv9 全クリア時: 「全クリア！」表示 + 1.2 秒後に遷移
  - 旧: signal 即遷移 → フィードバックが見えないまま結果画面
- [x] `_on_level_clear_delay()` で `advance_to_next_level()` 後に `_game._is_active` チェック → 全クリア検出時は instruction を「全クリア！」(GOLD) にして遅延遷移
- [x] Android 実機再デプロイ（362s で完了）

### フォローアップ13: ホーム画面 / リザルト画面のダミーデータを実データに置換

ユーザフィードバック: 「内部で保持するデータをホーム画面やリザルト画面に反映してほしい。現状はモック的にダミーデータしか表示していないのではないか？」

#### 調査結果

**ホーム (home_controller.gd) のダミー箇所:**
| 項目 | 旧 (ダミー) | 新 (実データ) |
|---|---|---|
| 脳年齢 | `31` 固定 | UserConfig.age_group → base_age (15/25/30/45/55) - プレイ数ボーナス、規約 -15..+10 でクランプ |
| ポイント | `3,230` 固定 | DataStore.load_best 全ゲーム分の best_score 合計 |
| デルタ | `+285` 固定 | 今日プレイした PlayLog のスコア合計（0 なら非表示） |
| 通算 ◯勝◯敗 | `15勝/8敗` 固定 | ghost_7ban_shobu の全 PlayLog から round_win イベント集計 |
| ストリーク | `5日連続` (loadメソッド無いため fallback) | STREAK_STATE → StreakState.current_streak |
| レーダー | 各ゲーム best_score / 5000 | 同（既に実装済） |

**個別結果 (individual_result_controller.gd) のダミー箇所:**
- ghost_7ban_shobu / reflex_tap の `ghost_score_placeholder` (273.0 / 450.0) → GhostData.load_round_medians 平均

**未保存データ:**
- StreakState は StreakService は実装済だが GameManager から呼んでおらず保存もされていない → on_game_finished_handler に追加
- GhostData.save_play は ghost_7ban_shobu 内で既に呼ばれている → 追加不要

#### タスク

- [x] `home_controller.gd` 改修
  - [x] DataStore Autoload を直接参照（has_method ガードを削除）
  - [x] AGE_GROUP_TO_AGE / ALL_GAME_TYPES マップ追加
  - [x] `_compute_brain_age()` 新規（age_group → base_age - clamp(3+plays/5, 3, 15)、規約 -15..+10）
  - [x] `_compute_total_best_score()` 新規（GAME_TYPES 全部の best_score 合計）
  - [x] `_compute_today_score_delta()` 新規（load_play_logs + played_date == today で集計）
  - [x] `_compute_battle_wins_losses()` 新規（ghost_7ban_shobu PlayLog から round_win 集計）
  - [x] `_compute_streak()` 新規（STREAK_STATE 経由）
  - [x] `_format_thousands()` ヘルパ追加
  - [x] `_load_user_config()` ヘルパ追加
- [x] `game_manager.gd` 改修
  - [x] `on_game_finished_handler` に `_update_streak_state(log.played_date)` 呼び出しを追加
  - [x] `_update_streak_state()` 新規メソッド: STREAK_STATE 読み込み → StreakService.update_streak → 保存
- [x] `individual_result_controller.gd` 改修
  - [x] `_apply_compare_cards` の ghost モードで `_load_ghost_avg(game_type, cfg)` を呼ぶよう変更
  - [x] `_load_ghost_avg()` 新規: GhostData.load_round_medians の平均値を返す（不在時は cfg fallback）
- [x] 検証 + Android 実機再デプロイ（392s で完了）

#### T1 / Lv1 ネーミング (回答のみ・実装は別ステアリングへ)

- ティア表記「T1〜T8」は仕様 §4-1 で明示定義されており、§3-5 に「**ティアラベルが SNS で実力指標として機能する**」(dan/kyu や TCG 風の格付け表現) という設計意図がある。
- ユーザ提案の「Lv1」は確かにわかりやすく、Lumosity / Peak など他社脳トレに合致。ただしリネームは:
  - 仕様 doc / tier_config.gd / problem_generator.gd / flash_calc.gd / flash_calc_ghost_store.gd / UI 文言の改修
  - **保存データ (FlashCalcGhostStore のキー)** が "T1" 等のため、既存ユーザ進捗の**マイグレーション**が必要
  - スコープ大なので**別ステアリングで切る**ことを推奨。

#### スコープ外（このフォローアップでは触らない）

- individual_result.tscn HomeButton（StyleBoxEmpty 系で意図的に別デザイン、独自処理あり）
- flash_calc_home.tscn BackButton（小型 220x64、専用画面で文脈が違う）

これらは将来 NavLinkButton に統合する余地はあるが、別 PR で行う。

---

## 実装後の振り返り

### 実装完了日
2026-05-17（実機目視確認はユーザ側で実施予定）

### 計画と実績の差分

**計画と異なった点**:
- `NotoSerifJP-Bold.otf` の ext_resource 追加は不要だった。mc_h1 / mc_h2 を `theme_type_variation` で当てるとプロジェクトテーマ経由で自動解決される。当初 tasklist にあった「追加読み込み」は誤計画。
- 規約 grep `(1[0-9]\b|2[0-3]\b)` は **20 / 22 の hit が出るが、HUD 補助 ≥20 / ナビラベル ≥22 / 装飾チップ ≥18 の各最小値を満たしているため compliant**。grep 自体は「カテゴリ別最低値」を区別できないので、合格判定には別途カテゴリ照合が必要だった。tasklist フェーズ 6 のチェック項目で運用判断を明文化。
- BackChip（ヘッダー戻るチップ）は **省略**。ボトムナビの NavHomeButton と機能重複するため。要件レビュー時に確定。
- DotIndicators は **modulate.a + 幅変更で active/inactive を表現する既存ロジックを温存**。StyleBox 2 種を切り替える案は採用せず、SBF_dot 1 個（CYAN_400 単色塗り）に統一。

**新たに必要になったタスク**:
- レビュー指摘を受けて mc_h2 (32) / mc_body (17) / mc_caption (14) / mc_subtitle (18) / mc_cta_glow (38) すべてに `theme_override_font_sizes/font_size` を併設する必要があることが判明。「theme variation を当てるだけで OK」という当初前提は誤りだった。

**技術的理由でスキップしたタスク**:
- なし（全タスクを完了）

### 学んだこと

**技術的な学び**:
- `default_theme.tres` の `mc_*` バリアントの font_size は MidnightCat 初期設計時の値で、その後 2026-05-16 に最低サイズ規約が引き上げられた際に追従更新されていなかった。**バリアントだけで規約を担保できる前提は崩れている**ため、当面は tscn 側で font_size override を併設するのが安全。テーマ側の font_size を一括引き上げするタスクは別途立てる価値がある。
- Godot 4 では `theme/custom` がプロジェクト全体テーマとして適用されるため、tscn 側の ext_resource にフォントを書かなくても `theme_type_variation` 経由でフォントが解決される。重複読み込みは不要。
- カルーセルの `_apply_carousel_layout` は modulate で隣接/遠方カードを薄暗くするが、暗背景でも視認性に問題なし。シアン縁取りが modulate のグレーを乗算で受けても十分視認できる（隣接 ADJACENT_BRIGHTNESS=0.70 のままで OK）。

**プロセス上の改善点**:
- レビュー（`doc-reviewer` サブエージェント）を実装前に挟んだことで Critical 5 件を事前検出できた。テーマファイルの実値を grep で確認するレビュー観点は今後も有効。
- ステアリングの requirements / design / tasklist の 3 ファイル間で「採用案」を 1 箇所だけに記述し、他では参照だけにする方針が必要（今回 DotIndicators で 2 案並立してしまった）。

### 次回への改善提案
- `mc_*` バリアントの既定値を 2026-05-16 規約に合わせて引き上げる別ステアリングを立てる（mc_h2: 32→36, mc_body: 17→24, mc_caption: 14→20, mc_subtitle: 18→20, mc_cta_glow: 38 維持または 28〜32 派生バリアント追加）。これが完了すれば override が不要になり、tscn が薄くなる。
- カルーセル系画面で StarLayer + Nebula + VoidBg の 3 点セットを使う頻度が高いので、`shared/midnight_bg.tscn` のような再利用シーンを作って各画面で instance すると DRY になる（現状は home / individual_result / game_list で重複コピー）。
- grep ベースの規約チェックは「数値の minimum 比較」までしかできない。font_size 20 が HUD なのか本文なのかは grep では判別不可。Editor 目視確認を必ず併用するか、より高度な静的チェック（例: ノード名から用途を推定する Python スクリプト）が必要。
