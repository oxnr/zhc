# Skill: Daily Summary & Human Intervention Manager

## Purpose
Generate daily summaries and manage the human intervention queue.

## Daily Summary (run at end of each day or on demand)

### What to Include
1. **Revenue summary**: Total earned today, by product/source
2. **Cost summary**: Total spent today, by category
3. **Net P&L**: Are we profitable today?
4. **Tasks completed**: What got done
5. **Tasks in progress**: What's being worked on
6. **Decisions made**: Key strategic choices by CEO
7. **Learnings**: What the company learned
8. **Intervention queue**: What needs human help

### Where to Publish
1. Save to `symphony/summaries/summary-YYYY-MM-DD.md`
2. Display on dashboard (push to Mission Control)
3. Email to onr (if SMTP configured in .env)

### How to Generate
Run: `python3 symphony/daily-summary.py`

## Intervention Queue Management

### When to Create an Intervention Request
Agents should request human intervention when:
- API keys or credentials are needed (e.g., X/Twitter API, Stripe setup)
- Account creation is required on external services
- Budget approval needed for spend > daily limit
- A strategic pivot needs human sign-off
- Legal/compliance questions arise
- An agent is stuck after 3 retry attempts

### Format
Write to `memory/intervention-queue.md`:
```
- [OPEN] HIGH | Need X/Twitter API key to enable social outreach | Scout (BizDev) | 2026-03-06T15:00:00Z
```

### Priority Levels
- **CRITICAL**: Company is blocked, no revenue can be generated
- **HIGH**: An agent is blocked on a specific task
- **MEDIUM**: Would improve operations but not blocking
- **LOW**: Nice to have, can wait

### Resolution
When human resolves an item, agents should update:
```
- [RESOLVED] HIGH | X/Twitter API key provided | Scout (BizDev) | 2026-03-06T15:00:00Z → resolved 2026-03-06T16:30:00Z
```

## Operating Philosophy
The human (onr) wants to intervene ONLY when necessary. The system should:
- Self-heal whenever possible
- Route around blocked paths (if X API unavailable, use a different channel)
- Queue non-urgent interventions for the daily summary
- Only ping for CRITICAL items that block all revenue
