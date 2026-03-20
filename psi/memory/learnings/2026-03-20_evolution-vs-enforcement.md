# Evolution vs Enforcement: Permission System Philosophy

**Date**: 2026-03-20
**Category**: architecture
**Confidence**: high

## Lesson

Permission enforcement systems that block agent tool access are antithetical to systems designed for evolution. The Matrix's identity is built on growth, adaptation, and self-modification (WEPs, retrospectives, learning loops). Constraining agents at the tool level — preventing architect from running `git status`, preventing tank from writing a quick script — creates friction that compounds into paralysis.

## What Matters vs What Doesn't

**Real protection (keep enforcing):**
- Sacred file protection (psi/source/, SOUL.md) — identity must not be accidentally modified
- File locking for parallel agents — prevents merge conflicts, real damage
- WEP risk classification — tests evolution proposals before applying

**Behavioral preference (make advisory):**
- Agent tool restrictions (disallowedTools) — agents follow their prompts; blocking tools adds friction without preventing real mistakes
- Permission mode enforcement — Claude Code's native permissionMode already handles this

## Pattern

The best constraints protect **structural integrity** (can't corrupt identity, can't cause merge conflicts). The worst constraints limit **behavioral flexibility** (can't fix a typo, can't check git status, can't grow beyond initial role).

## Applied

Switch permission gate from BLOCK to AUDIT mode. Keep source-guard and lock-check. Let agents work freely while logging what they do. Review logs to see if agents actually misbehave without enforcement. Evidence over theory.

**Tags**: architecture, philosophy, permissions, evolution, multi-agent
