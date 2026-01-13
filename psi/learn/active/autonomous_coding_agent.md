# Research: Autonomous Coding Agent Pattern

> Sources:
> - https://github.com/leonvanzyl/autonomous-coding
> - https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding
> Researched: 2026-01-08
> Agent: Morpheus

---

## What Is It?

A **two-agent pattern** for long-running autonomous coding that builds complete applications across multiple sessions using the Claude Agent SDK.

---

## Two-Agent Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SESSION 1                             │
│  ┌─────────────────────────────────────────────────┐    │
│  │           INITIALIZER AGENT                      │    │
│  │  Input: app_spec.txt                            │    │
│  │  Output: feature_list.json (200 test cases)     │    │
│  │  Tasks: Create specs, setup project, init git   │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    SESSION 2+                            │
│  ┌─────────────────────────────────────────────────┐    │
│  │            CODING AGENT                          │    │
│  │  Input: feature_list.json (picks up state)      │    │
│  │  Output: Implements features incrementally       │    │
│  │  Tasks: Code one feature, mark done, commit     │    │
│  │  Duration: 5-15 min per iteration               │    │
│  └─────────────────────────────────────────────────┘    │
│                    ↓ (auto-continues)                    │
│  [Repeat until all features complete]                   │
└─────────────────────────────────────────────────────────┘
```

---

## Key Patterns

| Pattern | Description | Value |
|---------|-------------|-------|
| **Stateful Continuity** | `feature_list.json` as source of truth | Cross-session progress |
| **Incremental Dev** | One feature per iteration | Distributes long runtime |
| **Git Integration** | Commit per feature | Audit trail |
| **Self-Managing** | Auto-continues with 3s delay | Minimal intervention |
| **Pausable** | Ctrl+C to pause, resume anytime | Flexible operation |
| **Fresh Context** | Each session = new context window | Avoids token limits |

---

## Security Model

**Defense-in-Depth:**
1. OS-level sandbox
2. Filesystem restricted to project dir only
3. Bash command allowlist (blocks unlisted commands)

**Allowed Commands:**
- File: `ls`, `cat`, `head`, `tail`, `wc`, `grep`
- Node: `npm`, `node`
- Git: `git`
- Process: `ps`, `lsof`, `sleep`, `pkill`

---

## Relevance to Our Matrix

### HIGHLY USEFUL Patterns to Adopt:

1. **Two-Agent Pattern**
   - Architect/Neo split mirrors this
   - Architect = Initializer (creates specs, ADRs)
   - Neo = Coding Agent (implements features)

2. **feature_list.json Concept**
   - We could use `psi/specs/stories/feature_list.json`
   - Track completion status per feature
   - Source of truth across sessions

3. **Auto-Continuation**
   - Add to `/yolo` mode
   - 3-second delay between iterations
   - Continue until feature_list complete

4. **Fresh Context Strategy**
   - Each `/neo` session reads feature_list
   - Picks up where left off
   - Avoids context bloat

5. **Security Allowlist**
   - Useful for `/yolo` mode safety
   - Only permit known-safe commands

### Already Have (Don't Need):

- Git integration (already do this)
- Progress tracking (psi/inbox/focus.md)
- Session management (retrospectives)

---

## Implementation Recommendation

### Create `/feature-list` command:

```markdown
# /feature-list - Feature Progress Tracker

## Usage
/feature-list init [spec-file]    # Create from spec
/feature-list status              # Show progress
/feature-list next                # Get next pending feature
/feature-list done [feature-id]   # Mark complete

## File: psi/specs/stories/feature_list.json

{
  "project": "CIS Dashboard",
  "features": [
    {"id": 1, "name": "Login page", "status": "done", "commit": "abc123"},
    {"id": 2, "name": "Dashboard layout", "status": "in_progress"},
    {"id": 3, "name": "User list", "status": "pending"}
  ]
}
```

### Update `/yolo` with auto-continuation:

```markdown
## Auto-Continue Mode
- Read feature_list.json
- Implement next pending feature
- Mark done, commit
- Wait 3 seconds
- Continue until all done or max iterations
```

---

## Verdict

**YES, HIGHLY USEFUL.**

The two-agent pattern validates our Architect → Neo workflow. The feature_list.json concept fills a gap we have - tracking feature completion across sessions.

**Next Steps:**
1. Create `/feature-list` command
2. Update `/yolo` with auto-continuation
3. Add security allowlist to autonomous modes

---

## Sources

- [leonvanzyl/autonomous-coding](https://github.com/leonvanzyl/autonomous-coding)
- [anthropics/claude-quickstarts](https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding)
- [Claude Agent SDK docs](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)

---

## Status: ACTIONABLE

Ready for implementation. Recommend creating `/feature-list` command next session.
