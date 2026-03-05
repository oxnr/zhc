#!/bin/bash
# Health check for all agents and services
echo "🏥 Zero Human Corp — Health Check"
echo "=================================="
echo ""

# Check agent processes
echo "Agents:"
for agent in ceo cto bizdev ops; do
    if pgrep -f "agent.*$agent" > /dev/null 2>&1; then
        echo "  ✅ $agent — running"
    else
        echo "  ❌ $agent — not running"
    fi
done

echo ""
echo "Services:"

# Check dashboard
if curl -s http://localhost:4200 > /dev/null 2>&1; then
    echo "  ✅ Dashboard — running at :4200"
else
    echo "  ❌ Dashboard — not running"
fi

# Check gateway
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "  ✅ Gateway — running at :3001"
else
    echo "  ⚠️  Gateway — not running (may be using CLI mode)"
fi

echo ""
echo "Memory:"
for f in memory/company-state.md memory/revenue-log.md memory/decisions.md; do
    if [ -f "$f" ]; then
        MOD=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
        NOW=$(date +%s)
        AGE=$(( (NOW - MOD) / 60 ))
        echo "  📝 $f — last updated ${AGE}m ago"
    else
        echo "  ❌ $f — missing"
    fi
done

echo ""
echo "Economy:"
LATEST=$(ls -t economy/reports/*.md 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
    echo "  📊 Latest report: $LATEST"
else
    echo "  ⚠️  No reports generated yet"
fi
