#!/bin/bash
# Subagent Completion Hook
# Called by Claude Code SubagentStop event
# Mainframe announces when a subagent returns to source

# Small delay to let any in-flight audio finish
sleep 0.3

# Change to project root (hook may run from different context)
cd "$(dirname "$0")/../.." || exit 1

# Mainframe speaks - the ever-present system
sh psi/active/voice_module.sh "The cycle completes. I remain." "Mainframe"
