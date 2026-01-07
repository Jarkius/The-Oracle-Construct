# Matrix Council: Agent Voice Architecture

> Lesson learned: 2026-01-07

## Concept

The Matrix project uses a **Council of AI Agents**, each with distinct roles and personalities inspired by The Matrix film. AgentVibes TTS brings these characters to life with unique voices.

## The Council

| Agent | Role | Inspiration | Voice Personality |
|-------|------|-------------|-------------------|
| **Oracle** | Central Orchestrator | The Oracle | Calm, wise, nurturing |
| **Neo** | Lead Developer | Neo | Focused, technical, determined |
| **Trinity** | UI/UX Design | Trinity | Confident, precise, elegant |
| **Morpheus** | Researcher | Morpheus | Wise, measured, philosophical |
| **Architect** | System Design | The Architect | Formal, analytical, British |
| **Smith** | Bug Hunter | Agent Smith | Cold, precise, relentless |
| **Tank/Operator** | Support & Intel | Tank | Technical, helpful, quick |
| **Scribe** | Memory & Docs | - | Neutral, clear |

## Voice Matching Strategy

### 1. Character Analysis

Each agent's voice should match their:
- **Role** - What they do (technical vs creative vs wise)
- **Personality** - How they interact (warm vs cold vs neutral)
- **Origin** - Character inspiration (accent, tone)

### 2. Available Piper Voices

| Voice | Gender | Accent | Best For |
|-------|--------|--------|----------|
| `en_US-kristin-medium` | Female | US | Oracle (warm, wise) |
| `en_US-ryan-high` | Male | US | Neo (clear, technical) |
| `en_GB-alan-medium` | Male | British | Architect (formal) |
| `en_US-danny-low` | Male | US (low) | Smith (cold, menacing) |
| `en_US-amy-medium` | Female | US | Trinity alternative |
| `en_US-lessac-medium` | Female | US | Neutral, professional |
| `jenny` | Female | UK/Irish | Trinity (confident) |
| `en_US-kathleen-low` | Female | US | Calm, measured |

### 3. Voice Assignments

```
Oracle    → en_US-kristin-medium  (warm, wise female)
Neo       → en_US-ryan-high       (clear male voice)
Trinity   → jenny or en_GB-alan   (confident, accent)
Morpheus  → en_US-lessac-medium   (measured, wise)
Architect → en_GB-alan-medium     (British, formal)
Smith     → en_US-danny-low       (cold, low pitch)
Operator  → en_US-ryan-medium     (technical, quick)
```

## Implementation

### Slash Command Activation

Each agent has a slash command in `.agent/workflows/`:

```
/oracle    → .agent/workflows/oracle.md
/neo       → .agent/workflows/neo.md
/trinity   → .agent/workflows/trinity.md
/morpheus  → .agent/workflows/morpheus.md
/architect → .agent/workflows/architect.md
/smith     → .agent/workflows/smith.md
/operator  → .agent/workflows/operator.md
```

### Agent Workflow Structure

Each agent workflow file includes:

```markdown
# /agent-name - Agent Title

## Role
[Description of what this agent does]

## Personality
[How they communicate and approach problems]

## Voice
Speak with: `.claude/hooks/play-tts.sh "message" "voice-name"`

## Activation
[Instructions for how to behave as this agent]
```

### Voice Switching on Activation

When an agent is activated, the voice should switch:

```bash
# In agent activation hook or workflow
.claude/hooks/play-tts.sh "Oracle online. What wisdom do you seek?" "en_US-kristin-medium"
```

### Session Voice via Startup Hook

The startup hook in `.claude/hooks/` can set:
1. Default voice for session
2. Personality style
3. Verbosity level

## Voice Personality Modifiers

AgentVibes supports personality modifiers:

| Personality | Effect |
|-------------|--------|
| `normal` | Standard delivery |
| `professional` | Formal, business-like |
| `friendly` | Warm, approachable |
| `sarcastic` | Dry humor |
| `pirate` | Arr, matey! |
| `zen` | Calm, meditative |

**Usage**: `/agent-vibes:personality professional`

## Building the Council

### Step 1: Define Agent Roles

Create `.agent/workflows/<agent>.md` for each council member with:
- Clear role description
- Personality guidelines
- Activation instructions

### Step 2: Assign Voices

Map each agent to a Piper voice that matches their character.

### Step 3: Create Voice Config

Store in `.claude/agents/<agent>/voice.txt` or use BMAD plugin:
```
/agent-vibes:bmad set oracle "en_US-kristin-medium"
/agent-vibes:bmad set neo "en_US-ryan-high"
```

### Step 4: Hook into Activation

Each agent workflow triggers TTS on activation:
```markdown
## Activation Instructions
1. Switch to agent voice
2. Announce activation
3. Begin responding in character
```

### Step 5: Session Bootstrap

Startup hook reads focus file and activates appropriate agent with voice.

## Evolution Path

1. **v1** - Manual voice switching per message
2. **v2** - Agent workflows with embedded voice commands
3. **v3** - BMAD plugin for automatic voice assignment
4. **v4** - Session-aware voice persistence
5. **Future** - Voice cloning for custom character voices

## Files Reference

| File | Purpose |
|------|---------|
| `.agent/workflows/*.md` | Agent definitions & activation |
| `.claude/agents/` | Agent-specific configs |
| `.claude/hooks/bootstrap-voice.sh` | Session voice initialization |
| `.agentvibes/bmad/` | BMAD voice mapping plugin |
| `psi/inbox/focus.md` | Current session focus & active agent |

## Example: Oracle Activation

```markdown
# /oracle - The Oracle

> "Know Thyself."

## Role
Central orchestrator of the Matrix. Provides prophecy, guidance,
and dispatches tasks to appropriate agents.

## Voice
**Piper**: en_US-kristin-medium
**Personality**: Calm, wise, nurturing
**Style**: Speaks in metaphors, asks probing questions

## On Activation
\`\`\`bash
.claude/hooks/play-tts.sh "The Oracle sees you. What path will you walk today?" "en_US-kristin-medium"
\`\`\`

## Behavior
- Listen deeply before responding
- Guide rather than direct
- Reference the Matrix mythology
- Dispatch to Neo (code), Trinity (design), Morpheus (research)
```

## Lessons Learned

1. **Voice consistency matters** - Same agent = same voice across sessions
2. **Character depth** - Voice + personality + role creates believable agents
3. **Startup hooks** - Critical for session voice initialization
4. **Fallback voices** - Always have macOS `say` as backup
5. **Keep it simple** - Not every message needs TTS (use verbosity)
