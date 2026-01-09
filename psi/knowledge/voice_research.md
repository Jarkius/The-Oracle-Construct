# Voice System Research

**Last Updated**: 2026-01-10

## Oracle Voice Tray (External Tool)

**Source**: `psi/inbox/research_oracle_voice_tray.md`
**Researcher**: Morpheus

### Findings
- **Strengths**: Centralized Voice Queue (no overlap), MQTT/HTTP support, Visual Timeline.
- **Weaknesses**: Uses macOS `say` (robotic) instead of Neural Voices (Piper). No background music.

### Decision (The Oracle's Verdict)
> "Take the pattern, not the body."

- **Adopt**: The **Queue Architecture** (File locking/Socket) and **HTTP API** pattern.
- **Reject**: The application itself (to preserve Piper/Soul).
- **Strategy**: Build a "Hybrid" system in the Matrix: Piper Voices + Queue Logic.

## Autonomous Coding Agents

**Source**: `psi/inbox/research_autonomous_coding_agent.md`
**Researcher**: Morpheus

### Key Insights
*(Pending Synthesis)*
