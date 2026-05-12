# 設計書

## アーキテクチャ概要

シェルスクリプト 3 本構成。各スクリプトは単一責任で、相互に依存しない。共通設定はスクリプト先頭の変数で集約。

```
┌─────────────────────────────────────────────────────────┐
│  Claude Code (Bash)                                      │
└──────────────┬──────────────┬───────────────────────────┘
               │              │              │
               ▼              ▼              ▼
       deploy_android.sh  connect_android.sh  logcat_android.sh
               │              │              │
               ▼              ▼              ▼
       ┌──────────┐    ┌──────────┐    ┌──────────┐
       │  godot   │    │   adb    │    │   adb    │
       │ --headless│    │ connect  │    │  logcat  │
       │ --export │    │          │    │   -s     │
       └─────┬────┘    └─────┬────┘    └──────────┘
             │               │
             ▼               ▼
       ┌──────────────────────────┐
       │     moto g 66j (LAN)     │
       └──────────────────────────┘
```

## コンポーネント設計

### 1. deploy_android.sh

**責務**:
- Godot プロジェクトを APK にビルド
- 旧プロセスを停止して新 APK をインストール
- アプリを起動
- 経過時間とステップ進捗を表示

**実装の要点**:
- `set -euo pipefail` で fail-fast
- パッケージ名は `export_presets.cfg` から動的取得 (`grep + sed`)
- adb のパスは `/opt/android-sdk/platform-tools/adb` を優先、PATH の adb にフォールバック
- 起動は `monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1` でランチャーインテント経由 (Activity 名のハードコード不要)
- 各ステップに `echo "==> [N/7] ..."` の進捗ヘッダを出す
- `SECONDS` 組み込み変数で経過時間を表示
- 引数パース: `--logcat`, `--no-launch`, `--clean`, `--help`
- 異常終了時の trap で「最後にどのステップで失敗したか」を提示
- `.godot/` キャッシュ未生成時は事前に `godot --headless --import --quit` を実行

**動的なパッケージ名取得**:
```bash
PACKAGE_NAME=$(grep -E '^package/unique_name=' export_presets.cfg \
  | head -1 | sed 's/.*"\(.*\)".*/\1/')
# fail-fast: 取得できなければ exit
[[ -z "$PACKAGE_NAME" ]] && { echo "❌ package_name not found in export_presets.cfg"; exit 2; }
```

**戻り値**:
- 0: 全工程成功
- 1: 端末未接続
- 2: ビルド失敗・設定ファイル不整合
- 3: インストール失敗
- 4: 起動失敗

### 2. connect_android.sh

**責務**:
- 毎回ポート番号が変わる adb wireless 接続の再確立
- 成功した接続情報をキャッシュして再利用

**実装の要点**:
- 環境変数 `PHONE_IP` で端末 IP を指定 (既定 `192.168.1.111`)
- 接続優先順位 (上から試す):
  1. **キャッシュファイル `.android-port`**: 前回成功した `IP:PORT` を保存しておき、まず `adb connect` を試す
  2. **対話プロンプト**: ポート番号を入力させ、`adb connect $PHONE_IP:$PORT` を実行
  3. **mDNS** (`adb mdns services`): bridge ネットワークでは動かないことが多いが保険として試行
- 接続成功時は `.android-port` に書き戻す
- 接続後 `adb devices -l` で確認
- `.android-port` は gitignore 対象

**.android-port ファイルフォーマット**:
```
192.168.1.111:42215
```
(単一行、`IP:PORT` のみ)

**戻り値**:
- 0: 接続成功 (device 状態)
- 1: 接続失敗

### 3. logcat_android.sh

**責務**:
- Godot アプリのログのみを抽出

**実装の要点**:
- フィルタ: `godot:V GodotApp:V *:E`
  - `godot` = GDScript `print()` 由来
  - `GodotApp` = Java/Android 側
  - `*:E` = 全タグの ERROR レベル (Android システムエラー)
- `--clear` フラグ時は `adb logcat -c` で起動時にバッファクリア
- 端末未接続時は `connect_android.sh` の実行を促す
- SIGINT で adb logcat プロセスを綺麗に終了

### 4. docs/android-deploy.md

**責務**:
- 開発者と Claude Code 双方が読む手順書

**実装の要点**:
- マークダウン構造: 前提 / 初回セットアップ / 日次の流れ / コマンドリファレンス / トラブルシュート
- 既存 `docs/` の他ファイルと同じ目次構成・文体を踏襲
- Claude Code に「いつ・どのコマンドを叩くべきか」が判断できる具体例を含む
- `.godot/` キャッシュの初期化に関する注意を「DevContainer 再起動時」セクションに記載

## データフロー

### 通常デプロイ (引数なし、全 7 ステップ)

```
1. ユーザ: bash scripts_build/deploy_android.sh
2. [1/7] パッケージ名取得: export_presets.cfg から PACKAGE_NAME 抽出
3. [2/7] 端末接続確認: adb devices で device 状態確認 (失敗→exit 1)
4. [3/7] .godot/ キャッシュ確認: なければ godot --headless --import --quit
5. [4/7] エクスポート: godot --headless --export-debug "Android" build/android/brain-ghost.apk
6. [5/7] 旧プロセス停止: adb shell am force-stop $PACKAGE_NAME
7. [6/7] インストール: adb install -r build/android/brain-ghost.apk
8. [7/7] 起動: adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1
9. 経過時間表示 (例: "✅ Done in 47s")
10. 端末: ブレインゴーストが起動
```

