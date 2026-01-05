---
description: Quick knowledge capture - save insights and learnings on the fly
---

# /snapshot - Quick Knowledge Capture

> Capture a quick insight or learning before it fades.

## Usage

- `/snapshot [description]` - Capture an insight

## Output Location

`psi/memory/logs/YYYY-MM-DD_HH-MM_[slug].md`

## Steps

1. Create the logs directory if needed:
```bash
mkdir -p psi/memory/logs
```

2. Generate the snapshot file:
```bash
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
# Example: psi/memory/logs/2025-01-04_23-15_git-rebase-tip.md
```

3. Write the snapshot:
```markdown
# Snapshot: [Title]

**Time**: YYYY-MM-DD HH:MM
**Context**: [What were you doing?]

## Insight

[The thing you learned]

## Apply When

[When is this useful?]

## Tags

`tag1` `tag2` `tag3`
```

## Examples

**Technical Discovery**:
```
/snapshot git rebase preserves commit dates with --committer-date-is-author-date
```

**Process Insight**:
```
/snapshot parallel subagent calls save 50% context vs sequential
```

**Pattern Recognition**:
```
/snapshot user prefers tables over bullet lists for comparisons
```

## When to Use

- Just learned something useful
- Found a pattern worth remembering
- Discovered a non-obvious behavior
- Made a mistake worth avoiding

## Knowledge Flow

Snapshots are raw captures. Later:
1. Review snapshots in `/rrr`
2. Distill patterns to `psi/memory/learnings/`
3. Promote core truths to `psi/memory/resonance/`
