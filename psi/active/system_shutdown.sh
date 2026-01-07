#!/bin/bash
# System Shutdown Protocol: "Unplug."
# Usage: ./psi/active/system_shutdown.sh

echo "---------------------------------------------------"
echo "🔌 SYSTEM SHUTDOWN: Terminating Connection..."
echo "---------------------------------------------------"

# 1. SAVE STATE (Optional - current state is already in matrix.json)
echo "💾 Saving Matrix Configuration..."
if [ -f ".claude/config/matrix.json" ]; then
    echo "   -> Configuration Preserved."
else
    echo "   -> Warning: Persistence file missing."
fi

# 2. VOICE SIGNOFF
echo "---------------------------------------------------"
./psi/active/voice_module.sh "Carrier signal lost. Free your mind." "System"
echo "🏛️ ARCHITECT: Connection Terminated."
echo "---------------------------------------------------"

exit 0
