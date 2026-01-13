# Chapter 7: Knowledge Flow — Where Learning Lives

> *"Knowledge is not what you know. Knowledge is what you remember to know."*

## The Problem
Without a system, knowledge scatters. We solve the same problems twice.

## The Solution: The Complete Knowledge Loop

We gather, store, retrieve, and apply knowledge in a closed loop.

```
┌─────────────────────────────────────────────────────────────────┐
│                    THE KNOWLEDGE LOOP                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   GATHER           STORE            RETRIEVE         APPLY     │
│   ──────           ─────            ────────         ─────     │
│                                                                 │
│   /learn    ──→   psi/learn/   ──→  /wisdom    ──→  Work      │
│   /snapshot ──→   archive/     ──→  /wisdom for ──→  Matrix   │
│   /rrr      ──→   learnings/   ──→  search      ──→  Project  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Layer 0: Research (Gather)
*   **Location**: `psi/learn/active/`
*   **Trigger**: `/learn start <topic>`
*   **Purpose**: Active research and exploration.
*   **Retrieve**: `/wisdom for <topic>`

## Layer 1: Snapshots (Raw)
*   **Location**: `psi/memory/logs/`
*   **Trigger**: `/snapshot "Found a bug in migration"`
*   **Purpose**: Capture the moment.

## Layer 2: Retrospectives (Narrative)
*   **Location**: `psi/memory/retrospectives/`
*   **Trigger**: `/rrr`
*   **Purpose**: Tell the full story (Context + Reflection).

## Layer 3: Learnings (Patterns)
*   **Location**: `psi/memory/learnings/`
*   **Trigger**: `/distill "Migration Strategy"` or `/learn done`
*   **Purpose**: Extract reusable patterns (Context stripped).
*   **Retrieve**: `/wisdom search <query>`

## Layer 4: CLAUDE.md (DNA)
*   **Location**: `CLAUDE.md`
*   **Trigger**: Human Approval.
*   **Purpose**: Law. If it's here, we *must* do it.

## The Flow Logic
```
/learn (Gather)
    ↓
psi/learn/active/ (Research)
    ↓
/learn done (Route)
    ↓
┌───────────────────────────────────────┐
│  Archive  │  Learnings  │  Project   │
│  (ref)    │  (Matrix)   │  (docs)    │
└───────────────────────────────────────┘
    ↓
/wisdom (Retrieve)
    ↓
Apply to work
    ↓
New learnings → /learn (Loop)
```

## Knowledge Retrieval

| Command | Purpose |
|---------|---------|
| `/wisdom` | Browse knowledge index |
| `/wisdom search <query>` | Search across all knowledge |
| `/wisdom for <topic>` | Find relevant wisdom before starting work |
| `/wisdom apply <file>` | Mark wisdom as applied |

## The Principle
*   **Nothing is Lost**: If I don't know, I check `psi/memory` and `psi/learn`.
*   **Loop is Closed**: Gather → Store → Retrieve → Apply → Learn more.
*   **Noise Reduction**: We distillate before we legislate.
*   **Human Control**: You approve the upgrade to CLAUDE.md.
*   **Proactive Wisdom**: Oracle auto-suggests relevant knowledge.
