---
description: Knowledge retrieval - browse, search, and apply stored wisdom
---

# /wisdom - Knowledge Retrieval

> *"Everything that has a beginning has an end. I see the end coming." — The Oracle*

## Purpose

Browse, search, and apply stored knowledge. The retrieval side of the learning loop.

**Philosophy**: Knowledge gathered must be accessible. Wisdom unused is wisdom lost.

## Usage

```
/wisdom                    # Show knowledge overview
/wisdom search <query>     # Search across all knowledge
/wisdom for <topic>        # Find wisdom relevant to a topic
/wisdom list [area]        # List knowledge in area (learnings/archive/projects)
/wisdom apply <file>       # Mark wisdom as applied to current work
/wisdom stats              # Show knowledge statistics
```

## Knowledge Locations

```
psi/
├── memory/learnings/      # Matrix wisdom (distilled, high-value)
├── learn/archive/         # Research archive (reference)
├── projects/*/docs/       # Project-specific knowledge
└── memory/adr/            # Architecture decisions
```

## Workflows

### Overview (`/wisdom`)

1. **Voice Greeting**:
```bash
sh psi/matrix/voice.sh "Let me show you what we know." "Oracle"
```

2. **Gather Stats**:
```bash
LEARNINGS=$(ls psi/memory/learnings/*.md 2>/dev/null | wc -l)
ARCHIVE=$(find psi/learn/archive -name "*.md" 2>/dev/null | wc -l)
ADR=$(ls psi/memory/adr/*.md 2>/dev/null | wc -l)
PROJECT_DOCS=$(find psi/projects/*/docs -name "*.md" 2>/dev/null | wc -l)
```

3. **Display Overview**:
```markdown
## Knowledge Overview

| Area | Count | Location |
|------|-------|----------|
| Matrix Learnings | $LEARNINGS | psi/memory/learnings/ |
| Research Archive | $ARCHIVE | psi/learn/archive/ |
| Architecture Decisions | $ADR | psi/memory/adr/ |
| Project Docs | $PROJECT_DOCS | psi/projects/*/docs/ |

### Recent Learnings
[list last 5 from psi/memory/learnings/]

### Recent Archive
[list last 5 from psi/learn/archive/]

Use `/wisdom search <query>` to find specific knowledge.
```

### Search (`/wisdom search <query>`)

1. **Search across all knowledge**:
```bash
# Search learnings
grep -ril "<query>" psi/memory/learnings/ 2>/dev/null

# Search archive
grep -ril "<query>" psi/learn/archive/ 2>/dev/null

# Search ADRs
grep -ril "<query>" psi/memory/adr/ 2>/dev/null

# Search project docs
grep -ril "<query>" psi/projects/*/docs/ 2>/dev/null
```

2. **Display Results**:
```markdown
## Search Results: "<query>"

### Matrix Learnings
- [file1.md](psi/memory/learnings/file1.md) - "matching context..."
- [file2.md](psi/memory/learnings/file2.md) - "matching context..."

### Research Archive
- [file3.md](psi/learn/archive/2026-01/file3.md) - "matching context..."

### Architecture Decisions
- [ADR-001.md](psi/memory/adr/ADR-001.md) - "matching context..."

[X] files found matching "<query>"
```

### Topic Relevance (`/wisdom for <topic>`)

1. **Find relevant wisdom for a topic** (useful before starting work):
```bash
# Search for topic keywords
grep -ril "<topic>" psi/memory/learnings/ psi/learn/archive/ psi/memory/adr/ 2>/dev/null
```

2. **Display with Context**:
```markdown
## Wisdom for: <topic>

### Highly Relevant (Matrix Learnings)
These are distilled insights that may directly apply:
- [relevant-file.md] - "key insight preview..."

### Reference Material (Archive)
Research that explored this topic:
- [archive-file.md] - "context preview..."

### Related Decisions (ADR)
Architectural decisions that touch this:
- [ADR-XXX.md] - "decision summary..."

---

**Recommendation**: Review [most-relevant.md] before starting work.
```

### List by Area (`/wisdom list [area]`)

**Areas**: `learnings`, `archive`, `adr`, `projects`

```markdown
## Learnings
| File | Created | Tags |
|------|---------|------|
| voice-patterns.md | 2026-01-10 | voice, piper, tts |
| hook-patterns.md | 2026-01-11 | hooks, claude |

## Archive (2026-01)
| File | Topic | Source |
|------|-------|--------|
| sanctum-research.md | Auth | Laravel docs |
| piper-training.md | TTS | GitHub |
```

### Apply Wisdom (`/wisdom apply <file>`)

Mark a wisdom file as applied to current work:

1. **Read the file**
2. **Ask where it was applied**:
```
Where did you apply this wisdom?
- Project: [name]
- Matrix component: [name]
- General reference
```

3. **Update knowledge-index.md**:
```markdown
## Recently Applied
| Wisdom | Applied To | Date |
|--------|------------|------|
| <file> | <destination> | YYYY-MM-DD |
```

4. **Confirm**:
```bash
sh psi/matrix/voice.sh "Wisdom applied and recorded." "Oracle"
```

### Statistics (`/wisdom stats`)

```markdown
## Knowledge Statistics

### Volume
- Total knowledge files: XX
- Matrix learnings: XX
- Research archive: XX
- Project docs: XX
- ADRs: XX

### Activity
- Last learning added: YYYY-MM-DD
- Last archive added: YYYY-MM-DD
- Most active topic: [topic]

### Application
- Wisdom applied this month: XX
- Most applied: [file]

### Health
- Orphan research (never archived): XX
- Stale learnings (>30 days, never applied): XX
```

## Auto-Suggest Integration (Option C)

When `/oracle` runs, it should check for relevant wisdom:

```markdown
### Relevant Wisdom

Before proceeding, you may want to review:
- [related-learning.md] - "preview..."

Use `/wisdom for <topic>` to explore more.
```

## Knowledge Index

Maintain `psi/memory/knowledge-index.md` as a browsable directory:

```markdown
# Knowledge Index

## By Topic

### Authentication
- [Laravel Patterns](learnings/laravel-patterns.md)
- [JWT vs Session](../learn/archive/2026-01/jwt-comparison.md)

### Voice/TTS
- [Piper Best Practices](learnings/voice-patterns.md)

### Architecture
- [GHQ + Symlinks](adr/ADR-002-ghq-project-architecture.md)
- [Multi-Agent Patterns](adr/ADR-001-multi-agent-patterns.md)

## Recently Applied
| Wisdom | Applied To | Date |
|--------|------------|------|
| ... | ... | ... |

## Recently Added
| File | Area | Date |
|------|------|------|
| ... | ... | ... |
```

## The Complete Loop

```
/learn              →  Gather knowledge
/learn done         →  Route to archive/learnings
/wisdom             →  Browse what we know
/wisdom for <topic> →  Find relevant wisdom
/wisdom apply       →  Mark as applied
                    →  Back to /learn (new insights)
```

## Voice

Oracle guides the wisdom retrieval. Wise, reflective, connecting past to present.

ARGUMENTS: $ARGUMENTS
