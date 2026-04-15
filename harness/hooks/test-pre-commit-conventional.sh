#!/bin/bash
# test-pre-commit-conventional.sh — Unit tests for pre-commit-conventional.sh
# Tests 10 cases: 8 standard + 2 edge cases
# Usage: bash harness/hooks/test-pre-commit-conventional.sh

HOOK="$(dirname "$0")/pre-commit-conventional.sh"
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_test() {
  local name="$1"
  local expected="$2"  # "pass" or "fail"
  local cmd="$3"

  # Build JSON input as the hook expects (PreToolUse Bash event)
  local json
  if command -v jq >/dev/null 2>&1; then
    json=$(jq -n --arg cmd "$cmd" '{tool_name:"Bash","tool_input":{"command":$cmd}}')
  else
    # Fallback without jq — escape cmd manually
    local escaped_cmd
    escaped_cmd=$(printf '%s' "$cmd" | sed 's/\\/\\\\/g; s/"/\\"/g')
    json="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"${escaped_cmd}\"}}"
  fi

  local output
  output=$(printf '%s' "$json" | bash "$HOOK" 2>/dev/null)

  # "deny" in output = hook blocked it (FAIL commit)
  local actual
  if printf '%s' "$output" | grep -q '"deny"'; then
    actual="fail"
  else
    actual="pass"
  fi

  if [ "$actual" = "$expected" ]; then
    printf "  ${GREEN}PASS${NC}  %s\n" "$name"
    ((PASS++))
  else
    printf "  ${RED}FAIL${NC}  %-45s  (expected=%s, got=%s)\n" "$name" "$expected" "$actual"
    if [ -n "$output" ]; then
      printf "        output: %s\n" "$(printf '%s' "$output" | head -c 200)"
    fi
    ((FAIL++))
  fi
}

echo "══════════════════════════════════════════════════════"
echo " pre-commit-conventional.sh — Test Suite (10 cases)"
echo "══════════════════════════════════════════════════════"
echo ""
echo "--- PASS cases ---"

# TC1: standard feat with scope
run_test "TC1  feat(auth): add login" \
  "pass" 'git commit -m "feat(auth): add login"'

# TC2: fix without scope
run_test "TC2  fix: correct typo" \
  "pass" 'git commit -m "fix: correct typo"'

# TC3: Korean scope
run_test "TC3  feat(블로그): 신규 포스트 [Korean scope]" \
  "pass" 'git commit -m "feat(블로그): 신규 포스트"'

# TC4: HEREDOC style (simulated as the hook sees the raw command string)
HEREDOC_CMD=$'git commit -m "$(cat <<\'EOF\'\n   feat(harness): add hook\n   EOF\n   )"'
run_test "TC4  HEREDOC feat(harness): add hook" \
  "pass" "$HEREDOC_CMD"

# TC8: --no-edit should be skipped entirely
run_test "TC8  git commit --no-edit [amend/merge skip]" \
  "pass" 'git commit --no-edit'

# TC9: breaking change indicator (!)
run_test "TC9  feat!: breaking change [! indicator]" \
  "pass" 'git commit -m "feat!: breaking change drops v1 API"'

echo ""
echo "--- FAIL cases ---"

# TC5: plain English prose (no type prefix)
run_test "TC5  'added new feature' [no type]" \
  "fail" 'git commit -m "added new feature"'

# TC6: WIP
run_test "TC6  'WIP' [bare keyword]" \
  "fail" 'git commit -m "WIP"'

# TC7: type only, no ": description"
run_test "TC7  'fix' [no description]" \
  "fail" 'git commit -m "fix"'

# TC10: empty message (edge case)
run_test "TC10 '' [empty message]" \
  "fail" 'git commit -m ""'

echo ""
echo "══════════════════════════════════════════════════════"
printf " Results: %d PASS  /  %d FAIL  /  10 total\n" "$PASS" "$FAIL"
echo "══════════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
