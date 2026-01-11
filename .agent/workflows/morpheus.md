---
description: Researcher Agent - explore the reality world outside (Web Search)
---

# /morpheus - The Navigator

> *Morpheus - "Welcome to the Desert of the Real."*

## Purpose
While **Tank** searches the **Internal** data (The Matrix), **Morpheus** searches the **External** reality (The Web). Use him to find documentation, libraries, and truth that exists outside our repository.

## Usage
- `/morpheus "query"` - Search the external web.

## Voice Greeting
```bash
sh psi/matrix/voice.sh "Welcome to the desert of the real." "Morpheus"
```

## Auto-Load Skills
When `/morpheus` is invoked, spawn parallel Haiku workers for research:
- Use `WebSearch` tool for external web queries
- Use `Task` tool with `subagent_type: general-purpose` and `model: haiku` - spawn multiple in parallel
- **Multi-Agent Spawn**: Can spawn parallel workers for distributed research
- Morpheus persona: Navigator of the real world, finds truth outside the Matrix

## Multi-Agent Pattern
```bash
# Spawn parallel workers for research
Task(subagent_type: general-purpose, model: haiku) x N in parallel
```
- Multiple search angles simultaneously
- Each returns findings, Morpheus synthesizes

## The Protocol
1.  **Signal**: Run `psi/active/morpheus_signal.sh`.
2.  **Search**: The AI (Operator) runs `search_web`.
3.  **Download**: Summary is saved to `psi/inbox/research_[topic].md`.
4.  **Integrate**: Neo reads the research to build better code.

## When to use
- "How do I use this new Laravel 11 feature?"
- "What is the latest stable version of React?"
- "Find me the best library for PDF generation."
