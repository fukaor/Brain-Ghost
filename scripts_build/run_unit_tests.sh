#!/usr/bin/env bash
# ============================================================
# ブレインゴースト — ユニットテスト実行スクリプト
#
# GUT (Godot Unit Test) を CLI から起動し、tests/unit/ 配下の
# すべてのテストを走らせる。CI と手元で同じコマンドを使えるよう
# オプションをここに固める。
#
# 使い方:
#   ./scripts_build/run_unit_tests.sh
#     → 引数なし: tests/unit/**/test_*.gd を全実行（デフォルトの -gdir を使う）
#
#   ./scripts_build/run_unit_tests.sh -gtest=res://tests/unit/core/test_daily_seed.gd
#     → 引数ありの場合はデフォルトの -gdir を付けず、そのまま GUT に渡す
#       （単一ファイルだけを確実に実行できる）
#
#   ./scripts_build/run_unit_tests.sh -gdir=res://tests/unit/core -ginclude_subdirs
#     → 引数で -gdir を上書き指定することも可能
#
# 前提:
#   - godot コマンドが PATH 上にあること (Godot 4.6.x)
#   - addons/gut/ に GUT v9.6.0 が配置済み
#   - .godot/ グローバルクラスキャッシュが生成済み
#     （未生成の場合は `godot --headless --editor --quit-after 60` を一度実行）
#
# 終了コード:
#   - 0: 全テストパス
#   - 非 0: テスト失敗またはランナーエラー
# ============================================================
set -euo pipefail

# プロジェクトルートへ移動（このスクリプトは scripts_build/ 配下にある前提）
cd "$(dirname "$0")/.."

if [ $# -eq 0 ]; then
  # 引数なし: デフォルト（tests/unit 配下を再帰スキャン）
  exec godot --headless \
    -s res://addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit \
    -ginclude_subdirs \
    -gexit
else
  # 引数あり: デフォルト -gdir を付けず、ユーザー指定をそのまま渡す
  exec godot --headless \
    -s res://addons/gut/gut_cmdln.gd \
    -gexit \
    "$@"
fi
