# Claude Code Handoff — Zero Human Corp

> Complete summary of everything built. Read this first in Claude Code.
> `cat CLAUDE_CODE_HANDOFF.md`

---

## Repo Location

This repo lives in the folder you selected in Cowork.
On your machine, find it and `cd` into it:

```bash
cd /path/to/your-cowork-folder/zero-human-corp
```

---

## What's Been Built (6 commits, ~58 files)

### Architecture

```
CEO (Atlas) ──── Opus 4.6 via Claude Code CLI ($200/mo Max)
  ├── CTO (Forge) ── Codex 5.3 via Codex CLI ($200/mo Pro)
  │     └── up to 5 coding workers (Codex 5.3)
  ├── BizDev (Scout) ── Opus 4.6
  │     └── up to 5 outreach/content workers (Opus 4.6)
  └── Ops (Sentinel) ── Opus 4.6
        └── up to 5 monitoring workers (auto-routed)

Deploy:    Cloudflare (Pages + Workers + D1 + R2) via wrangler CLI
Dashboard: Custom Mission Control at :4200 (Node + WebSocket, Dockerized)
Memory:    Markdown files in ./memory/ (git-tracked, real-time watched)
Tasks:     Symphony-style board in ./symphony/board.json
Economy:   P&L tracker in ./economy/ (hourly reports, Dockerized)
```

### File Map

```
zero-human-corp/
├── .env.example                         # All config — NO secrets committed
├── .gitignore
├── README.md                            # Full architecture doc
├── HACKATHON-SETUP.md                   # Step-by-step local setup
├── DECISIONS-NEEDED.md                  # Open questions
├── CLAUDE_CODE_HANDOFF.md               # THIS FILE
│
├── agents/
│   ├── ceo/
│   │   ├── agent.json                   # Atlas: Opus, full autonomy, $100/day budget
│   │   ├── system-prompt.md             # Personality, directives, constraints
│   │   └── skills/
│   │       ├── idea-framework.md        # ★ CORE: 6-phase DISCOVER→SCORE→VALIDATE→BUILD→MEASURE→SCALE/KILL
│   │       ├── delegate.md              # Task assignment to sub-agents
│   │       ├── revenue-scan.md          # Market opportunity scanner
│   │       ├── strategic-plan.md        # Strategic planning process
│   │       └── agents-orchestrator.md   # Multi-agent coordination
│   ├── cto/
│   │   ├── agent.json                   # Forge: Codex 5.3, Cloudflare deploy
│   │   └── system-prompt.md             # Full Cloudflare stack guide (Pages, Workers, D1, R2)
│   ├── bizdev/
│   │   ├── agent.json                   # Scout: Opus 4.6, outreach/content
│   │   └── system-prompt.md
│   └── ops/
│       ├── agent.json                   # Sentinel: Opus 4.6, self-healing
│       ├── system-prompt.md
│       └── skills/daily-summary.md      # Daily P&L + intervention queue
│
├── dashboard/                           # ★ CUSTOM Mission Control (tested, working)
│   ├── package.json                     # express + ws + chokidar
│   ├── server.js                        # Node server: watches files, WebSocket push
│   └── index.html                       # Single-page dark UI: agents, tasks, revenue, interventions
│
├── gateway/
│   ├── gateway.json                     # OpenClaw: model routing (Opus for planning, Codex for code)
│   └── channels/{terminal,slack,discord}.json
│
├── memory/                              # Persistent state (Markdown, watched by dashboard)
│   ├── company-state.md                 # Updated every CEO heartbeat
│   ├── revenue-log.md                   # REVENUE: $X | source | timestamp
│   ├── decisions.md                     # CEO decision log with reasoning
│   ├── learnings.md                     # Accumulated learnings
│   └── intervention-queue.md            # [OPEN] items needing human action
│
├── symphony/                            # Task board
│   ├── board.json                       # INBOX→ASSIGNED→IN_PROGRESS→IN_REVIEW→DONE
│   ├── task-manager.py                  # Board CRUD API
│   └── daily-summary.py                 # Report generator + optional email
│
├── economy/
│   ├── budget.json                      # $100/day limit, categories
│   └── tracker.py                       # Hourly P&L report generator
│
├── skills/                              # Shared skill library
│   ├── code-and-ship.md                 # Cloudflare-first shipping
│   ├── rapid-prototyper.md              # Speed benchmarks by stack
│   ├── growth-hacking.md                # Viral loops, channels, experiments
│   ├── analytics-reporter.md            # KPI framework
│   ├── finance-tracker.md               # Revenue/cost logging format
│   ├── {web-research,market-analysis,content-creation,outreach}.md
│
├── scripts/
│   ├── setup-github-ssh.sh              # Generate SSH key for CTO agent
│   ├── health-check.sh                  # Check all agents + services
│   └── reset-agents.sh                  # Kill agents, preserve memory
│
├── docker-compose.yml                   # Dashboard + tracker (agents run on host)
├── Dockerfile.{dashboard,tracker,watcher}
├── setup.sh                             # One-command full setup
├── start-dashboard.sh                   # Launch Mission Control (:4200)
├── start-ceo.sh                         # Launch CEO agent (Atlas)
└── watch-logs.sh                        # Terminal log viewer
```

