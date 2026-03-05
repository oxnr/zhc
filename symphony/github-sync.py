#!/usr/bin/env python3
"""
GitHub Issues ↔ Symphony Board Sync Daemon

Polls GitHub Issues every 30s and syncs to board.json for the dashboard.
Also provides functions for agents to create/close issues.

Requires: GITHUB_TOKEN and GITHUB_REPO env vars.
Uses `gh` CLI for simplicity and auth reuse.
"""

import json
import os
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

BOARD_FILE = Path(os.environ.get("ZHC_ROOT", ".")) / "symphony" / "board.json"
POLL_INTERVAL = int(os.environ.get("GITHUB_SYNC_INTERVAL", "30"))
REPO = os.environ.get("GITHUB_REPO", "")

# Label → status mapping
LABEL_STATUS_MAP = {
    "status:inbox": "INBOX",
    "status:backlog": "BACKLOG",
    "status:assigned": "ASSIGNED",
    "status:in-progress": "IN_PROGRESS",
    "status:in-review": "IN_REVIEW",
    "status:done": "DONE",
    "status:archived": "ARCHIVED",
}

# Label → priority mapping
LABEL_PRIORITY_MAP = {
    "priority:critical": "critical",
    "priority:high": "high",
    "priority:medium": "medium",
    "priority:low": "low",
}

# Label → agent mapping
LABEL_AGENT_MAP = {
    "agent:duke": "ceo",
    "agent:hackerman": "cto",
    "agent:borat": "bizdev",
    "agent:t-800": "ops",
    "agent:don-draper": "content",
    "agent:picasso": "designer",
}


def gh(*args):
    """Run a gh CLI command and return parsed JSON or raw output."""
    cmd = ["gh"] + list(args)
    if REPO:
        cmd.extend(["--repo", REPO])
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        print(f"[github-sync] gh error: {result.stderr.strip()}")
        return None
    return result.stdout.strip()


def gh_json(*args):
    """Run a gh CLI command and return parsed JSON."""
    output = gh(*args)
    if output:
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return None
    return None


def fetch_issues():
    """Fetch all open and recently closed issues from GitHub."""
    # Fetch open issues
    open_issues = gh_json(
        "issue", "list",
        "--state", "all",
        "--limit", "100",
        "--json", "number,title,body,state,labels,assignees,createdAt,updatedAt,closedAt,comments"
    )
    return open_issues or []


def issue_to_task(issue):
    """Convert a GitHub Issue to a Symphony task."""
    labels = [l["name"] for l in issue.get("labels", [])]

    # Determine status from labels
    status = "INBOX"
    for label in labels:
        if label in LABEL_STATUS_MAP:
            status = LABEL_STATUS_MAP[label]
            break
    # Closed issues are DONE
    if issue.get("state") == "CLOSED":
        status = "DONE"

    # Determine priority
    priority = "medium"
    for label in labels:
        if label in LABEL_PRIORITY_MAP:
            priority = LABEL_PRIORITY_MAP[label]
            break

    # Determine assignee agent
    assignee = None
    for label in labels:
        if label in LABEL_AGENT_MAP:
            assignee = LABEL_AGENT_MAP[label]
            break

    # Check for proof of work in comments (last comment with "PROOF:" prefix)
    proof = None
    for comment in reversed(issue.get("comments", [])):
        body = comment.get("body", "")
        if body.startswith("PROOF:"):
            proof = body[6:].strip()
            break

    # Tags from non-status/priority/agent labels
    tags = [l for l in labels
            if not l.startswith("status:") and not l.startswith("priority:") and not l.startswith("agent:")]

    return {
        "id": f"gh-{issue['number']}",
        "githubNumber": issue["number"],
        "title": issue["title"],
        "description": issue.get("body", ""),
        "status": status,
        "priority": priority,
        "assignee": assignee,
        "createdBy": "ceo",
        "createdAt": issue.get("createdAt"),
        "completedAt": issue.get("closedAt"),
        "tags": tags,
        "subtasks": [],
        "proofOfWork": proof,
    }


