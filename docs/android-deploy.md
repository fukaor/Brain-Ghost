# Android 実機デプロイ手順書

## 目的と対象読者

DevContainer 内の Claude Code (Bash) から Android 実機 (moto g 66j) にゲームをデプロイし、実装 → 検証 → 改修のループを高速に回すための運用手順書。

対象読者:
- 本プロジェクトの開発者
- Claude Code セッション (人間相当の判断で実行する)

実装の詳細・設計判断は `.steering/20260512-Android実機デプロイループ整備/` を参照。

---

## 関連スクリプト

| スクリプト | 役割 |
|---|---|
| `scripts_build/connect_android.sh` | adb wireless 接続の確立・再接続 |
| `scripts_build/deploy_android.sh` | ビルド → install → 起動の統合実行 |
| `scripts_build/logcat_android.sh` | Godot 出力に絞った logcat 追跡 |

---

## 前提条件

### 環境

- DevContainer 起動済み (Docker bridge ネットワーク)
- Android SDK が `/opt/android-sdk` にインストール済み
- Godot 4.6.2 stable + Android export templates インストール済み
- export_presets.cfg に `"Android"` runnable preset 存在 + `gradle_build/use_gradle_build=true` + arm64-v8a のみ ON + `export_format=0` (APK)

### 端末

- Android 11+ (本プロジェクトでは moto g 66j / Android 15 で動作確認)
- 「ワイヤレスデバッグ」ON + 「常に許可」設定済み
- 開発機 (DevContainer ホスト) と同一 LAN

### 初回ペアリング (一度だけ)

```bash
# 端末で：設定 → システム → 開発者オプション → ワイヤレスデバッグ
# → 「デバイスとペア設定する（ペアリングコードを使用）」を開く
# → IP:PORT と 6 桁コードが表示される

adb pair 192.168.x.x:PAIRING_PORT
# プロンプトに 6 桁コードを入力 → "Successfully paired"
```

ペアリング完了後はメイン画面の **接続用ポート** (ペアリングポートとは別) を確認:

```
ワイヤレスデバッグ画面の「IPアドレスとポート」 192.168.x.x:NNNNN
```

ここで表示される `IP:PORT` を覚えておく (次回以降は `connect_android.sh` が `.android-port` から再利用)。

---

## 日次の流れ

DevContainer 起動 / 端末再起動 / Wi-Fi 切断のたびに接続セッションは切れるので、デプロイ前に接続を確認する。

### 1. 接続確認 (毎回)

```bash
bash scripts_build/connect_android.sh
```

- `.android-port` のキャッシュ → 対話プロンプト → mDNS の順で接続を試行
- `device` 状態が表示されれば成功

### 2. デプロイ

```bash
# 通常: build → install → 起動
bash scripts_build/deploy_android.sh

# デプロイ後そのまま logcat を流す
bash scripts_build/deploy_android.sh --logcat

# インストールだけ、起動しない
bash scripts_build/deploy_android.sh --no-launch

# build/android/ を消してフルリビルド
bash scripts_build/deploy_android.sh --clean
```

### 3. ログ追跡 (別ターミナル推奨)

```bash
# Godot 出力 (print, push_error) と全タグ ERROR をフィルタ
bash scripts_build/logcat_android.sh

# バッファをクリアしてから追跡
bash scripts_build/logcat_android.sh --clear
```

`Ctrl+C` で終了。

---

## コマンドリファレンス

### deploy_android.sh

| オプション | 動作 |
|---|---|
| (なし) | export_presets.cfg からパッケージ名取得 → build → force-stop → install → 起動 |
| `--logcat` | デプロイ成功後そのまま `logcat_android.sh --clear` を exec |
| `--no-launch` | install まで実行し、step [7/7] の起動を skip |
| `--clean` | `build/android/` を削除してからエクスポート |
| `--help` / `-h` | 使い方表示 |

実行フロー (全 7 ステップ):

```
[1/7] export_presets.cfg から package/unique_name を動的取得
[2/7] adb devices で端末接続確認
[3/7] .godot/ キャッシュ + android/build/ テンプレート確認 (なければ自動生成)
[4/7] godot --headless --export-debug "Android" build/android/brain-ghost.apk
[5/7] adb shell am force-stop $PACKAGE_NAME (Gradle ビルド中の adb 切断は自動再接続)
[6/7] adb install -r build/android/brain-ghost.apk
[7/7] adb shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1
```

### connect_android.sh

