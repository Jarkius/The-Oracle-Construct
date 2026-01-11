# Matrix Council Voice Mapping Reference

> Last synchronized: 2026-01-07

## Master Voice Configuration

Source of truth: `.claude/config/voices.json`

| Agent | Piper Voice | Personality | Character |
|-------|-------------|-------------|-----------|
| **Oracle** | `en_US-kristin-medium` | wise | Calm, Nurturing, Prophetic |
| **Neo** | `en_US-ryan-high` | focused | Curious, Focused, Determined |
| **Trinity** | `jenny` | pleasing | Direct, Seductive, Capable |
| **Morpheus** | `en_US-carlin-high` | wise | Wise, Patient, Inspiring |
| **Architect** | `en_GB-alan-medium` | commanding | Logical, Verbose, Detached |
| **Smith** | `en_US-danny-low` | sarcastic | Cold, Precise, Menacing |
| **Tank** | `en_US-bryce-medium` | excited | Technical, Helpful, Quick |
| **Scribe** | `en_US-lessac-medium` | robotic | Neutral, Clear, Precise |
| **System** | `en_US-ryan-medium` | robotic | Neutral |
| **Computer** | `en_US-ryan-medium` | robotic | Neutral |

## File Locations

### Operational Config (What TTS Actually Uses)
```
.claude/config/voices.json        # Master voice → agent mapping
psi/matrix/voice.sh        # Voice router script
.claude/hooks/play-tts.sh         # TTS execution
```

### Agent Definitions (Documentation + Metadata)
```
.claude/agents/neo.md             # Neo persona + voice metadata
.claude/agents/trinity.md         # Trinity persona + voice metadata
.claude/agents/architect.md       # Architect persona + voice metadata
.claude/agents/agent-smith.md     # Smith persona + voice metadata
.claude/agents/morpheus.md        # Morpheus persona + voice metadata
.claude/agents/oracle-keeper.md   # Oracle persona + voice metadata
.claude/agents/tank.md            # Tank persona + voice metadata
.claude/agents/scribe.md          # Scribe persona + voice metadata
```

### Slash Command Workflows
```
.agent/workflows/oracle.md        # /oracle command
.agent/workflows/neo.md           # /neo command
.agent/workflows/trinity.md       # /trinity command
.agent/workflows/architect.md     # /architect command
.agent/workflows/smith.md         # /smith command
.agent/workflows/morpheus.md      # /morpheus command
.agent/workflows/operator.md      # /operator (Tank) command
.agent/workflows/rrr.md           # /rrr (Scribe) command
```

## Voice Invocation

### Via voice_module.sh (Recommended)
```bash
sh psi/matrix/voice.sh "Message here" "AgentName"
# Example:
sh psi/matrix/voice.sh "I see the code." "Neo"
```

### Via play-tts.sh (Direct)
```bash
.claude/hooks/play-tts.sh "Message here" "voice-id"
# Example:
.claude/hooks/play-tts.sh "I see the code." "en_US-ryan-high"
```

## Adding a New Agent

1. **Create agent file**: `.claude/agents/<name>.md`
   ```yaml
   ---
   name: agent-name
   role: Agent Role
   voice: piper-voice-id
   voice_label: Human Readable Name
   personality: personality-type
   ---
   ```

2. **Add to voices.json**: `.claude/config/voices.json`
   ```json
   "AgentName": {
     "voice": "piper-voice-id",
     "personality": "personality-type"
   }
   ```

3. **Create slash command**: `.agent/workflows/<name>.md`
   - Include voice greeting command

## Personality Types

Available personalities (from AgentVibes):
- `wise` - Calm, measured delivery
- `focused` - Clear, determined tone
- `pleasing` - Warm, approachable
- `commanding` - Authoritative, formal
- `sarcastic` - Dry, cutting wit
- `excited` - Energetic, enthusiastic
- `robotic` - Neutral, mechanical

## Synchronization Protocol

When updating voices:

1. Update `.claude/config/voices.json` first (source of truth)
2. Update `.claude/agents/*.md` to match
3. Verify `.agent/workflows/*.md` has correct voice_module.sh calls
4. Test with: `/agent-vibes:sample <voice-id>`
