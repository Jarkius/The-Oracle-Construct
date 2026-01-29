# Claude Code Workflows: Setup & Best Practices

> Source: Google Gemini (YouTube Research)
> Date: 2026-01-29
> Query: "Search YouTube for Claude Code workflows tutorials and explain how to create custom workflows. Include setup instructions and best practices with timestamps."

---

Creating custom workflows in Claude Code allows you to automate repetitive tasks, enforce project-specific coding standards, and manage complex feature implementations. The system relies on `CLAUDE.md` files for project-level instructions, Slash Commands for reusable scripts, and Subagents for parallelized work.

## How to Create Custom Workflows

To create a custom workflow, you primarily interact with the configuration files in your project's `.claude/` directory.

### 1. Setup Project Instructions (CLAUDE.md)

The `CLAUDE.md` file serves as the "brain" for your project. Claude reads this at the start of every session to understand your tech stack and preferred patterns.

- **Action:** Create a `CLAUDE.md` file in your root directory.
- **Content:** Define your build commands, test runners, and style guides.
- **Example:**

```markdown
# Project Guidelines
- Use TypeScript with ES Modules.
- Test Runner: `npm test`.
- Always run `npm run lint` before committing.
```

### 2. Create Custom Slash Commands

Slash commands are the most direct way to automate a multi-step workflow (e.g., "fix a bug and push to a PR").

- **Setup:** Place scripts or markdown instructions in `.claude/commands/`.
- **Execution:** These can be triggered by typing `/` followed by your command name in the Claude Code terminal.
- **Best Practice:** Use inline bash execution within the command to pre-compute data (like `git status`) to save Claude's context and time.

### 3. Implement Subagents for Complex Tasks

For large refactors, use subagents to handle isolated parts of the project without polluting the main conversation's context.

- **Command:** Use `/agents` to view, create, or manage subagents.
- **Customization:** Define a unique identifier (e.g., `api-designer`) and specify which tools it can access.

---

## Tutorial Highlights & Best Practices

Based on recent workflows from the Claude Code community and creators:

| Topic | Key Action | Why? |
|-------|-----------|------|
| Initial Setup | Run `/init` in new codebases. | Automatically generates a base `CLAUDE.md` tailored to your repo. |
| Planning | Use Plan Mode (`Shift + Tab`). | Separates thinking from execution, preventing costly "hallucinated" code edits. |
| Context | Use `/clear` frequently. | Claude's performance degrades as the context window fills; clearing resets focus. |
| Permissions | `--dangerously-skip-permissions` | Skips the "Can I run this?" prompts for faster "YOLO" development. |
| Verification | Include a verification step. | Ensure Claude runs tests or lints before declaring a task "complete." |

---

## Video Tutorials with Timestamps

### 1. The Complete Claude Code Workflow
**Video:** [The Complete Claude Code Workflow (to Build Anything)](https://www.youtube.com/watch?v=dk97zcYaq_o)
**Channel:** Riley Brown

- **[00:44]** - Installation and initial setup.
- **[16:12]** - Creating predictable agents.
- **[21:47]** - Bypassing permissions for faster workflows.
- **[25:19]** - Integrating with GitHub and saving progress.

Full timestamps from video:
- 00:00 Intro
- 00:44 Installing Claude Code
- 02:12 This is Claude Code
- 03:39 Creating Folders and Text Files
- 04:35 Using Claude Code as a Content Research Agent
- 16:12 We're creating a very predictable agent
- 18:17 Review: It's a general agent, that can control your cpu
- 19:13 Building Apps with Claude Code
- 21:47 Bypassing Permissions (Dangerously)
- 22:56 Creating a landing page
- 25:19 Setting up and "Saving" to GitHub
- 30:38 Deploying to Vercel
- 32:44 Building a web app with auth and db (Firebase)
- 35:14 Setting up Firebase
- 39:09 Our Web App With Auth Works!
- 43:06 You can add your own domain

### 2. Professional Setup & Custom Commands
**Video:** [Claude Code Setup That Actually Works | Full Tutorial 2025](https://www.youtube.com/watch?v=P-5bWpUbO60)
**Channel:** Eric Tech

- **[01:08]** - Initializing projects with `CLAUDE.md`.
- **[04:47]** - Creating a custom command for Unit Tests.
- **[08:40]** - Advanced multi-agent AI workflows.
- **[11:18]** - Using Git for session checkpoints.

Full timestamps from video:
- 00:00 - Install Claude Code
- 00:55 - Use in Cursor or VSCode
- 01:08 - Initialize Project (Claude.md)
- 02:27 - How to Select Your AI Model
- 02:45 - Referencing Files & Images
- 03:57 - Using Code as Context
- 04:20 - Quick-Launch Extension Shortcut
- 04:47 - Create Custom Command (for Unit Tests)
- 07:40 - Watch the AI Find & Fix Its Own Bugs
- 08:40 - Advanced: Using Multi-Agent AI
- 11:18 - Using Git for Checkpoints
- 11:41 - The "YOLO" Permission Skip
- 12:38 - Final Thoughts & Next Steps

### 3. The Creator's Workflow Setup
**Video:** [How the Creator of Claude Code Sets Up His Workflow (Setup Tutorial)](https://www.youtube.com/watch?v=aqtseECSdtY)
**Channel:** Snapper AI

- **[Setup]** - Learn the "3 Modes": Standard, Accept Edits, and Plan Mode.
- **[Tip]** - Start in Plan Mode, then switch to Accept Edits once the strategy is solid to "one-shot" the build.

Full timestamps from video:
- 00:00 Intro: The Claude Code Creator's Workflow
- 00:45 Running Multiple Claude Code Agents in Parallel (CLI)
- 01:26 Configuring Notifications in Claude Code
- 02:16 Avoiding Conflicts & Rolling Back Parallel Agents
- 02:50 Setting Up Claude Code Web
- 07:54 Handing Off Tasks from CLI to Claude Code Web
- 09:05 Teleporting Tasks Back to the CLI
- 10:24 CLAUDE.md: Shared Context & Workflow Rules
- 12:04 Creating a Draft CLAUDE.md with Claude Code
- 12:46 Setting Up the Claude Code GitHub Action
- 14:29 Using Claude Code During Pull Request Reviews
- 15:38 Plan Mode vs Accept Edits: When to Use Each
- 17:08 Wrap-Up & What's Coming Next

---

## Crucial Warnings

- **Context Management:** Do not let your `CLAUDE.md` get too long. If it exceeds 10k tokens or includes too many "rules," Claude may begin ignoring instructions. Ruthlessly prune rules that Claude already follows naturally.

- **Permissions:** Using the `--dangerously-skip-permissions` flag allows Claude to execute any command on your system. Use this only in trusted environments or within sandboxed containers.

---

## Important Links

- Boris Cherny's original thread on X: https://x.com/bcherny/status/2007179832300581177
- Claude Code GitHub Action workflow (claude.yml): https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml
- Learn more about Claude Code: https://claude.com/product/claude-code
