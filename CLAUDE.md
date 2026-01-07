# The Matrix: System Interface

> *"Know Thyself." — The Oracle*

This file defines the **Universal Commands** for the Matrix. Any AI agent (Claude Code, Windsurf, Cursor) can read this to understand how to interact with the system.

## ⚡ The Council (Agent Roles)

| Agent | Command | Role | Does | Does NOT |
|-------|---------|------|------|----------|
| **Oracle** | `/oracle` | Orchestrator | Align, dispatch, prophecy | Implement |
| **Neo** | `/neo` | Developer | Write ALL code, implement | Design, architecture |
| **Trinity** | `/trinity` | Design Lead | Design tokens, review, guide | Write code |
| **Morpheus** | `/morpheus` | External Intel | Gemini, Google AI, web search | Internal search |
| **Architect** | `/architect` | System Design | ADRs, architecture, structure | UI design, coding |
| **Smith** | `/smith` | Debugger | Bugs, security, anomalies | Feature dev |
| **Tank** | `/operator` | Internal Intel | Code search, git, dependencies | External search |
| **Scribe** | `/rrr` | Memory | Retrospectives, documentation | Active dev |

## 📂 Workspace Structure

```
~/workspace/
├── The-matrix/              # AI Development Environment
│   ├── .agent/workflows/    # Slash command definitions (*.md)
│   ├── .claude/             # Claude Code parallel world
│   │   ├── agents/          # Agent personality definitions
│   │   ├── commands/        # Command definitions
│   │   └── knowledge/       # Persistent knowledge base
│   └── psi/                 # AI Brain ("External Memory")
│       ├── inbox/           # Incoming focus & tasks
│       ├── active/          # Active scripts
│       └── memory/          # Blueprints, plans, learnings
│
├── cis-legacy/              # Old PHP Monolith (Port 8888)
│
└── cis-modern/              # CIS Modernization Project
    ├── api/                 # Laravel 11 API (Port 8889)
    ├── web/                 # React + Vite SPA (Port 5173)
    └── tests/               # Playwright E2E Tests
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
