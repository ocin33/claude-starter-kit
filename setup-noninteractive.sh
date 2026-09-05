#!/bin/bash
set -uo pipefail

# Claude Code Starter Kit — Non-Interactive Setup
# Run automatically by .claude/hooks/session-start.sh on every Claude Code on
# the web / mobile session. Same two phases as setup.sh, but:
#   - no prompts, no package-manager installs, no sudo
#   - Phase 2 pulls the persistent workspace from a git remote instead of
#     always generating an empty one, so knowledge/tasks/skills survive
#     across ephemeral containers and devices.
#
# Configuration (all optional, via environment variables — set these once in
# your Claude Code on the web Environment's "Environment Variables" so every
# session picks them up):
#   CLAUDE_USER_NAME     — short name shown in ~/.claude/CLAUDE.md
#   CLAUDE_USER_BIO      — one-line bio shown in ~/.claude/CLAUDE.md
#   WORKSPACE_DIR_NAME   — workspace directory under $HOME (default: claude-assistant)
#   WORKSPACE_REPO_URL   — https URL of your persistent workspace repo
#                          (e.g. https://github.com/<you>/claude-assistant)
#   WORKSPACE_REPO_TOKEN — GitHub token with contents:read/write on that repo,
#                          needed if WORKSPACE_REPO_URL is private

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

CLAUDE_USER_NAME="${CLAUDE_USER_NAME:-you}"
CLAUDE_USER_BIO="${CLAUDE_USER_BIO:-no bio set — run /onboard}"
WORKSPACE_DIR_NAME="${WORKSPACE_DIR_NAME:-claude-assistant}"
WORKSPACE_DIR="$HOME/$WORKSPACE_DIR_NAME"
WORKSPACE_REPO_URL="${WORKSPACE_REPO_URL:-}"
WORKSPACE_REPO_TOKEN="${WORKSPACE_REPO_TOKEN:-}"

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
# PHASE 1: Global config to ~/.claude/
# ===============================================
# ~/.claude/ has no persistence of its own — it's fully rebuilt from the kit
# on every container, so an unconditional overwrite is always safe here.

echo "Phase 1: installing global config to $CLAUDE_DIR ..."

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

echo "$WORKSPACE_DIR" > "$CLAUDE_DIR/workspace.conf"

if [[ "$WORKSPACE_DIR_NAME" != "claude-assistant" ]]; then
    for f in "$CLAUDE_DIR/rules/"*.md "$CLAUDE_DIR/CLAUDE.md"; do
        sed -i "s|~/claude-assistant/|~/$WORKSPACE_DIR_NAME/|g" "$f"
    done
fi

echo "  Global config installed."

# ===============================================
# PHASE 2: Workspace at $WORKSPACE_DIR
# ===============================================

echo "Phase 2: setting up workspace at $WORKSPACE_DIR ..."

clone_url="$WORKSPACE_REPO_URL"
if [[ -n "$WORKSPACE_REPO_TOKEN" && -n "$WORKSPACE_REPO_URL" ]]; then
    clone_url="$(echo "$WORKSPACE_REPO_URL" | sed -E "s#https://#https://x-access-token:${WORKSPACE_REPO_TOKEN}@#")"
fi

if [[ -d "$WORKSPACE_DIR/.git" ]]; then
    # Already present in this container (e.g. hook ran once already this
    # session, or the container was reused) — just pull latest, and only if
    # there's nothing uncommitted to lose.
    if git -C "$WORKSPACE_DIR" diff --quiet && git -C "$WORKSPACE_DIR" diff --cached --quiet; then
        if git -C "$WORKSPACE_DIR" pull --ff-only 2>/tmp/workspace-pull.err; then
            echo "  Workspace updated (git pull)."
        else
            echo "  warn: could not pull workspace, leaving as-is: $(cat /tmp/workspace-pull.err)"
        fi
    else
        echo "  warn: workspace has uncommitted changes — skipping pull, leaving as-is."
    fi
elif [[ -n "$WORKSPACE_REPO_URL" ]]; then
    if git clone "$clone_url" "$WORKSPACE_DIR" 2>/tmp/workspace-clone.err; then
        echo "  Workspace cloned from $WORKSPACE_REPO_URL."
    else
        echo "  warn: clone of $WORKSPACE_REPO_URL failed, generating a fresh local workspace instead:"
        sed "s#${WORKSPACE_REPO_TOKEN:-__unset__}#***#g" /tmp/workspace-clone.err 2>/dev/null || true
        WORKSPACE_REPO_URL=""
    fi
fi

