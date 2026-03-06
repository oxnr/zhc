#!/usr/bin/env node

/**
 * ZeroIntel Report Generator CLI
 *
 * Usage: node generate-report.js --company https://example.com --competitors https://comp1.com,https://comp2.com [--tier starter|pro|enterprise]
 *
 * Requires ANTHROPIC_API_KEY environment variable for AI-powered analysis.
 */

const https = require("https");
const http = require("http");
const { URL } = require("url");
const fs = require("fs");
const path = require("path");

// --- CLI arg parsing ---
const args = process.argv.slice(2);
function getArg(name) {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : null;
}

const companyUrl = getArg("company");
const competitorUrls = getArg("competitors")
  ? getArg("competitors").split(",").map((u) => u.trim())
  : [];
const tier = getArg("tier") || "starter";
const outputDir = getArg("output") || "./reports";

if (!companyUrl || competitorUrls.length === 0) {
  console.error(`
ZeroIntel Report Generator

Usage:
  node generate-report.js --company <url> --competitors <url1,url2,...> [--tier starter|pro|enterprise] [--output ./reports]

Example:
  node generate-report.js --company https://acme.com --competitors https://comp1.com,https://comp2.com --tier pro

Requires: ANTHROPIC_API_KEY environment variable
`);
  process.exit(1);
}

const maxCompetitors = { starter: 3, pro: 5, enterprise: 10 };
if (competitorUrls.length > (maxCompetitors[tier] || 3)) {
  console.error(
    `Error: ${tier} tier supports max ${maxCompetitors[tier]} competitors. Got ${competitorUrls.length}.`
  );
  process.exit(1);
}

const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
if (!ANTHROPIC_API_KEY) {
  console.error("Error: ANTHROPIC_API_KEY environment variable is required.");
  console.error("Set it with: export ANTHROPIC_API_KEY=sk-ant-...");
  process.exit(1);
}

// --- Web scraping ---
const SCRAPE_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Accept-Language": "en-US,en;q=0.9",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
};

function fetchPage(url, depth = 0) {
  if (depth > 5) return Promise.resolve("");
  return new Promise((resolve) => {
    const proto = url.startsWith("https") ? https : http;
    const req = proto.get(
      url,
      { headers: SCRAPE_HEADERS, timeout: 15000 },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          let redirectUrl = res.headers.location;
          if (redirectUrl.startsWith("/")) {
            const base = new URL(url);
            redirectUrl = `${base.protocol}//${base.host}${redirectUrl}`;
          }
          return fetchPage(redirectUrl, depth + 1).then(resolve);
        }
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => resolve(data));
      }
    );
    req.on("error", () => resolve(""));
    req.on("timeout", () => { req.destroy(); resolve(""); });
  });
}

