#!/bin/bash
set -uo pipefail

# Claude Code Starter Kit — Non-Interactive Setup
# Run automatically by .claude/hooks/session-start.sh whenever a Claude Code
# on the web / mobile session runs against THIS repo (claude-starter-kit).
#
# This only installs Phase 1 (global ~/.claude/ config: rules, security
# guard, session hooks). It intentionally does NOT set up a workspace here —
# Claude Code on the web loads .claude/skills/ (like /onboard, /tasks) only
# from the repo a session actually runs against, so a workspace generated
# under $HOME in a claude-starter-kit session is invisible to skill
# discovery no matter what's in it. To actually use the assistant
# (/onboard, /tasks, etc.), start a session directly against your own
# workspace repo instead (see README: "Claude Code on the web / mobile") —
# it needs this same kind of hook committed there, installing just the
# global config, since the repo itself already is the workspace.
#
# Optional env vars (set on the Environment's "Environment Variables"):
#   CLAUDE_USER_NAME — short name shown in ~/.claude/CLAUDE.md
#   CLAUDE_USER_BIO  — one-line bio shown in ~/.claude/CLAUDE.md

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

CLAUDE_USER_NAME="${CLAUDE_USER_NAME:-you}"
CLAUDE_USER_BIO="${CLAUDE_USER_BIO:-no bio set — run /onboard}"

echo "=== Claude Code Starter Kit — non-interactive install ==="

# -----------------------------------------------
# Dependency check (no installs — containers are expected to already have these)
# -----------------------------------------------
for tool in git python3 jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "  warn: $tool not found — some hooks/skills may not work"
    fi
done

# ===============================================
# Global config to ~/.claude/
# ===============================================
# ~/.claude/ has no persistence of its own — it's fully rebuilt from the kit
# on every container, so an unconditional overwrite is always safe here.

echo "Installing global config to $CLAUDE_DIR ..."

mkdir -p "$CLAUDE_DIR"/{rules,scripts,state}

cp "$SCRIPT_DIR/scripts/global-guard.py" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/pre-compact.sh" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/session-save-reminder.sh" "$CLAUDE_DIR/scripts/"
cp "$SCRIPT_DIR/scripts/post-compact-reinject.sh" "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh "$CLAUDE_DIR/scripts/"*.py

for rule in "$SCRIPT_DIR"/rules/*.md; do
    cp "$rule" "$CLAUDE_DIR/rules/"
done

cp "$SCRIPT_DIR/templates/settings.json" "$CLAUDE_DIR/settings.json"
cp "$SCRIPT_DIR/templates/gitignore" "$CLAUDE_DIR/.gitignore"
cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/statusline.sh"

sed -e "s/{{USER_NAME}}/$CLAUDE_USER_NAME/g" \
    -e "s|{{USER_BIO}}|$CLAUDE_USER_BIO|g" \
    "$SCRIPT_DIR/templates/global-CLAUDE.md" > "$CLAUDE_DIR/CLAUDE.md"

echo "  Global config installed."
echo ""
echo "=== Setup complete ==="
echo "Note: this repo has no workspace of its own. To use /onboard, /tasks,"
echo "etc., start a session against your workspace repo instead."
exit 0
