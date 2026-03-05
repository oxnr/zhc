# Decisions You Need to Make — Zero Human Corp

> Answer these BEFORE the hackathon. Each one unblocks a critical path.

---

## TIER 1: BLOCKING (Must answer before launch)

### 1. Subscriptions — Are you set up?
- [ ] **Claude Max** ($100 or $200/mo) — needed for Opus 4.6 via Claude Code CLI
  - $100/mo = standard limits, $200/mo = 2x limits
  - Which plan are you on? The $200 gives more headroom for a 24hr hackathon
- [ ] **ChatGPT Pro** ($200/mo) — needed for Codex 5.3 via Codex CLI
  - Confirm: do you have ChatGPT Pro (not Plus)? Pro is $200/mo with 10x limits

### 2. Rate Limits — How aggressive?
The CEO heartbeats every 5 minutes. Each heartbeat = 1 Opus call. That's ~288 calls/day JUST for heartbeats, not counting actual work.

**Decision needed:** What's your Opus 4.6 daily message limit?
- If ~100 messages/day → set heartbeat to 30min, be very conservative
- If ~500 messages/day → 10min heartbeat, moderate delegation
- If unlimited/high → 5min heartbeat, full autonomy

Same question for Codex 5.3. CTO will generate a LOT of code.

### 3. GitHub Token
- [ ] Create a GitHub Personal Access Token (classic) with `repo` scope
  - The CTO agent will create repos for each product it builds
  - Go to: https://github.com/settings/tokens/new
  - Set to `GITHUB_TOKEN` in .env

### 4. Stripe Account
- [ ] Do you have a Stripe account?
  - Needed to accept payments from products the company builds
  - If not: https://dashboard.stripe.com/register
  - Set `STRIPE_SECRET_KEY` in .env (starts with `sk_live_` or `sk_test_`)
  - **Start with test mode** (`sk_test_`) to validate the flow, switch to live when ready

### 5. Vercel Account
- [ ] Do you have a Vercel account?
  - Free tier is enough to start — the CTO deploys all products here
  - If not: https://vercel.com/signup
  - Get a Vercel token: https://vercel.com/account/tokens
  - Set `VERCEL_TOKEN` in .env

---

## TIER 2: IMPORTANT (Answer within first hour)

### 6. What's the Starting Capital?
Current setting: $0. The company must earn everything.
- **Option A**: $0 — pure bootstrap, CEO must find zero-cost revenue streams first
- **Option B**: $50 — give it a small budget for domains, tools, initial ads
- **Option C**: $200 — comfortable budget to experiment with paid channels
- Set `STARTING_CAPITAL` and `DAILY_BUDGET_LIMIT` in .env

### 7. Messaging Channel
How do you want to interact with the agents during the hackathon?
- **Terminal only** (default) — watch logs, read memory files
- **Slack** — get pings from agents, reply in Slack
  - Need: Slack workspace + bot token (https://api.slack.com/apps)
- **Discord** — same but Discord
  - Need: Discord server + bot token (https://discord.com/developers)

### 8. Domain for Products
If the company builds a SaaS tool and needs a domain:
- **Option A**: Use Vercel subdomains (free: `yourapp.vercel.app`) — recommended for hackathon
- **Option B**: Pre-buy a generic domain (like `zhcapps.com`) and use subdomains
  - Need: Cloudflare or Namecheap API key → `DOMAIN_API_KEY` in .env
- **Option C**: Let the CEO buy domains autonomously (requires budget + API key)

### 9. Email for Daily Summaries
If you want daily summaries emailed to you:
- Set `SUMMARY_EMAIL=your-email@example.com` in .env
- Set up SMTP (Gmail app password works): `SMTP_USER` + `SMTP_PASS`
- Or skip this and just check the dashboard

---

## TIER 3: STRATEGIC (Can evolve during hackathon)

### 10. Revenue Guardrails
Any hard rules for the CEO?
- **Industries to avoid?** (e.g., gambling, crypto, adult)
- **Tactics to avoid?** (e.g., no cold email spam, no buying ads)
- **Revenue floor?** (e.g., don't pursue anything that can't make $100/mo)
- **Ethical boundaries?** (e.g., no scraping people's data, no impersonation)

Current default: CEO has full autonomy within budget limits. Add rules to `agents/ceo/system-prompt.md` if you want guardrails.

### 11. Products: Build or Buy?
Should the CTO:
- **Build everything from scratch** (slower but fully owned)
- **Fork/adapt existing open source** (faster, possible licensing issues)
- **Mix** — fork for speed, rebuild for keepers

### 12. Hackathon Demo Goals
What do you want to SHOW at the hackathon?
- [ ] Live dashboard with agents working
- [ ] At least 1 product shipped and deployed
- [ ] Revenue > $0 (even $1 from a real customer)
- [ ] Full agent tree visualization
- [ ] Cost tracking and P&L
- [ ] Something else?

This determines how you allocate the CEO's first 2 hours.

### 13. Post-Hackathon Plans
This affects architecture decisions:
- **Hackathon-only demo** → optimize for showmanship, mock what you can't build
- **Keep running after** → invest in robustness, proper error handling, monitoring
- **Scale to multiple "companies"** → build the meta-layer now (company factory)

---

## Quick .env Checklist

```
CLAUDE_MODEL=claude-opus-4-6          ✅ Set
CODEX_MODEL=gpt-5.3-codex            ✅ Set
GITHUB_TOKEN=ghp_xxxxx               ❓ Need from you
STRIPE_SECRET_KEY=sk_test_xxxxx      ❓ Need from you
VERCEL_TOKEN=xxxxx                   ❓ Need from you
STARTING_CAPITAL=0                   ❓ Your call
DAILY_BUDGET_LIMIT=50                ❓ Your call
SUMMARY_EMAIL=your-email@example.com ❓ Confirm
CEO_HEARTBEAT_INTERVAL=300           ❓ Depends on rate limits
```
