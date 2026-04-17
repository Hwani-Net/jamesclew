#!/bin/bash
# ============================================================================
# BUILD TRANSITION GUARD
# PreToolUse hook on Write|Edit — blocks source code writing until
# PRD and pipeline-install are done (for build sessions).
#
# State files:
#   ~/.harness-state/prd_done          — set by /prd completion
#   ~/.harness-state/pipeline_done     — set by /pipeline-install completion
#   ~/.harness-state/build_detected    — set when build keyword detected
# ============================================================================

INPUT=$(cat)
PROJECT_HASH=$(echo "$PWD" | md5sum | cut -c1-8)
STATE_DIR="$HOME/.harness-state/build-$PROJECT_HASH"
mkdir -p "$STATE_DIR"

# Extract file path from input
FILE=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"//')
if [ -z "$FILE" ]; then
  FILE=$(echo "$INPUT" | grep -oE '"path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"path"\s*:\s*"//;s/"//')
fi

# Skip if no file path
[ -z "$FILE" ] && exit 0

# Skip non-source files (allow CLAUDE.md, plan files, config, docs, state files)
# Normalize Windows backslashes to forward slashes
FILE=$(echo "$FILE" | tr '\\' '/')

case "$FILE" in
  *CLAUDE.md|*README*|*.md|*package.json|*firebase.json|*.firebaserc|*tsconfig*|*.gitignore|*.claude/*|*harness/*|*state/*|*PRD*|*prd*)
    exit 0
    ;;
esac

# Skip if no build was detected in this session
[ ! -f "$STATE_DIR/build_detected" ] && exit 0

# Check if PRD and pipeline are done
PRD_DONE=0
PIPE_DONE=0
[ -f "$STATE_DIR/prd_done" ] && PRD_DONE=1
[ -f "$STATE_DIR/pipeline_done" ] && PIPE_DONE=1

# Check if /plan was entered
PLAN_DONE=0
[ -f "$STATE_DIR/plan_done" ] && PLAN_DONE=1

# If all three done, check ANNOTATE-APPROVED gate
if [ "$PRD_DONE" -eq 1 ] && [ "$PIPE_DONE" -eq 1 ] && [ "$PLAN_DONE" -eq 1 ]; then
  # Check for plan files in project root
  PLAN_FILE=""
  for candidate in "PLAN.md" "plan.md" docs/plan-*.md; do
    # Expand glob
    if [ -f "$candidate" ]; then
      PLAN_FILE="$candidate"
      break
    fi
  done
  # Also check docs/ glob explicitly
  if [ -z "$PLAN_FILE" ]; then
    PLAN_FILE=$(ls docs/plan-*.md 2>/dev/null | head -1)
  fi

  if [ -n "$PLAN_FILE" ]; then
    # Plan file exists — check for ANNOTATE-APPROVED header
    if ! grep -q "<!-- ANNOTATE-APPROVED" "$PLAN_FILE" 2>/dev/null; then
      echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Plan not yet annotate-approved. Run /annotate-plan ${PLAN_FILE} first. Plan file found: ${PLAN_FILE}\"}}" >&2
      exit 2
    fi
  fi
  # No plan file found (low-complexity) or annotate-approved → allow
  exit 0
fi

# Build blocking message
MISSING=""
[ "$PRD_DONE" -eq 0 ] && MISSING="${MISSING}/prd "
[ "$PIPE_DONE" -eq 0 ] && MISSING="${MISSING}/pipeline-install "
[ "$PLAN_DONE" -eq 0 ] && MISSING="${MISSING}/plan(EnterPlanMode) "

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"[BUILD TRANSITION BLOCK] 소스 코드 작성 차단. ${MISSING}먼저 실행하세요. 완료 후 state 파일 생성됩니다. 단순 일회성 유틸리티라면 판단 근거 명시 후 echo skip > ${STATE_DIR}/prd_done && echo skip > ${STATE_DIR}/pipeline_done 으로 우회 가능.\"}}" >&2
exit 2
