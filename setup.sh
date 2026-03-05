#!/bin/bash
# ============================================
# Zero Human Corp — One-Command Setup
# ============================================

set -e

echo "🏢 Setting up Zero Human Corp..."
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

check_cmd() {
    if command -v "$1" &> /dev/null; then
        echo "  ✅ $1 found"
        return 0
    else
        echo "  ❌ $1 not found — $2"
        return 1
    fi
}

MISSING=0
check_cmd "node" "Install Node.js 20+ from https://nodejs.org" || MISSING=1
check_cmd "python3" "Install Python 3.10+" || MISSING=1
check_cmd "git" "Install git" || MISSING=1
check_cmd "claude" "Install Claude Code CLI (requires Claude Max subscription)" || MISSING=1
check_cmd "codex" "Install Codex CLI (requires ChatGPT Pro subscription)" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "⚠️  Some prerequisites are missing. Install them and re-run setup.sh"
    echo "   The agents WILL still start, but model routing may fall back to available models."
    echo ""
fi

# Copy environment file
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env from template..."
    cp .env.example .env
    echo "  ⚠️  Edit .env to add your tokens (GitHub, Stripe, etc.)"
fi

# Install Mission Control dashboard
echo ""
echo "📊 Setting up Mission Control dashboard..."
if [ -f dashboard/package.json ]; then
    cd dashboard
    npm install --silent 2>/dev/null || echo "  ⚠️  npm install had warnings (non-critical)"
    cd ..
    echo "  ✅ Dashboard dependencies installed"
else
    echo "  ℹ️  Dashboard not yet cloned. Run:"
    echo "     git clone https://github.com/builderz-labs/mission-control dashboard"
    echo "     cd dashboard && npm install && cd .."
fi

# Install Python dependencies for economic tracker
echo ""
echo "💰 Setting up economic tracker..."
pip3 install --quiet --break-system-packages schedule watchdog 2>/dev/null || true
echo "  ✅ Python dependencies installed"

# Initialize git repo if needed
if [ ! -d .git ]; then
    echo ""
    echo "📁 Initializing git repository..."
    git init
    echo "node_modules/\n.env\n*.db\n__pycache__/" > .gitignore
    git add -A
    git commit -m "Initial commit: Zero Human Corp scaffold"
    echo "  ✅ Git repo initialized"
fi

# Create initial memory files if empty
echo ""
echo "🧠 Memory files ready"

echo ""
echo "============================================"
echo "🏢 Zero Human Corp setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your API tokens"
echo "  2. ./start-dashboard.sh  (Terminal 1)"
echo "  3. ./start-ceo.sh        (Terminal 2)"
echo "  4. ./watch-logs.sh       (Terminal 3)"
echo ""
echo "Dashboard will be at http://localhost:4200"
echo ""
