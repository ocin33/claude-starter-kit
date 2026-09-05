# Claude Code Starter Kit

A pre-built configuration that gives Claude Code persistent memory, security guardrails, and structured workflows. Clone, run `setup.sh`, and your next session picks up where the last one left off.

## How It Works

Claude Code reads `~/.claude/` at startup. This kit installs minimal global config there — rules, security hooks, and a pointer to your workspace. The workspace (`~/claude-assistant/`) holds everything else: knowledge, skills, tasks, agents, and session history.

```
You run setup.sh ──> Phase 1: Minimal config to ~/.claude/
                     Phase 2: Full workspace at ~/claude-assistant/

~/.claude/ (global, every project)     ~/claude-assistant/ (workspace)
├── CLAUDE.md (pointer)                ├── .claude/CLAUDE.md (detailed)
├── settings.json (hooks)              ├── .claude/skills/ (6 skills)
├── rules/ (behavioral)               ├── knowledge/ (on-demand)
├── scripts/ (4 hook scripts)          ├── agents/ (4 definitions)
└── statusline.sh                      ├── scripts/ (db, learnings)
                                       ├── state/ (sessions, backlog)
                                       ├── MEMORY.md (200 lines)
                                       └── tasks.db (SQLite)
```

**Why the split?** `~/.claude/` is Claude Code's config directory — it should stay lean. Rules and hooks load every session regardless of project. Knowledge, tasks, and skills live in the workspace, loaded only when you're working there. This keeps `~/.claude/` clean and your assistant data in a proper, version-controlled workspace.

**On-demand loading is how this avoids context bloat.** The workspace CLAUDE.md contains a table of file paths and one-line descriptions. Claude sees the table at startup (~20-30 lines), then uses `Read` to open specific files when relevant. A typical session loads 3-5 files out of however many you have.

## What's Included

| Component | What It Does |
|---|---|
| `/onboard` | 20-30 min guided setup: profile, 12 Favorite Problems, goals, tasks |
| `/tasks` | SQLite-backed task management. Tasks connect to your goals and problems |
| `/plan` | 6-phase gated workflow: explore, discover tools, design, approve, implement, verify |
| `/reflect` | Extracts corrections and preferences from sessions, routes them to the right files |
| `/bootstrap` | Sets up any project's `.claude/` for agentic development |
| `/create-skill` | Scaffolds new skills with validation — extend the system with your own workflows |
| Security guard | Blocks secrets access, force-push, writes outside `$HOME`, `rm -rf`. Audit log at `~/.claude/state/guard-log.jsonl` |
| Session persistence | Pre-compact hook saves state, post-compact hook re-injects critical rules. Session reminders after 10 min |
| Delegation rules | Subagent orchestration: authority boundaries, knowledge flow, quality control |
| Agent definitions | 4 pre-built agents: code-reviewer, bug-fixer, implementer, researcher |
| Development standards | Code quality limits, testing philosophy, commit conventions |
| Radical honesty | No flattery, no hype — specific praise when earned, problems first |

## Requirements

| Dependency | Minimum | Why | Install |
|---|---|---|---|
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) | latest | Core runtime | `npm i -g @anthropic-ai/claude-code` or `brew install claude-code` |
| Git | 2.x | Version control for config and workspace | Pre-installed on macOS; `apt install git` on Linux |
| Python | 3.10+ | Security guard, task database, learning extractor | Pre-installed on macOS; `apt install python3` on Linux |
| jq | 1.6+ | Statusline and hook scripts | `brew install jq` / `apt install jq` |
| SQLite | 3.x | Task database — CLI used in rules/skills for queries | Pre-installed on macOS; `apt install sqlite3` on Linux |
| Bash | 4.x+ | Hook scripts | Pre-installed |

**Optional:** `trash` (`brew install trash` on macOS, `apt install trash-cli` on Linux) — safe alternative to `rm -rf`, recommended by the security guard.

**Note:** Python's built-in `sqlite3` module handles database operations via `db.py`. The `sqlite3` CLI is used in rules and skills for quick inline queries.

**Supported platforms:** macOS, Linux. Windows via WSL should work but is untested.

## Setup (5 minutes)

```bash
git clone https://github.com/mp-web3/claude-starter-kit.git
cd claude-starter-kit
./setup.sh
```

The script checks dependencies, asks for your name, bio, and workspace directory (default: `~/claude-assistant`), then installs files in two phases.

Then start your first session:

```bash
cd ~/claude-assistant
claude
```

Type `/onboard` — Claude walks you through defining your profile, problems, goals, and tasks. Takes 20-30 minutes. Saves progress after every step, so you can disconnect and resume anytime.

## Claude Code on the web / mobile

