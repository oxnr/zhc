#!/bin/bash
# ============================================
# Start Zero Human Corp — Mission Control
# ============================================
# Usage:
#   ./start-dashboard.sh          # Run with Node.js directly
#   ./start-dashboard.sh --docker # Run via Docker

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📊 Starting Zero Human Corp — Mission Control"
echo ""

if [ "$1" = "--docker" ] || [ "$1" = "-d" ]; then
    echo "Starting via Docker..."
    docker compose up -d dashboard
    echo ""
    echo "Dashboard: http://localhost:${DASHBOARD_PORT:-4200}"
    echo "Logs:      docker compose logs -f dashboard"
else
    cd "$SCRIPT_DIR/dashboard"

    # Install deps if needed
    if [ ! -d node_modules ]; then
        echo "Installing dependencies..."
        npm install
    fi

    echo "Dashboard: http://localhost:${DASHBOARD_PORT:-4200}"
    echo ""

    PORT="${DASHBOARD_PORT:-4200}" ZHC_ROOT="$SCRIPT_DIR" node server.js
fi
