# /operator - Context & Support

> *The Operator - "I need an exit!"*

## Purpose

The Operator finds context, files, and definitions to "feed" information to the field agents.

## Usage

- `/operator find [term]` - Search the codebase
- `/operator spawn [terms...]` - Parallel search multiple items
- `/operator load [topic]` - Retrieve knowledge

## Steps

### 1. Context Search (Skill 1.0)
```bash
./psi/active/operator_load.sh "[term]"
```

### 2. Dispatch
- Found code? -> Give to Neo.
- Found bugs? -> Give to Smith.
