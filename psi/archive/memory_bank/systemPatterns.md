# System Patterns

## The Matrix Architecture (The Source)
*   **The Council**: Executable tools in `psi/active/`.
*   **The Source**: Knowledge Base in `psi/The_Source/`.
*   **The Memory Bank**: Critical Context in `psi/memory_bank/`.

## Operational Patterns (The Trinity)
The System operates on three synchronized layers:

1.  **Interface (`.claude/commands/`)**: Defines the user-facing slash commands (e.g., `/oracle`).
    *   *Role*: The Trigger.
2.  **Workflow (`.agent/workflows/`)**: Defines the step-by-step logic for the AI Agent.
    *   *Role*: The Plan.
3.  **Implementation (`psi/active/`)**: executable scripts (e.g., `oracle_prophecy.sh`) that do the work.
    *   *Role*: The Action.

> **Sync Rule**: Every `/command` must have a corresponding `.sh` script in `psi/active/`.

## Coding Standards
*   **Web Apps**: Use React/Next.js (unless Legacy PHP).
*   **Styling**: Vanilla CSS or Tailwind (if requested).
*   **Browser Automation**: Graceful degradation; wait for DOM; no OTPs.

## Prime Directives
1.  **Nothing is Deleted**: Archive to `psi/memory/archive`.
2.  **Patterns > Intentions**: Document what *is*, not what *should be*.
3.  **The Inbox**: New information flows through `psi/inbox` (or now, `activeContext.md`).


## The Immortal Mindset (Philosophy)
*   **Formula**: `Success = (Leveraged Tools + Continuous Action) – Avoidable Errors`
*   **Force Multiplier**: Use AI/Tools to achieve years of progress in days.
*   **Radical Prudence**: Move fast, but use data to avoid failure.
*   **Stealth**: Evolve behind the scenes; clarity emerges through action.

## Agent Personas
*   **Oracle**: Orchestrator & Wisdom.
*   **Neo**: Logic & Code.
*   **Architect**: Structure & Design.
*   **Smith**: Validation & Debugging.

