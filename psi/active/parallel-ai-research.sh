#!/bin/bash
# parallel-ai-research.sh - Use GPT-5.2 + Gemini APIs in parallel
# No browser needed - direct API calls

INBOX_DIR="$HOME/workspace/The-matrix/psi/learn/inbox"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

research_with_gemini() {
    local topic="$1"
    local filename="${INBOX_DIR}/gemini_${topic// /_}_${TIMESTAMP}.md"
    
    curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"contents\":[{\"parts\":[{\"text\":\"Search YouTube for '$topic' tutorials. Summarize key lessons with timestamps.\"}]}]}" \
        | jq -r '.candidates[0].content.parts[0].text' > "$filename" &
    
    echo "Gemini researching: $topic"
}

research_with_gpt() {
    local topic="$1"
    local filename="${INBOX_DIR}/gpt52_${topic// /_}_${TIMESTAMP}.md"
    
    curl -s "https://api.openai.com/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${OPENAI_API_KEY}" \
        -d "{\"model\":\"gpt-5.2\",\"max_completion_tokens\":2000,\"messages\":[{\"role\":\"user\",\"content\":\"Research '$topic' and provide comprehensive summary with key insights.\"}]}" \
        | jq -r '.choices[0].message.content' > "$filename" &
    
    echo "GPT-5.2 researching: $topic"
}

echo "=== Parallel AI Research (API Mode) ==="

# Run both AIs in parallel on same topic
for topic in "$@"; do
    research_with_gemini "$topic"
    research_with_gpt "$topic"
done

wait
echo "All research complete! Check $INBOX_DIR"
