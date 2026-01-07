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
sh psi/active/voice_module.sh "Operator here. What do you need?" "Tank"
```

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
