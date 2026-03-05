#!/bin/bash
# ============================================
# Generate SSH deploy key for CTO agent
# ============================================
# This creates a dedicated SSH key pair that the CTO agent
# uses to push code to GitHub repos it creates.

set -e

KEY_PATH="${GITHUB_SSH_KEY_PATH:-$HOME/.ssh/zhc_deploy}"

echo "🔑 Setting up GitHub SSH key for Zero Human Corp..."
echo ""

# Check if key already exists
if [ -f "$KEY_PATH" ]; then
    echo "  ⚠️  SSH key already exists at $KEY_PATH"
    echo "  Public key:"
    cat "${KEY_PATH}.pub"
    echo ""
    echo "  If you need a new key, delete the existing one first:"
    echo "    rm $KEY_PATH ${KEY_PATH}.pub"
    exit 0
fi

# Generate key
ssh-keygen -t ed25519 -C "zero-human-corp-cto@zhc" -f "$KEY_PATH" -N ""

echo ""
echo "✅ SSH key generated!"
echo ""
echo "📋 Public key (add this to GitHub):"
echo "============================================"
cat "${KEY_PATH}.pub"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Go to: https://github.com/settings/keys"
echo "  2. Click 'New SSH key'"
echo "  3. Title: 'Zero Human Corp - CTO Deploy Key'"
echo "  4. Paste the public key above"
echo "  5. Click 'Add SSH key'"
echo ""
echo "  OR for a specific repo (more secure):"
echo "  1. Go to: https://github.com/<your-org>/<repo>/settings/keys"
echo "  2. Click 'Add deploy key'"
echo "  3. Check 'Allow write access'"
echo "  4. Paste the public key above"
echo ""

# Configure SSH to use this key for GitHub
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "zhc_deploy" "$SSH_CONFIG" 2>/dev/null; then
    echo "📝 Adding SSH config entry..."
    cat >> "$SSH_CONFIG" << SSHEOF

# Zero Human Corp - CTO Agent
Host github.com-zhc
    HostName github.com
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
SSHEOF
    chmod 600 "$SSH_CONFIG"
    echo "  ✅ SSH config updated"
fi

echo ""
echo "🔧 Test connection with:"
echo "  ssh -T git@github.com-zhc"
