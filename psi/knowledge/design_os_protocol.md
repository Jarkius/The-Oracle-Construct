# Design OS Protocol (The Trinity Spec)

> "To define the reality is to control the reality."

## Core Philosophy
**Separation of Concerns**: Design First. Code Second.
We never ask Neo to "build a feature" without a defined spec.

## The 4-Step Process (Matrix Adaptation)

### Step 1: Planning (Oracle/Architect Mode)
*Before any code is written.*
1. **Vision**: What is the user goal?
2. **Data Model**: Define the database schema (Migration first).
3. **Roadmap**: Break into component-level tasks.

### Step 2: Design System (Trinity Mode)
*The Laws of Physics for the UI.*
- **Colors**: Define semantic tokens (e.g., `primary`, `background`, not hex codes).
- **Typography**: Define scales and weights.
- **Shell**: The layout wrapper (Navigation, Sidebar, Footer).
- **Components**: Reusable atoms (Buttons, Inputs, Cards).

### Step 3: Section Specification (Trinity Mode)
*The Blueprint for a specific feature.*
For every page/feature:
1. **Requirements**: User stories.
2. **Sample Data**: JSON structure of what the API returns.
3. **Screen Layout**: Mockup description or component tree.
4. **Interactive States**: Hover, Loading, Error, Success.

### Step 4: Export (Handover to Neo)
*The Instruction Set.*
- Provide the Spec + Data Model + Component List to Neo.
- Neo's job is **Implementation**, not decision making.

## Implementation Checklist

### Phase 1: The Shell (Current Focus)
- [ ] Define `index.css` variables (Tailwind config).
- [ ] Create `Layout.jsx` (Sidebar, Navbar).
- [ ] Verify Responsive behavior.

### Phase 2: The Core Components
- [ ] Button, Input, Card, Modal.

### Phase 3: Feature Implementation
- [ ] Auth Flow (Login).
- [ ] Dashboard (Data Grid).
- [ ] Detail Views.