if [[ ! -d "$WORKSPACE_DIR" ]]; then
    echo "  No WORKSPACE_REPO_URL configured (or clone failed) — generating a fresh local workspace."
    echo "  Set WORKSPACE_REPO_URL (and WORKSPACE_REPO_TOKEN if private) as environment"
    echo "  variables on this Environment so your workspace persists across sessions/devices."

    mkdir -p "$WORKSPACE_DIR"/{.claude/skills/onboard,.claude/skills/tasks,.claude/skills/plan-and-implement,.claude/skills/reflect,.claude/skills/bootstrap,.claude/skills/create-skill/scripts,knowledge/self,knowledge/user,knowledge/problems,knowledge/projects,agents,scripts,state/sessions}

    sed -e "s/{{USER_NAME}}/$CLAUDE_USER_NAME/g" \
        -e "s|{{USER_BIO}}|$CLAUDE_USER_BIO|g" \
        "$SCRIPT_DIR/templates/workspace-CLAUDE.md" > "$WORKSPACE_DIR/.claude/CLAUDE.md"

    for agent in "$SCRIPT_DIR"/agents/*.md; do
        cp "$agent" "$WORKSPACE_DIR/agents/"
    done

    cp "$SCRIPT_DIR/scripts/db.py" "$WORKSPACE_DIR/scripts/"
    cp "$SCRIPT_DIR/scripts/extract-learnings.py" "$WORKSPACE_DIR/scripts/"
    chmod +x "$WORKSPACE_DIR/scripts/"*.py

    cp "$SCRIPT_DIR/skills/onboard/SKILL.md" "$WORKSPACE_DIR/.claude/skills/onboard/"
    cp "$SCRIPT_DIR/skills/tasks/SKILL.md" "$WORKSPACE_DIR/.claude/skills/tasks/"
    cp "$SCRIPT_DIR/skills/tasks/LEARNINGS.md" "$WORKSPACE_DIR/.claude/skills/tasks/"
    cp "$SCRIPT_DIR/skills/plan-and-implement/SKILL.md" "$WORKSPACE_DIR/.claude/skills/plan-and-implement/"
    cp "$SCRIPT_DIR/skills/plan-and-implement/LEARNINGS.md" "$WORKSPACE_DIR/.claude/skills/plan-and-implement/"
    cp "$SCRIPT_DIR/skills/reflect/SKILL.md" "$WORKSPACE_DIR/.claude/skills/reflect/"
    cp "$SCRIPT_DIR/skills/reflect/LEARNINGS.md" "$WORKSPACE_DIR/.claude/skills/reflect/"
    cp "$SCRIPT_DIR/skills/bootstrap/SKILL.md" "$WORKSPACE_DIR/.claude/skills/bootstrap/"
    cp "$SCRIPT_DIR/skills/bootstrap/LEARNINGS.md" "$WORKSPACE_DIR/.claude/skills/bootstrap/"
    cp "$SCRIPT_DIR/skills/create-skill/SKILL.md" "$WORKSPACE_DIR/.claude/skills/create-skill/"
    cp "$SCRIPT_DIR/skills/create-skill/LEARNINGS.md" "$WORKSPACE_DIR/.claude/skills/create-skill/"
    cp "$SCRIPT_DIR/skills/create-skill/scripts/init_skill.py" "$WORKSPACE_DIR/.claude/skills/create-skill/scripts/"
    cp "$SCRIPT_DIR/skills/create-skill/scripts/validate_skill.py" "$WORKSPACE_DIR/.claude/skills/create-skill/scripts/"
    chmod +x "$WORKSPACE_DIR/.claude/skills/create-skill/scripts/"*.py

    cp "$SCRIPT_DIR/templates/workspace-gitignore" "$WORKSPACE_DIR/.gitignore"

    cat > "$WORKSPACE_DIR/MEMORY.md" << 'MEMEOF'
# Auto-Memory

## Active Tasks

(Run `/tasks` or `/onboard` to populate)

## Active Projects

(Will grow as you work on projects)

## Next Up

1. Run `/onboard` to set up your profile, problems, goals, and tasks

## File Map

| Path | Content |
|---|---|
| `knowledge/user/profile.md` | Your profile (created by /onboard) |
| `knowledge/user/goals.md` | Goals and subgoals (created by /onboard) |
| `knowledge/problems/00-overview.md` | 12 problems overview (created by /onboard) |
| `knowledge/self/identity.md` | AI self-knowledge (created by /onboard) |
MEMEOF

    (cd "$WORKSPACE_DIR" && git init -q && git add -A && git commit -q -m "initial setup from claude-starter-kit")
fi

# tasks.db is gitignored (SQLite binary) — must be (re)created in every fresh
# container regardless of how the workspace itself was obtained.
if [[ ! -f "$WORKSPACE_DIR/tasks.db" ]]; then
    python3 "$WORKSPACE_DIR/scripts/db.py" init
    python3 "$WORKSPACE_DIR/scripts/db.py" export
fi

echo "  Workspace ready."
echo ""
echo "=== Setup complete — cd $WORKSPACE_DIR ==="
exit 0
