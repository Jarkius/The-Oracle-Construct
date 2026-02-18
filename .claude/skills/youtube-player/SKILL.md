---
name: youtube-player
description: Play YouTube videos as audio on local machine with controls. Use when user wants to play YouTube links, control playback (play/stop/pause), adjust volume, enable loop mode, or set auto-stop timer. Supports commands: play, stop, status, volume, loop, duration timer.
---

# YouTube Audio Player

Play YouTube videos as audio with full controls on the local machine.

## Requirements

- yt-dlp (for extracting audio streams)
- mpv (for audio playback)

Install if missing:
```bash
# macOS
brew install yt-dlp mpv

# Linux (apt)
sudo apt install yt-dlp mpv
```

## Commands

### Play a URL
```bash
# Extract best audio stream URL and play via mpv
AUDIO_URL=$(yt-dlp -f "bestaudio" --get-url "$YOUTUBE_URL" 2>/dev/null)
mpv --no-video --really-quiet --terminal=no "$AUDIO_URL" &
echo $! > /tmp/matrix-player.pid
echo "Playing: $(yt-dlp --get-title "$YOUTUBE_URL" 2>/dev/null)"
```

### Play a Search Query (no URL needed)
```bash
# Search YouTube and play first result
SEARCH_URL=$(yt-dlp "ytsearch1:$QUERY" --get-url -f "bestaudio" 2>/dev/null)
TITLE=$(yt-dlp "ytsearch1:$QUERY" --get-title 2>/dev/null)
mpv --no-video --really-quiet --terminal=no "$SEARCH_URL" &
echo $! > /tmp/matrix-player.pid
echo "Playing: $TITLE"
```

### Stop Playback
```bash
if [ -f /tmp/matrix-player.pid ]; then
  kill $(cat /tmp/matrix-player.pid) 2>/dev/null
  rm /tmp/matrix-player.pid
  echo "Playback stopped."
else
  # Kill any mpv instances
  pkill -f "mpv --no-video" 2>/dev/null
  echo "Playback stopped."
fi
```

### Pause / Resume
```bash
# Send pause toggle to mpv via IPC
if [ -f /tmp/matrix-player.pid ]; then
  kill -STOP $(cat /tmp/matrix-player.pid)  # Pause
  # or
  kill -CONT $(cat /tmp/matrix-player.pid)  # Resume
fi
```

### Check Status
```bash
if [ -f /tmp/matrix-player.pid ] && kill -0 $(cat /tmp/matrix-player.pid) 2>/dev/null; then
  echo "Player is running (PID: $(cat /tmp/matrix-player.pid))"
else
  echo "No active playback"
fi
```

### Volume Control
```bash
# mpv with IPC socket for volume control
mpv --no-video --really-quiet --input-ipc-server=/tmp/matrix-mpv-socket "$AUDIO_URL" &
echo $! > /tmp/matrix-player.pid

# Set volume (0-100)
echo '{"command": ["set_property", "volume", 50]}' | socat - /tmp/matrix-mpv-socket
```

### Loop Mode
```bash
# Play on loop
mpv --no-video --really-quiet --loop=inf --input-ipc-server=/tmp/matrix-mpv-socket "$AUDIO_URL" &
echo $! > /tmp/matrix-player.pid
echo "Looping: $TITLE"
```

### Auto-Stop Timer
```bash
# Stop after N minutes
(sleep ${MINUTES}m && kill $(cat /tmp/matrix-player.pid) 2>/dev/null && rm /tmp/matrix-player.pid) &
echo "Auto-stop set for ${MINUTES} minutes"
```

## Advanced: Play with IPC (Full Control)

For full control, always launch mpv with IPC socket:
```bash
AUDIO_URL=$(yt-dlp -f "bestaudio" --get-url "$YOUTUBE_URL" 2>/dev/null)
TITLE=$(yt-dlp --get-title "$YOUTUBE_URL" 2>/dev/null)
mpv --no-video --really-quiet --input-ipc-server=/tmp/matrix-mpv-socket "$AUDIO_URL" &
echo $! > /tmp/matrix-player.pid
echo "Now playing: $TITLE"
```

Then control with:
```bash
# Pause/resume
echo '{"command": ["cycle", "pause"]}' | socat - /tmp/matrix-mpv-socket

# Volume
echo '{"command": ["set_property", "volume", 75]}' | socat - /tmp/matrix-mpv-socket

# Seek forward 30s
echo '{"command": ["seek", "30"]}' | socat - /tmp/matrix-mpv-socket

# Get current position
echo '{"command": ["get_property", "time-pos"]}' | socat - /tmp/matrix-mpv-socket
```

## Usage Examples

- "Play this YouTube video" → Extract audio, play via mpv
- "Play some lo-fi beats" → Search "lo-fi beats", play first result
- "Stop the music" → Kill mpv process
- "Set volume to 50" → IPC command to mpv
- "Loop this song" → Restart with --loop=inf
- "Stop playing in 30 minutes" → Timer kill

## Matrix Integration

Use Matrix voice for announcements:
```bash
sh psi/matrix/voice.sh "Now playing: $TITLE" "Neo"
```

## Notes

- Audio plays in background — does not block the terminal
- PID tracked at /tmp/matrix-player.pid for process management
- IPC socket at /tmp/matrix-mpv-socket for runtime control
- Works with any YouTube URL, playlist URL, or search query
- yt-dlp handles age-restricted content, geo-blocked content (with --geo-bypass)
