#!/bin/bash
# ============================================================================
# SESSION LEARNING HOOK
# Stop 이벤트 트리거 — 세션 종료 시 학습 내용을 로컬에 백업.
#
# 저장 내용:
#   1. PITFALLS 신규 기록 (마지막 저장 이후 추가된 P-NNN 항목)
#   2. 외부 LLM 검수 결과 요약 (regression-failed.log 등)
#   3. 대표님 교정 패턴 (user-prompt hook이 기록한 feedback 이벤트)
#
# DEPRECATED 2026-05-19 (P-172): gbrain 폐기. 로컬 백업 파일만 생성.
# 다음 세션 recall: agentmemory MCP (memory_recall) 또는
#   grep -ri "키워드" $OBSIDIAN_VAULT/05-wiki/
# ============================================================================

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

SLUG="session-$(date +%Y-%m-%d-%H%M)"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LAST_LEARNING_FILE="$STATE_DIR/last_learning_slug"
FEEDBACK_LOG="$STATE_DIR/session_feedback.log"
REGRESSION_LOG="$STATE_DIR/regression-failed.log"

# ── 1. PITFALLS 신규 기록 추출 (파일 시스템 기반) ────────────────────────
NEW_PITFALLS=""
LAST_PITFALL_FILE="$STATE_DIR/last_processed_pitfall_slug"
PITFALLS_DIR="D:/jamesclew/harness/pitfalls"

if [ -d "$PITFALLS_DIR" ]; then
  LAST_PROCESSED=$(cat "$LAST_PITFALL_FILE" 2>/dev/null || echo "")
  # List pitfall files sorted by modification time (newest first), limit 5
  ALL_PITFALLS=$(ls -t "$PITFALLS_DIR"/pitfall-*.md 2>/dev/null | xargs -I{} basename {} .md | head -10 || true)
  if [ -n "$ALL_PITFALLS" ]; then
    if [ -n "$LAST_PROCESSED" ] && echo "$ALL_PITFALLS" | grep -q "^${LAST_PROCESSED}$"; then
      NEW_PITFALLS=$(echo "$ALL_PITFALLS" | awk -v stop="$LAST_PROCESSED" '$0 == stop { exit } { print }')
    else
      NEW_PITFALLS=$(echo "$ALL_PITFALLS" | head -5)
    fi
  fi
fi

# ── 2. 회귀 테스트 실패 수집 ──────────────────────────────────────────────
REGRESSION_SUMMARY=""
if [ -f "$REGRESSION_LOG" ]; then
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

# ── 5. 로컬 파일 백업 ────────────────────────────────────────────────────
# DEPRECATED 2026-05-19 (P-172): gbrain put 제거. 로컬 백업만 유지.
# Recall: agentmemory MCP 또는 Obsidian vault grep
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
grep -ri "키워드" "\$OBSIDIAN_VAULT/05-wiki/"
# 또는 agentmemory: mcp__agentmemory__memory_recall
\`\`\`
LEARNING_EOF

echo "[session-learning] 로컬 백업 저장: $BACKUP_FILE"

# 마지막 슬러그 기록
echo "$SLUG" > "$LAST_LEARNING_FILE"

# 마지막 처리한 pitfall 슬러그 기록 (incremental 추출 anchor)
if [ -n "$NEW_PITFALLS" ]; then
  TOP_PITFALL=$(echo "$NEW_PITFALLS" | head -1)
  [ -n "$TOP_PITFALL" ] && echo "$TOP_PITFALL" > "$LAST_PITFALL_FILE"
fi
