---
description: Knowledge management - research, learn, synthesize, apply
---

# /learn - Knowledge Management

> *"I can only show you the door. You're the one that has to walk through it." — Morpheus*

## Purpose

Manage the knowledge lifecycle: discover, research, synthesize, and apply learnings to projects or the Matrix itself.

## Usage

```
/learn              # View inbox and active research
/learn add <url>    # Quick capture to inbox
/learn start <topic> # Begin active research
/learn done <topic>  # Complete research, decide destination
/learn repos        # List learning repos
/learn clone <url>  # Clone repo for learning
```

## Knowledge Flow

```
DISCOVER        RESEARCH         SYNTHESIZE       APPLY
────────        ────────         ──────────       ─────

Internet  ──┐                                 ┌─→ Project
Git Repos ──┼──→ learn/active/ ──→ Archive ──┼─→ Matrix
Ideas     ──┘                                 └─→ Discard
```

## File Structure

```
psi/learn/
├── inbox.md          # Quick capture (URLs, ideas)
├── backlog.md        # Prioritized learning queue
├── active/           # Currently researching
│   └── <topic>.md
├── repos/            # Symlinks to learning repos
│   └── <name> → ~/ghq/...
└── archive/          # Completed research
    └── YYYY-MM/
        └── <topic>.md
```

## Workflows

### View Status (`/learn`)

1. **Voice Greeting**:
```bash
sh psi/matrix/voice.sh "Let me show you the paths of knowledge." "Morpheus"
```

2. **Display Overview**:
```markdown
## Knowledge Status

### Inbox ([count] items)
[list from inbox.md]

### Active Research ([count] topics)
[list from active/]

### Learning Repos ([count] repos)
[list from repos/]

### Recently Archived
[last 3 from archive/]
```

### Quick Capture (`/learn add <url>`)

1. Append to `psi/learn/inbox.md`:
```markdown
- [ ] <url> - Added YYYY-MM-DD
```

2. Confirm:
```bash
sh psi/matrix/voice.sh "Captured. Ready when you are." "Morpheus"
```

### Start Research (`/learn start <topic>`)

1. Create `psi/learn/active/<topic>.md`:
```markdown
# Research: <Topic>

**Started**: YYYY-MM-DD
**Source**: [url or repo]
**Goal**: [what you want to learn]

---

## Notes

[your notes here]

---

## Key Insights

-

---

## Applies To

- [ ] Project: ____________
- [ ] Matrix: ____________
- [ ] Archive only (reference)
```

2. If URL is a git repo, offer to clone:
```bash
ghq get <url>
ln -s ~/ghq/... psi/learn/repos/<name>
```

3. Announce:
```bash
sh psi/matrix/voice.sh "Research initiated. The path is open." "Morpheus"
```

### Complete Research (`/learn done <topic>`)

1. Read `psi/learn/active/<topic>.md`

2. Ask destination:
```
Where should this knowledge go?
- [P] Project docs (psi/projects/<name>/docs/)
- [M] Matrix learnings (psi/memory/learnings/)
- [A] Archive only (psi/learn/archive/)
- [D] Discard (not useful)
```

3. Based on choice:

**Project**:
- Extract insights to `psi/projects/<name>/docs/<topic>.md`
- Move original to archive

**Matrix**:
- Distill to `psi/memory/learnings/<topic>.md`
- Move original to archive

**Archive**:
- Move to `psi/learn/archive/YYYY-MM/<topic>.md`

**Discard**:
- Delete or move to archive with `[DISCARDED]` prefix

4. Announce:
```bash
sh psi/matrix/voice.sh "Knowledge synthesized. The path continues." "Morpheus"
```

### Clone Learning Repo (`/learn clone <url>`)

1. Clone via ghq:
```bash
ghq get <url>
```

2. Create symlink:
```bash
# Extract repo name from URL
REPO_NAME=$(basename <url> .git)
ln -s ~/ghq/.../<repo> psi/learn/repos/$REPO_NAME
```

3. Confirm:
```bash
sh psi/matrix/voice.sh "Repository cloned and linked. Ready for study." "Morpheus"
```

### List Learning Repos (`/learn repos`)

```bash
ls -la psi/learn/repos/
```

Display as table:
```markdown
## Learning Repos

| Name | Source | Added |
|------|--------|-------|
| piper | github.com/rhasspy/piper | 2026-01-12 |
```

## Research File Template

```markdown
# Research: [Topic]

**Started**: YYYY-MM-DD
**Status**: Active | Complete | Archived
**Source**: [URL or description]
**Goal**: [What you want to learn]

---

## Context

[Why are you researching this?]

---

## Notes

[Your notes, observations, code snippets]

---

## Key Insights

1. [Insight 1]
2. [Insight 2]
3. [Insight 3]

---

## Applies To

- [ ] Project: [which project?]
- [ ] Matrix: [which aspect?]
- [ ] Archive only

---

## Next Steps

- [ ] [Action item]

---

## References

- [Link 1]
- [Link 2]
```

## The Knowledge Funnel

```
psi/learn/inbox.md        Many quick captures
        ↓ (curate)
psi/learn/active/         Focused research
        ↓ (complete)
psi/learn/archive/        Reference library
        ↓ (distill)
psi/memory/learnings/     Matrix wisdom (few, high quality)
        ↓ (evolve)
psi/The_Source/           Matrix DNA (rare, sacred)
```

## Principles

1. **Capture freely** — Low friction inbox
2. **Research intentionally** — One topic at a time
3. **Synthesize ruthlessly** — Extract only what matters
4. **Archive liberally** — Reference beats deletion
5. **Distill sparingly** — Only true wisdom enters memory
6. **Evolve rarely** — The Source is sacred

## Voice

Morpheus guides the learning journey. Calm, encouraging, showing the way.

ARGUMENTS: $ARGUMENTS
