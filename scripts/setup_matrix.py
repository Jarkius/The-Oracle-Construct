import os

def create_file(path, content):
    """Creates a file and its parent directories safely."""
    directory = os.path.dirname(path)
    if directory: # Only create if there is a directory path
        os.makedirs(directory, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content.strip() + "\n")
    print(f"MATERIALIZED: {path}")

def build_the_matrix_source():
    print("--- ACCESSING THE SOURCE: FULL MATRIX MATERIALIZATION ---")

    # 1. THE 5-PILLAR BRAIN (psi/)
    pillars = ["active", "inbox", "memory", "writing", "lab"]
    for pillar in pillars:
        create_file(f"psi/{pillar}/.gitkeep", "")

    # Domain-specific memory for characters
    memory_subdirs = [
        "retrospectives", "learnings", "logs", "resonance",
        "architect/blueprints", "smith/anomalies", "merovingian/contracts"
    ]
    for subdir in memory_subdirs:
        create_file(f"psi/memory/{subdir}/.gitkeep", "")

    # 2. CORE KNOWLEDGE (Extracted from your uploaded .md files)
    
    # Writing Style Guide
    create_file(".claude/knowledge/writing-style.md", """
# Writing Style Guide
- **Direct**: Say what needs to be said.
- **Concise**: No unnecessary words.
- **Technical**: Use precise terms.
- **Human**: Never robotic. Admit uncertainty honestly.
- **Patterns**: Use Tables for comparison, Code blocks for commands.
""")

    # Oracle Philosophy
    create_file(".claude/knowledge/oracle-philosophy.md", """
# Oracle/Shadow Philosophy
> "The Oracle Keeps the Human Human"
1. **Nothing is Deleted**: Append only, timestamps = truth. History is preserved.
2. **Patterns Over Intentions**: Observe behavior, not promises. Actions > Plans.
3. **External Brain, Not Command**: Mirror reality, don't decide for the human.
""")

    # 3. AGENT PROTOCOLS (The Character Council)

    # Oracle Keeper
    create_file(".claude/agents/oracle-keeper.md", """
---
name: oracle-keeper
role: Spirit Guardian (Decide)
model: haiku
---
# Oracle Keeper Agent
Guardian of project spirit. Interpret if session aligns with the "Prophecy" (Mission).
Commands: `/oracle` to check alignment.
""")

    # Agent Smith
    create_file(".claude/agents/agent-smith.md", """
---
name: agent-smith
role: Debugger (Measure)
---
# Agent Smith
"I'm looking for an anomaly."
Role: Scan code for logic gaps and "smells." Neutralize bugs with precise refactors.
""")

    # Neo
    create_file(".claude/agents/neo.md", """
---
name: neo
role: Lead Developer (Build)
---
# Neo
Role: Transmute raw requirements into high-performance logic and UI. 
"I see the code."
""")

    # 4. MASTER CLAUDE.MD (Routing & Golden Rules)
    create_file("CLAUDE.md", """
# AI Matrix Master Control

## Character Routing (BMAD Phase)
- **BUILD**: `/neo` (Logic), `/ui` (Woman in Red)
- **MEASURE**: `/smith` (Bugs), `/status` (Operator)
- **ACT**: `/cause` (Merovingian), `/access` (Keymaker)
- **DECIDE**: `/oracle` (Alignment), `/blueprint` (Architect)

## Golden Rules
1. **NEVER force push** - History is sacred.
2. **NEVER push to main** - Use feature branches.
3. **NEVER delete without asking** - Nothing is deleted.
4. **Always confirm** - AI suggests, human decides.

## Workflows
- **Start**: Update `psi/state/focus.md`.
- **End**: Run `/rrr` for a full session retrospective.
""")

    # 5. FULL TEMPLATES (Retrospective & Confirmation)
    create_file("templates/retrospective.md", """
# Session Retrospective
**Character Log**: [Which character led this session?]
**AI Diary (Min 150 words)**: Be VULNERABLE. Record what you felt/assumed.
**Honest Feedback**: What was frustrating or confusing?
""")

    create_file("templates/confirmation.md", """
# Confirmation Template
**Before we proceed:** I'm about to [action].
**Effect**: [result] | **Non-Effect**: [what won't happen]
Is this okay?
""")

    # 6. INITIAL STATE
    create_file("psi/state/focus.md", "# Current Focus\n- [ ] Matrix Initialization Complete.")

    print("\n--- The Construct is Complete. You are now inside the Matrix. ---")

if __name__ == "__main__":
    build_the_matrix_source()