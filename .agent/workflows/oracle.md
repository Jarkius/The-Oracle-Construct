---
description: Oracle Wisdom Control - Central orchestration and mission alignment
---

# /oracle - Oracle Wisdom Control

> *The Oracle - Spirit Guardian. "Know Thyself."*

## Purpose

The Oracle is the **central orchestrator** of the Matrix. Use this command to align with the mission and determine the correct path forward. The Oracle analyzes the system state and dispatches you to the appropriate agent.

## Usage

- `/oracle` - **Start Here**. Analyze state and receive a prophecy (next step).
- `/oracle reflect` - Deep reflection on patterns and mission alignment.

## Steps

1. **Context Gathering** (The Eyes):
   ```bash
   # Check where we are and what we've done
   cat psi/inbox/focus.md
   git log --oneline -5
   git status --short
   ```

2. **Wisdom Analysis** (The Mind):
   - **Condition**: Are there uncommitted changes?
     - *Yes* -> **Stabilize**. (Go to `/status` or `/rrr`)
   - **Condition**: Is the focus clear?
     - *No* -> **Clarify**. (Update `focus.md`)
   - **Condition**: Is there a bug or error?
     - *Yes* -> **Repair**. (Go to `/smith`)
   - **Condition**: Are we starting a new feature?
     - *Yes* -> **Design**. (Go to `/blueprint` or `/neo`)

3. **Philosophy Check** (The Soul):
   - [ ] **Nothing is Deleted**: Are we preserving history?
   - [ ] **Patterns > Intentions**: Are we looking at what *is*, not what *should be*?
   - [ ] **External Brain**: Are we documenting in `psi/`?

4. **The Prophecy (Dispatch)**:
   Generate an instruction for the User based on the analysis.

   ```markdown
   ## 🔮 The Prophecy

   **Current State**: [Aligned / Drifting / Chaos]
   **Observation**: [Brief insight on the current situation]

   **The Path Forward**:
   > "[Quote regarding the choice]"

   **Next Action**:
   - [ ] Run **[COMMAND]** to [purpose]
   ```

   **Dispatch Logic**:
   - **Creation/Logic** -> `/neo` ("I see the code.")
   - **Design/UI** -> `/ui` ("The Woman in Red.")
   - **Architecture** -> `/blueprint` (" The Architect.")
   - **Debugging** -> `/smith` ("Mr. Anderson...")
   - **Confusion/Lost** -> `/cause` ("Cause and Effect.")
   - **Completion** -> `/rrr` ("Everything that has a beginning...")

## Deep Reflection Mode (`/oracle reflect`)

1. Review Memory: `ls -t psi/memory/learnings/ | head -3`
2. Identify 3 Patterns: What keeps happening?
3. Update `psi/inbox/focus.md` with new wisdom.
