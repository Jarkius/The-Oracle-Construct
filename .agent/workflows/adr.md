---
description: Architecture Decision Record - document significant technical decisions
---

# /adr - Architecture Decision Record

> Architect's skill: Document significant technical decisions

## Usage

```
/adr [decision topic]
/adr authentication method
/adr database choice
```

## Auto-Trigger When User Says:
- "should we use X or Y"
- "what's the best approach for"
- "how should we architect"
- "let's decide on"
- "which technology for"

## Action

<workflow>

<step n="1" goal="Identify the Decision">
  <action>If topic specified → Use as decision title</action>
  <action>If not → Ask: "What architectural decision needs to be documented?"</action>
  <action>Check existing ADRs: `ls psi/specs/adrs/`</action>
</step>

<step n="2" goal="Gather Context">
  <action>Understand the problem:</action>
  - What is forcing this decision?
  - What are the constraints?
  - Who is affected?

  <action>Check related specs: `psi/specs/*.md`</action>
</step>

<step n="3" goal="Generate ADR">
  <action>Create ADR with this format:</action>

  ```markdown
  # ADR-[NUMBER]: [Decision Title]

  **Status**: Proposed | Accepted | Deprecated | Superseded
  **Date**: [YYYY-MM-DD]
  **Deciders**: [who made the decision]

  ## Context

  [What is the issue that we're seeing that is motivating this decision?]

  ## Decision Drivers

  - [Driver 1: e.g., scalability requirement]
  - [Driver 2: e.g., team expertise]
  - [Driver 3: e.g., cost constraints]

  ## Considered Options

  ### Option 1: [Name]
  - **Pros**: [list]
  - **Cons**: [list]

  ### Option 2: [Name]
  - **Pros**: [list]
  - **Cons**: [list]

  ### Option 3: [Name]
  - **Pros**: [list]
  - **Cons**: [list]

  ## Decision

  **Chosen Option**: [Option X]

  **Rationale**: [Why this option was selected]

  ## Consequences

  ### Positive
  - [Consequence 1]

  ### Negative
  - [Consequence 1]

  ### Risks
  - [Risk 1 and mitigation]

  ## Related

  - [Link to related ADRs, specs, or docs]
  ```
</step>

<step n="4" goal="Validate & Save">
  <ask>Review this ADR. Approve [a], Edit [e], or Cancel [c]?</ask>
  <action>Save to `psi/specs/adrs/adr-[number]-[slug].md`</action>
  <action>Report: "ADR recorded. Decision documented."</action>
</step>

</workflow>

## Principles

- "User journeys drive technical decisions"
- "Embrace boring technology for stability"
- "Connect every decision to business value"

ARGUMENTS: $ARGUMENTS
