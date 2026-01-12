---
description: Session continuity - recap where we left off with wisdom and clarity
---

# /recap - Session Recap

> *"Remember... remember what you were doing." — The Oracle*

## Purpose

Bridge between sessions. Restores context, identifies patterns, and determines the next action. Fast, voiced, actionable.

**Philosophy**: Combines Oracle's wisdom (path selection) with Architect's clarity (structure analysis).

## Usage

- `/recap` - Full recap with voice and path forward (default: 4 items)
- `/recap [n]` - Show n items (e.g., `/recap 7` for 7 items)

## Arguments

Parse `$ARGUMENTS` for optional count:
```
COUNT=${ARGUMENTS:-4}  # Default to 4 if no argument
```

## Steps

### 1. Voice Greeting
```bash
sh psi/matrix/voice.sh "Let me recall where we left off..." "Oracle"
```

### 2. Gather Context (parallel)
```bash
./psi/active/get_focus.sh
git log --oneline -$COUNT
git status --short
git diff --stat 2>/dev/null | tail -3
```

### 3. Synthesize Recap

Extract from latest retrospective:
- **Last Session**: Date + what was accomplished
- **Current Focus**: The active task or issue
- **Open Items**: Any blockers or pending work

Extract from git:
- **Recent Work**: Last 3-5 commits
- **Uncommitted**: Count of staged/unstaged changes

### 4. Quick Health Check (from Architect)

| Check | Status |
|-------|--------|
| Uncommitted changes? | Yes/No |
| Focus clear? | Yes/No |
| Recent retrospective? | Yes/No |

**Health**: Good / Needs Attention / Critical

### 5. Memory Timeline (from Scribe)

Display recent retrospectives as a table with dates and inferred status.

```bash
# Get last $COUNT retrospectives
ls -t psi/memory/retrospectives/**/*.md 2>/dev/null | head -$COUNT
```

**Status Inference:**
- `✅ closed` - Has "For Next Session" with all items checked OR no open items
- `🔄 wip` - Created today with unchecked items
- `📋 open` - Has unchecked "For Next Session" items from past sessions

**Output Format:**
```markdown
### Recent Memory ($COUNT Sessions)

| Date | Time | Focus | Status |
|------|------|-------|--------|
| Jan 12 | 14:08 | Voice Lifecycle | ✅ closed |
| Jan 11 | 23:00 | Source Renewal | ✅ closed |
| ... | ... | ... | ... |
```

Parse each file:
- **Date/Time**: From filename (e.g., `23.00_source_renewal.md` → Jan 11, 23:00)
- **Focus**: From `**Focus**:` line in frontmatter
- **Status**: Inferred from "For Next Session" section

### 5b. Pattern Check

Look back before moving forward. Extract from recent retrospectives:
- **Recurring Blockers**: What kept getting in the way?
- **Successful Patterns**: What worked well?
- **Lessons Learned**: Key insights from AI Diary sections

Quick pattern summary (1-2 sentences):
> "Pattern: [what keeps happening] → Consider: [how it affects today's path]"

If no patterns found or retrospectives are sparse, skip this section.

### 6. Path Analysis (from Oracle)

Determine the path based on **conditions + patterns**:

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

**Pattern Influence** (from Step 5):

After determining the base path, check if patterns modify it:

```
IF pattern shows recurring blocker for this type of task:
   → Add WARNING: "[blocker] has blocked similar work before"
   → Suggest: Address blocker first or plan around it

IF pattern shows successful approach:
   → Add INSIGHT: "[approach] worked well for similar tasks"
   → Suggest: Consider reusing that approach

IF pattern shows lesson learned:
   → Add REMINDER: "[lesson]"
   → Apply lesson to current path
```

The path forward should acknowledge the past:
> "Path: [ACTION] | Pattern: [relevant insight from past]"

### 7. Generate Output

```markdown
## Session Recap - [Date]

**Last Session**: [date] - [summary]
**Focus**: [current task/issue]
**Health**: [Good/Attention/Critical] - [reason]

**Recent Commits**:
- [commit 1]
- [commit 2]
- [commit 3]

**State**: [Clean | X uncommitted changes]

---

### Patterns from the Past

> "[Pattern observation]"

---

### The Path Forward

**Condition**: [what was detected]
**Pattern Influence**: [how past pattern affects this path]
**Action**: [what to do next]
**Command**: [suggested command if applicable]
```

### 8. Voice Summary
```bash
sh psi/matrix/voice.sh "[Last session]. [Current focus]. [Path forward]." "Oracle"
```

## Output Example

```markdown
## Session Recap - January 12, 2026

**Last Session**: Jan 11 - Source Renewal complete
**Focus**: Voice lifecycle management
**Health**: Good - all committed, focus clear

### Recent Memory (4 Sessions)

| Date | Time | Focus | Status |
|------|------|-------|--------|
| Jan 11 | 23:00 | Source Renewal | ✅ closed |
| Jan 11 | 22:35 | Bash Guard | ✅ closed |
| Jan 11 | 22:30 | Source Protection | ✅ closed |
| Jan 11 | 22:00 | Unplug | ✅ closed |

### Recent Commits (4)
- e042196 feat(voice): Add voice server lifecycle
- 9f8a8bd docs(memory): Source Renewal retrospective
- a77783e perf(soul): Skip binary checksums
- de25214 chore(soul): Update manifest for soul-v1.1

**State**: Clean

---

### Patterns from the Past

> "Simple > Complex - skipping checksums beat parallel spawns"

---

### The Path Forward

**Condition**: Focus clear, no blockers
**Pattern Influence**: Favor simple solutions over complex ones
**Action**: Continue with current path or choose new direction
**Command**: `/oracle` for guidance or `/unplug` to exit
```

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
