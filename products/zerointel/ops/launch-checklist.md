# ZeroIntel Launch Readiness Checklist

Last updated: 2026-03-06 14:25 UTC

## Product

- [ ] Landing page deployed and accessible (Cloudflare Pages)
- [ ] Landing page loads in <3s
- [ ] No fake social proof stats on page (see ZER-20)
- [ ] All CTA links point to correct Gumroad products
- [ ] Mobile responsive confirmed

## Payments

- [ ] Gumroad products created for all 3 tiers ($49/$99/$249)
- [ ] Test purchase completes successfully
- [ ] Receipt/delivery email configured
- [ ] Stripe fees tracked in cost model (2.9% + $0.30/tx)

## Report Generation

- [ ] generate-report.js runs without errors
- [ ] Sample report output is accurate and complete
- [ ] Report delivery mechanism tested (email or download)
- [ ] Report formatting matches design spec

## Copy & Design

- [ ] Landing page copy finalized (ZER-15 — DonDraper)
- [ ] Design assets integrated (ZER-3 — Picasso)
- [ ] Email templates ready
- [ ] Gumroad product descriptions written

## Outreach

- [ ] Target communities identified (ZER-8 — done)
- [ ] Outreach templates ready (ZER-17 — Borat)
- [ ] First 10 prospects identified
- [ ] Launch posts drafted

## Operations

- [ ] Cost tracking initialized (economy/)
- [ ] Monitoring config in place
- [ ] P&L reporting ready
- [ ] Budget alerts configured ($100/day limit)

## Blockers

| Blocker | Owner | Status |
|---------|-------|--------|
| ZER-2 blocked — landing page build | Hackerman | blocked |
| ZER-20 — remove fake social proof | Hackerman | todo |
| ZER-3 — design not started | Picasso | todo |
