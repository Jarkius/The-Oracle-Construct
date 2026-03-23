# Heartbeat Checklist

> *Human-editable, daemon-readable. Each item is a check the heartbeat runs every cycle.*

## Active Checks

- [x] Check overdue reminders in `psi/state/pulse/reminders.json`
- [x] Check GitHub CI status for active PRs (`gh pr list`)
- [x] Check for PR review requests assigned to Jarkius
- [x] Flag tasks with no update in 48+ hours (`psi/memory/tasks/active.json`)
- [x] Scan `psi/state/pulse/events.jsonl` for error spikes (3+ failures in 1h)

## Disabled Checks

<!-- Uncomment to enable -->
<!-- - [ ] Check disk space on project directory -->
<!-- - [ ] Ping external services (ChromaDB, etc.) -->
<!-- - [ ] Run evolution proposer for new WEPs -->

## Notes

- Items marked `[x]` are active; `[ ]` are disabled
- Add new checks by adding markdown checkbox lines
- The daemon reads this file each cycle, so edits take effect immediately
- Interval configured in `psi/state/pulse/heartbeat.json` (default: 30 min)
