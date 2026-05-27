#!/usr/bin/env bash
# ============================================================
# ブレインゴースト — Android 実機統合デプロイスクリプト
#
# 1 コマンドで以下を順次実行:
#   [1/7] export_presets.cfg からパッケージ名取得
#   [2/7] 端末接続確認 (adb)
#   [3/7] .godot/ キャッシュ確認 (なければ import)
#   [4/7] Godot ヘッドレスエクスポート (debug APK)
#   [5/7] 旧プロセス force-stop
#   [6/7] adb install -r
#   [7/7] adb shell monkey でランチャーインテント起動
#
# 使い方:
#   ./scripts_build/deploy_android.sh                 # 通常デプロイ
#   ./scripts_build/deploy_android.sh --logcat        # デプロイ後 logcat 起動
#   ./scripts_build/deploy_android.sh --no-launch     # インストールのみ
#   ./scripts_build/deploy_android.sh --clean         # build/android/ を消して再ビルド
#   ./scripts_build/deploy_android.sh --help          # 使い方
#
# 前提:
#   - 端末が adb 接続済み (未接続時は connect_android.sh を案内)
#   - export_presets.cfg に "Android" runnable preset が存在
#   - Godot 4.6.x の Android export template がインストール済み
#
# タイムアウト (環境変数で上書き可):
#   DEPLOY_EXPORT_TIMEOUT       Godot APK export 秒数 (default 600)
#   DEPLOY_IMPORT_TIMEOUT       asset import 秒数 (default 360)
#   DEPLOY_ADB_PING_TIMEOUT     端末到達確認の秒数 (default 10)
#   DEPLOY_ADB_CMD_TIMEOUT      単発 adb コマンドの秒数 (default 30)
#   DEPLOY_ADB_INSTALL_TIMEOUT  adb install -r の秒数 (default 180)
#
# 終了コード:
#   - 0: 全工程成功
#   - 1: 端末未接続 / 到達不能
#   - 2: ビルド失敗 / 設定不整合 / エクスポート タイムアウト
#   - 3: インストール失敗 / インストール タイムアウト
#   - 4: 起動失敗
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

# ----- 定数 -----

ADB="${ADB:-/opt/android-sdk/platform-tools/adb}"
[[ -x "$ADB" ]] || ADB="$(command -v adb)"
GODOT="${GODOT:-godot}"
PRESET_NAME="Android"
APK_PATH="build/android/brain-ghost.apk"

# ----- タイムアウト (環境変数で上書き可) -----
# 主犯対策: ステップ [4] エクスポートはどれだけ重くても必ず時間制限する
DEPLOY_EXPORT_TIMEOUT="${DEPLOY_EXPORT_TIMEOUT:-600}"   # Godot APK export (秒)
DEPLOY_IMPORT_TIMEOUT="${DEPLOY_IMPORT_TIMEOUT:-360}"   # godot --import
DEPLOY_ADB_PING_TIMEOUT="${DEPLOY_ADB_PING_TIMEOUT:-10}" # adb shell true 到達確認
DEPLOY_ADB_CMD_TIMEOUT="${DEPLOY_ADB_CMD_TIMEOUT:-30}"  # 単発 adb コール
DEPLOY_ADB_INSTALL_TIMEOUT="${DEPLOY_ADB_INSTALL_TIMEOUT:-180}" # APK install

# ----- 引数パース -----

OPT_LOGCAT=0
OPT_NO_LAUNCH=0
OPT_CLEAN=0

usage() {
  sed -n '2,/^# =\{10,\}$/p' "$0" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    --logcat) OPT_LOGCAT=1 ;;
    --no-launch) OPT_NO_LAUNCH=1 ;;
    --clean) OPT_CLEAN=1 ;;
    --help|-h) usage; exit 0 ;;
    *)
      echo "❌ unknown option: $arg"
      echo "   use --help for usage"
      exit 1
      ;;
  esac
done

# ----- エラーハンドリング -----

CURRENT_STEP="initializing"
on_error() {
  local exit_code=$?
  echo "" >&2
  echo "❌ Failed at step: $CURRENT_STEP (exit $exit_code)" >&2
  exit "$exit_code"
}
trap on_error ERR

# ----- ステップ [1/7]: パッケージ名取得 -----

CURRENT_STEP="[1/7] extract package_name"
echo "==> $CURRENT_STEP"

if [[ ! -f export_presets.cfg ]]; then
  echo "   ❌ export_presets.cfg が見つかりません" >&2
  exit 2
