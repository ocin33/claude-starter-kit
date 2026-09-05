#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web / mobile remote sessions — not on a
# developer's own machine, where they run ./setup.sh interactively instead.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

"$CLAUDE_PROJECT_DIR/setup-noninteractive.sh"
