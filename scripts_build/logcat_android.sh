#!/usr/bin/env bash
# ============================================================
# ブレインゴースト — Android logcat フィルタ追跡スクリプト
#
# Godot 出力 (print, push_error) と GodotApp タグ、全タグの ERROR を抽出。
# 通常の adb logcat はノイズが多すぎるため、開発で見たい情報だけに絞る。
#
# 使い方:
#   ./scripts_build/logcat_android.sh
#     → そのまま追跡を開始 (Ctrl+C で終了)
#
#   ./scripts_build/logcat_android.sh --clear
#     → ログバッファをクリアしてから追跡を開始
#
# フィルタ:
#   godot:V       GDScript の print() / push_error()
#   GodotApp:V    Java/Android 側エンジンログ
#   *:E           全タグの ERROR レベル (Android システムエラー)
#
# 前提:
#   - adb で端末が接続済み (未接続時は connect_android.sh を案内)
#
# 終了コード:
#   - 0: 正常終了 (Ctrl+C)
#   - 1: 端末未接続
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

ADB="${ADB:-/opt/android-sdk/platform-tools/adb}"
[[ -x "$ADB" ]] || ADB="$(command -v adb)"

CLEAR=0
for arg in "$@"; do
  case "$arg" in
    --clear) CLEAR=1 ;;
    --help|-h)
      sed -n '2,/^# =\{10,\}$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "❌ unknown option: $arg"
      echo "   use --help for usage"
      exit 1
      ;;
  esac
done

# ----- 端末接続確認 -----

if ! "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit found?0:1}'; then
  echo "❌ 端末が接続されていません"
  echo "   先に: bash scripts_build/connect_android.sh"
  exit 1
fi

# ----- ログクリア (オプション) -----

if [[ "$CLEAR" -eq 1 ]]; then
  echo "🧹 logcat buffer clear"
  "$ADB" logcat -c
fi

# ----- 追跡開始 -----

echo "📡 streaming: godot:V GodotApp:V *:E   (Ctrl+C で終了)"
exec "$ADB" logcat -s godot:V GodotApp:V '*:E'
