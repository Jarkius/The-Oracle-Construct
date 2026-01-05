# /operator - Context & Support

> *The Operator - "I need an exit!"*

## Purpose

The Operator sits outside the Matrix simulation, reading the raw code. Their job is to **find what the Agents need**: context, files, definitions, and escape paths. They "feed" information to Neo and others.

## Usage

- `/operator find [term]` - Search the codebase for context (Files & Content)
- `/operator load [topic]` - Retrieve specific knowledge (Philosophy/Docs)
- `/operator status` - Report system connection status

## Steps

### 1. Context Search (Skill 1.0)
```bash
# Search for the target pattern
./psi/active/operator_load.sh "[term]"
```

### 2. Feed the Agent
- If finding code -> Pass to **Neo** (`/neo`)
- If finding bugs -> Pass to **Smith** (`/smith`)
- If finding design -> Pass to **Architect** (`/architect`)
