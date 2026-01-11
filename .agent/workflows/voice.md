---
description: Voice of the Matrix - Speak to the user
---

# /voice - Voice of the Matrix

> *The Voice - "Sound occupies physical space."*

## Usage

- `/voice say [message]` - Speak a specific message.
- `/voice greet` - Speak a standard greeting.
- `/voice announce [message]` - Speak an announcement (attention capture).
- `/voice rollcall` - Summon the Council to introduce themselves.

## Philosophy (Evolved)

- **Engine**: AgentVibes (Personality-Infused).
- **Personalities**:
    - **Oracle**: Wise
    - **Neo**: Focused (Default)
    - **Trinity**: Pleasing/Direct
    - **Smith**: Sarcastic (British)
    - **Tank**: Excited
- **Rule**: "Voice for moments. Text for information."

## Steps

### Say (Custom Message)
```bash
sh psi/matrix/voice.sh "[message]" "System"
```

### Greet (Welcome)
```bash
sh psi/matrix/voice.sh "Welcome to the Oracle Construct. AgentVibes is online." "System"
```

### Announce (Attention)
```bash
# AgentVibes handles rate internally via personality
sh psi/matrix/voice.sh "Attention. [message]" "System"
```

### Roll Call (The Council)
```bash
sh psi/active/council_rollcall.sh
```
