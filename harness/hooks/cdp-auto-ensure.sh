#!/bin/bash
# cdp-auto-ensure.sh — Bash 명령에 'localhost:9222' / 'cdp-' / 'partners.coupang' 감지 시
# Chrome CDP 9222 자율 보장 (P-169 인프라). 살아있으면 skip, 아니면 start-cdp-chrome.ps1 자동 호출.

# TEST_HARNESS=1 분기 (테스트 시 mock)
if [[ -n "$TEST_HARNESS" ]]; then
  echo "[cdp-auto-ensure] TEST: skipped (TEST_HARNESS=1)"
  exit 0
fi

# stdin JSON 파싱
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Bash 도구가 아니면 skip
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# 트리거 키워드 매칭 (대소문자 무시)
if ! echo "$command" | grep -iqE "(localhost:9222|cdp-[a-z]+\.js|partners\.coupang\.com)"; then
  exit 0
fi

# 이미 9222 살아있으면 skip
if curl -s --max-time 2 http://localhost:9222/json/version > /dev/null 2>&1; then
  exit 0
fi

# 자동 시작 (PowerShell 스크립트, 최대 20초 대기)
echo "[cdp-auto-ensure] CDP 9222 끊김 감지 → 자율 재시작" >&2
SCRIPT="$HOME/.claude/scripts/start-cdp-chrome.ps1"
# 대표님 환경 path 후보 (deploy.sh 배포 위치)
if [[ ! -f "$SCRIPT" ]]; then
  SCRIPT="D:/jamesclew/harness/scripts/start-cdp-chrome.ps1"
fi
if [[ ! -f "$SCRIPT" ]]; then
  echo "[cdp-auto-ensure] ERR: start-cdp-chrome.ps1 not found" >&2
  exit 0
fi

powershell -ExecutionPolicy Bypass -File "$SCRIPT" 2>&1 | head -3 >&2
# 포트 살아날 때까지 추가 wait (스크립트 자체가 15초 polling, 여기서 추가 안전망)
tries=0
while [[ $tries -lt 10 ]]; do
  if curl -s --max-time 2 http://localhost:9222/json/version > /dev/null 2>&1; then
    echo "[cdp-auto-ensure] CDP 재시작 완료 (추가 wait $tries초)" >&2
    exit 0
  fi
  sleep 1
  tries=$((tries + 1))
done

echo "[cdp-auto-ensure] WARN: CDP 재시작 timeout, Bash 명령 진행" >&2
exit 0
