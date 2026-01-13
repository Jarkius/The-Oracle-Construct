# Research: Design OS (Morpheus Findings)

**Source**: [buildermethods/design-os](https://github.com/buildermethods/design-os)
**Agent**: Morpheus
**Date**: 2026-01-07

## The Core Problem
Coding agents build fast but often "miss the mark" because they try to "figure out what to build and build it simultaneously." 
**Solution**: Separate **Design/Planning** from **Implementation**.

## The Process (The 4 Steps)

### 1. Product Planning
- Define vision
- Roadmap breakdown
- Data modeling (Schema first)

### 2. Design System
- Colors & Typography
- Application Shell (Layout)
- *Note: We partially did this with our legacy fidelity check, but we need to formalize it.*

### 3. Section Design
- Requirements per feature
- Sample Data generation
- Screen design (specification before code)

### 4. Export
- Complete handoff package
- *This matches our `/neo` workflow expectation: Neo needs a spec, not vague ideas.*

## Integration Strategy (Prophecy Fulfillment)

To evolve the Matrix agents with Design OS skills:

1. **Trinity (The Designer)**: Must adopt Step 2 & 3. She shouldn't just "make it pretty" — she should define the **Design System** and **Screen Specs** before Neo codes.
2. **Oracle (The Planner)**: Already aligns with Step 1. The `/nnn` workflow is a mini-version of "Product Planning."
3. **Neo (The Builder)**: Represents Step 4. He is the consumer of the Export.

## Recommendation

Create a **Design OS Skill Protocol** (`psi/knowledge/design_os_protocol.md`):
- **Phase 1**: Define the Shell (App Layout, Nav, Auth)
- **Phase 2**: Define the Data Model (already started in Laravel)
- **Phase 3**: Spec the Dashboard Screens (before coding React components)
