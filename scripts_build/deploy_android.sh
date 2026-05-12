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
# 終了コード:
#   - 0: 全工程成功
#   - 1: 端末未接続
#   - 2: ビルド失敗 / 設定不整合
#   - 3: インストール失敗
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

# ----- ステップ [3/7]: キャッシュ & Android build template 確認 -----

CURRENT_STEP="[3/7] ensure caches & android build template"
echo "==> $CURRENT_STEP"

# .godot/ キャッシュ
if [[ ! -d .godot ]] || [[ -z "$(ls -A .godot 2>/dev/null)" ]]; then
  echo "   .godot キャッシュなし、import を実行 (数分かかる場合あり)"
  "$GODOT" --headless --import --quit-after 300 || {
    echo "   ❌ asset import に失敗。Godot バージョン・プロジェクト構成を確認してください" >&2
    exit 2
  }
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
if ! "$GODOT" --headless --export-debug "$PRESET_NAME" "$APK_PATH" > "$EXPORT_LOG" 2>&1; then
  echo "   ❌ Godot export に失敗 (末尾 20 行):" >&2
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

"$ADB" shell am force-stop "$PACKAGE_NAME"
echo "   stopped $PACKAGE_NAME"

# ----- ステップ [6/7]: インストール -----

CURRENT_STEP="[6/7] install APK"
echo "==> $CURRENT_STEP"

INSTALL_LOG=$(mktemp)
if ! "$ADB" install -r "$APK_PATH" > "$INSTALL_LOG" 2>&1; then
  echo "   ❌ adb install に失敗:" >&2
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
  if ! "$ADB" shell monkey -p "$PACKAGE_NAME" \
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
