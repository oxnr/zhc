#!/bin/bash
# Watch all agent logs in real-time
echo "📋 Watching Zero Human Corp logs..."
echo "   Press Ctrl+C to stop"
echo ""

# Watch memory files for changes (these are the "logs")
if command -v fswatch &> /dev/null; then
    fswatch -r memory/ economy/reports/
elif command -v inotifywait &> /dev/null; then
    while true; do
        inotifywait -r -e modify memory/ economy/reports/ 2>/dev/null
        echo "---"
        echo "📝 Memory updated at $(date)"
        echo "--- Company State ---"
        head -20 memory/company-state.md 2>/dev/null
        echo ""
        echo "--- Latest Revenue ---"
        tail -5 memory/revenue-log.md 2>/dev/null
        echo ""
        echo "--- Latest Decision ---"
        tail -10 memory/decisions.md 2>/dev/null
        echo "---"
    done
else
    # Fallback: poll every 10 seconds
    echo "Using polling mode (install fswatch or inotify-tools for real-time)"
    while true; do
        clear
        echo "🏢 Zero Human Corp — Live Status ($(date))"
        echo "============================================"
        echo ""
        echo "📊 Company State:"
        cat memory/company-state.md 2>/dev/null || echo "  Not initialized yet"
        echo ""
        echo "💰 Recent Revenue:"
        tail -10 memory/revenue-log.md 2>/dev/null || echo "  No revenue yet"
        echo ""
        echo "📝 Recent Decisions:"
        tail -10 memory/decisions.md 2>/dev/null || echo "  No decisions yet"
        echo ""
        echo "📈 Latest Report:"
        ls -t economy/reports/*.md 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "  No reports yet"
        sleep 10
    done
fi
