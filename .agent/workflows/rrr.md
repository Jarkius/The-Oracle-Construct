---
description: Rest, Reflect, Record - session shutdown and documentation
---

# /rrr - Session Retrospective

> *The Scribe - "Everything that has a beginning has an end."*

Create a session retrospective capturing what happened.

## Usage

```
/rrr              # Create retrospective for current session
```

## Voice Greeting
```bash
sh psi/matrix/voice.sh "Recording session memory. What happened today?" "System"
```

## Output Location

`psi/memory/retrospectives/YYYY-MM/DD/HH.MM_[slug].md`

## Required Sections

1. **Session Info** - Date, duration, focus
2. **What Happened** - Actual events (not plans)
3. **Key Decisions** - What was decided and why
4. **AI Diary** - Genuine reflection using the **3 Core Phrases**:
   - "I assumed X but learned Y..."
   - "I was confused about X until..."
   - "I expected X but got Y because..."
5. **Honest Feedback** - Real challenges (Frustrated/Delighted)
6. **Communication Dynamics** - How we talked:
   - Flow: Smooth / Interrupted / Back-and-forth
   - Tone: Collaborative / Directive / Exploratory
   - Blockers: What slowed us down?
   - Breakthroughs: Moments of clarity
7. **Co-Creation Map** - Who contributed what:
   - Human: Direction, decisions, approvals
   - AI: Research, synthesis, implementation
   - Together: What emerged from dialogue
8. **Next Actions** - What's next

## Process

1. **Summon The Scribe** (auto-creates template with git context):
   ```bash
   ./psi/active/scribe_record.sh "slug"
   # Or with start commit for precise git range:
   ./psi/active/scribe_record.sh "slug" "a30db99"
   ```

   This automatically:
   - Creates directory structure (`YYYY-MM/DD/`)
   - Generates template with all 8 sections
   - Injects git commits and diff stats
   - Returns file path

2. Fill in the template sections (marked with `[FILL]`)

3. Validate completeness:
   - AI Diary: 150+ words
   - All sections filled
   - No `[FILL]` markers remaining

4. **Generate Output**:
    ```markdown
    # Session Retrospective

    **Date**: $(date)
    **Duration**: [Time]
    **Focus**: [Task]

    ## Summary
    [Executive Summary]

    ## What We Built
    ### [Category]
    - [Item]

    ## Key Decisions
    | Decision | Rationale |
    |----------|-----------|
    | [What] | [Why] |

    ## AI Diary (Required - 150+ words)
    [Vulnerable reflection using core phrases]

    ## Honest Feedback
    ### Delighted
    - [What worked well]
    ### Frustrated
    - [What caused friction]

    ## Communication Dynamics
    - **Flow**: [Smooth / Interrupted / Back-and-forth]
    - **Tone**: [Collaborative / Directive / Exploratory]
    - **Blockers**: [What slowed us down]
    - **Breakthroughs**: [Moments of clarity]

    ## Co-Creation Map
    | Contributor | What |
    |-------------|------|
    | Human | [Direction, decisions, approvals] |
    | AI | [Research, synthesis, implementation] |
    | Together | [What emerged from dialogue] |

    ## Lessons Learned
    - **Pattern**: [Insight]

    ## Timeline
    | Time | Topic |
    |------|-------|
    | [Time] | [Event] |

    ## Next Steps
    - [ ] [Action]
    ```



## Quality Standards

- **AI Diary**: Minimum 150 words, must be vulnerable
- **Honest Feedback**: Must include friction points
- **No placeholders**: Fill all blanks before saving

## Template

See `templates/retrospective.md` for full template.
