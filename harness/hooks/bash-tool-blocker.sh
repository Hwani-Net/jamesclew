#!/bin/bash
# bash-tool-blocker.sh — PreToolUse hook for Bash
# Blocks Bash commands that should use dedicated tools (Read/Grep/Glob).
# Rationale: dedicated tools are 5-10x more token-efficient and auditable.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Extract first significant command (skip cd, env assignments)
# e.g., "cd /foo && cat bar" → "cat"
FIRST=$(echo "$CMD" | sed -E 's/^[[:space:]]*//' | \
  sed -E 's/^cd[[:space:]]+[^&;]+[[:space:]]*(&&|;)[[:space:]]*//' | \
  sed -E 's/^[A-Z_]+=[^[:space:]]+[[:space:]]+//' | \
  awk '{print $1}')

# Patterns to block — single-purpose calls only (not part of a pipeline)
BLOCK_MSG=""
case "$FIRST" in
  cat|head|tail)
    # Allow if piped or part of complex command
    if ! echo "$CMD" | grep -qE '\||>|<|\$\(|`'; then
      BLOCK_MSG="❌ '$FIRST'은 Read 도구를 사용하세요. Bash $FIRST는 토큰 비효율 + 라인번호 없음 + auditability 손실. 단순 파일 읽기는 Read tool 필수."
    fi
    ;;
  ls)
    # ls는 대부분 케이스 허용. 순수 `ls` (인자 없음)만 차단.
    # 허용: ls -l*, ls <path>, ls *.ext, ls <dir>/*, pipe/redirect
    LS_ARGS=$(echo "$CMD" | sed -E 's/^[[:space:]]*ls[[:space:]]*//' | awk '{$1=$1; print}')
    if [ -z "$LS_ARGS" ]; then
      BLOCK_MSG="❌ 인자 없는 'ls'는 Glob('**/*')을 사용하세요. ls <path>, ls *.ext는 허용."
    fi
    ;;
  grep|rg)
    if ! echo "$CMD" | grep -qE '\||<'; then
      BLOCK_MSG="❌ '$FIRST'는 Grep 도구를 사용하세요. ripgrep 기반 + 권한 최적화 + 더 나은 출력."
    fi
    ;;
  find)
    BLOCK_MSG="❌ 'find'는 Glob 도구를 사용하세요. (예: '**/*.ts' 패턴)"
    ;;
esac

if [ -n "$BLOCK_MSG" ]; then
  # PreToolUse deny output
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$BLOCK_MSG\"}}"
  exit 0
fi

exit 0
