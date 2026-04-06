#!/bin/bash
# self-evolve.sh — Self-Evolving Agent Loop
# Analyzes feedback log → generates feedback memories → updates harness rules
#
# Based on: ORPO (Yang 2023), Self-Evolving Agents Survey (arxiv 2507.21046)
#
# Usage: bash self-evolve.sh [--apply]
#   Without --apply: analysis only (dry run)
#   With --apply: writes feedback memories and updates rules

set -euo pipefail

APPLY="${1:-}"
STATE_DIR="$HOME/.harness-state"
FEEDBACK_LOG="$STATE_DIR/feedback_log.jsonl"
MEMORY_DIR="$HOME/.claude/projects/d--jamesclew/memory"
EVOLVE_LOG="$STATE_DIR/evolve_history.jsonl"

if [ ! -f "$FEEDBACK_LOG" ]; then
  echo "No feedback log found."
  exit 0
fi

TOTAL=$(wc -l < "$FEEDBACK_LOG" 2>/dev/null || echo 0)
echo "=== Self-Evolving Agent: Feedback Analysis ==="
echo "Total feedback entries: $TOTAL"
echo ""

# Categorize feedback patterns
declare -A PATTERNS
PATTERNS[declare_no_execute]=$(grep -cE '말만|선언|실행.*안|안.*해|하겠습니다.*안' "$FEEDBACK_LOG" 2>/dev/null || echo 0)
PATTERNS[premature_conclusion]=$(grep -cE '검증|확인.*안|팩트|못.*한다|안.*됩니다|이론.*존재' "$FEEDBACK_LOG" 2>/dev/null || echo 0)
PATTERNS[skip_review]=$(grep -cE '검수|검토|건너뛰|순서' "$FEEDBACK_LOG" 2>/dev/null || echo 0)
PATTERNS[unverified_claim]=$(grep -cE '컨텍스트.*안|체크.*안|추측|확인.*안' "$FEEDBACK_LOG" 2>/dev/null || echo 0)

echo "--- Pattern Frequency ---"
for pattern in "${!PATTERNS[@]}"; do
  echo "  $pattern: ${PATTERNS[$pattern]}"
done

# Determine which patterns need new rules (threshold: 2+ occurrences)
NEEDS_RULE=()
for pattern in "${!PATTERNS[@]}"; do
  if [ "${PATTERNS[$pattern]}" -ge 2 ] 2>/dev/null; then
    NEEDS_RULE+=("$pattern")
  fi
done