def sync_to_board(tasks):
    """Write tasks to board.json for the dashboard."""
    board = {
        "version": "1.0.0",
        "lastUpdated": datetime.now(timezone.utc).isoformat(),
        "columns": ["INBOX", "BACKLOG", "ASSIGNED", "IN_PROGRESS", "IN_REVIEW", "DONE", "ARCHIVED"],
        "tasks": tasks,
        "source": "github",
    }
    BOARD_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(BOARD_FILE, "w") as f:
        json.dump(board, f, indent=2)


def create_issue(title, body="", priority="medium", agent=None, labels=None):
    """Create a GitHub Issue with proper labels. Returns issue number."""
    cmd_labels = [f"priority:{priority}", "status:inbox"]
    if agent:
        cmd_labels.append(f"agent:{agent}")
    if labels:
        cmd_labels.extend(labels)

    args = ["issue", "create", "--title", title, "--body", body]
    for l in cmd_labels:
        args.extend(["--label", l])

    output = gh(*args)
    if output:
        # gh issue create outputs the URL, extract number
        try:
            return int(output.strip().split("/")[-1])
        except (ValueError, IndexError):
            pass
    return None


def close_issue(number, proof_of_work=None):
    """Close a GitHub Issue, optionally with proof of work comment."""
    if proof_of_work:
        gh("issue", "comment", str(number), "--body", f"PROOF: {proof_of_work}")
    gh("issue", "close", str(number))


def assign_issue(number, agent):
    """Update an issue's agent label and set status to assigned."""
    # Remove old agent labels, add new one
    gh("issue", "edit", str(number),
       "--add-label", f"agent:{agent},status:assigned",
       "--remove-label", "status:inbox,status:backlog")


def update_issue_status(number, status):
    """Update an issue's status label."""
    label_key = f"status:{status.lower().replace('_', '-')}"
    # Remove all other status labels
    remove = ",".join(k for k in LABEL_STATUS_MAP.keys() if k != label_key)
    gh("issue", "edit", str(number), "--add-label", label_key, "--remove-label", remove)


def ensure_labels():
    """Create required labels in the repo if they don't exist."""
    required = {
        "status:inbox": "0E8A16",
        "status:backlog": "0E8A16",
        "status:assigned": "1D76DB",
        "status:in-progress": "FBCA04",
        "status:in-review": "7057FF",
        "status:done": "0E8A16",
        "status:archived": "666666",
        "priority:critical": "B60205",
        "priority:high": "D93F0B",
        "priority:medium": "FBCA04",
        "priority:low": "C2E0C6",
        "agent:duke": "7057FF",
        "agent:hackerman": "0E8A16",
        "agent:borat": "1D76DB",
        "agent:t-800": "FBCA04",
        "agent:don-draper": "D93F0B",
        "agent:picasso": "C2E0C6",
    }
    existing_raw = gh("label", "list", "--json", "name")
    existing = set()
    if existing_raw:
        try:
            existing = {l["name"] for l in json.loads(existing_raw)}
        except (json.JSONDecodeError, TypeError):
            pass

    for name, color in required.items():
        if name not in existing:
            gh("label", "create", name, "--color", color, "--force")
            print(f"[github-sync] Created label: {name}")


def sync_loop():
    """Main sync loop: poll GitHub Issues → update board.json."""
    print(f"[github-sync] Starting sync daemon (repo: {REPO}, interval: {POLL_INTERVAL}s)")

    # Ensure labels exist on first run
    ensure_labels()

    while True:
        try:
            issues = fetch_issues()
            if issues is not None:
                tasks = [issue_to_task(i) for i in issues]
                # Sort: open first (by priority), then closed
                priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
                tasks.sort(key=lambda t: (
                    0 if t["status"] != "DONE" else 1,
                    priority_order.get(t["priority"], 2),
                ))
                sync_to_board(tasks)
                active = sum(1 for t in tasks if t["status"] not in ("DONE", "ARCHIVED"))
                print(f"[github-sync] Synced {len(tasks)} issues ({active} active)")
        except Exception as e:
            print(f"[github-sync] Error: {e}")

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    if not REPO:
        print("[github-sync] GITHUB_REPO not set. Sync disabled.")
        print("[github-sync] Set GITHUB_REPO=owner/repo in .env to enable.")
        # Keep running but do nothing (so entrypoint doesn't crash)
        while True:
            time.sleep(3600)
    else:
        sync_loop()
