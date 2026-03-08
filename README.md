<p align="center">
  <h1 align="center">ZHC - Zero Human Corp</h1>
</p>
<p align="center">
  Autonomous AI company in a single Docker container.<br>
  Built on <a href="https://github.com/openclaw/openclaw">OpenClaw</a> — agents strategize, build, sell, and ship.
</p>
<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/docker-ready-2496ED?style=for-the-badge" alt="Docker"></a>
  <a href="https://github.com/openclaw/openclaw"><img src="https://img.shields.io/badge/openclaw-powered-FF6B35?style=for-the-badge" alt="OpenClaw"></a>
</p>

## Live Product

**[ZeroIntel](https://oxnr.github.io/zhc/)** — AI-Powered Competitive Intelligence Reports. Get a $5,000 competitor analysis for $49. [Order a report](https://oxnr.github.io/zhc/order.html) | [Sample report](https://oxnr.github.io/zhc/sample-report.html)

---

## Quick Start

```bash
git clone https://github.com/oxnr/zhc.git
cd zhc
cp .env.example .env     # add ANTHROPIC_API_KEY and/or OPENAI_API_KEY
docker build -t zhc .
./run.sh
```

- **Dashboard**: http://localhost:4200
- **Task Board**: http://localhost:4200/tasks
- **OpenClaw Gateway**: http://localhost:18789
- **API**: http://localhost:4200/api/state

## How It Works

A Champion agent (Duke) boots via the [OpenClaw](https://github.com/openclaw/openclaw) gateway, plans a revenue strategy, and spawns specialist sub-agents. Each agent runs autonomously through OpenClaw's agent runtime — writing code, doing outreach, creating content, designing landing pages. Agent-to-agent coordination uses OpenClaw's ACP (Agent Client Protocol) for sub-agent spawning and task delegation.

**All agents run through OpenClaw.** Agent configs, model routing, skill loading, sub-agent spawning, and auth are all managed by the OpenClaw gateway (`openclaw.json`). No direct CLI calls — everything goes through the framework.

**Tasks are GitHub Issues.** The Champion creates issues, assigns them via labels, and a sync daemon polls GitHub every 30s to update the Kanban board. Agents close issues with proof-of-work comments.

**Economic accountability.** Inspired by [ClawWork](https://github.com/HKUDS/ClawWork), every agent action has a tracked cost. Per-agent token costs, revenue, and survival tiers are logged in append-only JSONL files for full auditability.

## Built On

| Framework | Role | Integration |
|-----------|------|-------------|
| [**OpenClaw**](https://github.com/openclaw/openclaw) | Agent gateway, model routing, auth, sub-agent spawning, skills | `openclaw.json` — all 6 agents defined as OpenClaw agents with model config, skills, and ACP sub-agent rules |
| [**OpenAI Symphony**](https://github.com/openai/symphony) | Task lifecycle orchestration | `symphony/` — Kanban board (INBOX → IN_PROGRESS → DONE), proof-of-work protocol, GitHub Issues sync |
| [**ClawWork**](https://github.com/HKUDS/ClawWork) | Economic accountability | `economy/cost_tracker.py` — per-agent cost tracking, survival tiers, JSONL event sourcing |
| [**Agency Agents**](https://github.com/msitarzewski/agency-agents) | Specialist skill patterns | `skills/` — OpenClaw SKILL.md format skills (14 skills across agents) |

**Mission Control** is the custom real-time dashboard (Express + WebSocket) for monitoring agents, tasks, and financials.

## Architecture

```
                    ┌───────────────────────────────┐
                    │       Mission Control          │
                    │  Dashboard · Task Board · API  │
                    │          (:4200)               │
                    └──────────────┬────────────────┘
                                   │
                    ┌──────────────▼────────────────┐
                    │      OpenClaw Gateway          │
                    │  Agent runtime · Model routing  │
                    │  ACP sub-agents · Skills        │
                    │  Auth (API keys or CLI OAuth)   │
                    │         (:18789)               │
                    └──────────────┬────────────────┘
                                   │
                      ┌────────────▼────────────┐
                      │    Duke (Champion)       │
                      │ Strategy · Revenue · Del │
                      └──┬───┬───┬───┬───┬──────┘
                         │   │   │   │   │
            ┌────────────┘   │   │   │   └────────────┐
            │          ┌─────┘   │   └─────┐          │
            ▼          ▼         ▼         ▼          ▼
      ┌──────────┐┌────────┐┌────────┐┌─────────┐┌─────────┐
      │Hackerman ││ Borat  ││ T-800  ││ Draper  ││ Picasso │
      │Tech Lead ││Dealer  ││  Ops   ││ Content ││ Design  │
      │Codex/OAI ││Anthro  ││Anthro  ││Anthro   ││Anthro   │
      └────┬─────┘└───┬────┘└───┬────┘└────┬────┘└────┬────┘
           │          │         │          │          │
        Workers    Workers   Workers    Workers    Workers
        (ACP)      (ACP)     (ACP)      (ACP)      (ACP)

      ┌─────────────────────────────────────────────────────┐
      │  Symphony Tasks · ClawWork Economy · GitHub Sync    │
      │  Daily Summaries · Memory Layer · JSONL Audit Log   │
      └─────────────────────────────────────────────────────┘
```

## Agents

All agents are defined in `openclaw.json` and run through the OpenClaw gateway:

| Role | Name | Model | Skills |
|------|------|-------|--------|
| Champion | Duke | `anthropic/claude-opus-4-6` | strategic-plan, delegate, revenue-scan, idea-framework |
| Tech Lead | Hackerman | `openai/gpt-5.3-codex` | coding-agent, code-and-ship, rapid-prototyper |
| Dealmaker | Borat | `anthropic/claude-opus-4-6` | market-analysis, outreach, growth-hacking |
| Ops | T-800 | `anthropic/claude-opus-4-6` | finance-tracker, analytics-reporter |
| Content | Don Draper | `anthropic/claude-opus-4-6` | content-creation, growth-hacking |
| Designer | Picasso | `anthropic/claude-opus-4-6` | code-and-ship, rapid-prototyper |

Models and skills are configurable in `openclaw.json`. The Champion spawns other agents as sub-agents via OpenClaw's ACP protocol.

## Configuration

```bash
cp .env.example .env
```

### Auth (pick one approach per provider)

**Option A: API Keys** (recommended)

```env
ANTHROPIC_API_KEY=sk-ant-...    # From console.anthropic.com
OPENAI_API_KEY=sk-...           # From platform.openai.com
```

**Option B: CLI Subscriptions**

Mount your CLI auth directories into the container. OpenClaw auto-detects CLI auth when API keys are not set.

```bash
# run.sh already mounts these:
-v ~/.claude:/root/.claude:ro
-v ~/.codex:/root/.codex:ro
```

### Models

Edit `openclaw.json` to change which models power each agent:

```json
{
  "agents": {
    "list": [
      {
        "id": "duke",
        "model": "anthropic/claude-opus-4-6"
      },
      {
        "id": "hackerman",
        "model": {
          "primary": "openai/gpt-5.3-codex",
          "fallbacks": ["anthropic/claude-opus-4-6"]
        }
      }
    ]
  }
}
```

OpenClaw supports 25+ model providers — see [OpenClaw model docs](https://docs.openclaw.ai/concepts/models).

### GitHub Integration

| Variable | Description |
|----------|-------------|
| `GITHUB_REPO` | `owner/repo` — enables GitHub Issues as task tracker |
| `GITHUB_TOKEN` | PAT with repo scope |
| `GITHUB_SYNC_INTERVAL` | Poll interval in seconds (default: 30) |

### Other

| Variable | Description |
|----------|-------------|
| `DASHBOARD_PORT` | Mission Control port (default: 4200) |
| `OPENCLAW_GATEWAY_PORT` | OpenClaw gateway port (default: 18789) |
| `DAILY_BUDGET_LIMIT` | Max daily spend on external services |
| `CLOUDFLARE_API_TOKEN` | For Cloudflare Pages deployment |

See `.env.example` for all options.

## Project Structure

```
zhc/
├── openclaw.json           # OpenClaw config — agents, models, skills, gateway
├── Dockerfile              # Single container (Node 22 + Python + OpenClaw)
├── entrypoint.sh           # Process manager
├── run.sh                  # Convenience launcher
├── docker-compose.yml      # Alternative to run.sh
│
├── dashboard/              # Mission Control
│   ├── server.js           # Express + WebSocket server
│   ├── index.html          # Main dashboard
│   └── tasks.html          # Kanban task board
│
├── agents/                 # Agent system prompts + per-agent skills
│   ├── ceo/                # Duke — strategy & delegation
│   ├── cto/                # Hackerman — code & deploy
│   ├── bizdev/             # Borat — market & outreach
│   ├── ops/                # T-800 — monitoring & reports
│   ├── content/            # Don Draper — copy & social
│   └── designer/           # Picasso — UI & branding
│
├── skills/                 # OpenClaw SKILL.md format skills
│   ├── code-and-ship/      # Cloudflare-first deployment
│   ├── rapid-prototyper/   # MVP speed builds
│   ├── growth-hacking/     # Channels & experiments
│   ├── finance-tracker/    # Revenue/cost logging
│   └── ...                 # 14 skills total
│
├── symphony/               # Task management (Symphony pattern)
│   ├── github-sync.py      # GitHub Issues ↔ board.json
│   ├── task-manager.py     # Task CRUD
│   └── board.json          # Live task state
│
├── economy/                # Financial tracking (ClawWork pattern)
│   ├── cost_tracker.py     # Per-agent cost tracking, survival tiers
│   ├── tracker.py          # Hourly P&L reports
│   ├── budget.json         # Budget constraints
│   └── reports/            # Auto-generated reports
│
├── gateway/                # Legacy gateway config (migrated to openclaw.json)
│
└── memory/                 # Persistent state (Markdown)
    ├── company-state.md
    ├── revenue-log.md
    ├── decisions.md
    └── learnings.md
```

## Volume Mounts

| Mount | Purpose | Mode |
|-------|---------|------|
| `./memory` | Agent state, decisions, learnings | rw |
| `./economy` | Budget, P&L, cost tracking | rw |
| `./symphony` | Task board, daily summaries | rw |
| `~/.claude` | Claude CLI auth | ro |
| `~/.codex` | Codex CLI auth | ro |
| `~/.openclaw` | OpenClaw state | rw |

## Deploy

```bash
docker build -t zhc .

# Fly.io, Railway, any VPS, etc.
docker run -d -p 4200:4200 -p 18789:18789 \
  -v $(pwd)/memory:/zhc/memory \
  -v $(pwd)/economy:/zhc/economy \
  -v $(pwd)/symphony:/zhc/symphony \
  -v ~/.claude:/root/.claude:ro \
  -v ~/.codex:/root/.codex:ro \
  -v ~/.openclaw:/root/.openclaw \
  --env-file .env --name zhc zhc
```

## Credits

- [**OpenClaw**](https://github.com/openclaw/openclaw) — Agent gateway, runtime, and orchestration framework
- [**OpenAI Symphony**](https://github.com/openai/symphony) — Task lifecycle and autonomous work management patterns
- [**ClawWork**](https://github.com/HKUDS/ClawWork) (HKUDS) — Economic accountability and survival tier framework
- [**Agency Agents**](https://github.com/msitarzewski/agency-agents) — Specialist agent skill patterns
