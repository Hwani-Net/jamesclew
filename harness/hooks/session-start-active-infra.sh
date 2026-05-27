#!/bin/bash
# session-start-active-infra.sh — SessionStart hook
# 매 세션 시작 시 활성 자율 인프라 + 핵심 정책 alert. 다음 세션 메인이 즉시 인지.
# CLAUDE.md '활성 자율 인프라' 섹션과 동기화 (1차 소스: CLAUDE.md).
# v2: ~/.harness-state/session-start-active-infra.log 사후 검증 로그 추가 (P-C2)

# stdin은 한 번만 읽어 변수에 저장
STDIN_DATA="$(cat)"

MSG="[ACTIVE INFRA] hook: cdp-auto-ensure(v2)+cdp-mark-fail / agentmemory-mirror-obsidian / pre-compact-snapshot. LIVE: multi-blog-personal.web.app (13p, source: D:/AI 비즈니스/smartreview) + gpt-korea.com/reviews (rewrite proxy). 핵심 정책: P-163(로컬 보조전용) / P-167(흐름 중단 금지) / P-168(자율 결정·결재 5건만) / P-169(CDP 자율) / P-218(sub-agent 위임 시 OpenClaw 작업은 WSL2 절대 경로 /home/creator/... 또는 wsl -d Ubuntu -e bash -c '...' 명시 강제, Windows 경로 C:/, /mnt/c/ 사용 금지). CLAUDE.md 'STICKY DECISIONS > 활성 자율 인프라' 섹션이 1차 소스 — 신규 hook/인프라 추가 시 그 섹션 동시 등록 필수."

# stdout JSON for additionalContext injection (기존 동작 보존)
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MSG"

# --- 사후 검증 로그 기록 ---
# session_id 추출 우선순위: stdin JSON > CLAUDE_CODE_SESSION_ID env > "unknown"
SESSION_ID=""
if command -v jq >/dev/null 2>&1; then
  SESSION_ID="$(printf '%s' "$STDIN_DATA" | jq -r '.session_id // empty' 2>/dev/null)"
fi
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID="${CLAUDE_CODE_SESSION_ID:-unknown}"
fi

TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo 'unknown-time')"
LOG_LINE="[${TIMESTAMP}] session_id=${SESSION_ID} active_infra_loaded"
LOG_DIR="$HOME/.harness-state"
LOG_FILE="$LOG_DIR/session-start-active-infra.log"

if [[ "${TEST_HARNESS:-}" == "1" ]]; then
  # TEST 모드: 파일 쓰기 skip, stdout에 mock 출력만
  printf '[TEST] would log: %s\n' "$LOG_LINE"
else
  # 실모드: 디렉토리 생성 후 로그 append (실패해도 hook 전체에 영향 없음)
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  printf '%s\n' "$LOG_LINE" >> "$LOG_FILE" 2>/dev/null || true
fi
