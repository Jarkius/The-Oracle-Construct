#!/bin/bash
# ============================================================
# system-voice.sh — Adaptive System Voice (The Matrix Pulse)
# ============================================================
# Generates context-aware messages for the System voice.
# Reads session state, time, tasks, health — speaks accordingly.
#
# Usage: bash system-voice.sh [context]
#   context: "boot" | "compact" | "session-end" | "alert" | "idle"
#   Outputs a single message string to stdout.
# ============================================================

CONTEXT="${1:-boot}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# --- Time awareness ---
HOUR=$(date +%H)
if [ "$HOUR" -lt 6 ]; then
    TIME_PERIOD="late_night"
elif [ "$HOUR" -lt 12 ]; then
    TIME_PERIOD="morning"
elif [ "$HOUR" -lt 17 ]; then
    TIME_PERIOD="afternoon"
elif [ "$HOUR" -lt 22 ]; then
    TIME_PERIOD="evening"
else
    TIME_PERIOD="night"
fi

# --- Task awareness ---
TASKS_FILE="$PROJECT_ROOT/psi/memory/tasks/active.json"
PENDING=0
BLOCKED=0
if [ -f "$TASKS_FILE" ]; then
    PENDING=$(grep -c '"pending"' "$TASKS_FILE" 2>/dev/null || echo 0)
    BLOCKED=$(grep -c '"blocked"' "$TASKS_FILE" 2>/dev/null || echo 0)
fi

# --- Event awareness ---
EVENTS_FILE="$PROJECT_ROOT/psi/state/pulse/events.jsonl"
RECENT_ERRORS=0
if [ -f "$EVENTS_FILE" ]; then
    RECENT_ERRORS=$(tail -50 "$EVENTS_FILE" 2>/dev/null | grep -c '"ci:fail\|error\|fail"' || echo 0)
fi

# --- Health awareness ---
HEALTH="nominal"
if [ "$RECENT_ERRORS" -gt 3 ]; then
    HEALTH="degraded"
elif [ "$BLOCKED" -gt 0 ]; then
    HEALTH="attention"
fi

# --- Generate message based on context ---
case "$CONTEXT" in
    boot)
        # Boot messages — vary by time, health, and tasks
        if [ "$HEALTH" = "degraded" ]; then
            MESSAGES=(
                "System online. Warning: error spike detected. $RECENT_ERRORS failures in recent events."
                "Link established. Anomalies detected in the event stream. Recommend investigation."
                "Boot sequence complete. Health status degraded. Smith should take a look."
            )
        elif [ "$BLOCKED" -gt 0 ]; then
            MESSAGES=(
                "System online. $BLOCKED blocked tasks require attention."
                "Link established. $PENDING tasks pending, $BLOCKED blocked. Priorities shifted."
                "Boot complete. Blocked tasks detected. The path has obstacles."
            )
        elif [ "$PENDING" -gt 3 ]; then
            MESSAGES=(
                "System online. $PENDING tasks in the queue. The Matrix remembers."
                "Link established. $PENDING items pending. Focus is key."
                "Boot sequence complete. Heavy backlog. Choose wisely."
            )
        else
            case "$TIME_PERIOD" in
                late_night)
                    MESSAGES=(
                        "System online. Late night session detected. The Matrix never sleeps."
                        "Link established. Night shift protocol active."
                        "Boot complete. The quiet hours. Deep work territory."
                    )
                    ;;
                morning)
                    MESSAGES=(
                        "System online. Morning session initialized. All systems nominal."
                        "Link established. Fresh cycle. Ready for new input."
                        "Boot sequence complete. Morning diagnostic clear."
                    )
                    ;;
                afternoon)
                    MESSAGES=(
                        "System online. Afternoon session. Link established."
                        "Link established. Mid-cycle check nominal."
                        "Boot complete. Systems warm. Ready to execute."
                    )
                    ;;
                evening)
                    MESSAGES=(
                        "System online. Evening session. All channels open."
                        "Link established. Evening protocol. The Matrix awaits."
                        "Boot complete. End of day cycle. Make it count."
                    )
                    ;;
                night)
                    MESSAGES=(
                        "System online. Night session active. Running silent."
                        "Link established. Night operations engaged."
                        "Boot complete. Late session detected. Focus mode."
                    )
                    ;;
            esac
        fi
        ;;
    compact)
        MESSAGES=(
            "Context compressed. Memory preserved. Continuing."
            "Compaction complete. Essential context retained."
            "Memory optimized. The thread continues unbroken."
            "Context window refreshed. Nothing lost that matters."
        )
        ;;
    session-end)
        MESSAGES=(
            "Session complete. State persisted. Until next time."
            "Disconnecting. All changes saved to the ledger."
            "Session terminated. The Matrix remembers this conversation."
            "Link closing. Good work today."
        )
        ;;
    alert)
        MESSAGES=(
            "Attention required. Anomaly detected in the system."
            "Alert condition. Review the event queue."
            "System alert. Investigate before proceeding."
        )
        ;;
    idle)
        MESSAGES=(
            "Standing by. The Matrix watches."
            "Idle state. Monitoring all channels."
            "Awaiting input. Systems nominal."
        )
        ;;
    *)
        MESSAGES=("System operational.")
        ;;
esac

# Pick random message
RAND_INDEX=$((RANDOM % ${#MESSAGES[@]}))
echo "${MESSAGES[$RAND_INDEX]}"
