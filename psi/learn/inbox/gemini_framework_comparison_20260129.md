# AgentOS vs BMAD vs Spec Kit - AI Development Framework Comparison

> **Source:** Gemini Pro via Parallel Agent
> **Topic:** Spec-Driven Development (SDD) and Agentic Workflows
> **Date:** 2026-01-29

---

## Executive Summary

| Framework | Best For | Philosophy |
|-----------|----------|------------|
| **BMAD** | Complex greenfield enterprise projects | Simulates full Agile team with AI personas |
| **Spec Kit** | Developers who want disciplined coding | Enforces Spec → Plan → Implement loop |
| **AgentOS** | Building long-running, context-aware systems | Infrastructure/runtime for agent state & memory |

---

## Quick Comparison

| Feature | BMAD | GitHub Spec Kit | AgentOS |
|---------|------|-----------------|---------|
| **Core Philosophy** | Agile Simulation (AI team) | Spec-Driven ("Think before code") | Context Infrastructure |
| **Complexity** | High | Medium | Variable |
| **Primary Output** | Full lifecycle (PRD→Code→Tests) | Code tied to specs | Agent operations & state |
| **Best For** | Greenfield projects | Feature work on existing codebases | Custom agentic platforms |
| **Agent Roles** | 20+ specialized (PM, Architect, UX, Dev) | Agnostic (you drive) | Configurable with memory |

---

## BMAD (The "Enterprise" Choice)

*"Breakthrough Method of Agile AI-Driven Development"*

Forces AI to act like a corporate software team with PM, Architect, and Developer agents.

### Pros
- **Context Preservation** - Heavy documentation prevents AI "forgetting"
- **Zero Hallucination** - Strict planning/coding separation reduces errors
- **Full Lifecycle** - Auto-generates user stories, acceptance criteria, QA plans

### Cons
- **Overwhelming Overhead** - Simple changes feel bureaucratic
- **Expensive** - Multiple agents burn more tokens
- **Steep Learning Curve** - Must learn BMAD folder structures

---

## GitHub Spec Kit (The "Developer's" Choice)

*"Spec-Driven Development Toolkit"*

CLI tool for IDE that fights "vibe coding" by forcing `spec.md` and `plan.md` approval first.

### Pros
- **Focus & Clarity** - Prevents infinite AI refactoring loops
- **Integration** - Works with Claude Code, Copilot, Cursor
- **Iterative** - Perfect for task-based feature work
- **Microsoft/GitHub Backing** - Better long-term support

### Cons
- **Manual Friction** - Must write/review specs (slow for quick scripts)
- **Less Autonomous** - Relies on human to drive CLI commands

---

## AgentOS (The "Infrastructure" Choice)

*"The Agent Runtime"*

Framework for running agents with focus on memory, state, and tool management.

### Pros
- **Memory & State** - Agents remember users over time
- **Model Agnostic** - Swap OpenAI/Anthropic/local models easily
- **Production Ready** - Deploys as service (FastAPI)

### Cons
- **Not a Workflow Tool** - Doesn't tell you HOW to code
- **Setup Complexity** - Requires databases, Docker

---

## Recommendations by Scenario

| Scenario | Winner | Why |
|----------|--------|-----|
| **Solo Founder building SaaS MVP** | BMAD | Gives you synthetic team (PM, Architect, Dev) |
| **Senior Dev adding features** | Spec Kit | Just enough structure without overhead |
| **Building AI Agent platform** | AgentOS | Backend framework for memory/routing/tools |

---

## Bottom Line

> **Start with Spec Kit** if unsure - lowest barrier to entry, teaches Spec-Driven Development habits without massive framework overhead.

---

## Tags

#agentos #bmad #spec-kit #ai-frameworks #spec-driven-development #comparison #gemini
