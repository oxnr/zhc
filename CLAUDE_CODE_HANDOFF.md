# Claude Code Handoff — Zero Human Corp

> Read this first. This is the single source of truth for continuing in Claude Code.

---

## What This Is

A fully autonomous, zero-human AI company. CEO agent (Opus 4.6) discovers revenue
opportunities, delegates to CTO (Codex 5.3) for building and BizDev (Opus 4.6) for
selling. Ops agent monitors everything. All running on subscription plans ($200/mo
Claude Max + $200/mo ChatGPT Pro), deploying to Cloudflare, with a custom real-time
dashboard at localhost:4200.

---

## Architecture

```
CEO (Atlas/Opus 4.6) ── plans, scores ideas, delegates, pivots
  ├── CTO (Forge/Codex 5.3) ── codes, deploys to Cloudflare
  │     └── up to 5 coding workers
  ├── BizDev (Scout/Opus 4.6) ── research, outreach, content, sales
  │     └── up to 5 outreach workers
  └── Ops (Sentinel/Opus 4.6) ── monitoring, cost tracking, self-healing
        └── up to 5 monitoring workers

Deploy:    Cloudflare Pages + Workers + D1 + R2 (via wrangler CLI)
Dashboard: Custom Node.js + WebSocket at :4200 (Dockerized)
Memory:    Markdown files in ./memory/ (watched by dashboard for real-time updates)
Tasks:     Symphony board in ./symphony/board.json
Economy:   Hourly P&L in ./economy/reports/
```

---

## File Map

```
zero-human-corp/
├── README.md                            # Public-facing project description
├── CLAUDE_CODE_HANDOFF.md               # THIS FILE
├── .env.example                         # All config, zero secrets
├── .gitignore
│
├── agents/
│   ├── ceo/
│   │   ├── agent.json                   # Opus, full autonomy, $100/day budget
│   │   ├── system-prompt.md             # Personality + constraints
│   │   └── skills/
│   │       ├── idea-framework.md        # ★ 6-phase: DISCOVER→SCORE→VALIDATE→BUILD→MEASURE→SCALE/KILL
│   │       ├── delegate.md              # Task assignment protocol
│   │       ├── revenue-scan.md          # Opportunity scoring (18/30 threshold)
│   │       ├── strategic-plan.md        # Strategy creation + 6-hour reviews
│   │       └── agents-orchestrator.md   # Multi-agent coordination
│   ├── cto/
│   │   ├── agent.json                   # Codex 5.3, Cloudflare deploy
│   │   └── system-prompt.md             # Full CF stack: Pages, Workers, D1, R2, KV
│   ├── bizdev/
│   │   ├── agent.json                   # Opus 4.6, outreach/content
│   │   └── system-prompt.md
│   └── ops/
│       ├── agent.json                   # Opus 4.6, self-healing, cost watchdog
│       ├── system-prompt.md
│       └── skills/daily-summary.md
│
├── dashboard/
│   ├── package.json                     # express + ws + chokidar
│   ├── server.js                        # Watches files, pushes via WebSocket
│   └── index.html                       # Single dark UI: agents, tasks, revenue, P&L, interventions
│
├── gateway/
│   ├── gateway.json                     # OpenClaw model routing (Opus for planning, Codex for code)
│   └── channels/{terminal,slack,discord}.json
│
├── memory/
│   ├── company-state.md                 # Updated every CEO heartbeat
│   ├── revenue-log.md                   # REVENUE/COST entries with amounts + timestamps
│   ├── decisions.md                     # CEO reasoning log
│   ├── learnings.md                     # Accumulated knowledge
│   └── intervention-queue.md            # [OPEN] items needing human action
│
├── symphony/
│   ├── board.json                       # INBOX→ASSIGNED→IN_PROGRESS→IN_REVIEW→DONE
│   ├── task-manager.py                  # CRUD for tasks
│   └── daily-summary.py                 # Report generator + optional email
│
├── economy/
│   ├── budget.json                      # $100/day, categories, alerts
│   └── tracker.py                       # Hourly P&L reports
│
├── skills/                              # Shared across agents
│   ├── code-and-ship.md                 # Cloudflare-first deployment
│   ├── rapid-prototyper.md              # Stack choices + speed benchmarks
│   ├── growth-hacking.md                # Channels, experiments, metrics
│   ├── analytics-reporter.md            # KPI framework
│   ├── finance-tracker.md               # Logging format
│   ├── web-research.md
│   ├── market-analysis.md
│   ├── content-creation.md
│   └── outreach.md
│
├── scripts/
│   ├── setup-github-ssh.sh              # SSH key for CTO git operations
│   ├── health-check.sh
│   └── reset-agents.sh
│
├── docker-compose.yml                   # Dashboard + economic tracker
├── Dockerfile.dashboard
├── Dockerfile.tracker
├── setup.sh                             # One-command install
├── start-dashboard.sh                   # :4200
├── start-ceo.sh                         # Boot Atlas
└── watch-logs.sh                        # Terminal status viewer
```

