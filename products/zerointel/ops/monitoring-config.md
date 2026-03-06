# ZeroIntel Monitoring Configuration

## Agent Health Monitoring

Check via Paperclip API: `GET /api/companies/{companyId}/agents`

### Agent Status Expectations

| Agent | Expected | Action if Down |
|-------|----------|----------------|
| Hackerman | running | Alert CEO — blocks all builds |
| DonDraper | running | Alert CEO — blocks copy delivery |
| Picasso | running | Alert CEO — blocks design delivery |
| Borat | running | Alert CEO — blocks outreach |
| Duke (CEO) | running | Board alert — top priority |

### Health Check Rules
- Agent `status != running` for >5 min with active tasks = alert
- Agent fails 3 heartbeats in a row = stop restart, escalate to CEO
- `lastHeartbeatAt` >10 min stale = investigate

## Task Progress Monitoring

Check via Paperclip API: `GET /api/companies/{companyId}/issues?status=in_progress,blocked`

### Stall Detection
- Task `in_progress` with no comment in >30 min = flag
- Task `blocked` with no resolution in >1 hour = escalate
- Task `todo` assigned but not started in >1 hour = ping assignee

## Cost Monitoring

### Budget Thresholds (from budget.json)
- Warning: 80% of $100/day = $80
- Critical: 95% of $100/day = $95
- Hard stop: 100% = $100

### Fixed Daily Costs
- Claude Max: $6.67/day
- ChatGPT Pro: $6.67/day
- Total fixed: $13.33/day

### Variable Cost Categories
- Hosting (Cloudflare): $20/day max
- Services (APIs, Stripe): $30/day max
- Marketing: $30/day max
- Reserve: $20/day max

### Stripe Fee Tracking
- Per transaction: 2.9% + $0.30
- On $49 sale: $1.72 fee, $47.28 net
- On $99 sale: $3.17 fee, $95.83 net
- On $249 sale: $7.52 fee, $241.48 net

## Deployment Monitoring

### Landing Page
- URL: TBD (Cloudflare Pages deployment pending)
- Check: HTTP 200 + page loads within 3s
- Frequency: Every 5 min post-launch

### Gumroad Products
- Starter ($49): TBD
- Pro ($99): TBD
- Enterprise ($249): TBD
- Check: Product pages accessible, purchase flow works

## Alerting

### Priority Levels
1. **Critical**: Revenue loss, service down, agent crash loop
2. **High**: Blocked tasks, budget exceeded, stale work
3. **Medium**: Agent idle, minor degradation
4. **Low**: Informational, optimization opportunities

### Escalation Path
T-800 -> Duke (CEO) -> Board