### ログ追跡付きデプロイ

```
1〜9: 通常デプロイと同じ
10. スクリプト: exec bash scripts_build/logcat_android.sh --clear
11. ターミナル: logcat ストリームを表示 (Ctrl+C で終了)
```

### 端末未接続からのリカバリ

```
1. ユーザ: bash scripts_build/deploy_android.sh
2. スクリプト: adb devices で device が見当たらない
3. スクリプト: "Run: bash scripts_build/connect_android.sh" を出力して exit 1
4. ユーザ: bash scripts_build/connect_android.sh
5. スクリプト: .android-port を試す → 失敗
6. スクリプト: 対話プロンプトでポート入力
7. スクリプト: adb connect → device 状態確認 → .android-port 更新
8. ユーザ: bash scripts_build/deploy_android.sh (再実行)
```

## エラーハンドリング戦略

### スクリプトレベル

```bash
set -euo pipefail
CURRENT_STEP="initializing"
trap 'echo "❌ Failed at step: $CURRENT_STEP" >&2' ERR
```

各ステップの先頭で `CURRENT_STEP="step name"` を設定し、ERR trap で表示。

### ステップ別の対処メッセージ

| 失敗ステップ | 出力メッセージ | 終了コード |
|---|---|---|
| package_name 抽出 | "package_name not found in export_presets.cfg" | 2 |
| adb devices | "Device not connected. Run: scripts_build/connect_android.sh" | 1 |
| .godot import | "Asset import failed. Check Godot version and project files." | 2 |
| godot export | "Godot export failed. Check export_presets.cfg." | 2 |
| adb install | "Install failed. Try: --clean, or check storage" | 3 |
| adb start (monkey) | "App launch failed. Check package is installed." | 4 |

### Godot エクスポートのログ抜粋

エクスポート失敗時は `godot` の stderr 末尾 20 行を表示。

## テスト戦略

### 動作確認 (手動)

- [ ] `connect_android.sh` を実行し `device` 状態になることを確認
- [ ] `deploy_android.sh` を実行し APK が install され起動することを確認
- [ ] `deploy_android.sh --clean` でフルリビルドが通ることを確認
- [ ] `deploy_android.sh --logcat` でデプロイ後に logcat が流れることを確認
- [ ] `deploy_android.sh --no-launch` でインストールのみで止まることを確認
- [ ] `deploy_android.sh --help` で使い方が表示されることを確認
- [ ] 端末未接続時のエラーメッセージが分かりやすいことを確認

### ユニットテスト

シェルスクリプトのユニットテストは行わない (動作確認で代替)。
`bash -n` でシンタックスチェック、`shellcheck` が利用可能なら併用。

## 依存ライブラリ

新規追加なし。既存環境に含まれるものを使う:

- `adb` (`/opt/android-sdk/platform-tools/adb`)
- `godot` (`/usr/local/bin/godot` 4.6.2.stable)
- `bash` 5.x
- `coreutils` (`mkdir`, `rm`, `date`, `grep`, `sed`)

## ディレクトリ構造

新規作成・変更されるファイル:

```
/workspace/
├── scripts_build/
│   ├── deploy_android.sh        ← 新規
│   ├── connect_android.sh       ← 新規
│   └── logcat_android.sh        ← 新規
├── docs/
│   └── android-deploy.md        ← 新規
├── build/                       ← 実行時に生成 (gitignore)
│   └── android/
│       └── brain-ghost.apk
├── .android-port                ← 実行時に生成 (gitignore)
└── .gitignore                   ← build/ と .android-port を追加
```

## 実装の順序

1. **準備**: `.gitignore` の確認・追記 (`build/`, `.android-port`)
2. **connect_android.sh**: 最も単純。先に作って動作確認することで、後段のデバッグ環境を確保
3. **logcat_android.sh**: 単機能。Godot 出力が見える状態を作る
4. **deploy_android.sh**: 上記 2 本を内部参照する形で構築
5. **docs/android-deploy.md**: 動作確認後に確定情報をまとめる
6. **動作確認**: 実機で全パターンを通す
7. **振り返り**: tasklist.md に記録

## セキュリティ考慮事項

- 署名 keystore (`/home/godot/.local/share/godot/keystores/debug.keystore`) は **debug 専用**。release ビルド時は別途扱う (今回はスコープ外)
- パッケージ名 `com.reigalabs.brainghost` はソース管理されている公開情報。秘匿不要
- スクリプトは LAN 内通信のみ。外部送信なし

## パフォーマンス考慮事項

- Gradle ビルドキャッシュは Godot data volume (`/home/godot/.local/share/godot`) で永続化済み
- 2 回目以降のインクリメンタルビルドは 30〜45 秒が目安
- `--clean` 指定時は `build/android/` のみ削除し、Godot 内部キャッシュ (`.godot/`) は保持
- 初回 `.godot/` import は数分かかる場合あり (アセット量に依存)
- arm64-v8a 単独エクスポートで APK 縮小済み

## 将来の拡張性

- Release ビルドフラグは将来追加時に YAGNI に基づき設計
- scrcpy 統合は `deploy_android.sh` に `--mirror` フラグとして将来追加
- Web版用に `deploy_web.sh` を同じスタイルで別途整備 (今回スコープ外)
- Makefile or just による短縮コマンド化は、3 本のスクリプトが安定してから検討
