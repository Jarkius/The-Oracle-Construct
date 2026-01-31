# Gemini Parallel Research

Execute multiple Gemini queries simultaneously using Claude-in-Chrome browser automation.

## Usage
```
/gemini-parallel "query1" "query2" "query3" "query4"
```

## Instructions

When this skill is invoked, follow these steps exactly:

### 1. Check Connection
First, verify browser extension is connected:
```
mcp__claude-in-chrome__tabs_context_mcp with createIfEmpty: true
```

If not connected, tell user to:
- Open Chrome/Brave with Claude extension
- Ensure extension is signed in

### 2. Parse Queries
Extract all quoted strings from the user's input as queries.
Maximum 4 queries per batch.

### 3. Create Tabs (Parallel)
Call `mcp__claude-in-chrome__tabs_create_mcp` once for each query.
**Do this in a single message to create all tabs in parallel.**

### 4. Navigate to Gemini (Parallel)
For each tab, call `mcp__claude-in-chrome__navigate` with:
- url: "https://gemini.google.com/app"
- tabId: [the tab ID from step 3]
**Do this in a single message for all tabs.**

### 5. Wait for Load
Wait 3 seconds: `computer` action `wait` duration 3

### 6. Submit Queries (Parallel)
For each tab, in a single message:
1. `mcp__claude-in-chrome__find` query "prompt input textbox"
2. `mcp__claude-in-chrome__computer` action `left_click` with the ref
3. `mcp__claude-in-chrome__computer` action `type` with the query text
4. `mcp__claude-in-chrome__computer` action `key` text "Enter"

**Critical**: Send all tab operations in ONE message for true parallelism.

### 7. Wait for Responses
Wait 12 seconds for Gemini to process all queries.

### 8. Capture Results
For each tab:
1. Take screenshot
2. Get page text with `mcp__claude-in-chrome__get_page_text`
3. Save to Matrix inbox

### 9. Report Results
Tell user:
- How many queries succeeded
- Where results are saved
- Any errors encountered

## Voice
Use Matrix voice at start: "Morpheus initiating parallel Gemini research"
Use Matrix voice at end: "Research complete. [N] queries processed"
