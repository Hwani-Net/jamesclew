#!/bin/bash
# pre-commit-conventional.sh — PreToolUse hook (Bash)
# Enforces Conventional Commits format on git commit commands
# Supports Korean scope: feat(블로그): description

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$TOOL_NAME" != "Bash" ] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Only intercept git commit commands
echo "$CMD" | grep -qE 'git\s+commit' || exit 0
# Skip --no-edit (amend/merge) and -C (reuse message)
echo "$CMD" | grep -qE '\-\-no\-edit|\-C\s' && exit 0

# Extract commit message
MSG=""
# HEREDOC style
if echo "$CMD" | grep -qE "<<'?EOF'?"; then
  MSG=$(echo "$CMD" | sed -n "/<<'\\?EOF'\\?/,/^[[:space:]]*EOF/p" | grep -v "EOF" | head -1 | sed 's/^[[:space:]]*//')
fi
# -m "message" or -m 'message'
if [ -z "$MSG" ]; then
  MSG=$(echo "$CMD" | grep -oP '(?<=-m\s")[^"]+' 2>/dev/null || \
        echo "$CMD" | grep -oP "(?<=-m\s')[^']+" 2>/dev/null)
fi
# Can't extract = allow through (don't block on parse failure)
[ -z "$MSG" ] && exit 0

# Validate Conventional Commits format (allows Unicode in scope for Korean)
VALID=$(echo "$MSG" | grep -cE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?: .{3,}' 2>/dev/null)
VALID=${VALID:-0}

if [ "$VALID" -eq 0 ]; then
  DENY_MSG="Conventional Commits 위반: '$(echo "$MSG" | head -c 80)'. 형식: type(scope)?: description"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$DENY_MSG\"}}"
  exit 0
fi

exit 0
