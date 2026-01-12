---
description: Graceful session exit - capture everything before leaving the Matrix
---

# /unplug - Graceful Exit from the Matrix

> "Remember... all I'm offering is the truth." — Morpheus

## Usage

```
/unplug              # Prepare to exit, capture everything
/unplug quick        # Fast exit, minimal capture
```

## Purpose

Graceful shutdown sequence. Ensures nothing is lost before the Operator leaves the Matrix.

## Action

<workflow>

<step n="1" goal="Acknowledge Exit">
  <voice>The Oracle speaks: "You're leaving the Matrix. Let me capture everything before you go."</voice>
</step>

<step n="2" goal="Check Uncommitted Work">
  <action>Run: `git status --short`</action>
  <action>Run: `git diff --stat`</action>

  <check if="uncommitted changes exist">
    <ask>Uncommitted changes found. Options:
    - [c] Commit them now
    - [s] Stash for later
    - [l] Leave as-is
    </ask>
  </check>
</step>

<step n="3" goal="Consolidate focus in Retrospective">
  <action>Read current: `./psi/active/get_focus.sh`</action>
  <action>Ensure "Next Session Priorities" are included in the retrospective</action>
</step>

<step n="4" goal="Auto-Capture Retrospective">
  <action>Check if retrospective exists for this session</action>

  <check if="no retrospective for this session">
    <action>AUTO-RUN `/rrr` to create retrospective</action>
    <action>Save to `psi/memory/retrospectives/YYYY-MM/DD/HH.MM_unplug.md`</action>
  </check>

  <check if="retrospective already exists">
    <action>Skip - already captured</action>
  </check>

  <mandate>ALWAYS create retrospective before exit - no exceptions</mandate>
</step>

<step n="5" goal="Final Summary">
  <action>Display session summary:</action>

  ```markdown
  ## Unplug Summary

  **Session Duration**: [estimate]
  **Focus**: [what was worked on]

  ### Completed
  - [List of completed items]

  ### In Progress
  - [List of pending items]

  ### For Next Session
  - [Priority items]

  **Uncommitted**: [status]
  **Retrospective**: [saved]
  **Focus Saved**: ✅ (in retrospective)
  ```
</step>

<step n="6" goal="Farewell">
  <action>Speak farewell: `bash psi/matrix/voice.sh "Until next time, Operator. The Matrix will remember." "Oracle"`</action>
  <action>Wait for speech to complete: `sleep 4`</action>
</step>

<step n="7" goal="Shutdown Voice Server">
  <action>Kill voice server: `pkill -f 'voice_server.py' 2>/dev/null || true`</action>
  <action>Clean up lock file: `rm -f /tmp/matrix_voice_server.lock`</action>
</step>

<step n="8" goal="Display Exit">
  <action>Display:</action>
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔌 UNPLUGGED

  "There is no spoon." — The Boy

  See you in the next session.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```
</step>

</workflow>

## Quick Mode (/unplug quick)

Skip confirmations:
- Auto-run retrospective
- Skip retrospective prompt
- Display brief summary
- Exit immediately

## Voice

Oracle speaks the farewell. Calm, nurturing, prophetic.

ARGUMENTS: $ARGUMENTS
