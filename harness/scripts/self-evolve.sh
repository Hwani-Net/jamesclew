#!/bin/bash
# self-evolve.sh — Self-Evolving Loop
# Analyzes feedback log and suggests/applies harness improvements
#
# Called by: agent manually, or as a scheduled task
# Input: ~/.claude/hooks/state/feedback_log.jsonl
# Output: suggests new rules or hook modifications
#
# This is the "Prompt Optimization" component of the Self-Evolving Agent architecture.
# Based on: ORPO (Yang 2023), ProTeGi (Pryzant 2023), Self-Evolving Agents Survey (2025)

STATE_DIR="$HOME/.claude/hooks/state"
FEEDBACK_LOG="$STATE_DIR/feedback_log.jsonl"
MEMORY_DIR="$HOME/.claude/projects/d--jamesclew/memory"

if [ ! -f "$FEEDBACK_LOG" ]; then
  echo "No feedback log found. No evolution needed."
  exit 0
fi

TOTAL=$(wc -l < "$FEEDBACK_LOG" 2>/dev/null || echo 0)
echo "=== Self-Evolving Agent: Feedback Analysis ==="
echo "Total feedback entries: $TOTAL"
echo ""

# Analyze patterns
echo "--- Pattern Frequency ---"
echo "선언-미실행 (말만하고 안함):"
grep -c '말만\|선언\|실행.*안\|안.*해' "$FEEDBACK_LOG" 2>/dev/null || echo 0

echo "섣부른 단정 (검증 없이 결론):"
grep -c '검증\|확인.*안\|팩트\|못.*한다\|안.*됩니다' "$FEEDBACK_LOG" 2>/dev/null || echo 0

echo "검수 건너뛰기:"
grep -c '검수\|검토\|건너뛰' "$FEEDBACK_LOG" 2>/dev/null || echo 0

echo "신뢰 부족:"
grep -c '못.*믿\|신뢰\|거짓' "$FEEDBACK_LOG" 2>/dev/null || echo 0

echo ""
echo "--- Recent Feedback (last 5) ---"
tail -5 "$FEEDBACK_LOG" 2>/dev/null | while read line; do
  TS=$(echo "$line" | jq -r '.ts // empty' 2>/dev/null)
  PROMPT=$(echo "$line" | jq -r '.prompt // empty' 2>/dev/null)
  echo "  [$TS] $PROMPT"
done

echo ""
echo "--- Suggested Evolution ---"

# Check if enforce-execution hook exists
if [ -f "$HOME/.claude/hooks/enforce-execution.sh" ]; then
  echo "✅ enforce-execution.sh (Stop 훅) 존재"
else
  echo "❌ enforce-execution.sh 미설치 — bash harness/deploy.sh 실행 필요"
fi

# Check feedback frequency — if high, suggest stronger measures
if [ "$TOTAL" -gt 10 ]; then
  echo "⚠️ 피드백 10회 초과 — 규칙 강화 또는 추가 훅 필요"
fi

echo ""
echo "=== Analysis Complete ==="
