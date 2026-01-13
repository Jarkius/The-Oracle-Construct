---
description: Knowledge management - research, learn, synthesize, apply
---

# /learn - Knowledge Management

> *"I can only show you the door. You're the one that has to walk through it." — Morpheus*

## Purpose

Manage the knowledge lifecycle: discover, research, synthesize, and apply learnings to projects or the Matrix itself.

**Architecture**: Morpheus (Sonnet) learns with understanding, Scribe (Opus) synthesizes wisdom. See ADR-003.

## Usage

```
/learn              # View inbox and active research
/learn add <url>    # Quick capture to inbox
/learn start <topic> # Begin active research
/learn done <topic>  # Complete research, decide destination
/learn repos        # List learning repos
/learn clone <url>  # Clone repo for learning
```

## Model Assignments

| Command | Agent | Model | Rationale |
|---------|-------|-------|-----------|
| `/learn` | Morpheus (voice) | main | Trivial listing |
| `/learn add` | — | main | One line append |
| `/learn start` | **Morpheus** | **sonnet** | Understanding scope |
| `/learn done` | **Scribe** | **opus** | Synthesis requires wisdom |

> *"Do not send a machine to do a thinker's job."*

## Knowledge Flow

```
DISCOVER        LEARN              SYNTHESIZE       APPLY
────────        ─────              ──────────       ─────

Internet  ──┐                                   ┌─→ Project (Architect?)
            │                                   │
Git Repos ──┼──→ Morpheus ──→ Scribe ──→ ──────┼─→ Matrix Learnings
            │    (Sonnet)     (Opus)            │
Ideas     ──┘                                   ├─→ Archive
                                                │
                                                └─→ The Source (Oracle gate)
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

**Model**: Main context (trivial)

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

**Model**: Main context (trivial)

1. Append to `psi/learn/inbox.md`:
```markdown
- [ ] <url> - Added YYYY-MM-DD
```

2. Confirm:
```bash
sh psi/matrix/voice.sh "Captured. Ready when you are." "Morpheus"
```

### Start Research (`/learn start <topic>`)

**Model**: Morpheus (Sonnet) — requires understanding

1. **Voice Greeting**:
```bash
sh psi/matrix/voice.sh "Beginning research. Let me understand the scope." "Morpheus"
```

2. **Spawn Morpheus (Sonnet)** for intelligent research setup:
```
Task:
  subagent_type: general-purpose
  model: sonnet
  prompt: |
    Starting research on: <topic>

    1. If URL provided, analyze what we're learning:
       - What is this? (library, framework, concept, tool)
       - Why is it relevant? (to Matrix or current projects)
       - What should we focus on?

    2. Create research file at psi/learn/active/<topic>.md:
       - Include context about why this matters
       - Set clear learning goals
       - Note any connections to existing knowledge

    3. If URL is a git repo, offer to clone:
       ghq get <url>
       ln -s ~/ghq/... psi/learn/repos/<name>

    Return:
    - Research file created
    - Learning goals identified
    - Connections to existing knowledge
```

3. **Announce**:
```bash
sh psi/matrix/voice.sh "Research initiated. The path is open." "Morpheus"
```

### Complete Research (`/learn done <topic>`)

**Model**: Scribe (Opus) — requires synthesis wisdom

1. **Voice Greeting**:
```bash
sh psi/matrix/voice.sh "Let me synthesize what we've learned." "Scribe"
```

2. **Spawn Scribe (Opus)** for synthesis:
```
Task:
  subagent_type: general-purpose
  model: opus
  prompt: |
    Synthesizing research on: <topic>

    1. Read psi/learn/active/<topic>.md

    2. Extract and distill:
       - Key insights (3-5 max)
       - Practical applications
       - Connections to Matrix philosophy
       - Warnings or gotchas

    3. Determine destination:
       - Archive: General reference, no immediate use
       - Learnings: Valuable pattern for future
       - Project: Applies to specific project
       - Source: Fundamental truth (requires Oracle gate)

    4. Prepare distilled output for chosen destination

    Return:
    - Summary of key insights
    - Recommended destination
    - Distilled content ready to write
```

3. **Ask Destination** (if not determined):
```
Where should this knowledge go?
- [A] Archive only (psi/learn/archive/)
- [L] Learnings (psi/memory/learnings/)
- [P] Project docs → suggest /architect review
- [S] The Source → requires Oracle blessing
```

4. **Conditional Gates**:

**IF destination == Project**:
```bash
sh psi/matrix/voice.sh "Consider running architect review for structural impact." "Scribe"
```
→ Suggest: `/architect review`

**IF destination == The Source**:
```bash
sh psi/matrix/voice.sh "This touches The Source. Oracle must bless this change." "Oracle"
```
→ Oracle (Opus) reviews alignment with philosophy
→ Only proceed with Oracle approval

5. **Write and Archive**:
- Write distilled content to destination
- Move original to `psi/learn/archive/YYYY-MM/<topic>.md`

6. **Announce**:
```bash
sh psi/matrix/voice.sh "Knowledge synthesized. The path continues." "Scribe"
```

### Clone Learning Repo (`/learn clone <url>`)

**Model**: Main context (trivial commands)

1. Clone via ghq:
```bash
ghq get <url>
```

2. Create symlink:
```bash
REPO_NAME=$(basename <url> .git)
ln -s ~/ghq/.../<repo> psi/learn/repos/$REPO_NAME
```

3. Confirm:
```bash
sh psi/matrix/voice.sh "Repository cloned and linked. Ready for study." "Morpheus"
```

### List Learning Repos (`/learn repos`)

**Model**: Main context (trivial)

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

## The Knowledge Funnel

```
psi/learn/inbox.md        Many quick captures
        ↓ (curate)
psi/learn/active/         Focused research (Morpheus - Sonnet)
        ↓ (complete)
psi/learn/archive/        Reference library
        ↓ (distill)        ← Scribe (Opus)
psi/memory/learnings/     Matrix wisdom (few, high quality)
        ↓ (evolve)         ← Oracle gate
psi/The_Source/           Matrix DNA (rare, sacred)
```

## Principles

1. **Capture freely** — Low friction inbox
2. **Learn intelligently** — Morpheus (Sonnet) understands what matters
3. **Synthesize wisely** — Scribe (Opus) extracts true wisdom
4. **Archive liberally** — Reference beats deletion
5. **Gate carefully** — Oracle guards The Source

## Voice

- **Morpheus** — Guides the learning journey (discover, start)
- **Scribe** — Announces synthesis (done)
- **Oracle** — Guards The Source (if destination is sacred)

## References

- ADR-003: Hierarchical Mind Architecture
- Morpheus Agent: `.claude/agents/morpheus.md`
- Scribe Agent: `.claude/agents/scribe.md`

ARGUMENTS: $ARGUMENTS
