---
globs: psi/**
---

# PSI Directory Rules

The `psi/` directory is the Oracle's psyche — memory, events, philosophy.

- **Nothing Is Deleted** — archive to `psi/archive/`, never `rm`
- **Events are append-only** — never truncate `psi/state/pulse/events.jsonl`
- **Sessions are immutable** — never edit files in `psi/memory/sessions/`
- **Use appendFile()** not Bun.write() for append operations (Bun append flag is broken)