| 環境変数 | 既定 | 用途 |
|---|---|---|
| `PHONE_IP` | `192.168.1.111` | 端末 IP の上書き |
| `ADB` | `/opt/android-sdk/platform-tools/adb` | adb バイナリパスの上書き |

接続優先順位:
1. `.android-port` キャッシュ
2. 対話プロンプト (ポート番号入力)
3. mDNS (DevContainer bridge では多くの場合動かない)

### logcat_android.sh

| オプション | 動作 |
|---|---|
| (なし) | `adb logcat -s godot:V GodotApp:V *:E` を exec |
| `--clear` | ログバッファをクリアしてから追跡開始 |

---

## トラブルシュート

### 端末が見つからない (`adb devices` が空)

```bash
# 1. キャッシュ済みの IP:PORT で再接続
bash scripts_build/connect_android.sh

# 2. それでもダメなら端末で「ワイヤレスデバッグ」のメイン画面で
#    表示されている IP:PORT を確認、対話プロンプトで入力

# 3. ペアリングが切れた場合は再ペアリング
adb pair 192.168.x.x:PAIRING_PORT
```

### Gradle ビルド中に接続が切れる

`adb daemon` が長時間アイドルで再起動して接続が失われる。
`deploy_android.sh` の step [5/7] に自動再接続ロジックを実装済み。
再接続も失敗した場合は手動で `connect_android.sh` を実行してから再試行。

### Android build template エラー

```
ERROR: Trying to build from a gradle built template, but no version info for it exists.
```

`android/.build_version` が壊れているか、Godot バージョンが変わった可能性。

```bash
# .build_version 再生成 (Godot 4.6.2.stable の場合)
echo "4.6.2.stable" > android/.build_version

# それでもダメなら android/ ごと削除して再デプロイ (自動再展開される)
rm -rf android/
bash scripts_build/deploy_android.sh
```

### Android SDK Build-Tools / Platform エラー

```
Failed to install the following SDK components: build-tools;XX.X.X platforms;android-XX
The SDK directory is not writable
```

Godot 4.6.2 はデフォルトで SDK 35 をターゲット。DevContainer 初期状態は SDK 34 のみ。

```bash
sudo /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \
  "build-tools;35.0.1" "platforms;android-35"
```

将来的には Dockerfile に書き込んでイメージレベルで対応すべき (TODO)。

### `.godot/` キャッシュが空 / 破損

```bash
# 手動 import
godot --headless --import --quit-after 300

# それでも直らない場合は削除して再生成
rm -rf .godot/
bash scripts_build/deploy_android.sh
```

### アプリが起動しない

```bash
# パッケージが端末にあるか
adb shell pm list packages | grep brainghost

# 直接起動を試す
adb shell monkey -p com.reigalabs.brainghost -c android.intent.category.LAUNCHER 1

# logcat で起動時エラー確認
bash scripts_build/logcat_android.sh --clear
```

### Wi-Fi スリープで切れる

端末側で:
- 開発者オプション → 「画面 ON 中はスリープしない」 ON
- ネットワーク設定 → Wi-Fi → 詳細 → スリープ時の Wi-Fi 維持

---

## DevContainer 再起動時

1. **adb 接続は失われる**: `bash scripts_build/connect_android.sh` を実行
2. **`.godot/` キャッシュは Docker volume で永続化**: 通常は再 import 不要
3. **`android/build/` テンプレート**: `deploy_android.sh` 内で自動再展開される
4. **`/opt/android-sdk/platforms/android-35` 等の SDK 追加コンポーネント**: コンテナ再ビルド時に消える可能性。Dockerfile への反映を推奨

---

## 性能の目安

| シナリオ | 所要時間 (実測) |
|---|---|
| 初回 (フル Gradle ビルド + SDK ダウンロード) | 6-7 分 |
| 2 回目以降 (Gradle キャッシュあり、変更なし) | 5-6 分 |
| `--no-launch` | 5-6 分 (差は数秒) |
| `--clean` (build/android/ 削除後) | 6-7 分 |

> 当初目標の「60 秒以内」は `use_gradle_build=true` 環境では非現実的。Gradle Build を OFF にすれば数十秒に短縮可能だが、AdMob 等のサードパーティプラグインを使う際に Gradle Build が必須になるため、本プロジェクトでは使用継続。Web 版での反復検証と組み合わせて運用する。

---

## 関連ドキュメント

- `docs/architecture.md` - Android プラットフォーム分岐方針
- `docs/repository-structure.md` - `scripts_build/` 配置ルール
- `.steering/20260512-Android実機デプロイループ整備/` - 設計と実装の経緯
- `CLAUDE.md` - プロジェクト全体の方針
