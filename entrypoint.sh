#!/bin/bash
set -e

cd /zhc

echo "[zhc] Zero Human Corp — starting all services..."

# Ensure data directories exist (first run with empty volumes)
mkdir -p memory economy/reports symphony/summaries

# ---- 1. Dashboard (Node.js, always on) ----
echo "[zhc] Starting dashboard on port ${PORT:-4200}..."
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

# ---- 4. CEO Agent (if Claude auth is available) ----
if [ -f /root/.claude/.credentials.json ]; then
    echo "[zhc] Claude auth found. Starting CEO agent (Duke)..."
    sleep 3  # Let dashboard start first
    ./start-ceo.sh &
    CEO_PID=$!
else
    echo "[zhc] No Claude auth at /root/.claude/.credentials.json"
    echo "[zhc] Running in dashboard-only mode. Mount ~/.claude to enable agents."
    CEO_PID=""
fi

# ---- Graceful shutdown ----
cleanup() {
    echo "[zhc] Shutting down..."
    kill $DASHBOARD_PID $TRACKER_PID ${SYNC_PID:-} ${CEO_PID:-} 2>/dev/null
    wait 2>/dev/null
    echo "[zhc] All services stopped."
    exit 0
}
trap cleanup SIGTERM SIGINT

echo "[zhc] All services started."
echo "[zhc]   Dashboard: http://localhost:${PORT:-4200}"
echo "[zhc]   Task Board: http://localhost:${PORT:-4200}/tasks"

# Dashboard is the critical process — if it dies, container stops.
# Other processes (tracker, sync, CEO) can fail without taking down the container.
wait $DASHBOARD_PID
echo "[zhc] Dashboard exited. Container stopping."
cleanup
