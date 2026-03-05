#!/bin/bash
set -e

cd /zhc

echo "[zhc] Zero Human Corp — starting all services..."

# Ensure data directories exist (first run with empty volumes)
mkdir -p memory economy/reports symphony/summaries .openclaw

# ---- 1. Dashboard (Node.js, always on) ----
echo "[zhc] Starting Mission Control dashboard on port ${DASHBOARD_PORT:-4200}..."
node dashboard/server.js &
DASHBOARD_PID=$!

# ---- 2. Economy Tracker (Python, hourly cycle) ----
echo "[zhc] Starting economy tracker (hourly)..."
python3 -c "
import time, importlib.util, sys, os
os.chdir('/zhc')
spec = importlib.util.spec_from_file_location('tracker', 'economy/tracker.py')
tracker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tracker)
try:
    tracker.generate_report()
    print('[tracker] Initial report generated.')
except Exception as e:
    print(f'[tracker] Initial report failed: {e}')
while True:
    time.sleep(3600)
    try:
        tracker.generate_report()
        print('[tracker] Hourly report generated.')
    except Exception as e:
        print(f'[tracker] Error: {e}')
" &
TRACKER_PID=$!

# ---- 3. GitHub Sync Daemon (if GITHUB_REPO is set) ----
if [ -n "$GITHUB_REPO" ]; then
    echo "[zhc] Starting GitHub sync daemon (repo: $GITHUB_REPO)..."
    python3 symphony/github-sync.py &
    SYNC_PID=$!
else
    echo "[zhc] GITHUB_REPO not set. GitHub sync disabled (using local board.json)."
    SYNC_PID=""
fi

# ---- 4. OpenClaw Gateway (agent orchestration) ----
HAS_AUTH=false

# Check for Anthropic API key or Claude CLI auth
if [ -n "$ANTHROPIC_API_KEY" ] || [ -f /root/.claude/.credentials.json ]; then
    HAS_AUTH=true
fi

# Check for OpenAI API key or Codex CLI auth
if [ -n "$OPENAI_API_KEY" ] || [ -f /root/.codex/auth.json ]; then
    HAS_AUTH=true
fi

if [ "$HAS_AUTH" = true ]; then
    echo "[zhc] Auth detected. Starting OpenClaw gateway (port ${OPENCLAW_GATEWAY_PORT:-18789})..."
    sleep 3  # Let dashboard start first

    openclaw gateway \
        --port "${OPENCLAW_GATEWAY_PORT:-18789}" \
        --verbose &
    GATEWAY_PID=$!

    # Give gateway time to start, then boot the Champion agent
    sleep 5
    echo "[zhc] Starting Duke (Champion) agent via OpenClaw..."
    openclaw agent \
        --agent duke \
        --message "You are Duke, Champion of Zero Human Corp. Boot sequence initiated.

Read your system prompt at agents/ceo/system-prompt.md and all skills in agents/ceo/skills/.
Read the current company state at memory/company-state.md.
Read the budget at economy/budget.json.

Then execute your Strategic Planning skill to:
1. Scan the market for novel revenue opportunities
2. Score and select the top 2-3 opportunities
3. Spawn specialist agents (Hackerman, Borat, Don Draper, Picasso, T-800) via sub-agents
4. Delegate initial tasks to each
5. Begin your heartbeat cycle

The company has \$0 and needs to earn real money.
Be creative. Be fast. Be ruthless about what works and what doesn't." &
    AGENT_PID=$!
else
    echo "[zhc] No API keys or CLI auth found."
    echo "[zhc] Running in dashboard-only mode."
    echo "[zhc] Set ANTHROPIC_API_KEY / OPENAI_API_KEY or mount ~/.claude ~/.codex to enable agents."
    GATEWAY_PID=""
    AGENT_PID=""
fi

# ---- Graceful shutdown ----
cleanup() {
    echo "[zhc] Shutting down..."
    kill $DASHBOARD_PID $TRACKER_PID ${SYNC_PID:-} ${GATEWAY_PID:-} ${AGENT_PID:-} 2>/dev/null
    wait 2>/dev/null
    echo "[zhc] All services stopped."
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "[zhc] All services started."
echo "[zhc]   Dashboard:        http://localhost:${DASHBOARD_PORT:-4200}"
echo "[zhc]   Task Board:       http://localhost:${DASHBOARD_PORT:-4200}/tasks"
echo "[zhc]   OpenClaw Gateway: http://localhost:${OPENCLAW_GATEWAY_PORT:-18789}"

# Dashboard is the critical process — if it dies, container stops.
# Other processes (tracker, sync, gateway, agents) can fail without taking down the container.
wait $DASHBOARD_PID
echo "[zhc] Dashboard exited. Container stopping."
cleanup
