#!/usr/bin/env python3
"""
Daily Summary Generator — Zero Human Corp
Generates end-of-day summaries from git activity, GitHub Issues, and board state.
Runs via Ops agent heartbeat or cron.
"""

import json
import os
import smtplib
import subprocess
from datetime import datetime, timezone, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from pathlib import Path

MEMORY_DIR = Path(os.environ.get("ZHC_ROOT", ".")) / "memory"
REPORTS_DIR = Path(os.environ.get("ZHC_ROOT", ".")) / "economy" / "reports"
BOARD_FILE = Path(os.environ.get("ZHC_ROOT", ".")) / "symphony" / "board.json"
SUMMARIES_DIR = Path(os.environ.get("ZHC_ROOT", ".")) / "symphony" / "summaries"
REPO = os.environ.get("GITHUB_REPO", "")


def _run(cmd, timeout=15):
    """Run a shell command, return stdout or empty string."""
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def _git_activity_today():
    """Get today's git commits."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    log = _run(["git", "log", f"--since={today}", "--oneline", "--no-merges"])
    if not log:
        return "No commits today.", 0
    lines = log.strip().split("\n")
    return log, len(lines)


def _github_issues_summary():
    """Get GitHub Issues activity via gh CLI."""
    if not REPO:
        return None

    # Issues closed today
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    closed_raw = _run(["gh", "issue", "list", "--repo", REPO,
                        "--state", "closed", "--limit", "50",
                        "--json", "number,title,closedAt"])
    closed_today = []
    if closed_raw:
        try:
            for issue in json.loads(closed_raw):
                if issue.get("closedAt", "").startswith(today):
                    closed_today.append(f"  - #{issue['number']}: {issue['title']}")
        except (json.JSONDecodeError, TypeError):
            pass

    # Issues opened today
    opened_raw = _run(["gh", "issue", "list", "--repo", REPO,
                        "--state", "all", "--limit", "50",
                        "--json", "number,title,createdAt"])
    opened_today = []
    if opened_raw:
        try:
            for issue in json.loads(opened_raw):
                if issue.get("createdAt", "").startswith(today):
                    opened_today.append(f"  - #{issue['number']}: {issue['title']}")
        except (json.JSONDecodeError, TypeError):
            pass

    # Open count
    open_raw = _run(["gh", "issue", "list", "--repo", REPO,
                      "--state", "open", "--json", "number"])
    open_count = 0
    if open_raw:
        try:
            open_count = len(json.loads(open_raw))
        except (json.JSONDecodeError, TypeError):
            pass

    return {
        "opened": opened_today,
        "closed": closed_today,
        "open_count": open_count,
    }


def _board_summary():
    """Summarize current board state."""
    if not BOARD_FILE.exists():
        return "No tasks yet.", {}
    with open(BOARD_FILE) as f:
        board = json.load(f)
    tasks = board.get("tasks", [])
    by_status = {}
    for t in tasks:
        s = t.get("status", "UNKNOWN")
        by_status[s] = by_status.get(s, 0) + 1
    active = sum(1 for t in tasks if t.get("status") not in ("DONE", "ARCHIVED"))
    text = f"Total: {len(tasks)} | Active: {active} | Done: {by_status.get('DONE', 0)}"
    return text, by_status


def _financial_summary():
    """Parse today's revenue/costs from revenue-log.md."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    rev_file = MEMORY_DIR / "revenue-log.md"
    total_revenue = 0.0
    total_costs = 0.0
    if rev_file.exists():
        for line in rev_file.read_text().split("\n"):
            line = line.strip()
            if today not in line:
                continue
            try:
                amount = float(line.split("$")[1].split("|")[0].strip())
                if line.startswith("- REVENUE:"):
                    total_revenue += amount
                elif line.startswith("- COST:"):
                    total_costs += amount
            except (IndexError, ValueError):
                pass
    return total_revenue, total_costs


def generate_daily_summary():
    """Generate a comprehensive daily summary from git + GitHub + board."""
    SUMMARIES_DIR.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc)
    today = now.strftime("%Y-%m-%d")

    # Git activity
    git_log, commit_count = _git_activity_today()

    # GitHub Issues
    gh_data = _github_issues_summary()

    # Board state
    board_text, by_status = _board_summary()

    # Financials
    revenue, costs = _financial_summary()

    # Build GitHub section
    gh_section = ""
    if gh_data:
        gh_section = f"""## GitHub Issues
- Open: {gh_data['open_count']}
- Opened today: {len(gh_data['opened'])}
- Closed today: {len(gh_data['closed'])}

### Opened Today
{chr(10).join(gh_data['opened']) if gh_data['opened'] else '  None'}

### Closed Today
{chr(10).join(gh_data['closed']) if gh_data['closed'] else '  None'}
"""
    else:
        gh_section = "## GitHub Issues\nGitHub sync not configured (set GITHUB_REPO).\n"

    # Company state
    company_state = ""
    state_file = MEMORY_DIR / "company-state.md"
    if state_file.exists():
        company_state = state_file.read_text()[-500:]

    summary = f"""# Daily Summary — {today}
Generated at {now.strftime('%H:%M UTC')}

## Financial Overview
| Metric | Value |
|--------|-------|
| Revenue Today | ${revenue:.2f} |
| Costs Today | ${costs:.2f} |
| Net P&L Today | ${revenue - costs:.2f} |

## Git Activity
Commits today: {commit_count}
```
{git_log}
```

{gh_section}
## Task Board
{board_text}

## Company State
{company_state if company_state else 'Not initialized.'}

---
*Auto-generated by T-800 (Ops Agent).*
"""

    summary_file = SUMMARIES_DIR / f"summary-{today}.md"
    summary_file.write_text(summary)
    print(f"[daily-summary] Saved to {summary_file}")
    return summary, summary_file


def send_email_summary(summary, recipient=None):
    """Send daily summary via email (optional)."""
    recipient = recipient or os.getenv("SUMMARY_EMAIL")
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")

    if not all([recipient, smtp_user, smtp_pass]):
        print("[daily-summary] Email not configured. Summary saved to file only.")
        return False

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"Zero Human Corp — Daily Summary ({today})"
    msg["From"] = smtp_user
    msg["To"] = recipient
    msg.attach(MIMEText(summary, "plain"))

    try:
        with smtplib.SMTP(smtp_host, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.send_message(msg)
        print(f"[daily-summary] Emailed to {recipient}")
        return True
    except Exception as e:
        print(f"[daily-summary] Email failed: {e}")
        return False


if __name__ == "__main__":
    summary, path = generate_daily_summary()
    send_email_summary(summary)
    print(f"\n{summary[:500]}...")
