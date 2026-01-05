---
description: Voice of the Matrix - Speak to the user
---

# /voice - Voice of the Matrix

> *The Voice - "Sound occupies physical space."*

## Usage

- `/voice say [message]` - Speak a specific message.
- `/voice greet` - Speak a standard greeting.
- `/voice announce [message]` - Speak an announcement (attention capture).

## Philosophy (Chapter 6)

- **Rate**: 300 (~1.5x speed). Fast but clear.
- **Voice**: Kanya (Presence).
- **Rule**: "Voice for moments. Text for information."

## Steps

### Say (Custom Message)
```bash
sh psi/active/voice_module.sh "[message]"
```

### Greet (Welcome)
```bash
sh psi/active/voice_module.sh "Welcome to the Oracle Construct. System online."
```

### Announce (Attention)
```bash
# Slower rate for announcements
export RATE=250
sh psi/active/voice_module.sh "Attention. [message]"
```
