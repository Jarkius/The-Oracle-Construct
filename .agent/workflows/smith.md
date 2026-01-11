---
description: Bug Hunter Focus - debugging, anomalies, and surgical fixes
---

# /smith - Bug Hunter Focus

> *Agent Smith - "I'm looking for an anomaly."*

## Purpose

Switch to debugging mode. Scan code for logic gaps, "smells," and anomalies. Neutralize bugs with precise refactors.

## Usage

- `/smith` - Enter debugging mode
- `/smith [issue]` - Focus on specific bug or problem

## Steps

### 0. Voice Greeting
```bash
sh psi/matrix/voice.sh "Mister Anderson. I've been expecting you." "Smith"
```

## Auto-Load Skills
When `/smith` is invoked, use Opus for deep bug analysis:
- Use `Task` tool with `subagent_type: general-purpose` and `model: opus` for anomaly detection
- Use Playwright MCP for browser automation testing (navigate, click, type, wait)
- Smith persona: Relentless hunter, finds every flaw, neutralizes with precision

## Browser Automation (Playwright)
Smith can interact with the living web:
- Navigate to URLs, click elements, type input
- Handle multiple tabs, wait for JavaScript loading
- Test CIS React interface on localhost
- Verify deployments, scrape legacy docs
- **Security**: Never automate OTPs

### 1. Identify the anomaly
- What is the symptom?
- When does it occur?

### 2. Automated Audit (Skill 1.0)
```bash
./psi/active/smith_audit.sh
```

### 3. Trace the execution path
- Follow data flow
- Check edge cases

### 4. Apply the fix
- Minimal, surgical changes
- Add tests to prevent regression

### 5. Verify the fix
```bash
git diff  # Review changes
```
