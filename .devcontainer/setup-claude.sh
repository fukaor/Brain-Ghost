#!/bin/bash
set -e

# ============================================================
# Configuration
# ============================================================
CONFIG_DIR="/home/godot/.claude"
SETTINGS_FILE="${CONFIG_DIR}/settings.json"
PLUGINS_DIR="/home/godot/.claude-plugins"
CITADEL_DIR="${PLUGINS_DIR}/Citadel"

# ============================================================
# 1. Claude Code permissions (idempotent — only writes if missing)
# ============================================================
mkdir -p "$CONFIG_DIR"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "MultiEdit",
      "Write",
      "Glob",
      "Grep",
      "LS",
      "Bash",
      "WebFetch",
      "WebSearch",
      "Skill",
      "mcp__ide__executeCode"
    ],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Edit(**/.env)",
      "Edit(**/.env.*)",
      "Bash(cat **/.env*)",
      "Bash(*API_KEY*)",
      "Bash(*SECRET*)",
      "Bash(*TOKEN*)",
      "Bash(*PASSWORD*)",
      "Bash(*KEYSTORE*)"
    ]
  }
}
EOF
  echo "✅ Claude Code permissions configured (new)"
else
  echo "✅ Claude Code permissions already exist (preserved)"
fi

# ============================================================
# 2. Git credential — symlink volume-backed file
# ============================================================
CRED_VOL="/home/godot/.git-credentials-vol/.git-credentials"
CRED_LINK="/home/godot/.git-credentials"

if [ ! -f "$CRED_VOL" ]; then
  touch "$CRED_VOL"
fi
if [ ! -L "$CRED_LINK" ]; then
  ln -sf "$CRED_VOL" "$CRED_LINK"
fi

# ============================================================
# 3. Godot export templates check
# ============================================================
TEMPLATES_DIR="/home/godot/.local/share/godot/export_templates"
GODOT_VERSION="4.6.3"

if [ -d "${TEMPLATES_DIR}/${GODOT_VERSION}.stable" ]; then
  TEMPLATE_COUNT=$(ls "${TEMPLATES_DIR}/${GODOT_VERSION}.stable/" 2>/dev/null | wc -l)
  echo "✅ Godot ${GODOT_VERSION} export templates found (${TEMPLATE_COUNT} files)"
else
  echo "⚠️  Godot export templates not found at ${TEMPLATES_DIR}/${GODOT_VERSION}.stable"
  echo "   Templates may need to be copied from /root/ (first run with volume)"

  # Copy from root's templates if available (volume may be empty on first run)
  if [ -d "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable" ]; then
    echo "   → Copying templates from build layer..."
    mkdir -p "${TEMPLATES_DIR}/${GODOT_VERSION}.stable"
    sudo cp -r "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/"* \
      "${TEMPLATES_DIR}/${GODOT_VERSION}.stable/"
    sudo chown -R godot:godot "${TEMPLATES_DIR}"
    echo "   ✅ Templates copied successfully"
  fi
fi

