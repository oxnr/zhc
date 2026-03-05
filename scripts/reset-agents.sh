#!/bin/bash
# Reset all agents (use when things go sideways)
echo "🔄 Resetting all agents..."
echo "   This will kill all running agents but preserve memory."
echo ""

# Kill agent processes
pkill -f "openclaw.*agent" 2>/dev/null
pkill -f "claude.*agent" 2>/dev/null
pkill -f "codex.*agent" 2>/dev/null

echo "  ✅ All agent processes killed"
echo ""
echo "Memory preserved in ./memory/"
echo "To restart: ./start-ceo.sh"