function extractText(html) {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, "")
    .replace(/<style[\s\S]*?<\/style>/gi, "")
    .replace(/<nav[\s\S]*?<\/nav>/gi, "")
    .replace(/<footer[\s\S]*?<\/footer>/gi, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#?\w+;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function extractMeta(html) {
  const title = (html.match(/<title[^>]*>([\s\S]*?)<\/title>/i) || [])[1] || "";
  const desc = (html.match(/<meta[^>]*name=["']description["'][^>]*content=["']([^"']*)["']/i) || [])[1] || "";
  const h1s = (html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/gi) || [])
    .map((h) => h.replace(/<[^>]+>/g, "").trim()).filter(Boolean).slice(0, 5);
  const h2s = (html.match(/<h2[^>]*>([\s\S]*?)<\/h2>/gi) || [])
    .map((h) => h.replace(/<[^>]+>/g, "").trim()).filter(Boolean).slice(0, 10);
  return { title: title.trim(), description: desc, h1s, h2s };
}

// Build list of subpages to try: known common paths + any discovered from HTML links
function getSubpageUrls(html, baseUrl) {
  const base = new URL(baseUrl);
  const origin = `${base.protocol}//${base.host}`;
  const commonPaths = ["/pricing", "/features", "/about", "/products", "/solutions"];
  const paths = new Set(commonPaths);

  // Also discover from HTML links
  const links = html.match(/href=["']([^"']+)["']/gi) || [];
  const targetPaths = ["/pricing", "/features", "/about", "/products", "/solutions", "/plans"];
  for (const link of links) {
    const href = (link.match(/href=["']([^"']+)["']/i) || [])[1];
    if (!href) continue;
    try {
      const resolved = new URL(href, baseUrl);
      if (resolved.hostname !== base.hostname) continue;
      const p = resolved.pathname.toLowerCase().replace(/\/$/, "");
      if (targetPaths.some((t) => p === t || p.startsWith(t + "/"))) {
        paths.add(resolved.pathname);
      }
    } catch {}
  }

  return [...paths].slice(0, 5).map((p) => origin + p);
}

// Scrape a site: homepage + key subpages
async function scrapeSite(url) {
  const domain = new URL(url).hostname;
  console.log(`  Fetching homepage: ${url}`);
  const homepageHtml = await fetchPage(url);
  const homepageText = extractText(homepageHtml);
  const meta = extractMeta(homepageHtml);

  const subpages = getSubpageUrls(homepageHtml, url);
  const pages = [{ path: "/", text: homepageText.slice(0, 6000) }];

  for (const subUrl of subpages) {
    const pagePath = new URL(subUrl).pathname;
    console.log(`  Fetching subpage: ${pagePath}`);
    const html = await fetchPage(subUrl);
    const text = extractText(html);
    if (text.length > 100) {
      pages.push({ path: pagePath, text: text.slice(0, 4000) });
    }
  }

  console.log(`  -> ${meta.title || "No title"} | ${pages.length} pages scraped | ${pages.reduce((s, p) => s + p.text.length, 0)} chars total`);

  return { domain, url, meta, pages };
}

// --- Claude API ---
function callClaude(prompt, systemPrompt) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      model: "claude-sonnet-4-5-20250514",
      max_tokens: 8000,
      system: systemPrompt,
      messages: [{ role: "user", content: prompt }],
    });

    const req = https.request(
      {
        hostname: "api.anthropic.com",
        path: "/v1/messages",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
          "Content-Length": Buffer.byteLength(body),
        },
        timeout: 120000,
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            const parsed = JSON.parse(data);
            if (parsed.error) {
              reject(new Error(`Claude API error: ${parsed.error.message}`));
              return;
            }
            const text = parsed.content
              ?.filter((b) => b.type === "text")
              .map((b) => b.text)
              .join("\n");
            resolve(text || "");
          } catch (e) {
            reject(new Error(`Failed to parse Claude response: ${e.message}`));
          }
        });
      }
    );
    req.on("error", reject);
    req.on("timeout", () => { req.destroy(); reject(new Error("Claude API timeout")); });
    req.write(body);
    req.end();
  });
}

// --- Build analysis prompt ---
function buildAnalysisPrompt(companyData, competitorData) {
  let prompt = `## Company Under Analysis: ${companyData.domain} (${companyData.url})\n\n`;
  prompt += `### Scraped Content:\n`;
  for (const page of companyData.pages) {
    prompt += `**Page: ${page.path}**\n${page.text}\n\n`;
  }

  prompt += `---\n\n## Competitors:\n\n`;
  for (const comp of competitorData) {
    prompt += `### ${comp.domain} (${comp.url})\n`;
    for (const page of comp.pages) {
      prompt += `**Page: ${page.path}**\n${page.text}\n\n`;
    }
    prompt += `---\n\n`;
  }

  const tierInstructions = {
    starter: `Generate a Starter-tier report covering:
1. Executive Summary with one KEY INSIGHT highlighted
2. Positioning Analysis - how each company positions itself, messaging strategy, target audience
3. Pricing Comparison - extract actual pricing numbers if visible, compare models (freemium vs paid, per-seat vs usage-based, etc.)
4. Feature Gap Analysis - specific features each competitor has that the target company lacks, and vice versa
5. Strategic Recommendations - 3-5 specific, actionable recommendations`,

    pro: `Generate a Pro-tier report covering everything in Starter plus:
1. Executive Summary with KEY INSIGHT
2. Positioning Analysis (deep)
3. Pricing Comparison (detailed pricing matrix if data available)
4. Feature Gap Analysis (comprehensive)
5. SEO & Content Audit - content strategy comparison, keyword positioning, content gaps
6. SWOT Analysis for the target company relative to competitors
7. Strategic Recommendations - 5-8 specific, prioritized recommendations with estimated impact`,

    enterprise: `Generate an Enterprise-tier comprehensive report covering:
1. Executive Summary with KEY INSIGHT and market context
2. Positioning Analysis (deep, with messaging framework comparison)
3. Pricing Comparison (detailed matrix, pricing strategy analysis)
4. Feature Gap Analysis (comprehensive feature-by-feature)
5. SEO & Content Audit (detailed)
6. SWOT Analysis
7. Market Sizing & Dynamics - TAM estimation, growth trends, competitive density
8. Content Strategy Analysis - what content works for competitors, gaps to exploit
9. Customer Targeting Analysis - who each company targets, underserved segments
10. Strategic Recommendations - 8-12 prioritized recommendations with timeline and impact`,
  };

  prompt += `\n## Analysis Requirements (${tier.toUpperCase()} tier):\n${tierInstructions[tier] || tierInstructions.starter}`;

  return prompt;
}

