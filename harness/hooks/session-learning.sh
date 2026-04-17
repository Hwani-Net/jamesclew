#!/bin/bash
# ============================================================================
# SESSION LEARNING HOOK
# Stop 이벤트 트리거 — 세션 종료 시 학습 내용을 gbrain에 누적 저장.
#
# 저장 내용:
#   1. PITFALLS 신규 기록 (마지막 저장 이후 추가된 P-NNN 항목)
#   2. 외부 LLM 검수 결과 요약 (regression-failed.log 등)
#   3. 대표님 교정 패턴 (user-prompt hook이 기록한 feedback 이벤트)
#
# 다음 세션 recall:
#   SessionStart hook 또는 세션 시작 시 수동으로:
#   gbrain query "session-$(date -d '7 days ago' +%Y-%m-%d)" 으로 최근 학습 조회
# ============================================================================

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

SLUG="session-$(date +%Y-%m-%d-%H%M)"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LAST_LEARNING_FILE="$STATE_DIR/last_learning_slug"
FEEDBACK_LOG="$STATE_DIR/session_feedback.log"
REGRESSION_LOG="$STATE_DIR/regression-failed.log"

# ── 1. PITFALLS 신규 기록 추출 (gbrain 기반) ─────────────────────────────
# PITFALLS.md는 harness/archive/로 이동됨 (2026-04-17 마이그레이션)
# 신규 pitfall은 gbrain put pitfall-NNN-{slug} 로 직접 저장됨
# 세션 요약은 gbrain query "pitfall" 으로 검색 가능
NEW_PITFALLS=""
# NEW_PITFALLS에는 오늘 추가된 pitfall gbrain 슬러그 목록을 기록
if command -v gbrain >/dev/null 2>&1; then
  TODAY=$(date +%Y-%m-%d)
  NEW_PITFALLS=$(gbrain list --limit 10 2>/dev/null | grep "pitfall-" | grep "$TODAY" || true)
fi

# ── 2. 회귀 테스트 실패 수집 ──────────────────────────────────────────────
REGRESSION_SUMMARY=""
if [ -f "$REGRESSION_LOG" ]; then
  # 오늘 날짜 항목만
  TODAY=$(date +%Y-%m-%d)
  REGRESSION_SUMMARY=$(grep "$TODAY" "$REGRESSION_LOG" 2>/dev/null || true)
fi

# ── 3. 피드백/교정 패턴 수집 ─────────────────────────────────────────────
FEEDBACK_SUMMARY=""
if [ -f "$FEEDBACK_LOG" ]; then
  TODAY=$(date +%Y-%m-%d)
  FEEDBACK_SUMMARY=$(grep "$TODAY" "$FEEDBACK_LOG" 2>/dev/null | tail -20 || true)
fi

# ── 4. 저장 내용이 없으면 스킵 ───────────────────────────────────────────
if [ -z "$NEW_PITFALLS" ] && [ -z "$REGRESSION_SUMMARY" ] && [ -z "$FEEDBACK_SUMMARY" ]; then
  echo "[session-learning] 신규 학습 내용 없음 — 저장 스킵"
  exit 0
fi

# ── 5. gbrain put으로 저장 ───────────────────────────────────────────────
CONTENT=$(cat << LEARNING_EOF
# Session Learning — ${TIMESTAMP}

## PITFALLS 신규 기록
${NEW_PITFALLS:-"(없음)"}

## 회귀 테스트 실패 패턴
${REGRESSION_SUMMARY:-"(없음)"}

## 대표님 교정 패턴
${FEEDBACK_SUMMARY:-"(없음)"}

## 다음 세션 recall 방법
\`\`\`bash
gbrain query "session 학습 $(date +%Y-%m-%d)"
\`\`\`
LEARNING_EOF
)

# gbrain CLI로 저장 (서버 실행 중인 경우)
if command -v gbrain >/dev/null 2>&1; then
  gbrain put "$SLUG" --content "$CONTENT" 2>/dev/null && {
    echo "[session-learning] gbrain 저장 완료: $SLUG"
    echo "$SLUG" > "$LAST_LEARNING_FILE"
  } || echo "[session-learning] gbrain put 실패 — 로컬 백업으로 저장"
else
  echo "[session-learning] gbrain CLI 없음 — 로컬 백업으로 저장"
fi

# 로컬 백업 (gbrain 실패 또는 미설치 시)
BACKUP_FILE="$STATE_DIR/learning-${SLUG}.md"
echo "$CONTENT" > "$BACKUP_FILE"
echo "[session-learning] 로컬 백업 저장: $BACKUP_FILE"

# 마지막 슬러그 기록
echo "$SLUG" > "$LAST_LEARNING_FILE"
