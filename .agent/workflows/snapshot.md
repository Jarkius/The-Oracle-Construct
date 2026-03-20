---
description: Quick knowledge capture - save insights and learnings on the fly
---
# /snapshot - Quick Memory

> *"Capture the moment."*

## Usage
`/snapshot "Insight text"`

## Action
1.  Appends timestamp + text to `psi/memory/logs/daily_log.md`.
2.  Used later by `/rrr` to build the full story.
3.  **ADR-010**: Also persists to SQLite + ChromaDB for semantic recall:
    ```bash
    bun memory save "Snapshot: <insight text>"
    ```

ARGUMENTS: $ARGUMENTS
