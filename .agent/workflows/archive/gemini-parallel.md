# Gemini Parallel Research Workflow

## Command
`/gemini-parallel "query1" "query2" "query3" "query4"`

## Description
Execute multiple Gemini queries in parallel using Claude-in-Chrome browser automation.

## Prerequisites
- Claude browser extension installed in Chrome/Brave
- Signed into Google account with Gemini Pro access
- Browser extension connected to Claude Code

## Workflow Steps

### Phase 1: Setup Tabs
For each query provided:
1. Create a new tab using `mcp__claude-in-chrome__tabs_create_mcp`
2. Navigate to `https://gemini.google.com/app` using `mcp__claude-in-chrome__navigate`

**Execute tab creation in parallel** - call multiple `tabs_create_mcp` in one message.

### Phase 2: Wait for Pages to Load
Wait 3 seconds for all Gemini pages to fully load.

### Phase 3: Submit Queries (Critical - Must be Sequential per Tab)
For each tab, execute this sequence:
1. Find the prompt input: `mcp__claude-in-chrome__find` with query "prompt input textbox"
2. Click the input element using the ref
3. Type the query using `computer` action `type`
4. Press Enter using `computer` action `key`

**Important**: The click→type→enter must be sequential for each tab, but different tabs can run in parallel.

### Phase 4: Wait for Responses
Wait 10-15 seconds for Gemini to generate responses.

### Phase 5: Capture Results
For each tab:
1. Take screenshot using `computer` action `screenshot`
2. Extract text using `mcp__claude-in-chrome__get_page_text`
3. Save to `psi/learn/inbox/gemini_*.md`

## Example Execution

```
User: /gemini-parallel "What is React?" "What is Vue?" "What is Angular?" "What is Svelte?"

Claude: [Creates 4 tabs in parallel]
Claude: [Navigates all to Gemini in parallel]
Claude: [Waits 3 seconds]
Claude: [For each tab: click input, type query, press Enter - in parallel]
Claude: [Waits 15 seconds for responses]
Claude: [Captures all responses and saves to inbox]
```

## Output Format
Results saved to: `psi/learn/inbox/gemini_[query_slug]_[timestamp].md`

## Limitations
- Maximum 4 parallel tabs recommended (browser performance)
- Requires manual sign-in to Gemini before first use
- Extension must be connected (check with `tabs_context_mcp`)

## Troubleshooting
- If tabs won't submit: Reload Gemini and try again
- If extension disconnected: Refresh browser and restart Claude Code
- If rate limited: Wait 30 seconds between batches
