---
globs: lib/**/*.ts
---

# TypeScript Rules for lib/

- **Runtime**: Bun (not Node.js)
- **Imports**: Use relative paths within modules, no path aliases
- **Append operations**: Use `import { appendFile } from 'node:fs/promises'` — NOT `Bun.write()` with append flag (silently broken in Bun 1.3.x)
- **Types**: Prefer explicit types over `any` — type escape hatches get caught in audits
- **Error handling**: Validate at boundaries (user input, external APIs). Trust internal code.
- **Events**: All PULSE events use JSONL format with `{ id, ts, type, agent, data }`
