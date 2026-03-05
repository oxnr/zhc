# Symphony Integration — Task Board & Autonomous Work Management

> Inspired by [OpenAI Symphony](https://github.com/openai/symphony)
> Adapted for Zero Human Corp's multi-agent architecture

## Concept

Symphony transforms project tasks into isolated, autonomous implementation runs.
Instead of supervising agents, the CEO **manages work** and agents deliver **proof of work**.

## How It Works in Zero Human Corp

### 1. Task Board (In-Memory + File-Based)

Tasks live in `symphony/board.json` and are visualized in the dashboard.

```
INBOX → BACKLOG → ASSIGNED → IN_PROGRESS → IN_REVIEW → DONE → ARCHIVED
```

### 2. Task Lifecycle

```
CEO creates task
    → Task enters INBOX
    → CEO assigns to lead agent (CTO/BizDev/Ops)
    → Lead agent moves to IN_PROGRESS
    → Lead spawns workers if needed
    → Workers complete sub-tasks
    → Lead moves to IN_REVIEW with proof of work
    → CEO reviews proof of work
    → CEO moves to DONE or sends back
```

### 3. Proof of Work

Every completed task MUST include:
- **Deliverable**: What was produced (URL, file, report)
- **Evidence**: Screenshots, test results, revenue data
- **Metrics**: Time taken, cost, quality score
- **Next steps**: Any follow-up needed

### 4. Task Schema

```json
{
  "id": "task-001",
  "title": "Build landing page for NicheNewsletter.ai",
  "description": "Create a conversion-optimized landing page...",
  "status": "IN_PROGRESS",
  "priority": "critical",
  "assignee": "cto",
  "createdBy": "ceo",
  "createdAt": "2026-03-06T10:00:00Z",
  "deadline": "2026-03-06T14:00:00Z",
  "budget": 5.00,
  "tags": ["product", "mvp", "revenue"],
  "subtasks": [
    { "id": "sub-001", "title": "Design layout", "assignee": "coding-worker-1", "status": "DONE" },
    { "id": "sub-002", "title": "Implement Stripe", "assignee": "coding-worker-2", "status": "IN_PROGRESS" }
  ],
  "proofOfWork": null
}
```

## Integration Points

- **CEO heartbeat**: Scans board every 5 min, reassigns stalled tasks
- **Dashboard**: Real-time board visualization at `/tasks`
- **Ops agent**: Monitors task SLAs and alerts on overdue items
- **Economic tracker**: Links task costs to budget categories