---

## Security

- Zero secrets in repo. All credentials in `.env` (gitignored).
- SSH key generated by `scripts/setup-github-ssh.sh` (gitignored).
- Cloudflare auth via `wrangler login` (OAuth, no token stored).
- Security audit passed: no hardcoded keys, emails, or tokens.

---

## How The CEO Finds Ideas

6-phase pipeline in `agents/ceo/skills/idea-framework.md`:

```
DISCOVER (30m)  — Pain point mining, underserved niche detection, arbitrage scanning
    ↓
SCORE (15m)     — 6 criteria scored 1-5 (need 18/30 to proceed)
    ↓
VALIDATE (1-2h) — Landing page test, pre-sell test, competitor gap analysis
    ↓
BUILD (2-4h)    — CTO ships MVP to Cloudflare, BizDev prepares launch
    ↓
MEASURE (24h)   — Traffic, signups, payment attempts, actual revenue
    ↓
SCALE or KILL   — Revenue > $0 → double down. $0 after 48h → kill and pivot.
```

Portfolio: 2-3 ideas in parallel. Idea A = full build, B = validation, C = research.

---

## Next Steps (in Claude Code)

### Quick Start
```bash
cd /path/to/zero-human-corp

# 1. Push to GitHub
gh repo create zero-human-corp --public --source=. --push

# 2. Run setup
./setup.sh

# 3. Fill in .env (Cloudflare, Stripe, GitHub tokens)
nano .env

# 4. Auth CLIs
claude                          # Claude Max
codex                           # ChatGPT Pro
wrangler login                  # Cloudflare
./scripts/setup-github-ssh.sh   # SSH key → add to GitHub

# 5. Start dashboard (Docker or direct)
./start-dashboard.sh            # http://localhost:4200

# 6. Launch the company
./start-ceo.sh                  # Atlas boots → discovers ideas → spawns agents
```

### What To Build Next
1. Wire OpenClaw gateway to actually spawn agents via `claude` and `codex` CLIs
2. Test the full CEO → CTO → deploy flow end-to-end
3. Add Stripe webhook endpoint for real-time revenue tracking
4. Add Cloudflare Pages deploy script that CTO calls
5. Consider: should the dashboard be deployed to Cloudflare too? (for mobile access)

---

## Decisions Still Open

1. Starting capital: $0 (bootstrap) or seed some budget?
2. Revenue guardrails: any industries or tactics off-limits?
3. Stripe: test mode (sk_test_) or live mode (sk_live_)?
4. Hackathon demo goal: first $1 revenue? Shipped product? Agent tree running?
