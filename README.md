<p align="center">
  <h1 align="center">ZHC - Zero Human Corp</h1>
</p>
<p align="center">
  Autonomous AI company in a single Docker container.<br>
  Agents strategize, build, sell, and ship — you watch the dashboard.
</p>
<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="License"></a>
  <a href="https://www.docker.com/"><img src="https://img.shields.io/badge/docker-ready-2496ED?style=for-the-badge" alt="Docker"></a>
</p>

![Mission Control Dashboard](docs/dashboard.png)

## Quick Start

```bash
git clone https://github.com/oxnr/zhc.git
cd zhc
cp .env.example .env     # configure models, keys, etc.
docker build -t zhc .
./run.sh
```

- **Dashboard**: http://localhost:4200
- **Task Board**: http://localhost:4200/tasks
- **API**: http://localhost:4200/api/state

## How It Works

A Champion agent (Duke) boots up, plans a revenue strategy, and delegates work to specialist agents. Each agent runs autonomously — writing code, doing outreach, creating content, designing landing pages. All coordination happens through GitHub Issues and a shared memory layer.

**Tasks are GitHub Issues.** The Champion creates issues, assigns them via labels, and a sync daemon polls GitHub every 30s to update the Kanban board. Agents close issues with proof-of-work comments.

**Git is the backbone.** Commits, PRs, and issue activity feed into auto-generated daily summaries.

**One container runs everything.** Mission Control dashboard, economy tracker, GitHub sync, and agents — managed by a bash entrypoint. The dashboard is the critical process; others can fail gracefully.

## Built On

ZHC combines three open-source frameworks into a single autonomous system:

