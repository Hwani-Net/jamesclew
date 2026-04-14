#!/bin/bash
# stop-dispatcher.sh — Single Stop hook dispatcher
# Replaces 5 separate Stop hooks with 1 sequential dispatcher.
# Reduces hook chain latency and prevents deadlock cascades.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"

# check_skill_candidate — detects complex sessions and reminds to save reusable skills
check_skill_candidate() {
  local tool_log="$STATE_DIR/tool_call_log"
  [ -f "$tool_log" ] || return 0

  # Extract current session_id from hook input (JSON field)
  local session_id
  session_id=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
  [ -z "$session_id" ] && return 0

  # Count tool calls for this session
  local count
  count=$(grep -c "|${session_id}|" "$tool_log" 2>/dev/null || echo 0)

  if [ "$count" -ge 20 ]; then
    printf '{"systemMessage":"이번 세션에서 복합 작업을 수행했습니다. 재사용 가능한 절차가 있다면 commands/에 스킬로 저장하고 gbrain put으로 동시 기록하세요.","continue":true}\n'
  fi
}

# 1. enforce-execution (block capable)
RESULT=$(echo "$INPUT" | bash "$HOME/.claude/hooks/enforce-execution.sh" 2>&1)
if echo "$RESULT" | grep -q '"decision":"block"'; then
  echo "$RESULT"
  exit 0
fi

# 2. evidence-first (block capable)
RESULT=$(echo "$INPUT" | bash "$HOME/.claude/hooks/evidence-first.sh" 2>&1)
if echo "$RESULT" | grep -q '"decision":"block"'; then
  echo "$RESULT"
  exit 0
fi

# 3. self-evolve (non-blocking, background-safe)
bash "$HOME/.claude/scripts/self-evolve.sh" --apply >/dev/null 2>&1 &

# 4. curation (non-blocking, skip if MEMORY_CURATOR_ACTIVE)
if [ "$MEMORY_CURATOR_ACTIVE" != "1" ]; then
  node --experimental-strip-types "$HOME/.claude/hooks/curation.ts" <<< "$INPUT" >/dev/null 2>&1 &
fi

# 5. telegram stop (non-blocking)
RESULT_FILE="$STATE_DIR/last_result.txt"
if [ -f "$RESULT_FILE" ]; then
  RESULT_CONTENT=$(cat "$RESULT_FILE")
  rm -f "$RESULT_FILE"
  if [ -n "$RESULT_CONTENT" ]; then
    bash "$HOME/.claude/hooks/telegram-notify.sh" done "$RESULT_CONTENT" >/dev/null 2>&1 &
  fi
fi

# 6. skill candidate reminder (non-blocking, systemMessage only)
check_skill_candidate

# Wait for background jobs (max 5s)
wait -n 2>/dev/null
exit 0
