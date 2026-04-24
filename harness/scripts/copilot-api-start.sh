#!/usr/bin/env bash
# copilot-api 시작 래퍼: 포트 4141 잔존 프로세스 자동 정리 후 시작
PORT=4141

# 기존 프로세스 정리
EXISTING=$(netstat -ano 2>/dev/null | grep ":${PORT}.*LISTENING" | awk '{print $5}' | head -1)
if [[ -n "$EXISTING" ]]; then
  echo "포트 ${PORT} 점유 PID ${EXISTING} 종료 중..."
  powershell -Command "Stop-Process -Id ${EXISTING} -Force -ErrorAction SilentlyContinue" 2>/dev/null
  sleep 1
fi

echo "copilot-api 시작 (port ${PORT})..."
copilot-api start --port "$PORT"
