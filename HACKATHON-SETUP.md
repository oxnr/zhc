# Hackathon Setup Guide — Zero Human Corp

> Everything you need to do on YOUR machine to get this running.
> The Cowork sandbox created the repo; now you bring it to life.

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

### Required

```bash
# Node.js 22+ (for OpenClaw + dashboard)
brew install node
# OR: https://nodejs.org

# Python 3.10+ (for economic tracker)
brew install python3
# OR: https://python.org

# OpenClaw (the agent framework)
npm install -g openclaw@latest

# Codex CLI (for GPT-5.3 Codex coding agents)
npm install -g @openai/codex

# Claude Code CLI (for Opus 4.6 planning agents)
# Requires Claude Max subscription — install via:
# https://code.claude.com/docs/en/getting-started
```

### Optional but Recommended

```bash
# GitHub CLI (for repo management)
brew install gh

# Docker (for containerized deployment later)
brew install --cask docker

# fswatch (for real-time log watching)
brew install fswatch
```

---

## Step 2: Authenticate Models

### Claude Code (Opus 4.6)
```bash
claude
# Follow the auth flow — sign in with your Claude Max account
# Test: claude --model opus "Say hello"
```

### Codex CLI (GPT-5.3 Codex)
```bash
codex
# Select "Sign in with ChatGPT"
# Sign in with your ChatGPT Pro account
# Test: codex "Say hello"
```

---

## Step 3: Run OpenClaw Onboarding

```bash
cd zero-human-corp
openclaw onboard
```

During onboarding, select:
- **AI Provider**: Custom (we handle routing ourselves via gateway.json)
- **Channels**: Terminal (start simple, add Slack/Discord later)
- **Memory**: Local filesystem (already configured in ./memory/)

---

## Step 4: Set Up Environment

```bash
cp .env.example .env
# Edit .env with your actual credentials
```

---

## Step 5: Install Dashboard

```bash
# Option A: Mission Control (recommended)
git clone https://github.com/builderz-labs/mission-control dashboard
cd dashboard && npm install && cd ..

# Option B: ClawDeck (alternative)
git clone https://github.com/clawdeckio/clawdeck dashboard
cd dashboard && bundle install && cd ..
```

---

## Step 6: Launch Everything

```bash
# Terminal 1: Dashboard
./start-dashboard.sh

# Terminal 2: CEO Agent
./start-ceo.sh

# Terminal 3: Log Watcher
./watch-logs.sh
```

Dashboard at http://localhost:4200

---

## Step 7: Verify It's Running

```bash
./scripts/health-check.sh
```

You should see:
- ✅ CEO (Atlas) — running
- ✅ Ops (Sentinel) — running
- ✅ Dashboard — running at :4200

CTO and BizDev will be spawned by the CEO once it starts strategic planning.

---

## Troubleshooting

### "openclaw: command not found"
```bash
npm install -g openclaw@latest
```

### "claude: command not found"
Install Claude Code: https://code.claude.com/docs/en/getting-started
Requires Claude Max subscription ($100-200/mo)

### "codex: command not found"
```bash
npm install -g @openai/codex
```

### Agent keeps stopping
Check rate limits — Claude Max has usage limits on Opus 4.6.
Consider lowering heartbeat interval from 5min to 15min to conserve quota:
Edit `agents/ceo/agent.json` → set `heartbeat.interval` to 900

### Dashboard won't start
```bash
cd dashboard && npm install && PORT=4200 npm start
```
