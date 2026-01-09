# ADR: Voice System Evolution to Python Server
> **Captured by:** Architect
> **Status:** Implemented

## Context
The previous `shlock`-based system suffered from:
1.  **Race Conditions**: Heavy load (20+ agents) caused lock timeouts.
2.  **Audio Collision**: Non-blocking generation led to overlapping speech.
3.  **Brittle Persistence**: Stale lockfiles (`/tmp/voice.lock`) required manual cleanup.

## Decision
We have replaced the decentralized file-lock system with a **Centralized Python Voice Server**.

### Why Python?
-   Native `queue.Queue` provides thread-safe, infinite-depth buffering.
-   `subprocess` management allows precise blocking/waiting for audio completion.
-   `socket` server is lightweight and ubiquitous.

## Consequences
### Positive
-   **Zero Collision**: Guaranteed sequential playback.
-   **Infinite Patience**: Agents never time out; they just wait.
-   **Barge-In Capable**: Easy implementation of `--panic` via threading.

### Negative
-   **Daemon Requirement**: Requires `voice_server.py` to be running.
-   **Complexity**: Introduces Python dependency into the core shell ecosystem.

## Compliance
-   **Voices**: All AgentVibes config (`voices.json`) strictly adhered to.
-   **Effects**: Legacy `ffmpeg` chains (Tron, Flamenco, Jump) preserved within the Worker logic.
