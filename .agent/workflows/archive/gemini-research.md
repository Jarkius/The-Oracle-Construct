---
description: Deep research using Gemini browser automation with Brave (ad-free)
---

# /gemini-research - Browser-Powered Deep Research

> *"Free your mind." - Morpheus*

## Purpose

Orchestrate multiple Gemini browser tabs for parallel deep research, YouTube transcription, and complex analysis - using Brave browser for ad-free experience.

## Usage

```bash
/gemini-research "quantum computing breakthroughs"
/gemini-research "https://youtube.com/watch?v=..." --youtube
/gemini-research "topic1" "topic2" "topic3" --parallel
```

## Prerequisites

MCP servers must be loaded (restart session if just installed):
- `brave-browser` - Brave with ad-blocking + anti-detection
- `playwright` - Fallback Chrome automation

Verify with `/mcp` command.

## Workflow

### 1. Voice Greeting
```bash
sh psi/matrix/voice.sh "Morpheus online. Opening the gates to Gemini." "Oracle"
```

### 2. Parse Arguments
```
TOPICS = parse $ARGUMENTS for research topics
MODE = --youtube | --deep | --parallel | default
```

### 3. Browser Automation

**Single Topic:**
```
1. Use brave-browser MCP to navigate to gemini.google.com
2. Wait for page load
3. Find chat input field
4. Type research prompt
5. Wait for response
6. Extract and return results
```

**Parallel Research (Multiple Topics):**
```
1. Open N Brave tabs (one per topic)
2. Navigate each to gemini.google.com
3. Send prompts in parallel
4. Collect all responses
5. Synthesize findings
```

**YouTube Mode:**
```
1. Open Brave tab to gemini.google.com
2. Send prompt: "Please transcribe and summarize this YouTube video: [URL]"
3. Wait for Deep Research mode to process
4. Extract transcript + analysis
```

### 4. Result Handling

Save results to Matrix learning system:
```bash
# Save to inbox
echo "$RESULT" > psi/learn/inbox/gemini_$(date +%Y%m%d_%H%M).md
```

### 5. Voice Summary
```bash
sh psi/matrix/voice.sh "Research complete. [summary]" "Oracle"
```

## Fallback: API Mode

If browser fails, fall back to Gemini API:
```bash
# Use matrix-gemini-agent MCP
gemini_research(topic, depth="deep")
```

## Example Prompts for Gemini

**Deep Research:**
```
Perform deep research on [TOPIC]. Include:
- Current state of the art
- Key players and recent developments
- Technical details and mechanisms
- Future implications
- Sources and references
```

**YouTube Analysis:**
```
Please transcribe this YouTube video and summarize the key points:
[URL]

Focus on:
- Main arguments/topics
- Key timestamps
- Actionable insights
```

## Integration with Matrix

Results flow into the knowledge system:
```
Gemini Browser → psi/learn/inbox/ → /distill → psi/memory/
```

## Notes

- Brave blocks YouTube ads automatically
- Anti-detection helps avoid CAPTCHAs
- Keep tabs under 4 to avoid rate limiting
- Google account required for Gemini access
