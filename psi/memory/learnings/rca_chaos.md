## Cause Analysis - System Chaos on Restart

**Symptom**: "every time, when I left from the matrix and come back , all chaosssss" (Lost Voices, Lost Theme).

**Cause Chain**:
1. **Why?** Voice models vanish and UI reverts or breaks.
2. **Why?** Voice models (`.claude/piper-voices/*.onnx`) are likely **gitignored** (to save space) but not automatically re-downloaded or checked on startup.
3.  **Why?** There is no "State Enforcement" script running at the start of your session to say "Ensure Client is Legacy" and "Ensure Voices exist".
4.  **Why?** we relied on manual fixes during the session, which are ephemeral (temporary).
5.  **Root Cause**: **Lack of Persistence Automation**. The Matrix has no "Save Game" state for your preferences.

**Action**:
1.  **Persist**: Create `.claude/config/matrix.json` to store "Theme: Legacy" and "Voice: Enabled".
2.  **Enforce**: Update `system_resume.sh` to read this config and apply it immediately (redownload voices if missing, reset CSS).