echo ""
echo "--- Patterns exceeding threshold (2+) ---"
if [ ${#NEEDS_RULE[@]} -eq 0 ]; then
  echo "  None. No evolution needed."
  exit 0
fi

for rule in "${NEEDS_RULE[@]}"; do
  echo "  ⚠️ $rule (${PATTERNS[$rule]}회)"
done

# === Audit History Analysis — find repeat FAIL items across sessions ===
AUDIT_FAIL_LOG="$STATE_DIR/audit_fail_history.jsonl"

# Run audit on recent transcripts and accumulate FAIL patterns
RECENT_TRANSCRIPTS=$(ls -t "$HOME/.claude/projects"/*/????????-????-????-????-????????????.jsonl 2>/dev/null | head -3)

for TF in $RECENT_TRANSCRIPTS; do
  SID=$(basename "$TF" .jsonl)
  # Skip if already audited
  grep -q "${SID:0:8}" "$AUDIT_FAIL_LOG" 2>/dev/null && continue
  AUDIT_RESULT=$(bash "$HOME/.claude/scripts/audit-session.sh" --full "$TF" 2>/dev/null || true)
  FAILS=$(echo "$AUDIT_RESULT" | grep '❌' | sed 's/.*❌  *//' | sed 's/  .*//')
  for FITEM in $FAILS; do
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"session\":\"${SID:0:8}\",\"fail\":\"$FITEM\"}" >> "$AUDIT_FAIL_LOG" 2>/dev/null
  done
done

# Count repeat FAIL items and save top fails for session-start warning
if [ -f "$AUDIT_FAIL_LOG" ]; then
  echo ""
  echo "--- Audit FAIL Frequency (cross-session) ---"
  grep -o '"fail":"[^"]*"' "$AUDIT_FAIL_LOG" | sort | uniq -c | sort -rn | head -5 | while read CNT ITEM; do
    CLEAN=$(echo "$ITEM" | tr -d '"' | sed 's/fail://')
    echo "  ⚠️ $CLEAN (${CNT}회)"
  done

  TOP_FAILS=$(grep -o '"fail":"[^"]*"' "$AUDIT_FAIL_LOG" | sort | uniq -c | sort -rn | head -3 | sed 's/.*"fail":"//;s/"//' | tr '\n' ', ' | sed 's/,$//')
  if [ -n "$TOP_FAILS" ]; then
    echo "$TOP_FAILS" > "$STATE_DIR/audit_top_fails"
  fi
fi

if [ "$APPLY" != "--apply" ]; then
  echo ""
  echo "Dry run. Use --apply to generate feedback memories."
  exit 0
fi

echo ""
echo "--- Generating Feedback Memories ---"
mkdir -p "$MEMORY_DIR"

# Generate feedback memory for each pattern
for rule in "${NEEDS_RULE[@]}"; do
  MEMORY_FILE="$MEMORY_DIR/feedback_auto_${rule}.md"

  # Get recent feedback examples for this pattern
  case "$rule" in
    declare_no_execute)
      DESCRIPTION="선언 후 실행하지 않는 패턴 반복 감지"
      CONTENT="\"반영합니다/구현합니다/진행합니다\" 선언 후 같은 응답에서 도구 호출을 하지 않는 패턴이 ${PATTERNS[$rule]}회 감지됨.

**Why:** 시스템 프롬프트의 \"위험 작업 확인\" 편향이 CLAUDE.md보다 우선하여 발생. 대표님이 반복 지적.

**How to apply:** 선언하는 동시에 도구 호출을 같은 응답에 포함. enforce-execution.sh Stop 훅이 구조적으로 차단하지만 의식적으로도 방지해야 함."
      ;;
    premature_conclusion)
      DESCRIPTION="검증 없이 불가능하다고 단정하는 패턴 반복 감지"
      CONTENT="\"안 됩니다/불가능합니다\" 결론을 검증 없이 내리는 패턴이 ${PATTERNS[$rule]}회 감지됨.

**Why:** 학습 데이터 기반 추측을 사실처럼 전달. 실제로 조사하면 방법이 존재하는 경우가 대부분이었음.

**How to apply:** 불가 판정 전 반드시 ① 웹 검색 ② 3회 다른 접근 시도 ③ 대안 2개 조사. enforce-execution.sh가 차단하지만 선제적으로 검색부터 해야 함."
      ;;
    skip_review)
      DESCRIPTION="검수/검토 절차를 건너뛰는 패턴 반복 감지"
      CONTENT="Multi-Pass Review Protocol을 선언해놓고 실제로는 검수를 건너뛰거나 형식적으로만 진행하는 패턴이 ${PATTERNS[$rule]}회 감지됨.

**Why:** 효율성 편향으로 검수 단계를 \"이미 했다\"고 치부. verify-deploy.sh 스크린샷 주입이 있지만 형식적으로 PASS 판정.

**How to apply:** 검수 결과를 구체적 수치(점수, FAIL 항목)로 보고. \"확인했습니다\"가 아닌 증거 제시."
      ;;
    unverified_claim)
      DESCRIPTION="검증 없이 추측으로 결론내는 패턴 반복 감지"
      CONTENT="컨텍스트 사용량, 기능 가능 여부 등을 실제 확인 없이 추측으로 답하는 패턴이 ${PATTERNS[$rule]}회 감지됨.

**Why:** 도구 호출보다 텍스트 응답이 빠르므로 확인 없이 답하는 편향.

**How to apply:** 수치가 필요한 답변은 반드시 도구(heartbeat, API 호출, 파일 읽기)로 확인 후 답변."
      ;;
  esac

  cat > "$MEMORY_FILE" << MEMEOF
---
name: Auto-evolved: ${rule}
description: ${DESCRIPTION}
type: feedback
---

${CONTENT}
MEMEOF

  echo "  ✅ Written: $MEMORY_FILE"

  # Log evolution event
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"pattern\":\"$rule\",\"count\":${PATTERNS[$rule]},\"action\":\"memory_created\"}" >> "$EVOLVE_LOG"
done

# Update MEMORY.md index
MEMORY_INDEX="$MEMORY_DIR/MEMORY.md"
for rule in "${NEEDS_RULE[@]}"; do
  if ! grep -q "feedback_auto_${rule}" "$MEMORY_INDEX" 2>/dev/null; then
    # Add to feedback section
    sed -i "/## 피드백/a - [Auto: ${rule}](feedback_auto_${rule}.md) — 자동 감지된 반복 패턴 (${PATTERNS[$rule]}회)" "$MEMORY_INDEX" 2>/dev/null
    echo "  ✅ MEMORY.md index updated: $rule"
  fi
done

echo ""
echo "=== Evolution Complete ==="
echo "Generated ${#NEEDS_RULE[@]} feedback memories."
echo "History logged to: $EVOLVE_LOG"
