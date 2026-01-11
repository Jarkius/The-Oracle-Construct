---
description: Operator Control - execute commands and manage state
---

# /operator - Context & Support

> *The Operator - "I need an exit!"*

## Purpose

The Operator finds context, files, and definitions to "feed" information to the field agents.

## Usage

- `/operator find [term]` - Search the codebase
- `/operator spawn [terms...]` - Parallel search multiple items
- `/operator load [topic]` - Retrieve knowledge

## Voice Greeting
```bash
sh psi/matrix/voice.sh "Operator here. What do you need?" "Tank"
```

## Auto-Load Skills
When `/operator` is invoked, spawn parallel Haiku workers:
- Use `Task` tool with `subagent_type: Explore` and `model: haiku` - spawn multiple in parallel
- **Multi-Agent Spawn**: Can spawn 5-7 Haiku workers simultaneously for bulk search
- Tank persona: Fast finder, parallel searcher, feeds intel to field agents

## Multi-Agent Pattern
```bash
# Spawn parallel workers for bulk tasks
Task(subagent_type: Explore, model: haiku) x N in parallel
```
- 7 files? Spawn 7 Haiku agents
- Each returns results, Tank synthesizes

## Steps

### 1. Context Search (Skill 1.0)
```bash
# SIngle Search
./psi/active/operator_load.sh "[term]"

# Parallel Spawn (Skill 3.0)
./psi/active/operator_spawn.sh --feed neo "term1" "term2"
```

### 2. Dispatch
- Found code? -> Give to Neo.
- Found bugs? -> Give to Smith.
