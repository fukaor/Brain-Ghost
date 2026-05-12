# 要求内容

## 概要

Claude Code (Bash) から moto g 66j (Android 15) 実機への「ビルド → インストール → 起動 → ログ追跡」を 1 コマンドで実行できる仕組みを整備する。Godot エディタ GUI を使わずデプロイループを完結させ、何度繰り返しても再現性のある形でスクリプト + ドキュメント化する。

## 背景

- moto g 66j を脳トレ検証用に購入し、ワイヤレス ADB 接続まで成功 (端末 `192.168.1.111:42215`)
- DevContainer (Docker bridge) 内で Godot 4.6.2 stable + Android SDK が完備、export_presets.cfg は arm64-only + Gradle Build 有効済み
- 開発フローとして「実装 → 実機検証 → 改修」を高頻度で回すため、毎回エディタを開いて電話アイコンをクリックする運用ではなく Claude Code から完結させたい
- 過去の Web デプロイ自動化(`scripts_build/`) と同じ構造に揃えることで、コードベース内に分散した補助スクリプトの一貫性を保つ

## 実装対象の機能

### 1. 統合デプロイスクリプト (`scripts_build/deploy_android.sh`)

1 コマンドで以下を順次実行 (全 7 ステップ):

1. パッケージ名を `export_presets.cfg` から動的取得 (single source of truth)
2. 端末接続確認 (`adb devices` で `device` 状態が見えること)
3. `.godot/` キャッシュ未生成時は `godot --headless --import` で事前 import
4. Godot ヘッドレスエクスポート (`godot --headless --export-debug "Android" build/android/brain-ghost.apk`)
5. 旧プロセス強制終了 (`adb shell am force-stop $PACKAGE_NAME`)
6. APK 上書きインストール (`adb install -r build/android/brain-ghost.apk`)
7. アプリ起動 (`adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1`)

最後にデプロイ所要時間を表示。

オプションフラグで挙動切り替え:
- `--logcat` : デプロイ後 logcat 追跡をそのまま開始
- `--no-launch` : インストールのみで起動しない
- `--clean` : `build/android/` を消してフルリビルド
- `--help` : 使い方表示

> 起動は `monkey` のランチャーインテント経由で行うため、Activity クラス名 (`com.godot.game.GodotApp` 等) のハードコードは不要。Godot バージョン差・export 設定差にロバスト。

### 2. 接続維持スクリプト (`scripts_build/connect_android.sh`)

毎回ポート番号が変わる adb wireless の再接続を補助。優先順位:

1. **キャッシュファイル** `.android-port` (gitignore 対象) に前回成功した `IP:PORT` を保存しておき、まずそれで `adb connect` を試す
2. **対話プロンプト** で接続用ポート番号を入力させ、`PHONE_IP:PORT` で接続。成功したら `.android-port` に書き戻し
3. **mDNS** (`adb mdns services`) は DevContainer の bridge ネットワークでは動かないことが多いため、最後の保険として試行

接続後 `adb devices -l` で結果を表示。

### 3. ログ追跡スクリプト (`scripts_build/logcat_android.sh`)

- `adb logcat -s godot:V GodotApp:V *:E` を実行
- `--clear` フラグで起動前にログクリア
- Ctrl+C で安全に終了

### 4. 手順書 (`docs/android-deploy.md`)

開発者およびClaude Code が参照する手順書:
- 前提条件 (ワイヤレスデバッグ有効化、ペアリング済み)
- 各スクリプトのコマンドリファレンスとよくあるフロー
- トラブルシュート表 (端末が見えない / インストール失敗 / 起動しない)
- DevContainer 特有の注意点 (再起動後の adb connect 再実行、`.godot/` キャッシュ)

## 受け入れ条件

### 統合デプロイスクリプト

- [ ] `scripts_build/deploy_android.sh` が実行権限付きで存在する
- [ ] パッケージ名を `export_presets.cfg` から動的に抽出している
- [ ] 引数なしで実行すると「import (必要時) → export → force-stop → install → start」が順に通る
- [ ] 端末未接続時は分かりやすいエラーメッセージで終了する (`exit 1`)
- [ ] エクスポート失敗時はその時点で停止し、ログを抜粋表示する
- [ ] `--logcat` を付けるとデプロイ後に logcat が起動する
- [ ] `--clean` を付けると `build/android/` を削除してから実行する
- [ ] `--no-launch` を付けるとインストールのみで起動しない
- [ ] `--help` で使い方が表示される
- [ ] 所要時間 (実時間秒) を最後に出力する

### 接続維持スクリプト

- [ ] `scripts_build/connect_android.sh` が実行権限付きで存在する
- [ ] `.android-port` のキャッシュ値で再接続を試みる
- [ ] 失敗時は対話プロンプトでポート入力を求める
- [ ] 成功した接続情報を `.android-port` に書き戻す
- [ ] 接続後 `adb devices -l` の結果を表示する

### ログ追跡スクリプト

- [ ] `scripts_build/logcat_android.sh` が実行権限付きで存在する
- [ ] Godot 出力 (`godot` タグ) と GodotApp タグ、全タグの Error が流れる
- [ ] `--clear` フラグで起動時にログクリア

### 手順書

- [ ] `docs/android-deploy.md` が存在する
- [ ] 「初回ペアリング」「日次の流れ」「トラブルシュート」のセクションを持つ
- [ ] 各スクリプトの引数・出力例が記載されている
- [ ] DevContainer 再起動時に必要な再接続手順が明記されている
- [ ] `.godot/` キャッシュに関する注意が記載されている

### 動作確認

- [ ] 実機に APK がインストールされ、`scenes/main/launch.tscn` 相当が起動する
- [ ] アプリのタイトルが「ブレインゴースト」として端末に表示される
- [ ] `adb logcat -s godot:V` で `print()` 出力が見える

## 成功指標

- インクリメンタルビルドで **60 秒以内** に実機画面が再起動するサイクルが回る
- Claude Code のチャットから `bash scripts_build/deploy_android.sh --logcat` 一発でデプロイ + ログ追跡まで開始できる
- スクリプトの出力が読みやすく、各ステップの成否が一目で分かる

## スコープ外

このフェーズでは以下は実装しない:

- Web版デプロイの整備 (将来 `scripts_build/deploy_web.sh` として別途)
- Release ビルド (署名付き AAB 生成、Play Console アップロード)
- Godot Remote Debug の検証 (Android では既知バグあり、別フェーズで検証)
- scrcpy 統合 (画面ミラーは後段で検討、まずは実機を手で操作)
- Makefile / Justfile 化 (3 本のスクリプトを直接実行できれば十分)
- 複数端末対応 (デバイスは moto g 66j 単一を前提)
- Android Studio / gradle CLI 直叩き (Godot のエクスポート経由で完結)

## 参照ドキュメント

- `docs/repository-structure.md` - `scripts_build/` 配置ルール
- `docs/development-guidelines.md` - コーディング規約
- `docs/architecture.md` - Android プラットフォーム分岐
- `CLAUDE.md` - プロジェクト全体の方針 (ワイヤレスデバッグ・パッケージ名)
- `export_presets.cfg` - パッケージ名 `com.reigalabs.brainghost`, runnable preset "Android"
