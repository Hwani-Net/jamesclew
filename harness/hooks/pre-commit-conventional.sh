#!/bin/bash
# pre-commit-conventional.sh — PreToolUse hook (Bash)
# Enforces Conventional Commits format on git commit commands.
# Supports Unicode scopes (e.g. Korean): feat(블로그): description
# v3 — Refactored: _deny first, awk HEREDOC, sed -m extraction,
#      empty-string denial, no grep -P dependency

# ── Helper: emit deny JSON (must be declared before any use) ──────────────────
_deny() {
  local reason
  reason=$(printf '%s' "$1" | head -c 200 | sed 's/\/\\/g; s/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
}

# ── 1. Read stdin safely ──────────────────────────────────────────────────────
[ -t 0 ] && exit 0
INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

# Strip NUL bytes / control chars
INPUT=$(printf '%s' "$INPUT" | tr -d '\000-\010\013\014\016-\037' 2>/dev/null || printf '%s' "$INPUT")

# ── 2. Parse tool_name ───────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
else
  TOOL_NAME=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
fi
[ "$TOOL_NAME" != "Bash" ] && exit 0

# ── 3. Extract command ────────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  CMD=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"[[:space:]]*$/\1/')
fi
[ -z "$CMD" ] && exit 0

# ── 4. Gate: only intercept git commit ───────────────────────────────────────
printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit' || exit 0

# ── 5. Skip flags that reuse/bypass message input ────────────────────────────
printf '%s' "$CMD" | grep -qE '(--no-edit|-C[[:space:]]|--allow-empty-message)' && exit 0

# ── 6. Detect whether -m flag is present ─────────────────────────────────────
# Used to distinguish "can't parse" (allow) from "-m ''" (deny)
HAS_M_FLAG=0
printf '%s' "$CMD" | grep -qE '[[:space:]]-m[[:space:]]' && HAS_M_FLAG=1

# ── 7. Extract commit message ────────────────────────────────────────────────
MSG=""

# Strategy A: HEREDOC — awk captures first non-empty content line
if printf '%s' "$CMD" | grep -qE "<<['\"]?EOF['\"]?"; then
  MSG=$(printf '%s' "$CMD" | awk '
    /<<'"'"'?"?EOF"?'"'"'?/ { capturing=1; next }
    /^[[:space:]]*EOF[[:space:]]*$/ { capturing=0; next }
    capturing && /[^[:space:]]/ { gsub(/^[[:space:]]+/, ""); print; exit }
  ')
fi

# Strategy B: -m "message"  (double-quoted)
if [ -z "$MSG" ]; then
  MSG=$(printf '%s' "$CMD" | sed -n 's/.*-m[[:space:]]\{1,\}"\([^"]*\)".*/\1/p' | head -1)
fi

# Strategy C: -m 'message'  (single-quoted)
if [ -z "$MSG" ]; then
  MSG=$(printf '%s' "$CMD" | sed -n "s/.*-m[[:space:]]\{1,\}'\([^']*\)'.*/\1/p" | head -1)
fi

# Sanitise
MSG=$(printf '%s' "$MSG" | tr -d '\000-\010\013\014\016-\037' 2>/dev/null || printf '%s' "$MSG")

# ── 8. Empty message checks ───────────────────────────────────────────────────
if [ -z "$MSG" ]; then
  # -m flag was present but message extracted empty → explicit empty commit
  if [ "$HAS_M_FLAG" -eq 1 ]; then
    _deny "Conventional Commits 위반: 빈 커밋 메시지. 형식: type(scope)?: description"
    exit 0
  fi
  # No -m flag + no message → can't determine, allow through
  exit 0
fi

# Pure whitespace → deny
TRIMMED=$(printf '%s' "$MSG" | tr -d '[:space:]')
if [ -z "$TRIMMED" ]; then
  _deny "Conventional Commits 위반: 빈 커밋 메시지. 형식: type(scope)?: description"
  exit 0
fi

# ── 9. Validate Conventional Commits ─────────────────────────────────────────
# Format: type[(scope)][!]: description (≥1 char after ": ")
# type: controlled list only — blocks "WIP", "added new feature", etc.
# scope: optional, parenthesised — [^)]+ matches Unicode (Korean, etc.)
# !: optional breaking-change indicator
CC_TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
CC_REGEX="^(${CC_TYPES})(\([^)]+\))?!?: .+"

if printf '%s' "$MSG" | grep -qE "$CC_REGEX" 2>/dev/null; then
  exit 0
fi

# ── 10. Deny with preview ─────────────────────────────────────────────────────
_deny "Conventional Commits 위반: '$(printf '%s' "$MSG" | head -c 80)'. 형식: type(scope)?: description — 예) feat(auth): add login"
exit 0
