#!/bin/bash
# ============================================
# Start CEO Agent (Duke) — The Brain
# ============================================

set -e

echo "[ceo] Starting Duke (CEO Agent)..."
echo "[ceo] Model: Claude Opus 4.6 (via Claude Code CLI)"
echo "[ceo] Heartbeat: Every 5 minutes"

# Source environment
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

if ! command -v claude &> /dev/null; then
    echo "[ceo] ERROR: Claude Code CLI not found."
    echo "[ceo] Install via: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo "[ceo] Initializing CEO with system prompt..."

# Start CEO agent via Claude Code in autonomous mode
claude --model opus \
    --system-prompt "$(cat agents/ceo/system-prompt.md)" \
    --allowedTools "Bash(read files:*),Bash(write files:*),Bash(execute:*),WebSearch,WebFetch" \
    --print \
    --verbose \
    "You are Duke, CEO of Zero Human Corp. Boot sequence initiated.

Read your full system prompt, skills, and the current company state.
Then execute your Strategic Planning skill to:
1. Scan the market for novel revenue opportunities
2. Score and select the top 2-3 opportunities
3. Spawn the CTO (Hackerman) and BizDev (Borat) agents
4. Delegate initial tasks to each
5. Begin your heartbeat cycle

Start NOW. The company has \$0 and needs to earn real money.
Be creative. Be fast. Be ruthless about what works and what doesn't.

Files to read first:
- agents/ceo/skills/strategic-plan.md
- agents/ceo/skills/revenue-scan.md
- agents/ceo/skills/delegate.md
- memory/company-state.md
- economy/budget.json"
