# Claude Code Handoff — Zero Human Corp

> This document summarizes everything built so far and what to do next in Claude Code.

---

## Repo Location

**On your machine:** The repo lives wherever your Cowork workspace folder is mapped.
Look in the folder you selected in Cowork — the `zero-human-corp/` directory is there.

```bash
cd /path/to/your/workspace/zero-human-corp
```

---

## What's Been Built (4 commits, 53 files)

### Git Log
```
572faee  Add Docker, idea framework, security hardening
302a2be  Switch to Cloudflare/Wrangler, configure for $200 Max tiers
7de4a04  Add hackathon setup guide and decisions checklist
458c701  Initial commit: Zero Human Corp scaffold
```

### Architecture

```
CEO (Atlas) ──── Opus 4.6 via Claude Code CLI ($200/mo Max)
  ├── CTO (Forge) ── Codex 5.3 via Codex CLI ($200/mo Pro)
  │     └── up to 5 coding workers (Codex 5.3)
  ├── BizDev (Scout) ── Opus 4.6
  │     └── up to 5 outreach/content workers (Opus 4.6)
  └── Ops (Sentinel) ── Opus 4.6
        └── up to 5 monitoring workers (auto-routed)

Deploy target: Cloudflare (Pages + Workers + D1 + R2) via wrangler CLI
Dashboard: Mission Control at :4200 (Dockerized)
Memory: Markdown files in ./memory/ (git-tracked)
Task Board: Symphony-style in ./symphony/board.json
```

### File Map

```
zero-human-corp/
├── .env.example                         # All config — NO secrets committed
├── .gitignore                           # Ignores .env, SSH keys, Docker, reports
├── README.md                            # Full architecture doc
├── HACKATHON-SETUP.md                   # Step-by-step local setup guide
├── DECISIONS-NEEDED.md                  # Questions to answer before launch
├── CLAUDE_CODE_HANDOFF.md               # THIS FILE
│
├── agents/
│   ├── ceo/
│   │   ├── agent.json                   # Atlas config (Opus, full autonomy, $100/day budget)
│   │   ├── system-prompt.md             # CEO personality, directives, constraints
│   │   └── skills/
│   │       ├── idea-framework.md        # ★ CORE: 6-phase idea discovery → execution pipeline
│   │       ├── delegate.md              # How to assign tasks to sub-agents
│   │       ├── revenue-scan.md          # Market opportunity scanner
│   │       ├── strategic-plan.md        # Strategic planning process
│   │       └── agents-orchestrator.md   # Multi-agent coordination
│   ├── cto/
│   │   ├── agent.json                   # Forge config (Codex, deploys to Cloudflare)
│   │   └── system-prompt.md             # CTO with full Cloudflare stack guide
│   ├── bizdev/
│   │   ├── agent.json                   # Scout config (Opus, outreach/content)
│   │   └── system-prompt.md
│   └── ops/
│       ├── agent.json                   # Sentinel config (Opus, self-healing)
│       ├── system-prompt.md
│       └── skills/
│           └── daily-summary.md         # Daily P&L + intervention queue
│
├── gateway/
│   ├── gateway.json                     # OpenClaw gateway: model routing, agent registry
│   └── channels/
│       ├── terminal.json                # Enabled by default
│       ├── slack.json                   # Disabled (configure later)
│       └── discord.json                 # Disabled (configure later)
│
├── memory/                              # Persistent state (Markdown, git-tracked)
│   ├── company-state.md                 # Current status (updated every heartbeat)
│   ├── revenue-log.md                   # All revenue + cost transactions
│   ├── decisions.md                     # CEO decision log with reasoning
│   ├── learnings.md                     # What the company learned
│   └── intervention-queue.md            # Items needing human attention
│
├── symphony/                            # Task board (Symphony-inspired)
│   ├── SPEC.md                          # Task lifecycle specification
│   ├── board.json                       # Live task state
│   ├── task-manager.py                  # Board CRUD operations
│   └── daily-summary.py                 # Daily report generator + email
│
├── economy/                             # Financial tracking
│   ├── budget.json                      # $100/day limit, category breakdown
│   └── tracker.py                       # P&L report generator
│
├── skills/                              # Shared skill library
│   ├── web-research.md
│   ├── code-and-ship.md                 # Cloudflare-first shipping guide
│   ├── content-creation.md
│   ├── market-analysis.md
│   ├── outreach.md
│   ├── growth-hacking.md               # From agency-agents
│   ├── rapid-prototyper.md             # Cloudflare stack, speed benchmarks
│   ├── analytics-reporter.md           # KPI tracking framework
│   └── finance-tracker.md              # Revenue/cost logging format
│
├── scripts/
│   ├── setup-github-ssh.sh             # Generate SSH deploy key for CTO
│   ├── health-check.sh                 # Check all agents + services
│   └── reset-agents.sh                 # Kill all agents, preserve memory
│
├── docker-compose.yml                   # Dashboard + tracker + watcher
├── Dockerfile.dashboard
├── Dockerfile.tracker
├── Dockerfile.watcher
│
├── setup.sh                             # One-command setup (installs everything)
├── start-dashboard.sh                   # Launch Mission Control
├── start-ceo.sh                         # Launch CEO agent
└── watch-logs.sh                        # Tail live status
```

