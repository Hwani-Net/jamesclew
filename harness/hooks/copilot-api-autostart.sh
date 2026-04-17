#!/bin/bash
# JamesClaw Agent — copilot-api auto-start on SessionStart
# 4141 health check → dead면 백그라운드 기동. 5초 이내 반환.

STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"
LOG="$STATE_DIR/copilot-api.log"

# Health check (2초 타임아웃)
if curl -s --max-time 2 http://localhost:4141/v1/models > /dev/null 2>&1; then
  exit 0
fi

# Dead → 백그라운드 기동. npm global bin이 PATH에 있어야 함.
if ! command -v copilot-api > /dev/null 2>&1; then
  echo "[copilot-api-autostart] binary not found, skipping" >> "$LOG"
  exit 0
fi

nohup copilot-api start --port 4141 > "$LOG" 2>&1 &
START_PID=$!
echo "[copilot-api-autostart] started pid=$START_PID at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"

# 최대 3초 대기하며 ready 확인 (non-blocking스럽게)
for i in 1 2 3; do
  sleep 1
  if curl -s --max-time 1 http://localhost:4141/v1/models > /dev/null 2>&1; then
    echo "[copilot-api-autostart] ready after ${i}s" >> "$LOG"
    break
  fi
done

exit 0