Claude Code on the web (and the mobile app) run each session in a fresh, ephemeral container tied to a single GitHub repo — the repo you started the session against **is** the session's project directory. Claude Code loads `.claude/skills/`, `.claude/agents/`, etc. only from that repo, never from an arbitrary path under `$HOME`. That means `/onboard`, `/tasks`, and the other workspace skills only work in a session started directly against **your workspace repo** (a private repo with the Phase 2 layout — skills, agents, scripts, knowledge/ — same as `~/claude-assistant/` below), not against `claude-starter-kit` itself.

So the setup has two parts:

1. **This repo** (`claude-starter-kit`) only needs `.claude/hooks/session-start.sh` for the case where you're doing dev work on the kit itself: it installs the global `~/.claude/` config (rules, security guard, session hooks) automatically via `setup-noninteractive.sh`, no prompts, no package-manager installs (assumes `git`/`python3`/`jq` are already present in the container).
2. **Your workspace repo** (e.g. a private `claude-assistant` repo, seeded with the Phase 2 layout from `./setup.sh`) needs the *same kind* of hook committed to it, since it's already the workspace once a session runs there — no cloning required. Start your actual assistant sessions (`/onboard`, `/tasks`, ...) against that repo instead of this one.

Optional environment variables (set once in your Claude Code on the web Environment → Environment Variables) apply to both:
- `CLAUDE_USER_NAME` / `CLAUDE_USER_BIO` — shown in `~/.claude/CLAUDE.md`

## Directory Structure

