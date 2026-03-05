# Zero Human Corp

> A fully autonomous, zero-human AI company powered by OpenClaw multi-agent orchestration.
> Opus 4.6 for strategic planning & reasoning. Codex 5.3 for all coding tasks.
> Both running on subscription plans (Claude Max + ChatGPT Pro) — no API burn.

## Architecture

```
                    ┌─────────────────────────────────┐
                    │        MISSION CONTROL           │
                    │   (Real-time Dashboard @ :4200)  │
                    │  28 panels · WebSocket · SQLite  │
                    └────────────┬────────────────────┘
                                 │
                    ┌────────────▼────────────────────┐
                    │      CEO AGENT (Opus 4.6)        │
                    │  Strategic planning · Reasoning   │
                    │  Revenue discovery · Delegation   │
                    │  Gateway: Slack/Discord/Terminal  │
                    └────────────┬────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                   │
    ┌─────────▼──────┐ ┌────────▼────────┐ ┌───────▼────────┐
    │  CTO AGENT     │ │  BIZ DEV AGENT  │ │  OPS AGENT     │
    │  (Codex 5.3)   │ │  (Opus 4.6)     │ │  (Opus 4.6)    │
    │                │ │                  │ │                 │
    │  Code gen      │ │  Market research │ │  Monitoring     │
    │  Debugging     │ │  Client outreach │ │  Cost tracking  │
    │  Deployment    │ │  Deal closing    │ │  Self-healing   │
    └───────┬────────┘ └────────┬────────┘ └───────┬────────┘
            │                   │                   │
     ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
     │ Worker Pool │    │ Worker Pool │    │ Worker Pool │
     │ (Codex 5.3) │    │ (Opus 4.6)  │    │ (auto-route)│
     │ max 5 each  │    │ max 5 each  │    │ max 5 each  │
     └─────────────┘    └─────────────┘    └─────────────┘
```

## Quick Start (Hackathon Speed)

### Prerequisites
- Claude Max subscription ($100/mo or $200/mo) — gives Opus 4.6 via Claude Code
- ChatGPT Pro subscription — gives Codex 5.3 via Codex CLI
- Node.js 20+, Python 3.10+, Docker (optional)

### 1. Clone & Install

```bash
git clone <this-repo>
cd zero-human-corp
./setup.sh
```

### 2. Configure Models

```bash
cp .env.example .env
# Edit .env with your subscription endpoints
```

### 3. Launch

```bash
# Terminal 1: Start Mission Control dashboard
./start-dashboard.sh

# Terminal 2: Start the CEO agent
./start-ceo.sh

# Terminal 3: Watch logs
./watch-logs.sh
```

Dashboard at `http://localhost:4200`

## Project Structure

```
zero-human-corp/
├── README.md
├── setup.sh                    # One-command setup
├── start-dashboard.sh          # Launch Mission Control
├── start-ceo.sh                # Launch CEO agent
├── watch-logs.sh               # Tail all agent logs
├── .env.example                # Environment template
│
├── agents/                     # Agent configurations
│   ├── ceo/                    # CEO agent (Opus 4.6)
│   │   ├── agent.json          # Agent config
│   │   ├── system-prompt.md    # CEO personality & strategy
│   │   └── skills/             # CEO-specific skills
│   │       ├── delegate.md     # How to spawn sub-agents
│   │       ├── revenue-scan.md # Revenue opportunity scanner
│   │       └── strategic-plan.md
│   ├── cto/                    # CTO agent (Codex 5.3)
│   │   ├── agent.json
│   │   ├── system-prompt.md
│   │   └── skills/
│   ├── bizdev/                 # Business Dev (Opus 4.6)
│   │   ├── agent.json
│   │   ├── system-prompt.md
│   │   └── skills/
│   └── ops/                    # Operations (Opus 4.6)
│       ├── agent.json
│       ├── system-prompt.md
│       └── skills/
│
├── gateway/                    # OpenClaw gateway config
│   ├── gateway.json            # Main gateway configuration
│   └── channels/               # Channel integrations
│       ├── slack.json
│       ├── discord.json
│       └── terminal.json
│
├── memory/                     # Shared persistent memory (Markdown)
│   ├── company-state.md        # Current company status
│   ├── revenue-log.md          # All revenue transactions
│   ├── decisions.md            # CEO decision history
│   └── learnings.md            # What the company learned
│
├── dashboard/                  # Mission Control (Builderz fork)
│   ├── package.json
│   └── ...
│
├── economy/                    # Economic tracking (ClawWork-inspired)
│   ├── tracker.py              # Revenue/cost tracker
│   ├── budget.json             # Budget constraints
│   └── reports/                # Auto-generated P&L reports
│
├── symphony/                   # Task board (inspired by OpenAI Symphony)
│   ├── SPEC.md                 # Task lifecycle specification
│   ├── board.json              # Live task board state
│   ├── task-manager.py         # Board operations API
│   ├── daily-summary.py        # Daily summary generator + email
│   └── summaries/              # Archived daily summaries
│
├── skills/                     # Shared skill library (includes agency-agents)
│   ├── web-research.md
│   ├── code-and-ship.md
│   ├── content-creation.md
│   ├── market-analysis.md
│   ├── outreach.md
│   ├── growth-hacking.md       # from agency-agents
│   ├── rapid-prototyper.md     # from agency-agents
│   ├── analytics-reporter.md   # from agency-agents
│   └── finance-tracker.md      # from agency-agents
│
└── scripts/                    # Utility scripts
    ├── health-check.sh
    ├── cost-report.sh
    └── reset-agents.sh
```

