# Cross-Agent Handoffs (Phase 7.5)

> *"I can only show you the door." — Morpheus*

This directory stores structured handoff artifacts when one agent passes work to another.

## Format

Each handoff is a markdown file: `YYYY-MM-DD_from-to_topic.md`

## Structure

```markdown
# Handoff: [From Agent] → [To Agent]
**Date**: YYYY-MM-DD HH:MM
**Task**: One-sentence description

## Context
Why this task exists and what led to it.

## Key Decisions Made
- Decision 1 (and why)
- Decision 2 (and why)

## Files Changed / Relevant
- path/to/file.ts — what was done
- path/to/other.md — reference material

## Watch For
- Known risks or edge cases
- Constraints the receiving agent must respect

## Tests / Verification
- How to verify the work is correct
- What tests to run

## Next Steps
1. Specific action item
2. Specific action item
```

## Usage

Handoffs are created by:
- The `/handoff` command (Trinity → Neo design handoffs)
- The `/unplug` command (session-end handoffs)
- Any agent recognizing they need a different agent's skills
