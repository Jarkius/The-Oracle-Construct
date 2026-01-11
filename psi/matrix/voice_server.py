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

# Configuration
HOST = '127.0.0.1'
PORT = 6969
LOCK_FILE = '/tmp/matrix_voice_server.lock'

# Logging Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
LOG_DIR = os.path.join(PROJECT_ROOT, 'psi', 'memory', 'logs', 'voice')
LOG_FILE = os.path.join(LOG_DIR, 'voice_server.log')

# Ensure log directory exists
os.makedirs(LOG_DIR, exist_ok=True)

def log(message):
    """Log to both console and file with timestamp."""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f"[{timestamp}] {message}"
    print(line)
    sys.stdout.flush()
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(line + '\n')
    except Exception:
        pass  # Don't crash on log failure

# The Voice Queue
# Stores tuples: (text, speaker, is_panic)
voice_queue = queue.Queue()

# Current Playback Process (for Panic management if needed, though we prefer mixing for Panic)
current_process = None

def get_voice_cmd(text, speaker):
    """
    Constructs the command to generate and play audio.
    This logic mimics the previous voice_module.sh logic.
    For simplicity in this V1, we will call back to a helper script or use direct logic.
    To avoid code duplication, we can reuse `voice_module.sh` in a 'legacy-standalone' mode 
    OR (better) implement the generation logic here.
    
    Given the complexity of the bash script (voices.json parsing, special overrides for Smith/Tank),
    the SAFEST path is to have the server call a "worker" script that does the generation/playback.
    
    Let's create `psi/active/voice_worker.sh` that takes inputs and plays them.
    But `voice_module.sh` is already that script!
    
    Wait. If we call `voice_module.sh` from here, `voice_module.sh` currently has locking logic.
    We need to STRIP locking from `voice_module.sh` or make it optional.
    
    Strategy:
    1. Server calls `bash psi/active/voice_worker.sh "text" "speaker"`
    2. `voice_worker.sh` contains the generation/playback logic (no locking).
    """
    # For now, let's assume we split voice_module.sh. 
    # Or, we pass a flag to voice_module.sh to SKIP locking.
    # Let's use "--worker" flag.
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
