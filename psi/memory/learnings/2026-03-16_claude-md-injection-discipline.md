# Injection Discipline: What Goes In CLAUDE.md

**Date**: 2026-03-16
**Context**: CLAUDE.md grew to 44k chars (1,091 lines), exceeding the 40k warning threshold
**Confidence**: High

## Key Learning

Auto-injected files consume context budget on EVERY turn. Content must be strictly limited to behavioral rules — not reference docs, not system manuals, not configs.

Solution: behavioral rules in auto-injected files (CLAUDE.md, SOUL.md, USER.md, BOOT.md), reference material in on-demand files (SYSTEMS.md), philosophy in The Source.

## The Pattern

- Does agent need this EVERY turn? → CLAUDE.md
- Does agent need this for a specific system? → SYSTEMS.md
- Is this philosophy/wisdom? → The Source
- Already in SOUL.md/USER.md/BOOT.md? → Remove from CLAUDE.md

## Why This Matters

44k chars = ~5% context window consumed before any work. 92% reduction (44k→4k) improves every future session.

## Tags

`architecture`, `context-management`, `injection`, `CLAUDE.md`, `performance`
