#!/usr/bin/env bash
# ============================================================
# ブレインゴースト — Android 実機ワイヤレス接続スクリプト
#
# adb wireless で実機 (moto g 66j 等) に接続する補助。
# DevContainer 環境では Wi-Fi ADB のポートが端末再起動・Wi-Fi 切断のたびに
# 変わるため、前回成功した IP:PORT を .android-port にキャッシュして再利用する。
#
# 使い方:
#   ./scripts_build/connect_android.sh
#     → .android-port → 対話プロンプト → mDNS の順に試行
#
# 環境変数:
#   PHONE_IP   端末の LAN IP (既定: 192.168.1.111)
#
# 接続優先順位:
#   1. .android-port にキャッシュされた IP:PORT で adb connect
#   2. 対話プロンプトでポートを入力させ adb connect
#   3. mDNS (`adb mdns services`) で自動探索 (bridge では多くの場合動かない)
#
# 前提:
#   - 端末側で「ワイヤレスデバッグ」が ON
#   - 初回ペアリング (adb pair) は完了済み
#   - 端末と DevContainer ホストが同一 LAN
#
# 終了コード:
#   - 0: device 状態で接続成功
#   - 1: 接続失敗
# ============================================================
set -euo pipefail

cd "$(dirname "$0")/.."

PHONE_IP="${PHONE_IP:-192.168.1.111}"
PORT_FILE=".android-port"
ADB="${ADB:-/opt/android-sdk/platform-tools/adb}"
[[ -x "$ADB" ]] || ADB="$(command -v adb)"

# ----- ヘルパー関数 -----

is_device_online() {
  "$ADB" devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit found?0:1}'
}

try_connect() {
  local endpoint="$1"
  echo "  → trying $endpoint"
  "$ADB" connect "$endpoint" 2>&1 | grep -qE "(connected|already connected)" || return 1
  sleep 0.5
  is_device_online
}

save_port() {
  echo "$1" > "$PORT_FILE"
  echo "💾 cached: $1 → $PORT_FILE"
}

# ----- 既に接続済みなら早期 return (現在の endpoint をキャッシュに反映) -----

if is_device_online; then
  echo "✅ already connected"
  CURRENT=$("$ADB" devices | awk '$2=="device" && $1 ~ /:/ {print $1; exit}')
  [[ -n "$CURRENT" ]] && save_port "$CURRENT"
  "$ADB" devices -l
  exit 0
fi

# ----- 優先順位 1: キャッシュファイル -----

echo "==> [1/3] trying cached endpoint ($PORT_FILE)"
if [[ -f "$PORT_FILE" ]]; then
  CACHED=$(tr -d '[:space:]' < "$PORT_FILE")
  if [[ -n "$CACHED" ]] && try_connect "$CACHED"; then
    echo "✅ connected via cache"
    "$ADB" devices -l
    exit 0
  fi
  echo "  ⚠ cache invalid or stale"
else
  echo "  (no cache yet)"
fi

# ----- 優先順位 2: 対話プロンプト -----

echo "==> [2/3] manual input"
echo "  端末で「ワイヤレスデバッグ」を開き、表示されている"
echo "  「IPアドレスとポート」のポート番号を入力してください。"
echo "  (端末 IP: $PHONE_IP)"
read -r -p "  Port: " PORT
if [[ -n "${PORT:-}" ]]; then
  ENDPOINT="${PHONE_IP}:${PORT}"
  if try_connect "$ENDPOINT"; then
    save_port "$ENDPOINT"
    echo "✅ connected via manual input"
    "$ADB" devices -l
    exit 0
  fi
  echo "  ⚠ manual connect failed"
fi

# ----- 優先順位 3: mDNS (最後の保険) -----

echo "==> [3/3] mDNS discovery (last resort)"
MDNS_OUT=$("$ADB" mdns services 2>/dev/null || true)
ENDPOINT=$(echo "$MDNS_OUT" | awk '/_adb-tls-connect/ {print $3; exit}')
if [[ -n "$ENDPOINT" ]] && try_connect "$ENDPOINT"; then
  save_port "$ENDPOINT"
  echo "✅ connected via mDNS"
  "$ADB" devices -l
  exit 0
fi

echo "❌ 接続に失敗しました。確認事項:"
echo "  - 端末の「ワイヤレスデバッグ」が ON か"
echo "  - 端末と DevContainer ホストが同一 LAN にいるか"
echo "  - 端末 IP ($PHONE_IP) が正しいか (PHONE_IP 環境変数で変更可)"
echo "  - 必要なら adb pair から再実行"
exit 1
