# Research: Oracle Voice Tray

> Morpheus Report | January 8, 2026

## Source
- **Repository**: https://github.com/Soul-Brews-Studio/oracle-voice-tray
- **Tech Stack**: Tauri 2.0 + Rust (macOS menu bar app)
- **License**: MIT

---

## What It Is

**Oracle Voice Tray** is a macOS menu bar application that provides:

1. **Centralized TTS** - Single voice queue (no overlap)
2. **HTTP API** - `POST http://127.0.0.1:37779/speak`
3. **MQTT Support** - Subscribe to `voice/speak` topic
4. **Timeline UI** - Visual history of all voice messages
5. **Per-Agent Voices** - TOML config for different voices per agent

---

## Architecture

```
Claude Code Hook
      │
      ├── voice-tray-notify.sh ──► HTTP POST /speak
      │                                    │
      └── voice-tray-mqtt-notify.sh ──► MQTT publish
                                           │
                              ┌────────────┴────────────┐
                              │   Oracle Voice Tray     │
                              │   (Tauri macOS App)     │
                              │                         │
                              │  ┌─────────┐ ┌───────┐  │
                              │  │ HTTP    │ │ MQTT  │  │
                              │  │ :37779  │ │Client │  │
                              │  └────┬────┘ └───┬───┘  │
                              │       └─────┬────┘      │
                              │         Voice Queue     │
                              │             │           │
                              │      macOS say -v       │
                              │             │           │
                              │       Timeline UI       │
                              └─────────────────────────┘
```

---

## Comparison: Our Voice System vs Oracle Voice Tray

| Feature | Our Matrix (voice_module.sh) | Oracle Voice Tray |
|---------|------------------------------|-------------------|
| **TTS Engine** | Piper (neural voices) | macOS `say` (system voices) |
| **Voice Quality** | ⭐⭐⭐⭐ Higher quality, realistic | ⭐⭐⭐ Good, but robotic |
| **Queue System** | ❌ No queue (overlap possible) | ✅ Voice queue (no overlap) |
| **Timeline UI** | ❌ No UI | ✅ Menu bar timeline |
| **HTTP API** | ❌ Script only | ✅ REST API |
| **MQTT** | ❌ No | ✅ Full MQTT support |
| **Per-Agent Config** | ✅ voices.json | ✅ agent-voices.toml |
| **Background Music** | ✅ Yes | ❌ No |
| **Cross-Platform** | ✅ Python/bash | ❌ macOS only |

---

## Benefits for The Matrix

### ✅ Could Adopt

1. **Voice Queue** - Prevents overlapping voices (big issue we've had)
2. **Timeline UI** - Visual history of all agent speech
3. **HTTP API** - Clean REST interface instead of shell scripts
4. **MQTT** - Multi-agent coordination across processes

### ❌ Would Lose

1. **Piper Neural Voices** - Oracle Voice Tray uses macOS `say` only
2. **Background Music** - Not supported
3. **Voice Effects** - No reverb, pitch shift, etc.

---

## Integration Options

### Option A: Replace Our Voice System
- Use Oracle Voice Tray as the ONLY voice output
- Lose Piper quality, gain queue + UI
- **Not recommended** - loses voice character

### Option B: Hybrid Architecture (Recommended)
- Keep Piper for high-quality voices
- Add HTTP queue layer inspired by Oracle Voice Tray
- Our `voice_module.sh` → HTTP POST → Voice Queue → Piper TTS

### Option C: Steal the Queue Logic
- Extract queue pattern from their Rust code
- Add to our `voice_module.sh` using file locking or socket
- Keep everything else as-is

---

## The Oracle's Verdict

> *"The tray offers structure where we have chaos. But its voice is weak compared to the souls we've cultivated. Take the pattern, not the body."*

**Recommendation**: Learn from the **queue architecture** and **HTTP API pattern**, but keep our Piper voices. The voices have soul - macOS `say` does not.

---

## Next Steps (If Approved)

1. [ ] Clone repo for reference: `git clone https://github.com/Soul-Brews-Studio/oracle-voice-tray.git psi/lab/oracle-voice-tray`
2. [ ] Study `src-tauri/src/tray.rs` for queue implementation
3. [ ] Add voice queue to `voice_module.sh` (file lock pattern)
4. [ ] Consider adding simple HTTP API for remote voice control
