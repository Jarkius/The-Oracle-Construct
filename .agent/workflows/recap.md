---
description: Session continuity - recap where we left off with wisdom and clarity
---

# /recap - Session Recap

> *"Remember... remember what you were doing." — The Oracle*

## Purpose

Bridge between sessions. Restores context, identifies patterns, and determines the next action. Fast, voiced, actionable.

**Architecture**: Tank (Haiku) gathers data, Oracle (Opus) synthesizes wisdom. See ADR-003.

## Usage

- `/recap` - Full recap with voice and path forward (default: 4 items)
- `/recap [n]` - Show n items (e.g., `/recap 7` for 7 items)

## Arguments

Parse `$ARGUMENTS` for optional count:
```
COUNT=${ARGUMENTS:-4}  # Default to 4 if no argument
```

## Steps

### 1. Voice Greeting (Oracle)
```bash
sh psi/matrix/voice.sh "Let me recall where we left off..." "Oracle"
```

### 2. Spawn Tank (Haiku) to Gather Context

Use Task tool to spawn a Haiku agent for mechanical gathering:

```
Task:
  subagent_type: Explore
  model: haiku
  prompt: |
    Gather session context for recap (COUNT=$COUNT items):

    Run these commands:
    1. ./psi/active/get_focus.sh 2>/dev/null || echo "No focus set"
    2. git log --oneline -$COUNT
    3. git status --short
    4. git diff --stat 2>/dev/null | tail -3
    5. ls -t psi/memory/retrospectives/**/*.md 2>/dev/null | head -$COUNT

    For each retrospective file found, extract:
    - Date/Time from filename (e.g., 23.00_source_renewal.md → 23:00)
    - Focus from **Focus**: line
    - Check if "For Next Session" has unchecked items

    Return structured summary:
    ```
    FOCUS: <current focus or "none">
    FOCUS_SOURCE: <retrospective filename>

    COMMITS:
    - <hash> <message>
    - ...

    STATE: <clean | N uncommitted files>
    DIFF_STATS: <summary of changes>

    RETROSPECTIVES:
    | Date | Time | Focus | Status |
    |------|------|-------|--------|
    | ... | ... | ... | closed/wip/open |

    PATTERNS:
    <any recurring themes or lessons from retrospectives>
    ```
```

### 3. Oracle Synthesizes (Main Context)

Receive Tank's structured summary and apply wisdom:

**Health Check:**
| Check | Status |
|-------|--------|
| Uncommitted changes? | Yes/No (from STATE) |
| Focus clear? | Yes/No (from FOCUS) |
| Recent retrospective? | Yes/No (from RETROSPECTIVES) |

**Health**: Good / Needs Attention / Critical

**Path Analysis:**
```
IF uncommitted changes exist:
   → Path: STABILIZE (commit or stash first)

ELSE IF focus is unclear:
   → Path: CLARIFY (run /rrr to create retrospective)

ELSE IF bug/error mentioned in focus:
   → Path: REPAIR (go to /smith)

ELSE IF new feature in focus:
   → Path: BUILD (go to /neo or /architect)

ELSE:
   → Path: CONTINUE (resume last task)
```

### 4. Generate Output

```markdown
## Session Recap - [Date]

**Last Session**: [date] - [summary from focus]
**Focus**: [current task/issue]
**Health**: [Good/Attention/Critical] - [reason]

---

### Recent Memory ($COUNT Sessions)

| Date | Time | Focus | Status |
|------|------|-------|--------|
| ... | ... | ... | ... |

### Recent Commits ($COUNT)
- [commit 1]
- [commit 2]
- ...

**State**: [Clean | X uncommitted changes]

---

### Patterns from the Past

> "[Pattern observation from Tank's summary]"

---

### The Path Forward

**Condition**: [what was detected]
**Pattern Influence**: [how past pattern affects this path]
**Action**: [what to do next]
**Command**: [suggested command if applicable]
```

### 5. Voice Summary (Oracle)
```bash
sh psi/matrix/voice.sh "[Last session]. [Current focus]. [Path forward]." "Oracle"
```

## Token Efficiency

| Component | Model | Why |
|-----------|-------|-----|
| Gathering (git, files) | Haiku | Mechanical, cheap |
| Synthesis (wisdom) | Opus | Reasoning, expensive |

**Estimated savings**: ~85% fewer tokens for search operations.

## Comparison

| Command | Purpose | Speed | Voice | Depth |
|---------|---------|-------|-------|-------|
| `/recap` | Quick context + path | **Fast** | Yes | Light |
| `/health` | System diagnostics | Medium | No | Data |
| `/oracle` | Deep wisdom + dispatch | Slow | Yes | Deep |

## When to Use

- **Start of session**: First command to run
- **After break**: Returning to work after interruption
- **Context lost**: When you forget what you were doing
- **Quick alignment**: Need path forward without deep analysis

## References

- ADR-003: Hierarchical Mind Architecture
- Tank Agent: `.claude/agents/tank.md`
- Oracle Keeper: `.claude/agents/oracle-keeper.md`