# ============================================================
# 3.5 Godot project import (prevents Japanese font mojibake)
# ------------------------------------------------------------
# .godot/ と *.import は .gitignore 対象のため、クリーンコンテナでは
# 未インポート状態。さらに volume マウントで .godot が root 所有になると
# godot ユーザーがインポート結果を書けず、フォントが valid=false でスタックし
# 日本語が豆腐(□)・Material Symbols が生テキスト化する（文字化け）。
# → 所有権を godot に直し、ヘッドレスインポートを実行して未然に防ぐ。
# ============================================================
GODOT_PROJECT_DIR="/workspace"
if [ -f "${GODOT_PROJECT_DIR}/project.godot" ]; then
  # .godot が root 所有なら godot:godot に修正（書き込み可能にする）
  if [ -d "${GODOT_PROJECT_DIR}/.godot" ] && [ "$(stat -c '%U' "${GODOT_PROJECT_DIR}/.godot")" != "godot" ]; then
    echo "  → Fixing .godot ownership (was $(stat -c '%U' "${GODOT_PROJECT_DIR}/.godot"))..."
    sudo chown -R godot:godot "${GODOT_PROJECT_DIR}/.godot" || true
  fi

  # フォント等がインポート済みか確認（未インポートなら import を実行）
  if ! ls "${GODOT_PROJECT_DIR}/.godot/imported/"*.fontdata >/dev/null 2>&1; then
    echo "  → Importing Godot assets (first run — prevents font mojibake)..."
    (cd "${GODOT_PROJECT_DIR}" && godot --headless --import >/dev/null 2>&1) || true

    # 過去の失敗インポートが残した valid=false の *.import でスタックした場合、
    # フォントの .import を破棄して1回だけ再インポート（豆腐化の再発防止）。
    if ! ls "${GODOT_PROJECT_DIR}/.godot/imported/"*.fontdata >/dev/null 2>&1; then
      echo "  → Font import stuck; clearing stale .import and retrying once..."
      rm -f "${GODOT_PROJECT_DIR}"/assets/fonts/*.import
      (cd "${GODOT_PROJECT_DIR}" && godot --headless --import >/dev/null 2>&1) || true
    fi

    if ls "${GODOT_PROJECT_DIR}/.godot/imported/"*.fontdata >/dev/null 2>&1; then
      echo "  ✅ Godot assets imported (fonts ready)"
    else
      echo "  ⚠️  Font import did not complete — run manually: godot --headless --import"
    fi
  else
    echo "✅ Godot assets already imported (fonts ready)"
  fi
fi

# ============================================================
# 4. Plugin installation (only on --install-plugins / first run)
# ============================================================
if [ "$1" = "--install-plugins" ]; then
  echo ""
  echo "📦 Installing Claude Code plugins..."
  echo ""

  # --- Citadel (orchestration harness) ---
  if [ ! -d "$CITADEL_DIR/.git" ]; then
    echo "  → Cloning Citadel..."
    if git clone https://github.com/SethGammon/Citadel.git "$CITADEL_DIR"; then
      echo "  ✅ Citadel cloned to $CITADEL_DIR"
    else
      echo "  ❌ Citadel clone failed — run manually:"
      echo "     git clone https://github.com/SethGammon/Citadel.git $CITADEL_DIR"
    fi
  else
    echo "  ⏭️  Citadel already exists, pulling latest..."
    cd "$CITADEL_DIR" && git pull --ff-only || true
    cd /workspace
  fi

  # --- Generate plugin commands file (copy-paste ready) ---
  cat > "${CONFIG_DIR}/plugin-commands.txt" << 'CMDS_EOF'
# ── MUST HAVE ──────────────────────────────────
# 1. Citadel (orchestration harness)
/plugin marketplace add /home/godot/.claude-plugins/Citadel
/plugin install citadel@citadel-local
/do setup
# 2. Firecrawl (web research / scraping)
/plugin install firecrawl@claude-plugins-official
# 3. GitHub (PR, Issue, code review)
/plugin install github@claude-plugins-official
# ── HIGH VALUE ─────────────────────────────────
# 4. Code review (5-agent parallel)
/plugin marketplace add anthropics/claude-code
/plugin install code-review@claude-code-plugins
# 5. Feature development workflow
/plugin install feature-dev@claude-code-plugins
# 6. Security guidance
/plugin install security-guidance@claude-plugins-official
# ── NICE TO HAVE ───────────────────────────────
# 7. Context7 (live docs lookup)
/plugin install context7@claude-plugins-official
# ── RELOAD ─────────────────────────────────────
/reload-plugins
CMDS_EOF

  echo ""
  echo "✅ Plugin commands generated: ~/.claude/plugin-commands.txt"

  # Mark that plugins need to be installed
  touch "${CONFIG_DIR}/.plugins-pending"

  # --- GitHub CLI auth hint ---
  if ! gh auth status &>/dev/null; then
    echo ""
    echo "💡 GitHub CLI not authenticated."
    echo "   Run: gh auth login"
    echo "   (auth state persists across container rebuilds)"
  fi
fi

# ============================================================
# 5. Citadel hooks (per-project, runs every start)
# ============================================================
if [ -d "$CITADEL_DIR/scripts" ] && [ -f "$CITADEL_DIR/scripts/install-hooks.js" ]; then
  if [ ! -f "/workspace/.claude/harness.json" ]; then
    echo "  → Installing Citadel hooks for this project..."
    node "$CITADEL_DIR/scripts/install-hooks.js" 2>/dev/null || true
    echo "  ✅ Citadel hooks installed"
  fi
fi

# ============================================================
# 6. Project-specific setup (optional hook)
# ============================================================
if [ -f "/workspace/.devcontainer/setup-project.sh" ]; then
  echo "  → Running project-specific setup..."
  bash /workspace/.devcontainer/setup-project.sh
fi

# ============================================================
# Startup summary
# ============================================================
echo ""
echo "✅ DevContainer ready ($(date '+%H:%M:%S JST'))"
echo "   claude  — start Claude Code"
echo "   cc      — alias for claude"
echo "   gh      — GitHub CLI"
echo "   godot   — Godot ${GODOT_VERSION} (headless)"
echo ""
echo "   Godot commands:"
echo "   godot --headless --import            — import assets"
echo "   godot --headless --export-release Web — export Web build"
echo "   godot --headless --export-release Android — export Android build"

# --- Plugin install reminder (shows until user marks done) ---
if [ -f "${CONFIG_DIR}/.plugins-pending" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────┐"
  echo "│  ⚠️  Claude Code プラグイン未インストール        │"
  echo "│                                                 │"
  echo "│  Claude Code 起動後、以下を1行ずつ貼り付け:     │"
  echo "│  cat ~/.claude/plugin-commands.txt              │"
  echo "│                                                 │"
  echo "│  完了後、バナーを消すには:                       │"
  echo "│  rm ~/.claude/.plugins-pending                  │"
  echo "└─────────────────────────────────────────────────┘"
fi
echo ""