fi

PACKAGE_NAME=$(grep -E '^package/unique_name=' export_presets.cfg \
  | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [[ -z "$PACKAGE_NAME" ]]; then
  echo "   ❌ package/unique_name が export_presets.cfg に見つかりません" >&2
  exit 2
fi

echo "   PACKAGE_NAME = $PACKAGE_NAME"

# ----- ステップ [2/7]: 端末接続確認 -----

CURRENT_STEP="[2/7] check device"
echo "==> $CURRENT_STEP"

if ! "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit found?0:1}'; then
  echo "   ❌ 端末が接続されていません" >&2
  echo "   → bash scripts_build/connect_android.sh を実行してから再試行" >&2
  exit 1
fi

DEVICE=$("$ADB" devices | awk '$2=="device" {print $1; exit}')
echo "   device = $DEVICE"

# 到達確認: リスト上に居ても No route to host で実通信できないケースを早期検出
# (前回コンテナクラッシュの遠因 = adb 再接続ループ放置)
if ! timeout "${DEPLOY_ADB_PING_TIMEOUT}s" "$ADB" -s "$DEVICE" shell true >/dev/null 2>&1; then
  echo "   ❌ 端末 $DEVICE はリストに居ますが到達不能 (${DEPLOY_ADB_PING_TIMEOUT}s 以内に応答なし)" >&2
  echo "      → adb デーモンを停止して再接続ループを断つ" >&2
  "$ADB" kill-server >/dev/null 2>&1 || true
  echo "      → 端末側 Wi-Fi / USB を確認後 connect_android.sh で再接続してください" >&2
  exit 1
fi

# ----- ステップ [3/7]: キャッシュ & Android build template 確認 -----

CURRENT_STEP="[3/7] ensure caches & android build template"
echo "==> $CURRENT_STEP"

# .godot/ キャッシュ
if [[ ! -d .godot ]] || [[ -z "$(ls -A .godot 2>/dev/null)" ]]; then
  echo "   .godot キャッシュなし、import を実行 (上限 ${DEPLOY_IMPORT_TIMEOUT}s)"
  if ! timeout --kill-after=15s "${DEPLOY_IMPORT_TIMEOUT}s" \
       "$GODOT" --headless --import --quit-after 300; then
    rc=$?
    if [[ $rc -eq 124 || $rc -eq 137 ]]; then
      echo "   ❌ asset import が ${DEPLOY_IMPORT_TIMEOUT}s でタイムアウト" >&2
      echo "      → DEPLOY_IMPORT_TIMEOUT=600 等で延長可能" >&2
    else
      echo "   ❌ asset import に失敗 (rc=$rc)。Godot バージョン・プロジェクト構成を確認してください" >&2
    fi
    exit 2
  fi
else
  echo "   .godot キャッシュあり (skip import)"
fi

# android/build/ テンプレート (gradle_build=true 用)
ANDROID_BUILD_DIR="android/build"
ANDROID_TEMPLATE_ZIP="$HOME/.local/share/godot/export_templates/4.6.2.stable/android_source.zip"
if [[ ! -f "$ANDROID_BUILD_DIR/build.gradle" ]]; then
  if [[ ! -f "$ANDROID_TEMPLATE_ZIP" ]]; then
    echo "   ❌ Android source template が見つかりません: $ANDROID_TEMPLATE_ZIP" >&2
    echo "   → Godot 4.6.2 の export templates を再インストールしてください" >&2
    exit 2
  fi
  echo "   android/build/ テンプレートなし、$ANDROID_TEMPLATE_ZIP を展開"
  mkdir -p "$ANDROID_BUILD_DIR"
  unzip -q -o "$ANDROID_TEMPLATE_ZIP" -d "$ANDROID_BUILD_DIR"
  touch "$ANDROID_BUILD_DIR/.gdignore"
  echo "   展開完了 + .gdignore 作成"
else
  echo "   android/build/ テンプレートあり (skip)"
fi

# ----- ステップ [4/7]: エクスポート -----

CURRENT_STEP="[4/7] export APK"
echo "==> $CURRENT_STEP"

if [[ "$OPT_CLEAN" -eq 1 ]]; then
  echo "   --clean: build/android/ を削除"
  rm -rf build/android
fi
mkdir -p build/android

EXPORT_LOG=$(mktemp)
echo "   timeout = ${DEPLOY_EXPORT_TIMEOUT}s (DEPLOY_EXPORT_TIMEOUT で上書き可)"
if ! timeout --kill-after=30s "${DEPLOY_EXPORT_TIMEOUT}s" \
     "$GODOT" --headless --export-debug "$PRESET_NAME" "$APK_PATH" > "$EXPORT_LOG" 2>&1; then
  rc=$?
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    echo "   ❌ Godot export が ${DEPLOY_EXPORT_TIMEOUT}s でタイムアウト (rc=$rc)" >&2
    echo "      → DEPLOY_EXPORT_TIMEOUT=900 等で延長可能" >&2
  else
    echo "   ❌ Godot export に失敗 (rc=$rc, 末尾 20 行):" >&2
  fi
  tail -20 "$EXPORT_LOG" >&2
  rm -f "$EXPORT_LOG"
  exit 2
fi
rm -f "$EXPORT_LOG"

if [[ ! -f "$APK_PATH" ]]; then
  echo "   ❌ APK が生成されませんでした ($APK_PATH)" >&2
  exit 2
fi

APK_SIZE=$(du -h "$APK_PATH" | awk '{print $1}')
echo "   APK = $APK_PATH ($APK_SIZE)"

# ----- ステップ [5/7]: 旧プロセス停止 (Gradle ビルド中に切断された場合は再接続) -----

CURRENT_STEP="[5/7] force-stop previous process"
echo "==> $CURRENT_STEP"

# Gradle ビルド中に adb daemon が再起動して接続が切れることがある → 再接続を試みる
if ! "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit found?0:1}'; then
  echo "   ⚠ 端末との接続が切れました。再接続を試行..."
  if [[ -f .android-port ]]; then
    CACHED=$(tr -d '[:space:]' < .android-port)
    "$ADB" connect "$CACHED" >/dev/null 2>&1 || true
    sleep 0.5
  fi
  if ! "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit found?0:1}'; then
    echo "   ❌ 再接続に失敗。bash scripts_build/connect_android.sh を実行してから再試行" >&2
    exit 1
  fi
  echo "   ✅ 再接続成功"
fi

timeout "${DEPLOY_ADB_CMD_TIMEOUT}s" "$ADB" shell am force-stop "$PACKAGE_NAME"
echo "   stopped $PACKAGE_NAME"

# ----- ステップ [6/7]: インストール -----

CURRENT_STEP="[6/7] install APK"
echo "==> $CURRENT_STEP"

INSTALL_LOG=$(mktemp)
if ! timeout --kill-after=15s "${DEPLOY_ADB_INSTALL_TIMEOUT}s" \
     "$ADB" install -r "$APK_PATH" > "$INSTALL_LOG" 2>&1; then
  rc=$?
  if [[ $rc -eq 124 || $rc -eq 137 ]]; then
    echo "   ❌ adb install が ${DEPLOY_ADB_INSTALL_TIMEOUT}s でタイムアウト (rc=$rc)" >&2
  else
    echo "   ❌ adb install に失敗 (rc=$rc):" >&2
  fi
  cat "$INSTALL_LOG" >&2
  rm -f "$INSTALL_LOG"
  echo "   → ストレージ空き容量・署名整合性を確認 (--clean を試す)" >&2
  exit 3
fi
grep -E "(Success|Performing|Streamed)" "$INSTALL_LOG" | head -3
rm -f "$INSTALL_LOG"

# ----- ステップ [7/7]: 起動 -----

CURRENT_STEP="[7/7] launch app"
if [[ "$OPT_NO_LAUNCH" -eq 1 ]]; then
  echo "==> $CURRENT_STEP (skipped: --no-launch)"
else
  echo "==> $CURRENT_STEP"
  LAUNCH_LOG=$(mktemp)
  if ! timeout "${DEPLOY_ADB_CMD_TIMEOUT}s" "$ADB" shell monkey -p "$PACKAGE_NAME" \
       -c android.intent.category.LAUNCHER 1 > "$LAUNCH_LOG" 2>&1; then
    echo "   ❌ アプリ起動に失敗:" >&2
    cat "$LAUNCH_LOG" >&2
    rm -f "$LAUNCH_LOG"
    exit 4
  fi
  rm -f "$LAUNCH_LOG"
  echo "   launched $PACKAGE_NAME"
fi

# ----- 完了 -----

echo ""
echo "✅ Done in ${SECONDS}s"

if [[ "$OPT_LOGCAT" -eq 1 ]]; then
  echo ""
  echo "📡 starting logcat..."
  exec bash scripts_build/logcat_android.sh --clear
fi
