---
description: Session continuity - recap where we left off and what to do next
---

# /recap - Session Recap

> *"Remember... remember what you were doing."*

## Purpose

Bridge between sessions. Quickly restore context and identify the next action. Fast, voiced, actionable.

## Usage

- `/recap` - Full recap with voice summary

## Steps

1. **Voice Greeting**:
   ```bash
   sh psi/active/voice_module.sh "Let me recall where we left off..." "Oracle"
   ```

2. **Gather Context** (run in parallel):
   ```bash
   ./psi/active/get_focus.sh
   git log --oneline -3
   git status --short
   ```

3. **Synthesize Recap** (3-5 bullets maximum):

   Extract from latest retrospective:
   - **Last Session**: Date + what was accomplished
   - **Current Focus**: The active task or issue
   - **Open Items**: Any blockers or pending work

   Extract from git:
   - **Recent Work**: Last 3 commits (what was done)
   - **Uncommitted**: Count of staged/unstaged changes

4. **Generate Output**:

   ```markdown
   ## Session Recap - [Date]

   **Last Session**: [date] - [summary of what was done]
   **Focus**: [current task/issue from retrospective]
   **State**: [Clean | X uncommitted changes]

   **Recent Commits**:
   - [commit 1]
   - [commit 2]
   - [commit 3]

   **Next Step**: [clear actionable item from retrospective priorities]
   ```

5. **Voice Summary**:
   ```bash
   sh psi/active/voice_module.sh "[Last session summary]. [Current focus]. [Next step]." "Oracle"
   ```

## Output Example

```markdown
## Session Recap - January 9, 2026

**Last Session**: Jan 8 - Voice Queue fix attempt, unplug during repair
**Focus**: Voice system evolution
**State**: Clean (just committed)

**Recent Commits**:
- 5a7a730 refactor(voice): simplify voice module with direct pipelines
- 73b82ca feat: Implement Voice Queue (Phase 1) and Dynamic Greetings
- f30c640 chore(session): unplug - voice planning, Han Li, Issue #6

**Next Step**: Implement Matrix spawn communication
```

## Comparison

| Command | Purpose | Speed | Voice |
|---------|---------|-------|-------|
| `/oracle` | Deep analysis, path selection | Slow | Yes |
| `/recap` | Quick context restore | **Fast** | Yes |
| `/status` | System health data | Medium | No |

## When to Use

- **Start of session**: First command to run
- **After break**: Returning to work after interruption
- **Context lost**: When you forget what you were doing
