# The Matrix: System Interface

> *"The system is portable. The logic is internal."*

This file defines the **Universal Commands** for the Matrix. Any AI agent (Claude Code, Cline, Windsurf) can read this to understand how to interact with the system.

## ⚡ The Council (Executable Tools)

| Agent | Command | Action (Underlying Script) | Function |
|-------|---------|----------------------------|----------|
| **Oracle** | `/oracle` | `psi/active/oracle_prophecy.sh` | **Council Alignment (Unified)** |
| **Tank** | `/operator` | `psi/active/operator_spawn.sh` | **Search & Intelligence** |
| **Neo** | `/neo` | `psi/active/neo_logic.sh` | **Code Logic & Creation** |
| **Smith** | `/smith` | `psi/active/smith_audit.sh` | **Audit & Bug Fixing** |
| **Scribe** | `/rrr` | `psi/active/scribe_record.sh` | **Memory & Retrospectives** |
| **Architect**| `/architect`| `psi/active/architect_map.sh` | **System Mapping** |
| **Morpheus** | `/morpheus` | `psi/active/morpheus_signal.sh` | **External Research (Web)** |
| **Mero** | `/cause` | `psi/active/mero_cause.sh` | **Root Cause Analysis** |
| **Fixer** | `/fix` | `git config ...` (See workflows) | **System Repair** |

## 🧠 The Source (Knowledge Core)
All philosophy and definitions are stored in **The Source**.
- **Location**: [`psi/The_Source/`](psi/The_Source/)
- **Architecture**: [`psi/The_Source/05_matrix_architecture.md`](psi/The_Source/05_matrix_architecture.md)
- **Constitution**: [`psi/The_Source/02_claude_dna.md`](psi/The_Source/02_claude_dna.md)

## 🛡️ Prime Directives
1.  **Nothing is Deleted**: Archive to `psi/memory/archive`.
2.  **Patterns > Intentions**: Document what *is*, not what *should be*.
3.  **The Inbox**: Information flows through `psi/inbox`.

---
*Portable Matrix Interface v2.0*
