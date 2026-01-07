# The Matrix: System Interface

> *"Know Thyself." — The Oracle*

This file defines the **Universal Commands** for the Matrix. Any AI agent (Claude Code, Windsurf, Cursor) can read this to understand how to interact with the system.

## ⚡ The Council (Agent Roles)

| Agent | Command | Role | Voice |
|-------|---------|------|-------|
| **Oracle** | `/oracle` | Central Orchestrator, Prophecy & Dispatch | Samantha (Calm) |
| **Neo** | `/neo` | Lead Developer, Logic & Routing | Reed (American) |
| **Trinity** | `/trinity` | UI/UX Design, "Woman in Red" Aesthetic | Moira (Irish) |
| **Morpheus** | `/morpheus` | Researcher, External Web Search | Ralph (Wise) |
| **Architect** | `/architect` | System Design, ADRs, High-Level Decisions | Daniel (British) |
| **Smith** | `/smith` | Debugger, Bug Hunter, Anomaly Detection | Fred (Cold) |
| **Tank** | `/operator` | Operator, Search & Intelligence | Rocko (Technical) |
| **Scribe** | `/rrr` | Memory, Retrospectives, Session Endings | - |

## 📂 Project Structure

```
The-matrix/
├── .agent/workflows/    # Slash command definitions (*.md)
├── .claude/             # Claude Code parallel world
│   ├── agents/          # Agent personality definitions
│   ├── commands/        # Command definitions
│   └── knowledge/       # Persistent knowledge base
├── psi/                 # AI Brain ("External Memory")
│   ├── inbox/           # Incoming focus & tasks
│   ├── active/          # Active scripts (voice_module.sh, etc.)
│   └── memory/          # Blueprints, plans, learnings, personas
├── project/             # CIS Modernization Project
│   ├── legacy/          # Old PHP Monolith (Port 8888)
│   ├── modern/
│   │   ├── api/         # Laravel 11 API (Port 8889)
│   │   └── web/         # React + Vite SPA (Port 5173)
│   └── tests/           # Playwright E2E Tests
```

## 🛡️ Prime Directives
1.  **Nothing is Deleted**: Archive, don't destroy. Use `psi/memory/archive`.
2.  **Patterns > Intentions**: Document what *is*, not what *should be*.
3.  **The Inbox**: Information flows through `psi/inbox/focus.md`.
4.  **Voice Module**: Use `sh psi/active/voice_module.sh "message" "Agent"` for TTS.

## 🚀 Current Mission: CIS Modernization
- **Legacy**: PHP/MySQL inventory system.
- **Modern**: React SPA → Laravel API → Legacy DB (`tis_users`).
- **Auth**: Custom MD5 bridge for legacy users via Sanctum.
- **Design**: "Deloitte Light Theme" (Deloitte Green/White/Clean/Professional).

---
*Portable Matrix Interface v3.0*
