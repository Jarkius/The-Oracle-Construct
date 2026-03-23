# Handoff: Windows Awakening + Recall Pipeline Fix

**Date**: 2026-03-23 14:10 GMT+7

## What We Did
- Fixed cascading bootstrap failure (4 wrong service paths in matrix-services.sh)
- Fixed EVENT_WRITER paths in heartbeat + gateway (pulse/ subdir didn't exist)
- Full Piper TTS on Windows — 10 voices, same ONNX models as macOS
- Audio effects working: Smith Tron loop, Tank jump sound, Mainframe Flamenco, System KITT
- Adaptive System voice (reads time, tasks, health before speaking)
- Platform abstraction: platform.ts, lib-platform.sh, /tmp/ → $MATRIX_TMPDIR
- DB migrated to data/agents.db
- Task registry cleaned (0008-0013 → completed)
- Observability: TS PULSE event writer, ChromaDB alerts, voice in watchdog
- Recall pipeline fixed: recap-rich.ts + recap.ts paths corrected
- ψ junction created (Oracle MCP resolves paths)

## Pending
- [ ] vector-db.ts decomposition (2,194 lines → 7 modules)
- [ ] Start Docker Desktop → `docker start chromadb` → full memory online
- [ ] Start services: `bash .claude/hooks/matrix-services.sh start heartbeat`
- [ ] Log rotation for memory-errors.log + heartbeat
- [ ] Restart shell for ffmpeg/sox persistent PATH
- [ ] Push 18+ commits to origin

## Next Session
- [ ] Push all commits: `git push origin main`
- [ ] Start Docker + ChromaDB for semantic memory
- [ ] Start heartbeat service (paths fixed, should work now)
- [ ] CIS Modernization — the actual mission (task-0002)
- [ ] Consider vector-db.ts split if touching memory layer

## Key Files
- Plan: `~/.claude/plans/inherited-twirling-mccarthy.md`
- Retrospective: `psi/memory/retrospectives/2026-03/23/13.56_windows-awakening-voice-parity.md`
- Platform utils: `src/core/utils/platform.ts`, `.claude/hooks/lib-platform.sh`
- Voice engine: `scripts/voice/voice.sh`, `scripts/voice/system-voice.sh`
- PULSE writer: `src/core/utils/pulse-events.ts`
- Recap scripts: `~/.claude/skills/recap/recap-rich.ts`, `recap.ts`
