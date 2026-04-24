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

# ── 5. 파일 백업 + gbrain put ───────────────────────────────────────────
# pitfall-064: Windows Git Bash 에서는 `gbrain put < file` 이 `/dev/stdin` 미지원으로 실패.
# 실증 결과 `gbrain put --content "$VAR"` 방식이 multi-line (줄바꿈·백틱·따옴표) 모두 무결하게 저장됨.
# 따라서 Windows 기본은 --content 방식을 사용. Unix 계열에서도 동일 동작.
BACKUP_FILE="$STATE_DIR/learning-${SLUG}.md"

cat > "$BACKUP_FILE" << LEARNING_EOF
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

echo "[session-learning] 로컬 백업 저장: $BACKUP_FILE"

# gbrain CLI 로 저장 (--content 방식, Windows 호환)
if command -v gbrain >/dev/null 2>&1; then
  CONTENT=$(cat "$BACKUP_FILE")
  if gbrain put "$SLUG" --content "$CONTENT" 2>/dev/null >/dev/null; then
    echo "[session-learning] gbrain 저장 완료: $SLUG"
  else
    echo "[session-learning] gbrain put 실패 — 로컬 백업만 유지"
  fi
else
  echo "[session-learning] gbrain CLI 없음 — 로컬 백업만 유지"
fi

# 마지막 슬러그 기록
echo "$SLUG" > "$LAST_LEARNING_FILE"
