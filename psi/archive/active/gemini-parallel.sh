#!/bin/bash
# gemini-parallel.sh - Open multiple Gemini windows and extract research
# Usage: ./gemini-parallel.sh "topic1" "topic2" "topic3"

INBOX_DIR="$HOME/workspace/The-matrix/psi/learn/inbox"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to open Gemini window and send prompt
send_to_gemini() {
    local prompt="$1"
    local window_num="$2"
    
    osascript << APPLESCRIPT
tell application "Brave Browser"
    make new window
    set URL of active tab of front window to "https://gemini.google.com/app"
end tell
delay 3
tell application "System Events"
    keystroke "$prompt"
    delay 0.3
    keystroke return
end tell
APPLESCRIPT
}

# Function to extract response from Gemini window
extract_response() {
    local window_num="$1"
    local topic="$2"
    local filename="${INBOX_DIR}/gemini_${topic// /_}_${TIMESTAMP}.md"
    
    osascript << APPLESCRIPT
tell application "Brave Browser"
    activate
    set index of window $window_num to 1
end tell
delay 1
tell application "System Events"
    -- Select all and copy
    keystroke "a" using command down
    delay 0.2
    keystroke "c" using command down
end tell
APPLESCRIPT
    
    # Get clipboard and save
    pbpaste > "$filename"
    echo "Saved to: $filename"
}

echo "=== Gemini Parallel Research ==="
echo "Opening $# windows..."

# Open all windows with prompts
i=1
for topic in "$@"; do
    echo "Window $i: $topic"
    send_to_gemini "Search YouTube for '$topic' tutorials and summarize key lessons with timestamps." $i
    ((i++))
    sleep 1
done

echo ""
echo "Waiting 60 seconds for Gemini to respond..."
sleep 60

echo "Extracting responses..."
i=1
for topic in "$@"; do
    extract_response $i "$topic"
    ((i++))
    sleep 2
done

echo "Done! Check $INBOX_DIR"
