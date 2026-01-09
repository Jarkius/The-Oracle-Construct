# Knowledge: Voice Queue System V2
> **Captured by:** Scribe
> **Date:** 2026-01-10
> **Component:** PSI Core / Voice

## 1. Overview
The Voice System has evolved from a brittle File-Locking mechanism (`shlock`) to a robust **Client-Server Architecture**.

## 2. Architecture
-   **Server**: `psi/active/voice_server.py`
    -   Type: Python Daemon (Single Threaded Queue Payload).
    -   Port: `6969`.
    -   Mechanism: `queue.Queue` (In-Memory FIFO).
    -   Launch Security: Must be launched detached (`< /dev/null`) to prevent TTY Suspension (`SIGTTOU`).
-   **Client**: `psi/active/voice_module.sh`
    -   Mode `client`: Sends JSON Payload -> Server.
    -   Mode `worker`: Executed by Server -> Generates Audio (Blocking).

## 3. Protocols
### The Queue Protocol (Standard)
1.  Client sends `{"text": "...", "speaker": "..."}`.
2.  Server responds `OK: Queued` and closes connection immediately.
3.  Server Worker thread picks up item.
4.  Worker calls `voice_module.sh ... --worker`.
5.  Worker **waits** (`subprocess.wait()`) for completion.
6.  Next item processed.

### The Panic Protocol (`--panic`)
1.  Client sends `{"panic": true, ...}`.
2.  Server spawns immediate independent thread.
3.  Audio plays **concurrently** with Queue.

## 4. Learnings & Fixes
-   **Server Silence**: Caused by `nohup` process trying to write to `stdout` without redirection. Fixed by `> log 2>&1` AND `< /dev/null`.
-   **Zombie Processes**: Previous `afplay` instances can linger if the server is killed violently. `killall afplay piper` is required for clean resets.
-   **Audio Fidelity**: Direct `piper` calls were required (bypassing `play-tts.sh` wrapper) to ensure blocking behavior for the queue to work.

## 5. Artifacts
-   `psi/active/voice_server.py`: The Brain.
-   `psi/active/voice_module.sh`: The Voice.
-   `psi/active/demo_rollcall_queue.sh`: The Proof (Order).
-   `psi/active/demo_rollcall_chaos.sh`: The Proof (Chaos).