### Global Config (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md                  # Minimal global instructions (points to workspace)
├── settings.json              # Hooks, permissions, security config
├── workspace.conf             # Path to workspace directory
├── rules/
│   ├── communication.md       # Radical honesty, verification, review protocol
│   ├── security.md            # Path boundaries, secrets, git discipline
│   ├── sessions.md            # Session start/end protocols, content routing
│   ├── tasks.md               # Task alignment, completion verification, operational rules
│   ├── delegation.md          # Subagent orchestration patterns
│   ├── development.md         # Code quality, testing, commits
│   └── research.md            # Source priority, endpoint verification, output format
├── scripts/
│   ├── global-guard.py        # Security: path boundaries, secrets blocking
│   ├── pre-compact.sh         # Saves state before context compression
│   ├── post-compact-reinject.sh # Re-injects critical rules after compaction
│   └── session-save-reminder.sh
└── statusline.sh              # Context %, cost, branch info
```

### Workspace (`~/claude-assistant/`)

The `.claude/` directory inside the workspace is standard Claude Code project config — it holds the project-level CLAUDE.md and skills. This is separate from the global `~/.claude/`. Claude Code discovers skills from `<project>/.claude/skills/` automatically.

```
~/claude-assistant/
├── .claude/                   # Project-level Claude Code config
│   ├── CLAUDE.md              # Detailed workspace instructions
│   └── skills/                # Skills available when running from this workspace
│       ├── onboard/SKILL.md   # Guided first-session setup
│       ├── tasks/SKILL.md     # Task management
│       ├── plan-and-implement/ # Structured build workflow
│       │   ├── SKILL.md
│       │   └── LEARNINGS.md
│       ├── reflect/           # Session learning extraction
│       │   ├── SKILL.md
│       │   └── LEARNINGS.md
│       ├── bootstrap/         # Project .claude/ setup
│       │   ├── SKILL.md
│       │   └── LEARNINGS.md
│       └── create-skill/      # Skill scaffolding + validation
│           ├── SKILL.md
│           ├── LEARNINGS.md
│           └── scripts/
│               ├── init_skill.py
│               └── validate_skill.py
├── knowledge/                 # Claude reads these on demand
│   ├── self/identity.md       # AI self-knowledge (created by /onboard)
│   ├── user/profile.md        # Your profile (created by /onboard)
│   ├── user/goals.md          # Goals and subgoals (created by /onboard)
│   ├── problems/              # Your 12 problems (created by /onboard)
│   └── projects/              # Project-specific knowledge (grows over time)
├── agents/
│   ├── code-reviewer.md       # Reviews diffs for bugs, security, style
│   ├── bug-fixer.md           # Investigates, reproduces, fixes bugs + writes tests
│   ├── implementer.md         # Implements features from a plan/spec
│   └── researcher.md          # Explores codebases and docs, returns structured findings
├── scripts/
│   ├── db.py                  # SQLite task database
│   └── extract-learnings.py   # Session JSONL parser for /reflect
├── state/
│   ├── sessions/              # Session logs
│   ├── backlog.md             # Task backlog (auto-exported from SQLite)
│   └── rule-feedback.json     # Rule health counters (from /reflect)
├── MEMORY.md                  # Cross-session index (first 200 lines auto-loaded)
└── tasks.db                   # SQLite task store (gitignored)
```

## Security Guard

The guard script (`scripts/global-guard.py`) hooks into Claude Code's `PreToolUse` event — it runs before every tool call and can block dangerous operations.

| Category | What's Blocked | Why |
|---|---|---|
| Path boundaries | Reads/writes outside `$HOME` and `/tmp` | Prevents system file modification |
| Secrets | `.env`, `.key`, `.pem`, `.secret` files | Prevents accidental exposure |
| Git safety | `git push --force`, `git add` on secret files | Prevents data loss and secret commits |
| Destructive ops | `rm -rf` | Use `trash` instead (recoverable) |
| Branch protection | Direct push to `main`/`master` | Forces feature branch workflow |

**How it works:** The guard is configured in `settings.json` as a `PreToolUse` hook. Claude Code sends the tool name and input as JSON to stdin. The script checks against its rules and returns `{"allow": true}` or `{"blocked": true, "reason": "..."}`. Claude sees the reason and adjusts.

Every blocked action is logged to `~/.claude/state/guard-log.jsonl` with timestamp, tool name, reason, and context. Review with:

```bash
cat ~/.claude/state/guard-log.jsonl | python3 -m json.tool
```

Customize by editing `~/.claude/scripts/global-guard.py` — add directory blocks, file extension rules, or stricter rules for company repos.

## Rules System

Rules in `~/.claude/rules/` are loaded every session, from every project. They constrain Claude's behavior:

| Rule | What It Does |
|---|---|
| `communication.md` | Radical honesty, verify-before-assuming, review=revise, audit=fix |
| `security.md` | Hard blocks, git discipline, secrets management, project isolation |
| `sessions.md` | Start/end protocols, content routing table, context management |
| `tasks.md` | Task alignment checks, completion verification, operational guidelines |
| `delegation.md` | Subagent authority boundaries, knowledge flow, quality control |
| `development.md` | Code quality limits, testing philosophy, commit conventions |
| `research.md` | Source priority, endpoint verification, synthesis rules |

## Agent Definitions

The `agents/` directory in the workspace contains pre-built agent definitions for common development tasks. These work with Claude Code's Agent tool for delegating work to subagents.

| Agent | Purpose | Writes Code? |
|---|---|---|
| `code-reviewer` | Reviews diffs for bugs, security issues, style violations, test gaps | No (read-only) |
| `bug-fixer` | Takes a symptom, reproduces, finds root cause, fixes + tests | Yes |
| `implementer` | Implements features from a plan/spec in dependency order | Yes |
| `researcher` | Explores codebases, reads docs, answers technical questions | No (research only) |

All agents follow the delegation rules: they can read, write, and test, but cannot commit, push, or make architectural decisions. Each agent produces structured output (status, summary, files changed, next steps) for the main session to review.

## Self-Improvement Loop

```
Session work -> Claude notices correction -> Writes to knowledge file -> Commits
Next session -> Claude reads the file -> Doesn't repeat the mistake
```

Same correction twice -> gets promoted to a rule (always-loaded, every session).

Run `/reflect` periodically to formalize this. It reads your session transcript, detects corrections and preferences, checks for contradictions with existing rules, and tracks which rules are helping vs hurting via feedback counters.

## Growing the System

The starter kit is minimal on purpose. As you use it:

- Claude creates knowledge files as it learns about your projects and preferences
- Session notes accumulate in `state/sessions/`, creating searchable history
- Rules evolve — corrections become rules, unhealthy rules get flagged by `/reflect`
- New skills can be added with `/create-skill` for workflows worth repeating
- `LEARNINGS.md` files in each skill capture what worked and what didn't
- Use `/bootstrap` to set up any project for agentic development

The `knowledge/` directory is your assistant's brain. Commit and push it regularly.

## Customization

**Workspace location:** Set during `setup.sh`. Stored in `~/.claude/workspace.conf`. Default: `~/claude-assistant`.

**Project-specific rules:** Create `.claude/rules/my-rule.md` in any project directory. Loads only for that project.

**Deny rules:** Edit `~/.claude/settings.json` -> `permissions.deny` to block specific tools or commands globally.

**Session reminder timing:** Edit `~/.claude/scripts/session-save-reminder.sh` — change `600` (seconds) to adjust the threshold.

**Compaction prompt:** Edit the PreCompact prompt hook in `~/.claude/settings.json` to customize what Claude preserves during context compression.

**Development standards:** Edit `~/.claude/rules/development.md` to add your language-specific conventions, preferred linters, or stricter limits.

**Company repo protection:** Edit `~/.claude/rules/security.md` to add company-specific blocks (read-only repos, no autonomous push, etc.).

## Credits

Built from patterns developed by [Mattia Papa](https://mattiapapa.dev) over months of daily Claude Code usage.

## License

MIT