## Human Intervention Model

You (onr) intervene ONLY when needed. The system handles everything else.

**What the system handles autonomously:**
- All planning (CEO/Opus 4.6), all coding (CTO/Codex 5.3)
- Agent spawning, task assignment, health monitoring
- Revenue tracking, cost optimization, P&L reporting
- Market research, opportunity scoring, pivots

**What triggers an intervention request to you:**
- API keys or credentials needed (X, Stripe, etc.)
- Account creation on external services
- Budget approval for spend > $50/day
- Strategic pivot sign-off (if CEO thinks it's warranted)
- Legal/compliance questions

**How you stay informed:**
- Dashboard at `http://localhost:4200` (real-time, always up)
- Daily summary emailed to you (configure SMTP in .env)
- Intervention queue in `memory/intervention-queue.md`
- All decisions logged in `memory/decisions.md`

## The "Off Mode" Strategy

Instead of burning API tokens, we run both models on unlimited subscription plans:

| Model | Plan | Cost | Use Case |
|-------|------|------|----------|
| Claude Opus 4.6 | Claude Max ($100-200/mo) | Flat rate | CEO, BizDev, Ops — all planning & reasoning |
| GPT-5.3 Codex | ChatGPT Pro ($200/mo) | Flat rate | CTO, all coding workers — code gen & deployment |

**How it works:** OpenClaw routes agent requests through Claude Code CLI (for Opus) and Codex CLI (for Codex 5.3) instead of raw API calls. The gateway handles model routing based on agent role.

## Revenue Philosophy

The CEO agent doesn't follow a playbook. It:
1. Scans the market for novel, underserved opportunities
2. Evaluates ROI based on the company's current capabilities
3. Prioritizes creative, outside-the-box revenue streams
4. Avoids commodity plays (no generic freelancing marketplaces)
5. Ships fast, iterates faster, kills what doesn't work

Think: building micro-SaaS tools for niche markets nobody's serving, creating data products, arbitraging information asymmetries, or inventing entirely new service categories.

## Key Design Principles

- **Truly autonomous**: After initial setup, human intervention is for debugging only
- **Economically accountable**: Every agent tracks its costs vs revenue generated
- **Self-healing**: Ops agent monitors and restarts failed services
- **Memory-first**: All decisions, learnings, and state persisted as Markdown
- **Visualization**: Mission Control shows the full agent tree, tasks, costs, and earnings in real-time

## Built On / Inspired By

| Project | What We Use From It | Link |
|---------|-------------------|------|
| **OpenClaw** | Core agent framework, gateway, memory, skills | [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) (247K stars) |
| **ClawWork** | Economic accountability model, revenue tracking | [github.com/HKUDS/ClawWork](https://github.com/HKUDS/ClawWork) (6.6K stars) |
| **Mission Control** | Dashboard, 28 panels, task board, cost tracking | [github.com/builderz-labs/mission-control](https://github.com/builderz-labs/mission-control) |
| **Symphony** | Task lifecycle, proof-of-work, autonomous work mgmt | [github.com/openai/symphony](https://github.com/openai/symphony) (4.3K stars) |
| **Agency Agents** | Specialist agent skills (55+ across 9 divisions) | [github.com/msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) |
| **ClawDeck** | Alternative dashboard (kanban-style) | [github.com/clawdeckio/clawdeck](https://github.com/clawdeckio/clawdeck) |
