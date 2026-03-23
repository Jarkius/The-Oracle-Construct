# Lesson: Cascading Bootstrap Failures Hide Behind Silence

**Date**: 2026-03-23
**Source**: Windows awakening session — voice + services all offline
**Tags**: debugging, observability, platform, root-cause-analysis

## The Pattern

When the monitoring system itself is broken, you get **no alerts** — which looks identical to **no problems**. The absence of evidence is not evidence of absence.

## What Happened

The Phase 2 restructure moved 111 files but didn't update 4 hardcoded startup commands in `matrix-services.sh`. Every service failed with "Module not found." Because heartbeat never started, no health checks ran. Because the EVENT_WRITER path was also wrong, even if heartbeat had started, it couldn't write events. The entire nervous system was severed.

For a full week, no alerts fired. The system appeared healthy because the thing that would report sickness was itself sick.

## The Fix

1. Always check **actual error logs** (daemon-logs/heartbeat.log had the answer)
2. After any file restructure, verify **all startup scripts** reference correct paths
3. Use variables (`$HEARTBEAT_SCRIPT`) not hardcoded paths in startup commands
4. Add a "monitoring health" meta-check — does the monitor itself work?

## Cross-Platform Lesson

The TypeScript code was mostly fine. All breakage was in **shell scripts** — hardcoded `/tmp/`, `afplay` (macOS-only), `python3` (Windows Store alias), `bc` (not on Windows). Test the bash, not just the TypeScript.
