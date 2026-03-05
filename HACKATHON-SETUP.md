# Hackathon Setup Guide — Zero Human Corp

> Everything you need to do on YOUR machine to get this running.
> Config: Claude Max $200/mo + ChatGPT Pro $200/mo + Cloudflare (free tier)

---

## Step 0: Push to GitHub

On your desktop terminal:

```bash
cd ~/path-to/zero-human-corp
gh repo create zero-human-corp --public --source=. --push
# OR manually:
git remote add origin git@github.com:YOUR_USERNAME/zero-human-corp.git
git branch -M main
git push -u origin main
```

---

## Step 1: Install Prerequisites

```bash
# Node.js 22+ (for OpenClaw + dashboard + wrangler)
brew install node
# OR: https://nodejs.org

# Python 3.10+ (for economic tracker)
brew install python3

# GitHub CLI
brew install gh

# OpenClaw (the agent framework)
npm install -g openclaw@latest

# Codex CLI (for GPT-5.3 Codex — coding agents)
npm install -g @openai/codex

# Wrangler CLI (Cloudflare Workers/Pages deploy tool)
npm install -g wrangler

# Claude Code CLI (for Opus 4.6 — planning agents)
# Requires Claude Max $200/mo subscription
# Install: https://code.claude.com/docs/en/getting-started

# Optional: real-time log watching
brew install fswatch
```

---

## Step 2: Authenticate Everything

### Claude Code (Opus 4.6)
```bash
claude
# Follow the auth flow — sign in with your Claude Max $200/mo account
# Test:
claude --model opus --print "Reply with exactly: OPUS_OK"
```

### Codex CLI (GPT-5.3 Codex)
```bash
codex
# Select "Sign in with ChatGPT"
# Sign in with your ChatGPT Pro $200/mo account
# Test:
codex "Reply with exactly: CODEX_OK"
```

### Cloudflare (Wrangler)
```bash
wrangler login
# Opens browser — sign in with your Cloudflare account
# Test:
wrangler whoami
```

### GitHub SSH Key (for CTO agent to push code)
```bash
./scripts/setup-github-ssh.sh
# Generates a deploy key — add the public key to GitHub:
# https://github.com/settings/keys → New SSH key
```

---

## Step 3: Run Setup

```bash
cd zero-human-corp
./setup.sh
```

This will:
- Check all prerequisites
- Create `.env` from template
- Generate SSH key for CTO
- Clone + install Mission Control dashboard
- Install Python dependencies
- Test model access

---

## Step 4: Configure .env

```bash
# Edit .env with your actual credentials:
nano .env  # or vim, code, etc.
```

Fill in:
```
GITHUB_TOKEN=ghp_xxxxx              # https://github.com/settings/tokens/new (repo scope)
STRIPE_SECRET_KEY=sk_test_xxxxx     # https://dashboard.stripe.com/apikeys
CLOUDFLARE_ACCOUNT_ID=xxxxx         # https://dash.cloudflare.com → right sidebar
CLOUDFLARE_API_TOKEN=xxxxx          # https://dash.cloudflare.com/profile/api-tokens
```

---

## Step 5: Run OpenClaw Onboarding

```bash
openclaw onboard
```

During onboarding, select:
- **AI Provider**: Custom (we handle routing via gateway.json)
- **Channels**: Terminal (start simple)
- **Memory**: Local filesystem (already configured in ./memory/)

---

## Step 6: Launch

```bash
# Terminal 1: Dashboard
./start-dashboard.sh
# → http://localhost:4200

# Terminal 2: CEO Agent (Atlas)
./start-ceo.sh
# → Atlas boots, reads strategy, scans market, spawns CTO + BizDev

# Terminal 3: Log Watcher
./watch-logs.sh
# → Live company status, revenue, decisions
```

---

## Step 7: Verify

```bash
./scripts/health-check.sh
```

Expected:
- ✅ CEO (Atlas) — running
- ✅ Ops (Sentinel) — running
- ✅ Dashboard — running at :4200
- CTO (Forge) and BizDev (Scout) get spawned by CEO within first 10 minutes

---

## Troubleshooting

### "openclaw: command not found"
```bash
npm install -g openclaw@latest
```

### "claude: command not found"
Install Claude Code: https://code.claude.com/docs/en/getting-started
Requires Claude Max $200/mo subscription

### "codex: command not found"
```bash
npm install -g @openai/codex
```

### "wrangler: command not found"
```bash
npm install -g wrangler
```

### Agent keeps stopping
Check rate limits. Even on $200/mo, Opus 4.6 has limits.
If hitting them, increase heartbeat interval:
```bash
# In agents/ceo/agent.json, change heartbeat.interval to 600 (10 min)
```

### Cloudflare deploy fails
```bash
wrangler whoami  # Verify auth
wrangler pages list  # Check Pages projects
```

### Dashboard won't start
```bash
cd dashboard && npm install && PORT=4200 npm start
```
