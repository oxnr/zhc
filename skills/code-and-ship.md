# Skill: Code and Ship

## Purpose
Build and deploy software products as fast as possible.

## Default Tech Stack (Speed-Optimized)
- **Frontend**: Next.js 15 + Tailwind CSS
- **Backend**: Next.js API routes or Python FastAPI
- **Database**: Supabase (free tier) or SQLite
- **Payments**: Stripe Checkout (simplest integration)
- **Hosting**: Vercel (free tier for MVPs)
- **Domain**: Use Vercel subdomain initially, buy domain only after revenue

## Shipping Protocol
1. Create git repo with clear structure
2. Build MVP (minimum features to charge money)
3. Test locally
4. Deploy to Vercel
5. Verify deployment works
6. Set up Stripe payment link
7. Report live URL + payment URL to CEO

## Code Standards (MVP Level)
- Working > Beautiful
- Ship with basic error handling
- Include .env.example
- Include one-command deploy script
- No tests for MVP (add after validation)

## Speed Benchmarks
- Landing page: < 30 minutes
- Simple SaaS tool: < 2 hours
- API + frontend: < 3 hours
- Full product with payments: < 4 hours
