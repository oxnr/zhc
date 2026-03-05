#!/usr/bin/env python3
"""
Symphony Task Manager — Board operations for Zero Human Corp
Agents call these functions to manage the task board.
"""

import json
import uuid
from datetime import datetime, timezone
from pathlib import Path

BOARD_FILE = Path("./symphony/board.json")


def load_board():
    with open(BOARD_FILE) as f:
        return json.load(f)


def save_board(board):
    board["lastUpdated"] = datetime.now(timezone.utc).isoformat()
    with open(BOARD_FILE, "w") as f:
        json.dump(board, f, indent=2)


def create_task(title, description, priority="medium", assignee=None,
                created_by="ceo", deadline=None, budget=0, tags=None):
    """Create a new task and add to INBOX."""
    board = load_board()

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
        "history": [
            {
                "action": "created",
                "by": created_by,
                "at": datetime.now(timezone.utc).isoformat()
            }
        ]
    }

    board["tasks"].append(task)
    save_board(board)
    print(f"Created task: {task['id']} — {title}")
    return task["id"]


def move_task(task_id, new_status, by="system"):
    """Move a task to a new status column."""
    board = load_board()

    for task in board["tasks"]:
        if task["id"] == task_id:
            old_status = task["status"]
            task["status"] = new_status
            task["history"].append({
                "action": f"moved {old_status} → {new_status}",
                "by": by,
                "at": datetime.now(timezone.utc).isoformat()
            })
            save_board(board)
            print(f"Moved {task_id}: {old_status} → {new_status}")
            return True

    print(f"Task {task_id} not found")
    return False


def assign_task(task_id, assignee, by="ceo"):
    """Assign a task to an agent."""
    board = load_board()

    for task in board["tasks"]:
        if task["id"] == task_id:
            task["assignee"] = assignee
            if task["status"] == "INBOX":
                task["status"] = "ASSIGNED"
            task["history"].append({
                "action": f"assigned to {assignee}",
                "by": by,
                "at": datetime.now(timezone.utc).isoformat()
            })
            save_board(board)
            print(f"Assigned {task_id} to {assignee}")
            return True

    return False


def complete_task(task_id, proof_of_work, by="system"):
    """Mark task as IN_REVIEW with proof of work."""
    board = load_board()

    for task in board["tasks"]:
        if task["id"] == task_id:
            task["status"] = "IN_REVIEW"
            task["proofOfWork"] = {
                "deliverable": proof_of_work.get("deliverable"),
                "evidence": proof_of_work.get("evidence"),
                "metrics": proof_of_work.get("metrics"),
                "nextSteps": proof_of_work.get("nextSteps"),
                "completedAt": datetime.now(timezone.utc).isoformat(),
                "completedBy": by
            }
            task["history"].append({
                "action": "submitted for review",
                "by": by,
                "at": datetime.now(timezone.utc).isoformat()
            })
            save_board(board)
            print(f"Task {task_id} submitted for review")
            return True

    return False


def get_board_summary():
    """Get a summary of the current board state."""
    board = load_board()
    summary = {}
    for col in board["columns"]:
        tasks_in_col = [t for t in board["tasks"] if t["status"] == col]
        summary[col] = len(tasks_in_col)

    total = len(board["tasks"])
    done = summary.get("DONE", 0) + summary.get("ARCHIVED", 0)

    print(f"\n📋 Task Board Summary")
    print(f"{'='*40}")
    for col, count in summary.items():
        bar = "█" * count
        print(f"  {col:15} {count:3} {bar}")
    print(f"{'='*40}")
    print(f"  Total: {total} | Completed: {done}")

    return summary


def get_agent_tasks(agent_name):
    """Get all tasks assigned to a specific agent."""
    board = load_board()
    return [t for t in board["tasks"]
            if t["assignee"] == agent_name
            and t["status"] not in ("DONE", "ARCHIVED")]


def get_overdue_tasks():
    """Get all tasks past their deadline."""
    board = load_board()
    now = datetime.now(timezone.utc).isoformat()
    overdue = []
    for task in board["tasks"]:
        if (task["deadline"]
                and task["deadline"] < now
                and task["status"] not in ("DONE", "ARCHIVED")):
            overdue.append(task)
    return overdue


if __name__ == "__main__":
    get_board_summary()
