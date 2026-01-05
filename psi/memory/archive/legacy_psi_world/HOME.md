# psi/ - AI Brain

> Navigation hub for the 5-pillar structure

## Pillars

| Pillar | Question | Content |
|--------|----------|---------|
| `active/` | What am I researching? | Current investigations |
| `inbox/` | Who am I talking to? | Communication, handoffs |
| `memory/` | What do I remember? | Knowledge base |
| `writing/` | What am I writing? | Drafts, articles |
| `lab/` | What am I experimenting with? | Experiments, POCs |

## Memory Structure

```
memory/
├── retrospectives/   # Session narratives (by date)
├── learnings/        # Extracted patterns
├── logs/             # Quick snapshots
└── resonance/        # Core identity, soul
```

## Knowledge Flow

```
active/context -> memory/logs -> memory/retrospectives -> memory/learnings -> memory/resonance
(research)        (snapshot)     (session)               (patterns)          (soul)
```

## Usage

### Starting a Session
1. Check `inbox/focus.md` for current state
2. Update focus with new task
3. Begin work

### During Work
- Use `/snapshot` to capture quick insights
- Append to `memory/logs/` as needed

### Ending a Session
1. Run `/rrr` to create retrospective
2. Update `inbox/focus.md`
3. Note any handoffs needed

### Periodic Review
1. Review recent retrospectives
2. Extract patterns to `learnings/`
3. Promote core truths to `resonance/`
