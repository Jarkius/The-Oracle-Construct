# Lesson: Platform Abstraction Debt & Monitoring-Action Gap

**Date**: 2026-03-23
**Source**: System plumbing session — task sync, self-heal, control center fixes
**Tags**: windows, platform, python, monitoring, self-heal, chromadb

## Pattern 1: Platform Abstraction is Debt

Every bash hook that hardcodes `python3` breaks on Windows. The `python` command exists but the Windows Store alias fails in subshells. MSYS paths (`/c/...`) don't work in Python's `open()`.

**Fix applied**: Explicit python detection with fallback path + piped stdin pattern instead of file path arguments.

**Systemic fix needed**: A shared `lib-python.sh` that all hooks source, providing `$PY` and `win_path()` helper.

## Pattern 2: Monitoring Without Action is Noise

ChromaDB emitted 41 `chromadb:fail` events. No agent acted on them. The PULSE event system captured the signal perfectly — but the dispatch rules, self-heal, and heartbeat had no rule for this event type.

**Detection without remediation trains operators to ignore signals.**

**Fix applied**: Added ChromaDB check to `pulse-self-heal.sh` with auto-restart attempt. Added toggle to control center UI.

## Pattern 3: Data Corruption Hides in the Tail

600 of 605 events in `events.jsonl` had malformed JSON (triple `}}}`). The last 5 events were clean, so `tail -5` looked fine. Only full-file validation revealed the problem.

**Always validate the full dataset, not just recent entries.**
