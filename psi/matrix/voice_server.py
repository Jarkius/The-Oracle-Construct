"""
============================================================
voice_server.py - Voice SERVER (The Queue Daemon)
============================================================

PURPOSE:
  Background daemon that manages voice playback for the Matrix.
  Ensures agents speak ONE AT A TIME (no overlapping voices).

ARCHITECTURE:
  ┌─────────────┐      ┌──────────────────┐      ┌───────────┐
  │  voice.sh   │ ──── │ voice_server.py  │ ──── │ Piper TTS │
  │  (CLIENT)   │ TCP  │ (THIS SERVER)    │ call │  (AUDIO)  │
  └─────────────┘      └──────────────────┘      └───────────┘

HOW IT WORKS:
  1. Server listens on TCP port 6969
  2. voice.sh sends JSON: {"text": "...", "speaker": "...", "panic": false}
  3. Server adds request to queue
  4. Worker thread processes queue sequentially
  5. For each item: calls voice.sh --worker to generate/play audio
  6. Next item plays only after current finishes

QUEUE vs PANIC:
  - QUEUE (default): Requests wait their turn, orderly playback
  - PANIC (--panic): Bypasses queue, plays immediately in new thread
    Use for urgent messages that can't wait

THREADING MODEL:
  - Main thread: Accepts TCP connections
  - Worker thread: Processes queue sequentially (daemon thread)
  - Panic threads: Spawned on-demand for immediate playback

FILES:
  - Lock file: /tmp/matrix_voice_server.lock (contains PID)
  - Log file: psi/memory/logs/voice/voice_server.log

USAGE:
  Start:   python3 psi/matrix/voice_server.py &
  Stop:    kill $(cat /tmp/matrix_voice_server.lock)
  Check:   pgrep -f voice_server.py

IMPORTANT:
  - Must be running for voice.sh to work
  - Auto-started by session-start hook
  - Restart after code changes (server caches code)

============================================================
"""

import socket
import threading
import json
import subprocess
import time
import os
import queue
import signal
import sys
from datetime import datetime

# ============================================================
# CONFIGURATION
# ============================================================
HOST = '127.0.0.1'          # Listen on localhost only
PORT = 6969                  # TCP port for voice requests
LOCK_FILE = '/tmp/matrix_voice_server.lock'  # PID file

# ============================================================
# LOGGING SETUP
# ============================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
LOG_DIR = os.path.join(PROJECT_ROOT, 'psi', 'memory', 'logs', 'voice')
LOG_FILE = os.path.join(LOG_DIR, 'voice_server.log')

# Ensure log directory exists
os.makedirs(LOG_DIR, exist_ok=True)

def log(message):
    """
    Log to both console and file with timestamp.
    Logs go to: psi/memory/logs/voice/voice_server.log
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f"[{timestamp}] {message}"
    print(line)
    sys.stdout.flush()
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(line + '\n')
    except Exception:
        pass  # Don't crash on log failure

# ============================================================
# THE VOICE QUEUE
# ============================================================
# This queue ensures voices play one at a time
# Each item is a tuple: (text, speaker, is_panic)
voice_queue = queue.Queue()

# Track current playback process (for potential interruption)
current_process = None

def get_voice_cmd(text, speaker):
    """
    Build command to generate and play audio.

    Calls voice.sh with --worker flag, which:
    1. Skips the client mode (no TCP send)
    2. Goes directly to Piper TTS generation
    3. Plays the audio file

    The --worker flag is essential - without it, voice.sh would
    try to send back to THIS server, causing infinite loop!
    """
    cmd = ["bash", "./psi/matrix/voice.sh", text, speaker, "--worker"]
    return cmd

def process_queue():
    """
    Worker thread that consumes the queue sequentially.
    """
    global current_process
    log("✅ Voice Server: Queue Worker Started")
    
    while True:
        try:
            # Block until we get an item
            item = voice_queue.get()
            text, speaker, is_panic = item

            if is_panic:
                # Panic messages are handled immediately by the connection thread, 
                # so they shouldn't usually end up here unless we want them queued?
                # No, Panic = Instant.
                # So this block is for standard messages.
                pass
            
            log(f"🎙️ Processing: {speaker} - {text[:20]}...")
            
            # Execute the audio generation/playback
            # This must BLOCK until audio is done to maintain the queue
            cmd = get_voice_cmd(text, speaker)
            
            # Run user's script
            # We want to wait for it to finish
            proc = subprocess.Popen(cmd)
            current_process = proc
            proc.wait()
            current_process = None
            
            log(f"✅ Finished: {speaker}")
            
            voice_queue.task_done()
            
        except Exception as e:
            log(f"❌ Error in worker: {e}")

def handle_client(conn, addr):
    """
    Handles incoming TCP connections.
    """
    try:
        data = conn.recv(4096).decode('utf-8')
        if not data:
            return
            
        # Expecting JSON: {"text": "...", "speaker": "...", "panic": true/false}
        request = json.loads(data)
        text = request.get("text", "")
        speaker = request.get("speaker", "System")
        panic = request.get("panic", False)
        
        if not text:
            return

        if panic:
            log(f"🚨 PANIC REQUEST: {speaker}")
            # Launch immediately in a separate thread (Barge-In)
            # Do NOT check queue. Do NOT wait.
            cmd = get_voice_cmd(text, speaker)
            threading.Thread(target=subprocess.run, args=(cmd,)).start()
            conn.sendall(b"OK: Panic Triggered")
        else:
            log(f"📥 Queued: {speaker}")
            # Standard Queue
            voice_queue.put((text, speaker, False))
            conn.sendall(b"OK: Queued")

    except json.JSONDecodeError:
        log("❌ Invalid JSON received")
        conn.sendall(b"Error: Invalid JSON")
    except Exception as e:
        log(f"❌ Error handling client: {e}")
    finally:
        conn.close()

def start_server():
    # Write PID to lock file
    with open(LOCK_FILE, 'w') as f:
        f.write(str(os.getpid()))
        
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # Allow reuse of port immediately after kill
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((HOST, PORT))
        server.listen(20)
        log(f"🚀 Matrix Voice Server listening on {HOST}:{PORT}")
        
        # Start the Queue Worker
        threading.Thread(target=process_queue, daemon=True).start()
        
        while True:
            conn, addr = server.accept()
            threading.Thread(target=handle_client, args=(conn, addr)).start()
            
    except Exception as e:
        log(f"❌ Server Crash: {e}")
    finally:
        server.close()
        if os.path.exists(LOCK_FILE):
            os.remove(LOCK_FILE)

if __name__ == "__main__":
    start_server()
