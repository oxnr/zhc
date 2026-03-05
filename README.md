# Zero Human Corp

> Fully autonomous AI company in a single Docker container.
> Claude Opus 4.6 for strategy & reasoning. Codex 5.3 for coding.
> Both on flat-rate subscriptions — no API burn.

![Mission Control Dashboard](docs/dashboard.png)

## Architecture

```
┌──────────────────────────────────────────────┐
│              SINGLE DOCKER CONTAINER          │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │         MISSION CONTROL (:4200)         │  │
│  │   Dashboard + Task Board + WebSocket    │  │
│  └────────────────┬────────────────────────┘  │
│                   │                           │
│  ┌────────────────▼────────────────────────┐  │
│  │        CEO — Duke 👑 (Opus 4.6)         │  │
│  │   Strategy · Revenue · Delegation       │  │
│  └────────────────┬────────────────────────┘  │
│          ┌────────┼────────┐                  │
│  ┌───────▼──┐ ┌───▼────┐ ┌▼─────────┐        │
│  │Hackerman │ │ Borat  │ │  T-800   │        │
│  │💻 CTO    │ │👍 Biz  │ │🤖 Ops    │        │
│  │Codex 5.3 │ │Opus 4.6│ │Opus 4.6  │        │
│  └──────────┘ └────────┘ └──────────┘        │
│                                               │
│  ┌─────────────────────────────────────────┐  │
│  │  GitHub Sync · Economy Tracker · Daily  │  │
│  │  Summaries · All state in mounted vols  │  │
│  └─────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone
git clone https://github.com/onr/zero-human-corp.git
cd zero-human-corp

# 2. Build
docker build -t zhc .

# 3. Run
./run.sh
# Or manually:
docker run -d -p 4200:4200 \
  -v $(pwd)/memory:/zhc/memory \
  -v $(pwd)/economy:/zhc/economy \
  -v $(pwd)/symphony:/zhc/symphony \
  -v ~/.claude:/root/.claude:ro \
  -v ~/.codex:/root/.codex:ro \
  --name zhc zhc
```

- Dashboard: http://localhost:4200
- Task Board: http://localhost:4200/tasks
- API: http://localhost:4200/api/state

## How It Works

**Tasks are GitHub Issues.** The CEO agent creates issues, assigns them to agents via labels, and the sync daemon polls GitHub every 30s to update the dashboard. When agents finish work, issues get closed with proof-of-work comments.

**Git is the documentation backbone.** All commits, PRs, and issue activity feed into daily summaries generated automatically.

**Everything runs in one container.** Dashboard (Node.js), economy tracker (Python), GitHub sync daemon, and the CEO agent — all managed by a bash entrypoint. Dashboard is the critical process; if it dies, the container restarts. Other processes can fail gracefully.

## Configuration

```bash
cp .env.example .env
# Edit .env:
```

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_REPO` | For task tracking | `owner/repo` — enables GitHub Issues as tasks |
| `GITHUB_TOKEN` | For task tracking | PAT with repo scope |
| Claude auth | For agents | Mount `~/.claude` into container (read-only) |
| Codex auth | For CTO agent | Mount `~/.codex` into container (read-only) |

## Agents

| Agent | Name | Model | Role |
|-------|------|-------|------|
| CEO | Duke 👑 | Opus 4.6 | Strategy, revenue discovery, delegation |
| CTO | Hackerman 💻 | Codex 5.3 | Code generation, debugging, deployment |
| BizDev | Borat 👍 | Opus 4.6 | Market research, outreach, deal closing |
| Ops | T-800 🤖 | Opus 4.6 | Monitoring, cost tracking, daily summaries |

## Project Structure

```
zero-human-corp/
├── Dockerfile              # Single container — everything
├── entrypoint.sh           # Process manager
├── run.sh                  # Convenience launcher
├── start-ceo.sh            # CEO agent boot
├── docker-compose.yml      # Alternative to run.sh
│
├── dashboard/              # Mission Control + Task Board
│   ├── server.js           # Express + WebSocket server
│   ├── index.html          # Main dashboard
│   └── tasks.html          # Kanban task board
│
├── agents/                 # Agent configs + system prompts
│   ├── ceo/                # Duke — strategy & delegation
│   ├── cto/                # Hackerman — code & deploy
│   ├── bizdev/             # Borat — market & outreach
│   └── ops/                # T-800 — monitoring & reports
│
├── symphony/               # Task management
│   ├── github-sync.py      # GitHub Issues ↔ board.json sync
│   ├── task-manager.py     # Task CRUD (GitHub or local)
│   ├── daily-summary.py    # Git + GitHub + board summaries
│   └── board.json          # Live task board state
│
├── economy/                # Financial tracking
│   ├── tracker.py          # Revenue/cost tracker
│   ├── budget.json         # Budget constraints
│   └── reports/            # Auto-generated P&L
│
└── memory/                 # Persistent state (Markdown)
    ├── company-state.md    # Current company status
    ├── revenue-log.md      # All revenue transactions
    ├── decisions.md        # Decision history
    └── learnings.md        # What the company learned
```

## Volume Mounts

| Mount | Purpose | Mode |
|-------|---------|------|
| `./memory` | Agent state, decisions, learnings | rw |
| `./economy` | Budget, P&L reports | rw |
| `./symphony` | Task board, daily summaries | rw |
| `~/.claude` | Claude CLI auth | ro |
| `~/.codex` | Codex CLI auth | ro |

## The Subscription Strategy

No API keys. Both models run on unlimited subscription plans:

| Model | Plan | Cost | Agents |
|-------|------|------|--------|
| Claude Opus 4.6 | Claude Max | $200/mo | CEO, BizDev, Ops |
| GPT-5.3 Codex | ChatGPT Pro | $200/mo | CTO, coding workers |

Auth is mounted from the host machine's CLI config directories.

## Deploy

The Docker image runs anywhere:

```bash
# Build once
docker build -t zhc .

# Run anywhere that supports Docker
# Fly.io, Railway, any VPS, etc.
```

## Inspired By

- [OpenAI Symphony](https://github.com/openai/symphony) — Task lifecycle, autonomous work management
- [Agency Agents](https://github.com/msitarzewski/agency-agents) — Specialist agent skills