| Framework | Role in ZHC | Integration |
|-----------|-------------|-------------|
| [**OpenClaw**](https://openclaw.ai) | Agent gateway & model routing | `gateway/gateway.json` — routes tasks to the right model based on agent role, manages spawn rules and session lifecycle |
| [**OpenAI Symphony**](https://github.com/openai/symphony) | Task lifecycle orchestration | `symphony/` — task board with states (INBOX → ASSIGNED → IN_PROGRESS → IN_REVIEW → DONE), proof-of-work protocol |
| [**Agency Agents**](https://github.com/msitarzewski/agency-agents) | Specialist skill patterns | `skills/` — reusable skill files (rapid prototyper, growth hacking, finance tracker, analytics reporter, etc.) |

**Mission Control** is the custom real-time dashboard (Express + WebSocket) that watches all file changes and pushes live updates to the browser.

## Architecture

```
                        ┌─────────────────────────┐
                        │     Mission Control      │
                        │   Dashboard · API · WS   │
                        │       (:4200)            │
                        └────────────┬────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │        OpenClaw Gateway         │
                    │  Model routing · Spawn rules    │
                    │  gateway/gateway.json            │
                    └────────────────┬────────────────┘
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
        │Code+Ship ││Sales   ││Monitor ││Copy+SEO ││UI+Brand │
        └────┬─────┘└───┬────┘└───┬────┘└────┬────┘└────┬────┘
             │          │         │          │          │
          Workers    Workers   Workers    Workers    Workers
          (up to 5)  (up to 5) (up to 5) (up to 5) (up to 5)

        ┌─────────────────────────────────────────────────────┐
        │  Symphony Task Board · Economy Tracker · GitHub     │
        │  Sync Daemon · Daily Summaries · Memory Layer       │
        └─────────────────────────────────────────────────────┘
```

## Agents

| Role | Name | Description |
|------|------|-------------|
| Champion | Duke | Strategy, revenue discovery, delegation |
| Tech Lead | Hackerman | Code generation, builds, deployment |
| Dealmaker | Borat | Market research, outreach, deal closing |
| Ops | T-800 | Monitoring, cost tracking, summaries |
| Content | Don Draper | Copy, blog, social media, SEO |
| Designer | Picasso | UI/UX, landing pages, branding |

Each agent has its own system prompt, skills, and tool access defined in `agents/<role>/`. The Champion delegates to leads, and each lead can spawn up to 5 worker agents. Model routing is handled by the OpenClaw gateway — configure which models power which roles in `gateway/gateway.json`.

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

### Models

ZHC is model-agnostic. Configure which models and CLI tools your agents use:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CODE_PATH` | `claude` | CLI binary for reasoning agents |
| `CLAUDE_MODEL` | `claude-opus-4-6` | Model for strategy/reasoning |
| `CODEX_CLI_PATH` | `codex` | CLI binary for coding agents |
| `CODEX_MODEL` | `gpt-5.3-codex` | Model for code generation |

Model routing rules live in `gateway/gateway.json`. Auth is handled by mounting your CLI config directories into the container — whatever auth method your CLIs use (API keys, OAuth, subscriptions) works transparently.

### GitHub Integration

| Variable | Description |
|----------|-------------|
| `GITHUB_REPO` | `owner/repo` — enables GitHub Issues as task tracker |
| `GITHUB_TOKEN` | PAT with repo scope (used by `gh` CLI) |
| `GITHUB_SYNC_INTERVAL` | Seconds between polls (default: 30) |

### Other

| Variable | Description |
|----------|-------------|
| `DASHBOARD_PORT` | Dashboard port (default: 4200) |
| `DAILY_BUDGET_LIMIT` | Max daily spend on external services |
| `CEO_HEARTBEAT_INTERVAL` | Seconds between Champion check-ins (default: 300) |
| `CLOUDFLARE_API_TOKEN` | For deploying to Cloudflare Pages |

See `.env.example` for all options.

## Project Structure

```
zhc/
├── Dockerfile              # Single container
├── entrypoint.sh           # Process manager
├── run.sh                  # Convenience launcher
├── docker-compose.yml      # Alternative to run.sh
│
├── gateway/                # OpenClaw gateway config
│   └── gateway.json        # Model routing, agent spawn rules
│
├── dashboard/              # Mission Control
│   ├── server.js           # Express + WebSocket server
│   ├── index.html          # Main dashboard
│   └── tasks.html          # Kanban task board
│
├── agents/                 # Agent configs + system prompts
│   ├── ceo/                # Duke — strategy & delegation
│   ├── cto/                # Hackerman — code & deploy
│   ├── bizdev/             # Borat — market & outreach
│   ├── ops/                # T-800 — monitoring & reports
│   ├── content/            # Don Draper — copy & social
│   └── designer/           # Picasso — UI & branding
│
├── skills/                 # Shared skill files (Agency Agents pattern)
│   ├── rapid-prototyper.md
│   ├── growth-hacking.md
│   ├── finance-tracker.md
│   └── ...
│
├── symphony/               # Task management (Symphony pattern)
│   ├── github-sync.py      # GitHub Issues ↔ board.json
│   ├── task-manager.py     # Task CRUD (GitHub or local)
│   ├── daily-summary.py    # Auto daily summaries
│   └── board.json          # Live task state
│
├── economy/                # Financial tracking
│   ├── tracker.py          # Revenue/cost tracker
│   ├── budget.json         # Budget constraints
│   └── reports/            # Auto-generated P&L
│
└── memory/                 # Persistent state (Markdown)
    ├── company-state.md    # Current status
    ├── revenue-log.md      # All transactions
    ├── decisions.md        # Decision history
    └── learnings.md        # What the company learned
```

## Volume Mounts

| Mount | Purpose | Mode |
|-------|---------|------|
| `./memory` | Agent state, decisions, learnings | rw |
| `./economy` | Budget, P&L reports | rw |
| `./symphony` | Task board, daily summaries | rw |
| `~/.claude` | CLI auth (reasoning agents) | ro |
| `~/.codex` | CLI auth (coding agents) | ro |

## Deploy

The Docker image runs anywhere:

```bash
docker build -t zhc .

# Fly.io, Railway, any VPS, etc.
docker run -d -p 4200:4200 \
  -v $(pwd)/memory:/zhc/memory \
  -v $(pwd)/economy:/zhc/economy \
  -v $(pwd)/symphony:/zhc/symphony \
  -v ~/.claude:/root/.claude:ro \
  -v ~/.codex:/root/.codex:ro \
  --env-file .env --name zhc zhc
```
