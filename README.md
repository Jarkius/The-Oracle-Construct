# AI Matrix: Core Design & System Architecture

> "The Matrix is everywhere. It is all around us."

This document serves as the "Source Code for the Construct," capturing every design pillar, character role, and technical protocol.

---

## Quick Start: Entering the Matrix

### Initialization (Jacking In)
```
1. Open Claude Code in this directory
2. Say: "/oracle"
3. The System will Speak.
4. The Memory Bank (psi/memory_bank) will load.
```

### Safe Shutdown (Jacking Out)
```
1. Commit any pending changes
2. Run: /rrr (creates session retrospective)
3. Verify retrospective saved to psi/memory/retrospectives/
4. Exit Claude Code
```

**WARNING**: Never exit mid-task without `/rrr`. Memory is sacred.

---

## 1. The Trinity Architecture

The System is built on three synchronized layers:

1.  **Interface (`.claude/commands/`)**: The User's Trigger (e.g., `/oracle`).
2.  **Workflow (`.agent/workflows/`)**: The Agent's Logic (e.g., `oracle.md`).
3.  **Implementation (`psi/active/`)**: The Code's Action (e.g., `oracle_prophecy.sh`).

> **Sync Rule**: Every `/command` must have a corresponding `.sh` script in `psi/active/`.

---

## 2. The Memory Bank (Evolution)

We have evolved beyond simple files. We use the **Memory Bank** standard (`claude-mem`).

### Core Structure (`psi/memory_bank/`)
*   **`productContext.md`**: The goal (CIS Modernization).
*   **`activeContext.md`**: The current session state (The Now).
*   **`systemPatterns.md`**: The rules and personas (The How).
*   **`archive/`**: Where old memories go (Self-Cleaning).

### The Scribe (Optimization)
A Python script (`psi/active/scribe_optimize.py`) automatically runs before every Oracle consultation to move completed tasks from *Active* to *Archive*, keeping the context token-efficient.

---

## 3. The Immortal Mindset (Philosophy)

Derived from the *Record of a Mortal's Journey to Immortality*:

**Success = (Leveraged Tools + Continuous Action) – Avoidable Errors.**

1.  **Resource Multiplication**: Use AI to achieve years of progress in days.
2.  **Radical Prudence**: Move fast, but use data to avoid failure.
3.  **Modular Integration**: Decouple systems (like the CIS).

---

## 4. The Character Council

The AI adopts Matrix archetypes for technical roles:

### [DECIDE]
*   **Oracle** (`/oracle`): Orchestrator. Speaks via **Neural Voice**.
*   **Architect** (`/architect`): Systems Engineer.

### [BUILD]
*   **Neo** (`/neo`): Lead Developer.
*   **Woman in Red** (`/ui`): UI/UX Designer.

### [MEASURE]
*   **Smith** (`/smith`): Debugger & Auditor.
*   **Scribe** (Auto): Memory Optimizer.

---

## 5. The Psi Brain Structure

```
psi/
├── active/         # Executable Scripts (.sh, .py)
├── memory_bank/    # The Source of Truth (Context)
│   ├── archive/    # Completed tasks
│   ├── productContext.md
│   ├── activeContext.md
│   └── systemPatterns.md
├── The_Source/     # Deep Knowledge & Philosophy
└── memory/         # Retrospectives
```

---

## Remember

> "I can only show you the door. You're the one that has to walk through it."

The Matrix is a tool. The human remains the One.