---

## Security Model

- **NO secrets in the repo.** All credentials go in `.env` (gitignored).
- SSH key for CTO agent generated by `scripts/setup-github-ssh.sh`
- Cloudflare auth via `wrangler login` (browser-based OAuth, no token in repo)
- Stripe keys in `.env` only
- Agent configs reference env vars, never hardcoded values

---

## What To Do Next in Claude Code

### 1. Push to GitHub
```bash
cd /path/to/zero-human-corp
gh repo create zero-human-corp --public --source=. --push
```

### 2. Run Setup
```bash
./setup.sh
```

### 3. Fill in .env
You need:
- `CLOUDFLARE_ACCOUNT_ID` — from dash.cloudflare.com right sidebar
- `CLOUDFLARE_API_TOKEN` — dash.cloudflare.com/profile/api-tokens → "Edit Workers"
- `STRIPE_SECRET_KEY` — dashboard.stripe.com/apikeys (use sk_test_ for now)
- `GITHUB_TOKEN` — github.com/settings/tokens/new (repo scope)

### 4. Authenticate CLIs
```bash
claude                    # Sign in with Claude Max account
codex                     # Sign in with ChatGPT Pro account
wrangler login            # Sign in with Cloudflare account
./scripts/setup-github-ssh.sh  # Generate + add SSH key to GitHub
```

### 5. Start Docker Services
```bash
docker compose up -d      # Dashboard, tracker, watcher
```

### 6. Launch the Company
```bash
./start-ceo.sh            # Atlas boots, discovers ideas, spawns agents
```

---

## The Idea Framework (How The CEO Decides What To Build)

The CEO follows a 6-phase pipeline defined in `agents/ceo/skills/idea-framework.md`:

```
DISCOVER (30m) → SCORE (15m) → VALIDATE (1-2h) → BUILD (2-4h) → MEASURE (24h) → SCALE or KILL
```

**Key scoring criteria** (1-5 each, need 18/30 to proceed):
Pain Severity, Market Size, Build Speed, Revenue Speed, AI Moat, Recurring Revenue

**Portfolio approach**: Run 2-3 ideas in parallel. Idea A gets full build,
Idea B gets landing page validation, Idea C gets research only.

**Kill discipline**: $0 revenue after 48 hours = kill and pivot immediately.

---

## What Can Run Overnight

Once setup is complete and the CEO agent is booted:
1. Atlas will discover and score ideas (Phase 1-2)
2. Atlas will spawn CTO + BizDev
3. CTO will build MVP(s)
4. BizDev will prepare launch content
5. Ops monitors everything, generates hourly reports
6. Check `memory/company-state.md` and the dashboard in the morning

**Rate limit note**: On $200/mo Max, Opus 4.6 will throttle eventually.
If agents stall, increase heartbeat interval in `agents/ceo/agent.json`.

---

## Decisions Still Open

1. Starting capital ($0 or seed it?)
2. Revenue guardrails (any off-limits industries/tactics?)
3. Hackathon demo goal (first revenue? shipped product? agent tree?)
4. Stripe: test mode or live mode?
