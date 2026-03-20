import os
import datetime

ACTIVE_CONTEXT = "psi/memory_bank/activeContext.md"
ARCHIVE_FILE = "psi/memory_bank/archive/session_history.md"

def optimize():
    if not os.path.exists(ACTIVE_CONTEXT):
        return

    with open(ACTIVE_CONTEXT, "r") as f:
        lines = f.readlines()

    pending_lines = []
    completed_lines = []
    
    # Simple logic: Identify [x] tasks
    for line in lines:
        if line.strip().startswith("- [x]"):
            completed_lines.append(line)
        else:
            pending_lines.append(line)

    if not completed_lines:
        return # Nothing to optimize

    # 1. Append to Archive
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARCHIVE_FILE, "a") as f:
        f.write(f"\n### Archived at {timestamp}\n")
        f.writelines(completed_lines)

    # 2. Rewrite Active Context
    with open(ACTIVE_CONTEXT, "w") as f:
        f.writelines(pending_lines)

    print(f"✨ Scribe: Optimized {len(completed_lines)} completed memories to archive.")

if __name__ == "__main__":
    optimize()
