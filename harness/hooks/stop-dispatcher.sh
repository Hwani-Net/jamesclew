#!/bin/bash
# stop-dispatcher.sh — Single Stop hook dispatcher
# Replaces 5 separate Stop hooks with 1 sequential dispatcher.
# Reduces hook chain latency and prevents deadlock cascades.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"

# check_declare_execute_ratio — detects declare-without-execute pattern (P-declare_no_execute)
check_declare_execute_ratio() {
  local state_dir="$STATE_DIR"
  local declare_log="$state_dir/declare_track.log"
  local timestamp
  timestamp=$(date '+%Y-%m-%dT%H:%M:%S')

  # Extract assistant response text from Stop hook input
  local response_text
  response_text=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    # Stop hook: message may be in 'message' or nested 'content'
    msg = d.get('message', '')
    if not msg:
        content = d.get('content', [])
        if isinstance(content, list):
            msg = ' '.join(c.get('text', '') for c in content if isinstance(c, dict))
    print(msg)
except Exception:
    pass
" 2>/dev/null)

  # Count declaration patterns in response
  local decl_count=0
  local patterns=("반영합니다" "구현합니다" "진행합니다" "수정합니다" "추가합니다" "생성합니다")
  for pat in "${patterns[@]}"; do
    if echo "$response_text" | grep -qF "$pat"; then
      decl_count=$((decl_count + 1))
    fi
  done

  # Count tool calls: use tool_call_log if available, else fall back to session_changes.log line count
  local tool_calls=0
  local session_id
  session_id=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)

  local tool_log="$state_dir/tool_call_log"
  if [ -f "$tool_log" ] && [ -n "$session_id" ]; then
    tool_calls=$(grep -c "|${session_id}|" "$tool_log" 2>/dev/null || echo 0)
  else
    local changes_log="$state_dir/session_changes.log"
    if [ -f "$changes_log" ]; then
      tool_calls=$(wc -l < "$changes_log" 2>/dev/null || echo 0)
    fi
  fi

  # Log to declare_track.log
  mkdir -p "$state_dir"
  echo "${timestamp}|declarations=${decl_count}|tool_calls=${tool_calls}" >> "$declare_log"

  # Inject warning if declarations found but no tool calls in this response
  if [ "$decl_count" -gt 0 ] && [ "$tool_calls" -eq 0 ]; then
    printf '{"systemMessage":"[DECLARE-NO-EXEC] 선언만 감지, 실행 증거 없음. 즉시 실행 원칙 위반.","continue":true}\n'
    # Write flag for user-prompt-declare-warn.sh (2-file package)
    mkdir -p "$state_dir"
    echo "선언-미실행 감지 ($(date '+%H:%M:%S'))" > "$state_dir/declare_no_exec_flag"
  fi
}

# check_review_evidence — detects review declarations without numeric scores or reasoning (skip_review pattern)
check_review_evidence() {
  local state_dir="$STATE_DIR"
  local review_log="$state_dir/review_evidence.log"
  local timestamp
  timestamp=$(date '+%Y-%m-%dT%H:%M:%S')
  mkdir -p "$state_dir"

  # Extract assistant response text from Stop hook input
  local response_text
  response_text=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    msg = d.get('message', '')
    if not msg:
        content = d.get('content', [])
        if isinstance(content, list):
            msg = ' '.join(c.get('text', '') for c in content if isinstance(c, dict))
    print(msg)
except Exception:
    pass
" 2>/dev/null)

  # Check for review completion declarations
  local review_found=0
  local review_patterns=("검수 완료" "리뷰 완료" "PASS" "통과" "검증 완료")
  for pat in "${review_patterns[@]}"; do
    if echo "$response_text" | grep -qF "$pat"; then
      review_found=1
      break
    fi
  done

  [ "$review_found" -eq 0 ] && return 0

  # Check for evidence: numeric score, PASS/FAIL with items, or substantial reasoning
  local evidence_found=0

  # (a) Numeric score patterns: N/10, N점, score: N, SCORE: N
  if echo "$response_text" | grep -qiE '[0-9]+/10|[0-9]+점|score[[:space:]]*:[[:space:]]*[0-9]+'; then
    evidence_found=1
  fi

  # (b) PASS or FAIL with specific items listed (look for bullet/dash/number list near verdict)
  if [ "$evidence_found" -eq 0 ]; then
    if echo "$response_text" | grep -qiE '(PASS|FAIL)[^가-힣a-zA-Z0-9]*([-*•]|\d+\.)'; then
      evidence_found=1
    elif echo "$response_text" | grep -qiE '([-*•]|\d+\.)[^가-힣a-zA-Z0-9]*(PASS|FAIL)'; then
      evidence_found=1
    fi
  fi

  # (c) Substantial reasoning: response length > 200 chars after the first review keyword
  if [ "$evidence_found" -eq 0 ]; then
    local keyword_pos
    keyword_pos=$(echo "$response_text" | python3 -c "
import sys
text = sys.stdin.read()
keywords = ['검수 완료', '리뷰 완료', 'PASS', '통과', '검증 완료']
pos = len(text)
for kw in keywords:
    idx = text.find(kw)
    if idx != -1 and idx < pos:
        pos = idx
remainder = text[pos:] if pos < len(text) else ''
print(len(remainder))
" 2>/dev/null || echo 0)
    if [ "${keyword_pos:-0}" -gt 200 ]; then
      evidence_found=1
    fi
  fi

  # Log result
  echo "${timestamp}|review_found=1|evidence_found=${evidence_found}" >> "$review_log"

  # Inject warning if review declared but no evidence found
  if [ "$evidence_found" -eq 0 ]; then
    printf '{"systemMessage":"[SKIP-REVIEW] 검수 선언만 있고 수치/근거 없음. Multi-Pass Review 규칙 위반. 점수(N/10), PASS/FAIL 항목 목록, 또는 200자 이상의 상세 근거를 포함하세요.","continue":true}\n'
  fi
}

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

# 6. declare-execute ratio check (blocking capable, systemMessage on violation)
check_declare_execute_ratio

# 7. review evidence check (blocking capable, systemMessage on violation)
check_review_evidence

# 8. skill candidate reminder (non-blocking, systemMessage only)
check_skill_candidate

# Wait for background jobs (max 5s)
wait -n 2>/dev/null
exit 0