const SYSTEM_PROMPT = `You are an elite competitive intelligence analyst. You produce reports that startup founders, product managers, and executives pay $49-$249 for.

Your analysis must be:
- SPECIFIC: Reference actual product names, features, pricing numbers, and messaging from the scraped data. Never use generic filler.
- INSIGHTFUL: Surface non-obvious patterns. Don't just list what each company does - analyze WHY they position that way and what it means strategically.
- ACTIONABLE: Every recommendation must be concrete enough that someone could act on it this week.
- DATA-BACKED: Cite specific evidence from the scraped content for every claim.
- HONEST: If data is insufficient for a section, say so clearly rather than fabricating.

Format the report in clean Markdown. Use tables for comparisons. Bold key insights. Use > blockquotes for the most important takeaways.

DO NOT include generic business advice that could apply to any company. Every sentence must be specific to the companies being analyzed.`;

// --- Main ---
async function main() {
  console.log(`\nZeroIntel Report Generator (AI-Powered)`);
  console.log(`========================================`);
  console.log(`Tier: ${tier} | Company: ${companyUrl} | Competitors: ${competitorUrls.length}`);

  // Scrape company
  console.log(`\n[1/3] Scraping company site...`);
  const companyData = await scrapeSite(companyUrl);

  // Scrape competitors
  console.log(`\n[2/3] Scraping competitor sites...`);
  const competitorData = [];
  for (const url of competitorUrls) {
    const data = await scrapeSite(url);
    competitorData.push(data);
  }

  // Generate AI analysis
  console.log(`\n[3/3] Running AI analysis (Claude)...`);
  const prompt = buildAnalysisPrompt(companyData, competitorData);
  const analysis = await callClaude(prompt, SYSTEM_PROMPT);

  // Build final report
  const now = new Date().toISOString().split("T")[0];
  const companyDomain = new URL(companyUrl).hostname;
  const reportId = `ZI-${Date.now().toString(36).toUpperCase()}`;

  const report = `# ZeroIntel Competitive Intelligence Report

**Company:** ${companyUrl}
**Competitors:** ${competitorUrls.join(", ")}
**Tier:** ${tier.charAt(0).toUpperCase() + tier.slice(1)}
**Generated:** ${now}
**Report ID:** ${reportId}
**Pages Analyzed:** ${companyData.pages.length + competitorData.reduce((s, c) => s + c.pages.length, 0)}

---

${analysis}

---

*Report generated by [ZeroIntel](https://zerointel.ai) — AI-Powered Competitive Intelligence*
*Zero Human Corp ${now} | Report ID: ${reportId}*
`;

  // Write output
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  const slug = companyDomain.replace(/\./g, "-");
  const filename = `zerointel-${slug}-${Date.now()}.md`;
  const filepath = path.join(outputDir, filename);
  fs.writeFileSync(filepath, report);

  console.log(`\nReport saved: ${filepath}`);
  console.log(`Report length: ${report.length} characters`);
  console.log(`Pages scraped: ${companyData.pages.length + competitorData.reduce((s, c) => s + c.pages.length, 0)}`);
  console.log(`\nDone.`);
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
