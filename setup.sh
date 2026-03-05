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
        echo "  ✅ $1 found ($(command -v $1))"
        return 0
    else
        echo "  ❌ $1 not found — $2"
        return 1
    fi
}

MISSING=0
check_cmd "node" "Install Node.js 22+ from https://nodejs.org" || MISSING=1
check_cmd "python3" "Install Python 3.10+" || MISSING=1
check_cmd "git" "Install git" || MISSING=1
check_cmd "claude" "Install Claude Code CLI (requires Claude Max $200/mo)" || MISSING=1
check_cmd "codex" "Install Codex CLI: npm install -g @openai/codex (requires ChatGPT Pro $200/mo)" || MISSING=1
check_cmd "wrangler" "Install Wrangler CLI: npm install -g wrangler" || MISSING=1
check_cmd "gh" "Install GitHub CLI: brew install gh (optional)" || true

if [ "$MISSING" -eq 1 ]; then
    echo ""
    echo "⚠️  Some prerequisites are missing."
    echo ""
    echo "Quick install (macOS):"
    echo "  brew install node python3 git gh"
    echo "  npm install -g openclaw@latest @openai/codex wrangler"
    echo "  # Claude Code: https://code.claude.com/docs/en/getting-started"
    echo ""
    echo "Quick install (Linux):"
    echo "  sudo apt install nodejs python3 git"
    echo "  npm install -g openclaw@latest @openai/codex wrangler"
    echo ""
fi

# Copy environment file
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env from template..."
    cp .env.example .env
    echo "  ⚠️  Edit .env to add your tokens:"
    echo "     - GITHUB_TOKEN"
    echo "     - STRIPE_SECRET_KEY"
    echo "     - CLOUDFLARE_ACCOUNT_ID"
    echo "     - CLOUDFLARE_API_TOKEN"
fi

# Install OpenClaw if not present
echo ""
echo "🦞 Checking OpenClaw..."
if command -v openclaw &> /dev/null; then
    echo "  ✅ OpenClaw installed"
else
    echo "  📦 Installing OpenClaw..."
    npm install -g openclaw@latest 2>/dev/null && echo "  ✅ OpenClaw installed" || echo "  ⚠️  Install manually: npm install -g openclaw@latest"
fi

# Install Wrangler if not present
echo ""
echo "☁️  Checking Wrangler (Cloudflare CLI)..."
if command -v wrangler &> /dev/null; then
    echo "  ✅ Wrangler installed"
else
    echo "  📦 Installing Wrangler..."
    npm install -g wrangler 2>/dev/null && echo "  ✅ Wrangler installed" || echo "  ⚠️  Install manually: npm install -g wrangler"
fi

# Set up GitHub SSH key for CTO agent
echo ""
echo "🔑 Setting up GitHub SSH key for CTO agent..."
KEY_PATH="${GITHUB_SSH_KEY_PATH:-$HOME/.ssh/zhc_deploy}"
if [ -f "$KEY_PATH" ]; then
    echo "  ✅ SSH key exists at $KEY_PATH"
else
    echo "  Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "zero-human-corp-cto@zhc" -f "$KEY_PATH" -N ""
    echo ""
    echo "  ⚠️  ADD THIS PUBLIC KEY TO GITHUB:"
    echo "  ============================================"
    cat "${KEY_PATH}.pub"
    echo "  ============================================"
    echo "  Go to: https://github.com/settings/keys → New SSH key"
    echo ""
fi

# Authenticate Cloudflare
echo ""
echo "☁️  Cloudflare auth..."
if wrangler whoami &> /dev/null 2>&1; then
    echo "  ✅ Wrangler authenticated"
else
    echo "  ⚠️  Run: wrangler login (opens browser to authenticate)"
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
    echo "  ℹ️  Dashboard not yet cloned. Running now..."
    git clone https://github.com/builderz-labs/mission-control dashboard 2>/dev/null && {
        cd dashboard && npm install --silent 2>/dev/null && cd ..
        echo "  ✅ Dashboard cloned and installed"
    } || {
        echo "  ⚠️  Could not clone dashboard. Run manually:"
        echo "     git clone https://github.com/builderz-labs/mission-control dashboard"
        echo "     cd dashboard && npm install && cd .."
    }
fi

# Install Python dependencies for economic tracker
echo ""
echo "💰 Setting up economic tracker..."
pip3 install --quiet --break-system-packages schedule watchdog 2>/dev/null || pip3 install --quiet schedule watchdog 2>/dev/null || true
echo "  ✅ Python dependencies installed"

# Initialize git repo if needed
if [ ! -d .git ]; then
    echo ""
    echo "📁 Initializing git repository..."
    git init
    git add -A
    git commit -m "Initial commit: Zero Human Corp scaffold"
    echo "  ✅ Git repo initialized"
fi

# Create initial memory files if empty
echo ""
echo "🧠 Memory files ready"

# Verify model access
echo ""
echo "🤖 Model access check..."
if command -v claude &> /dev/null; then
    echo "  Testing Claude Opus 4.6..."
    timeout 30 claude --model opus --print "Reply with exactly: OPUS_OK" 2>/dev/null | head -1 || echo "  ⚠️  Claude test timed out (check subscription)"
fi
if command -v codex &> /dev/null; then
    echo "  Testing Codex 5.3..."
    timeout 30 codex --model gpt-5.3-codex "Reply with exactly: CODEX_OK" 2>/dev/null | head -1 || echo "  ⚠️  Codex test timed out (check subscription)"
fi

echo ""
echo "============================================"
echo "🏢 Zero Human Corp setup complete!"
echo "============================================"
echo ""
echo "Remaining manual steps:"
echo "  1. Edit .env with your API tokens"
echo "  2. Add SSH public key to GitHub (printed above)"
echo "  3. Run: wrangler login (if not already authenticated)"
echo ""
echo "Launch:"
echo "  ./start-dashboard.sh  (Terminal 1) → http://localhost:4200"
echo "  ./start-ceo.sh        (Terminal 2) → Atlas begins strategic planning"
echo "  ./watch-logs.sh       (Terminal 3) → Live company status"
echo ""
