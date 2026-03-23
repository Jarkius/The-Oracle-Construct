#!/bin/bash
# play-tts-windows.sh — Windows TTS provider using PowerShell System.Speech
# Called by voice.sh worker mode or provider-manager on Windows

MESSAGE="$1"
SPEAKER="${2:-System}"

if [ -z "$MESSAGE" ]; then
  echo "Usage: $0 \"Message\" [SpeakerName]"
  exit 1
fi

# Map Matrix agents to Windows SAPI voices
case "$SPEAKER" in
  Oracle|Trinity) VOICE="Microsoft Zira Desktop" ;;
  Neo|Tank|Architect) VOICE="Microsoft David Desktop" ;;
  Smith|Mainframe) VOICE="Microsoft Mark Desktop" ;;
  *) VOICE="Microsoft David Desktop" ;;
esac

# Escape single quotes in message for PowerShell
SAFE_MSG="${MESSAGE//\'/\'\'}"

powershell.exe -Command "
  Add-Type -AssemblyName System.Speech
  \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
  try { \$synth.SelectVoice('$VOICE') } catch { }
  \$synth.Rate = 1
  \$synth.Speak('$SAFE_MSG')
" 2>/dev/null

exit $?
