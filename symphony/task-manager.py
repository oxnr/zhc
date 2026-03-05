#!/usr/bin/env python3
"""
Symphony Task Manager — Board operations for Zero Human Corp

When GITHUB_REPO is set, tasks are GitHub Issues (source of truth).
The sync daemon (github-sync.py) polls Issues → board.json for the dashboard.

When GITHUB_REPO is NOT set, falls back to local board.json CRUD.
"""

import json
import os
import uuid
from datetime import datetime, timezone
from pathlib import Path

BOARD_FILE = Path(os.environ.get("ZHC_ROOT", ".")) / "symphony" / "board.json"
GITHUB_REPO = os.environ.get("GITHUB_REPO", "")


def _use_github():
    return bool(GITHUB_REPO)


# ---- GitHub-backed operations ----

def _github_create(title, description, priority, assignee, tags):
    from symphony import github_sync as gs
    labels = list(tags) if tags else []
    return gs.create_issue(title, body=description, priority=priority,
                           agent=assignee, labels=labels)


def _github_move(task_id, new_status):
    from symphony import github_sync as gs
    number = _gh_number(task_id)
    if not number:
        return False
    gs.update_issue_status(number, new_status)
    return True


def _github_assign(task_id, assignee):
    from symphony import github_sync as gs
    number = _gh_number(task_id)
    if not number:
        return False
    gs.assign_issue(number, assignee)
    return True


def _github_complete(task_id, proof_of_work):
    from symphony import github_sync as gs
    number = _gh_number(task_id)
    if not number:
        return False
    proof_text = proof_of_work.get("deliverable", "")
    if proof_of_work.get("evidence"):
        proof_text += f"\nEvidence: {proof_of_work['evidence']}"
    if proof_of_work.get("metrics"):
        proof_text += f"\nMetrics: {proof_of_work['metrics']}"
    gs.close_issue(number, proof_of_work=proof_text)
    return True


def _gh_number(task_id):
    """Extract GitHub issue number from task ID like 'gh-42'."""
    if task_id.startswith("gh-"):
        try:
            return int(task_id[3:])
        except ValueError:
            pass
    # Try looking up in board.json
    if BOARD_FILE.exists():
        with open(BOARD_FILE) as f:
            board = json.load(f)
        for task in board.get("tasks", []):
            if task["id"] == task_id and task.get("githubNumber"):
                return task["githubNumber"]
    print(f"[task-manager] Cannot resolve GitHub issue number for {task_id}")
    return None


# ---- Local board.json operations (fallback) ----

def _load_board():
    if not BOARD_FILE.exists():
        return {"version": "1.0.0", "lastUpdated": "", "columns": [
            "INBOX", "BACKLOG", "ASSIGNED", "IN_PROGRESS", "IN_REVIEW", "DONE", "ARCHIVED"
        ], "tasks": [], "source": "local"}
    with open(BOARD_FILE) as f:
        return json.load(f)


def _save_board(board):
    board["lastUpdated"] = datetime.now(timezone.utc).isoformat()
    BOARD_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(BOARD_FILE, "w") as f:
        json.dump(board, f, indent=2)


# ---- Public API (routes to GitHub or local) ----

def create_task(title, description, priority="medium", assignee=None,
                created_by="ceo", deadline=None, budget=0, tags=None):
    """Create a new task. Returns task ID."""
    if _use_github():
        number = _github_create(title, description, priority, assignee, tags)
        if number:
            task_id = f"gh-{number}"
            print(f"Created GitHub Issue #{number}: {title}")
            return task_id
        print(f"[task-manager] Failed to create GitHub issue, falling back to local")

    # Local fallback
    board = _load_board()
    task = {
        "id": f"task-{uuid.uuid4().hex[:8]}",
        "title": title,
        "description": description,
        "status": "INBOX" if not assignee else "ASSIGNED",
        "priority": priority,
        "assignee": assignee,
        "createdBy": created_by,
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "deadline": deadline,
        "budget": budget,
        "tags": tags or [],
        "subtasks": [],
        "proofOfWork": None,
    }
    board["tasks"].append(task)
    _save_board(board)
    print(f"Created task: {task['id']} — {title}")
    return task["id"]


def move_task(task_id, new_status, by="system"):
    """Move a task to a new status column."""
    if _use_github():
        if _github_move(task_id, new_status):
            print(f"Moved {task_id} → {new_status} (GitHub)")
            return True

    # Local fallback
    board = _load_board()
    for task in board["tasks"]:
        if task["id"] == task_id:
            old_status = task["status"]
            task["status"] = new_status
            _save_board(board)
            print(f"Moved {task_id}: {old_status} → {new_status}")
            return True
    print(f"Task {task_id} not found")
    return False


def assign_task(task_id, assignee, by="ceo"):
    """Assign a task to an agent."""
    if _use_github():
        if _github_assign(task_id, assignee):
            print(f"Assigned {task_id} to {assignee} (GitHub)")
            return True

    # Local fallback
    board = _load_board()
    for task in board["tasks"]:
        if task["id"] == task_id:
            task["assignee"] = assignee
            if task["status"] == "INBOX":
                task["status"] = "ASSIGNED"
            _save_board(board)
            print(f"Assigned {task_id} to {assignee}")
            return True
    return False


def complete_task(task_id, proof_of_work, by="system"):
    """Complete a task with proof of work."""
    if _use_github():
        if _github_complete(task_id, proof_of_work):
            print(f"Completed {task_id} (GitHub issue closed)")
            return True

    # Local fallback
    board = _load_board()
    for task in board["tasks"]:
        if task["id"] == task_id:
            task["status"] = "DONE"
            task["proofOfWork"] = {
                "deliverable": proof_of_work.get("deliverable"),
                "evidence": proof_of_work.get("evidence"),
                "metrics": proof_of_work.get("metrics"),
                "completedAt": datetime.now(timezone.utc).isoformat(),
                "completedBy": by
            }
            _save_board(board)
            print(f"Task {task_id} completed")
            return True
    return False


def get_board_summary():
    """Get a summary of the current board state."""
    board = _load_board()
    summary = {}
    for col in board.get("columns", []):
        tasks_in_col = [t for t in board["tasks"] if t.get("status") == col]
        summary[col] = len(tasks_in_col)

    total = len(board["tasks"])
    done = summary.get("DONE", 0) + summary.get("ARCHIVED", 0)

    print(f"\n Task Board Summary")
    print(f"{'=' * 40}")
    for col, count in summary.items():
        bar = "#" * count
        print(f"  {col:15} {count:3} {bar}")
    print(f"{'=' * 40}")
    print(f"  Total: {total} | Completed: {done}")
    return summary


def get_agent_tasks(agent_name):
    """Get all active tasks assigned to a specific agent."""
    board = _load_board()
    return [t for t in board["tasks"]
            if t.get("assignee") == agent_name
            and t.get("status") not in ("DONE", "ARCHIVED")]


def get_overdue_tasks():
    """Get all tasks past their deadline."""
    board = _load_board()
    now = datetime.now(timezone.utc).isoformat()
    return [t for t in board["tasks"]
            if t.get("deadline") and t["deadline"] < now
            and t.get("status") not in ("DONE", "ARCHIVED")]


if __name__ == "__main__":
    get_board_summary()