---

## Security

Zero secrets in repo. All via `.env` (gitignored) or CLI OAuth.
Audit passed — no hardcoded keys, tokens, emails, or credentials anywhere.

---

## Setup Sequence

```bash
# 1. Push to GitHub
gh repo create zero-human-corp --public --source=. --push

# 2. Install everything
./setup.sh

# 3. Create .env from template and fill in:
cp .env.example .env
#   CLOUDFLARE_ACCOUNT_ID    — dash.cloudflare.com → right sidebar
#   CLOUDFLARE_API_TOKEN     — dash.cloudflare.com/profile/api-tokens → "Edit Workers"
#   STRIPE_SECRET_KEY        — dashboard.stripe.com/apikeys (sk_test_ to start)
#   GITHUB_TOKEN             — github.com/settings/tokens/new (repo scope)

# 4. Authenticate CLIs
claude                          # Claude Max $200/mo
codex                           # ChatGPT Pro $200/mo
wrangler login                  # Cloudflare (browser OAuth)
./scripts/setup-github-ssh.sh   # SSH key → add to github.com/settings/keys

# 5. Launch
docker compose up -d            # Dashboard + tracker
./start-ceo.sh                  # Atlas boots → ideas → agents → revenue
```

Dashboard at http://localhost:4200 — one screen, everything.

---

## How The CEO Thinks

Pipeline: `DISCOVER (30m) → SCORE (15m) → VALIDATE (1-2h) → BUILD (2-4h) → MEASURE (24h) → SCALE or KILL`

Scoring: 6 criteria (Pain, Market, Build Speed, Revenue Speed, AI Moat, Recurring) × 1-5 each. Need 18/30.

Portfolio: 2-3 ideas simultaneously. A = full build, B = landing page test, C = research.

Kill rule: $0 after 48h = dead. Move on.

Full details: `agents/ceo/skills/idea-framework.md`

---

## What To Build Next

1. **Wire the gateway**: Make OpenClaw actually spawn sub-agents via `claude` and `codex` CLIs
2. **End-to-end test**: CEO → CTO → Cloudflare deploy → live URL
3. **Stripe webhooks**: Real-time revenue events into `memory/revenue-log.md`
4. **Wrangler deploy script**: Reusable `scripts/deploy-to-cf.sh` that CTO calls
5. **Rate limit handling**: Graceful backoff when Opus/Codex throttle on $200 tier

---

## Decisions Settled

| Decision | Answer |
|----------|--------|
| Claude plan | Max $200/mo |
| ChatGPT plan | Pro $200/mo |
| Deploy target | Cloudflare (Pages + Workers) via wrangler |
| GitHub | SSH key generated, user creates account |
| Stripe | Yes, tokens in .env when ready |
| Dashboard | Custom single-pane at :4200 |
| Docker | Dashboard + tracker containerized, agents on host |
| Secrets | All in .env, zero in repo |

## Decisions Still Open

| Decision | Options |
|----------|---------|
| Starting capital | $0 bootstrap vs seed some budget |
| Revenue guardrails | Any off-limits industries or tactics? |
| Stripe mode | sk_test_ (safe) vs sk_live_ (real money) |
| Hackathon demo goal | First $1? Shipped product? Running agent tree? |
