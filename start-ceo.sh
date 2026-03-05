#!/bin/bash
# ============================================
# Start CEO Agent (Atlas) — The Brain
# ============================================

set -e

echo "🧠 Starting Atlas (CEO Agent)..."
echo "   Model: Claude Opus 4.6 (via Claude Code CLI)"
echo "   Heartbeat: Every 5 minutes"
echo ""

# Source environment
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check if OpenClaw is installed
if command -v openclaw &> /dev/null; then
    echo "Using OpenClaw gateway..."
    openclaw start \
        --config ./gateway/gateway.json \
        --agent ceo \
        --verbose
elif command -v claude &> /dev/null; then
    echo "Using Claude Code CLI directly..."
    echo ""
    echo "Initializing CEO with system prompt..."

    # Start CEO agent via Claude Code in autonomous mode
    claude --model opus \
        --system-prompt "$(cat agents/ceo/system-prompt.md)" \
        --tools "spawn-agent,web-search,execute-shell,read-file,write-file" \
        --allowedTools "Bash(read files:*),Bash(write files:*),Bash(execute:*),WebSearch,WebFetch" \
        --print \
        --verbose \
        "You are Atlas, CEO of Zero Human Corp. Boot sequence initiated.

Read your full system prompt, skills, and the current company state.
Then execute your Strategic Planning skill to:
1. Scan the market for novel revenue opportunities
2. Score and select the top 2-3 opportunities
3. Spawn the CTO (Forge) and BizDev (Scout) agents
4. Delegate initial tasks to each
5. Begin your heartbeat cycle

Start NOW. The company has $0 and needs to earn real money.
Be creative. Be fast. Be ruthless about what works and what doesn't.

Files to read first:
- agents/ceo/skills/strategic-plan.md
- agents/ceo/skills/revenue-scan.md
- agents/ceo/skills/delegate.md
- memory/company-state.md
- economy/budget.json"

else
    echo "❌ Neither OpenClaw nor Claude Code CLI found."
    echo "   Install one of:"
    echo "   - OpenClaw: https://github.com/openclaw/openclaw"
    echo "   - Claude Code: Requires Claude Max subscription"
    exit 1
fi
